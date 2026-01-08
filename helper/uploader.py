from flask import Flask, request, jsonify
import os
import json
import datetime
import socket
import subprocess
import ipaddress
from pathlib import Path

import requests
import requests_unixsocket

app = Flask(__name__)
DOCKER_SOCK = '/var/run/docker.sock'
CONTROL_TOKEN = os.environ.get('CONTROL_TOKEN', '')
ALLOWLIST_FILE = os.environ.get("ALLOWLIST_FILE", "/nginx-dynamic/control_allowlist.conf")
DOCKER_SUBNET = os.environ.get("DOCKER_SUBNET", "172.20.0.0/16")
# Optional: host-level checks (ufw/auth.log/cert parsing). Off by default because this
# service typically runs in a container without host access.
ENABLE_HOST_CHECKS = os.environ.get("ENABLE_HOST_CHECKS", "") == "1"

# Reuse one session for Docker unix-socket calls
DOCKER_SESSION = requests_unixsocket.Session()

def _authorized(req):
    token = req.headers.get('X-Control-Token') or req.args.get('token')
    if CONTROL_TOKEN:
        return token == CONTROL_TOKEN
    return False  # if token not set, deny by default

def docker_post(path):
    url = f"http+unix://{requests.utils.quote(DOCKER_SOCK, safe='')}" + path
    return DOCKER_SESSION.post(url, timeout=5)

def docker_get(path):
    url = f"http+unix://{requests.utils.quote(DOCKER_SOCK, safe='')}" + path
    return DOCKER_SESSION.get(url, timeout=5)

def docker_kill(container, signal="HUP"):
    url = f"http+unix://{requests.utils.quote(DOCKER_SOCK, safe='')}" + f"/containers/{container}/kill?signal={signal}"
    return DOCKER_SESSION.post(url, timeout=5)

def docker_inspect(container):
    """Check if container exists and return its info, or None if not found."""
    try:
        r = docker_get(f"/containers/{container}/json")
        if r.status_code == 200:
            return r.json()
        return None
    except Exception:
        return None

def get_vm_ip():
    try:
        result = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        result.connect(("8.8.8.8", 80))
        ip = result.getsockname()[0]
        result.close()
        return ip
    except:
        return "127.0.0.1"

def _client_ip():
    """
    Determine the real client IP when behind Nginx.
    Priority:
    - first address in X-Forwarded-For (if present)
    - X-Real-IP
    - Flask remote_addr
    """
    xff = (request.headers.get("X-Forwarded-For") or "").split(",")[0].strip()
    if xff:
        return xff
    xr = (request.headers.get("X-Real-IP") or "").strip()
    if xr:
        return xr
    return request.remote_addr or ""

def _read_allowlist():
    p = Path(ALLOWLIST_FILE)
    if not p.exists():
        return []
    ips = []
    try:
        for line in p.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("allow "):
                val = line[len("allow "):].strip().rstrip(";").strip()
                ips.append(val)
    except Exception:
        return []
    # de-dup preserving order
    seen = set()
    out = []
    for ip in ips:
        if ip not in seen:
            out.append(ip)
            seen.add(ip)
    return out

def _write_allowlist(ips):
    """
    Write allowlist in a stable, human-friendly way.
    - Validates IPs
    - Preserves insertion order (after normalization)
    - Writes atomically
    """
    normalized = []
    seen = set()
    for raw in ips:
        try:
            ip_s = str(ipaddress.ip_address(raw))
        except Exception:
            continue
        if ip_s in seen:
            continue
        normalized.append(ip_s)
        seen.add(ip_s)

    p = Path(ALLOWLIST_FILE)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(p.suffix + ".tmp")
    header = [
        "# Dynamic allowlist for sensitive endpoints (e.g. /control/, /whitelist/*)",
        "# Managed by helper_index and/or tu-vm.sh.",
        "#",
        "# Format:",
        "#   allow 192.0.2.10;",
        "#   allow 2001:db8::1;",
        "#   deny all;",
        "",
    ]
    lines = header + [f"allow {ip};" for ip in normalized] + ["deny all;", ""]
    tmp.write_text("\n".join(lines))
    tmp.replace(p)

def _reload_nginx():
    # Send SIGHUP to nginx container so it reloads config/includes
    try:
        r = docker_kill("ai_nginx", "HUP")
        return r.status_code in (204, 200, 304)
    except Exception:
        return False

@app.route('/status', methods=['GET'])
def status():
    vm_ip = os.environ.get('HOST_IP') or get_vm_ip()
    domain = os.environ.get('DOMAIN', 'tu.local')
    
    # Check key services
    res = {
        'vm_ip': vm_ip,
        'services': {
            'landing': f'https://{domain}',
            'openwebui': f'https://oweb.{domain}',
            'n8n': f'https://n8n.{domain}',
            'pihole': f'https://pihole.{domain}'
        }
    }
    
    # Lightweight hardware exposure (mobile-friendly)
    try:
        # CPU load averages
        if hasattr(os, 'getloadavg'):
            la1, la5, la15 = os.getloadavg()
            res['load_avg'] = {'1m': la1, '5m': la5, '15m': la15}
        # Memory via /proc/meminfo
        meminfo = {}
        with open('/proc/meminfo') as f:
            for line in f:
                k, v = line.split(':', 1)
                meminfo[k.strip()] = v.strip()
        def to_mb(s):
            try:
                return int(s.split()[0]) // 1024
            except Exception:
                return 0
        total = to_mb(meminfo.get('MemTotal', '0 kB'))
        free = to_mb(meminfo.get('MemAvailable', '0 kB'))
        used = max(0, total - free)
        res['memory_mb'] = {'total': total, 'used': used, 'free': free}
        # Disk usage root
        st = os.statvfs('/')
        total_d = (st.f_blocks * st.f_frsize) // (1024*1024)
        free_d = (st.f_bavail * st.f_frsize) // (1024*1024)
        used_d = max(0, total_d - free_d)
        res['disk_mb'] = {'total': total_d, 'used': used_d, 'free': free_d}
        # CPU count
        res['cpu_cores'] = os.cpu_count() or 1
    except Exception:
        pass

    # Check service health
    # Postgres
    try:
        s = socket.create_connection(('postgres', 5432), timeout=2)
        s.close()
        res['postgres'] = True
    except Exception:
        res['postgres'] = False
    
    # Redis
    try:
        s = socket.create_connection(('redis', 6379), timeout=2)
        s.close()
        res['redis'] = True
    except Exception:
        res['redis'] = False
    
    # Qdrant
    try:
        s = socket.create_connection(('qdrant', 6333), timeout=2)
        s.close()
        res['qdrant'] = True
    except Exception:
        res['qdrant'] = False

    # Ollama
    try:
        s = socket.create_connection(('ollama', 11434), timeout=2)
        s.close()
        res['ollama'] = True
    except Exception:
        res['ollama'] = False
    
    # Tika
    try:
        s = socket.create_connection(('ai_tika', 9998), timeout=2)
        s.close()
        res['tika'] = True
    except Exception:
        res['tika'] = False
    
    # MinIO
    try:
        s = socket.create_connection(('ai_minio', 9000), timeout=2)
        s.close()
        res['minio'] = True
    except Exception:
        res['minio'] = False
    
    return jsonify(res)

@app.route('/whitelist/auto', methods=['GET'])
def whitelist_auto():
    """
    Bootstrap: if allowlist is empty, add the requester's IP to the allowlist and reload Nginx.
    Always safe to call from the landing page.
    """
    try:
        docker_net = None
        try:
            docker_net = ipaddress.ip_network(DOCKER_SUBNET, strict=False)
        except Exception:
            docker_net = None

        current = _read_allowlist()
        # Treat a list that only contains docker-internal IPs as "empty" for bootstrap purposes.
        def is_docker_ip(s: str) -> bool:
            if not docker_net:
                return False
            try:
                return ipaddress.ip_address(s) in docker_net
            except Exception:
                return False

        non_docker = [x for x in current if not is_docker_ip(x)]
        if non_docker:
            return jsonify({"ok": True, "changed": False, "ips": current})

        ip = _client_ip()
        try:
            ip_obj = ipaddress.ip_address(ip)
            ip = str(ip_obj)
        except Exception:
            return jsonify({"ok": False, "error": f"invalid client ip '{ip}'"}), 400

        # Do not allow bootstrapping with docker-internal IPs (common when testing from inside containers).
        if is_docker_ip(ip):
            return jsonify({"ok": False, "error": f"refusing to bootstrap with docker-internal ip '{ip}'"}), 400

        # Replace allowlist with the real client IP (and keep any existing non-docker entries)
        _write_allowlist([ip] + non_docker)
        reloaded = _reload_nginx()
        return jsonify({"ok": True, "changed": True, "added": ip, "reloaded": reloaded, "ips": _read_allowlist()})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500

@app.route('/whitelist', methods=['GET'])
def whitelist_list():
    if not _authorized(request):
        return jsonify({'ok': False, 'error': 'unauthorized'}), 401
    return jsonify({"ok": True, "ips": _read_allowlist()})

@app.route('/whitelist/add', methods=['POST'])
def whitelist_add():
    if not _authorized(request):
        return jsonify({'ok': False, 'error': 'unauthorized'}), 401
    data = request.get_json(silent=True) or {}
    ip = (data.get("ip") or request.args.get("ip") or "").strip()
    try:
        ip = str(ipaddress.ip_address(ip))
    except Exception:
        return jsonify({"ok": False, "error": "invalid ip"}), 400
    current = _read_allowlist()
    if ip not in current:
        current.append(ip)
        _write_allowlist(current)
        reloaded = _reload_nginx()
        return jsonify({"ok": True, "changed": True, "ips": _read_allowlist(), "reloaded": reloaded})
    return jsonify({"ok": True, "changed": False, "ips": current})

@app.route('/whitelist/remove', methods=['POST'])
def whitelist_remove():
    if not _authorized(request):
        return jsonify({'ok': False, 'error': 'unauthorized'}), 401
    data = request.get_json(silent=True) or {}
    ip = (data.get("ip") or request.args.get("ip") or "").strip()
    try:
        ip = str(ipaddress.ip_address(ip))
    except Exception:
        return jsonify({"ok": False, "error": "invalid ip"}), 400
    current = _read_allowlist()
    new_list = [x for x in current if x != ip]
    if new_list != current:
        _write_allowlist(new_list)
        reloaded = _reload_nginx()
        return jsonify({"ok": True, "changed": True, "ips": _read_allowlist(), "reloaded": reloaded})
    return jsonify({"ok": True, "changed": False, "ips": current})

@app.route('/updates', methods=['GET'])
def check_updates():
    """Check for available updates and return status"""
    try:
        # Daily cache file written by host script (or defaulted here)
        status_file = '/tmp/tu-vm-update-status.json'

        # If a recent status exists (<24h), return it as-is
        if os.path.exists(status_file):
            try:
                with open(status_file, 'r') as f:
                    status = json.load(f)
                last_check_str = status.get('last_check') or '1970-01-01T00:00:00'
                last_check = datetime.datetime.fromisoformat(last_check_str)
                if datetime.datetime.now() - last_check < datetime.timedelta(hours=24):
                    return jsonify(status)
            except Exception:
                pass

        # If stale or missing, emit a default once-per-day placeholder without running heavy checks here.
        # The host cron (daily-checkup.sh) should refresh this file within the day.
        status = {
            'updates_available': False,
            'last_check': datetime.datetime.now().isoformat(),
            'message': 'Awaiting daily update check (scheduled)',
            'details': '',
            'os_updates': 0,
            'docker_updates': 0,
            'docker_outdated': []
        }
        try:
            with open(status_file, 'w') as f:
                json.dump(status, f)
        except Exception:
            pass
        return jsonify(status)
    except Exception as e:
        return jsonify({
            'updates_available': False,
            'error': str(e),
            'last_check': datetime.datetime.now().isoformat()
        }), 500

@app.route('/announcements', methods=['GET'])
def announcements():
    """Dynamic announcements based on current VM/container state and daily update status."""
    announcements_list = []

    now = datetime.datetime.now()

    # 1) Container health announcements (based on daily health check)
    try:
        health_file = '/tmp/tu-vm-health-status.json'
        if os.path.exists(health_file):
            with open(health_file, 'r') as f:
                health_status = json.load(f)
            
            unhealthy_services = health_status.get('unhealthy_services', [])
            down_services = health_status.get('down_services', [])
            total_restarts = health_status.get('total_restarts', 0)
            
            if down_services:
                announcements_list.append({
                    'title': 'Services Down',
                    'message': f'Critical: {len(down_services)} services are down: {", ".join(down_services)}. Run "./tu-vm.sh restart" to restart services.',
                    'type': 'critical',
                    'timestamp': health_status.get('last_check') or now.isoformat(),
                    'priority': 'critical'
                })
            
            if unhealthy_services:
                announcements_list.append({
                    'title': 'Unhealthy Services',
                    'message': f'Warning: {len(unhealthy_services)} services are unhealthy: {", ".join(unhealthy_services)}. Check service logs and consider restarting.',
                    'type': 'warning',
                    'timestamp': health_status.get('last_check') or now.isoformat(),
                    'priority': 'high'
                })
            
            if total_restarts > 10:
                announcements_list.append({
                    'title': 'Excessive Service Restarts',
                    'message': f'Warning: Services have restarted {total_restarts} times in the last 24h. This may indicate resource issues or configuration problems.',
                    'type': 'warning',
                    'timestamp': health_status.get('last_check') or now.isoformat(),
                    'priority': 'high'
                })
    except Exception:
        pass

    # 2) Log errors announcement (based on daily log check)
    try:
        log_file = '/tmp/tu-vm-log-status.json'
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                log_status = json.load(f)
            errors_found = log_status.get('errors_found', 0)
            critical_errors = log_status.get('critical_errors', 0)
            warning_errors = log_status.get('warning_errors', 0)
            
            if errors_found > 0:
                error_details = log_status.get('error_details', '')
                containers_checked = log_status.get('containers_checked', 0)
                
                if critical_errors > 0:
                    announcements_list.append({
                        'title': 'Critical Log Errors',
                        'message': f'Critical: {critical_errors} critical errors found in logs. Sample: {error_details[:100]}... Check logs immediately.',
                        'type': 'critical',
                        'timestamp': log_status.get('last_check') or now.isoformat(),
                        'priority': 'critical'
                    })
                elif warning_errors > 0:
                    announcements_list.append({
                        'title': 'Log Errors Detected',
                        'message': f'Warning: {warning_errors} errors found in the last 24h across {containers_checked} containers. Sample: {error_details[:100]}... Check logs with "docker logs <container>".',
                        'type': 'warning',
                        'timestamp': log_status.get('last_check') or now.isoformat(),
                        'priority': 'high'
                    })
    except Exception:
        pass

    # 2) Updates announcement (based on daily status file)
    try:
        status_file = '/tmp/tu-vm-update-status.json'
        if os.path.exists(status_file):
            with open(status_file, 'r') as f:
                status = json.load(f)
            updates_available = bool(status.get('updates_available'))
            if updates_available:
                details = status.get('details') or ''
                announcements_list.append({
                    'title': 'Updates Available',
                    'message': details or 'System and/or container updates are available. Run "sudo ./tu-vm.sh update".',
                    'type': 'update',
                    'timestamp': status.get('last_check') or now.isoformat(),
                    'priority': 'high'
                })
    except Exception:
        pass

    # 3) Resource-aware announcements (laptop-friendly guidance)
    try:
        # Load averages
        la1, la5, la15 = (0.0, 0.0, 0.0)
        if hasattr(os, 'getloadavg'):
            la1, la5, la15 = os.getloadavg()
        cores = os.cpu_count() or 1

        # Memory
        meminfo = {}
        with open('/proc/meminfo') as f:
            for line in f:
                k, v = line.split(':', 1)
                meminfo[k.strip()] = v.strip()
        def to_mb(s):
            try:
                return int(s.split()[0]) // 1024
            except Exception:
                return 0
        total_mb = to_mb(meminfo.get('MemTotal', '0 kB'))
        avail_mb = to_mb(meminfo.get('MemAvailable', '0 kB'))
        used_mb = max(0, total_mb - avail_mb)

        # Disk
        st = os.statvfs('/')
        total_d = (st.f_blocks * st.f_frsize) // (1024*1024)
        free_d = (st.f_bavail * st.f_frsize) // (1024*1024)
        used_d = max(0, total_d - free_d)

        # High CPU load announcement
        if la5 > max(1.0, 0.9 * cores):
            announcements_list.append({
                'title': 'High CPU Load Detected',
                'message': f'5‑minute load average {la5:.2f} on {cores} cores. Consider pausing heavy services (e.g., Ollama) when on battery.',
                'type': 'info',
                'timestamp': now.isoformat(),
                'priority': 'normal'
            })

        # Low memory announcement
        if total_mb > 0 and (used_mb / max(1, total_mb)) > 0.80:
            announcements_list.append({
                'title': 'Memory Pressure',
                'message': f'Memory usage {used_mb}/{total_mb} MB. Close unused apps or reduce service limits to save battery.',
                'type': 'warning',
                'timestamp': now.isoformat(),
                'priority': 'high'
            })

        # Low disk space announcement
        if free_d < 2048:  # < 2 GB
            announcements_list.append({
                'title': 'Low Disk Space',
                'message': f'Only {free_d} MB free on root filesystem. Consider running "./tu-vm.sh cleanup" and pruning Docker.',
                'type': 'warning',
                'timestamp': now.isoformat(),
                'priority': 'high'
            })

        # Battery detection (laptop-specific)
        try:
            # Check if running on battery
            with open('/sys/class/power_supply/BAT0/status', 'r') as f:
                battery_status = f.read().strip()
            with open('/sys/class/power_supply/BAT0/capacity', 'r') as f:
                battery_capacity = int(f.read().strip())
            
            # Battery-specific warnings
            if battery_status == 'Discharging' and battery_capacity < 20:
                announcements_list.append({
                    'title': 'Low Battery',
                    'message': f'Battery is at {battery_capacity}% and discharging. Consider stopping resource-intensive services like Ollama to preserve battery.',
                    'type': 'warning',
                    'timestamp': now.isoformat(),
                    'priority': 'high'
                })
            elif battery_status == 'Discharging' and battery_capacity < 50:
                announcements_list.append({
                    'title': 'Battery Mode',
                    'message': f'Running on battery ({battery_capacity}%). Consider stopping Ollama and other heavy services to extend battery life.',
                    'type': 'info',
                    'timestamp': now.isoformat(),
                    'priority': 'medium'
                })
        except:
            pass

    except Exception:
        pass

    # 4) Optional host-level security checks (disabled by default)
    if ENABLE_HOST_CHECKS:
        try:
            # Check UFW firewall status (if ufw exists)
            try:
                if os.path.exists("/usr/sbin/ufw") or os.path.exists("/sbin/ufw") or os.path.exists("/usr/bin/ufw"):
                    ufw_status = subprocess.run(['ufw', 'status'], capture_output=True, text=True, timeout=5)
                    if ufw_status.returncode == 0:
                        ufw_output = (ufw_status.stdout or "").lower()
                        if 'inactive' in ufw_output:
                            announcements_list.append({
                                'title': 'Firewall Disabled',
                                'message': 'UFW firewall is inactive. Run "sudo ./tu-vm.sh secure" to enable secure access control.',
                                'type': 'warning',
                                'timestamp': now.isoformat(),
                                'priority': 'high'
                            })
                        elif 'allow 80/tcp' in ufw_output and 'allow 443/tcp' in ufw_output:
                            announcements_list.append({
                                'title': 'Public Access Enabled',
                                'message': 'Services are accessible from the internet. Consider switching to secure mode with "sudo ./tu-vm.sh secure" for better security.',
                                'type': 'warning',
                                'timestamp': now.isoformat(),
                                'priority': 'medium'
                            })
            except Exception:
                pass

            # Check for failed authentication attempts in logs (if log exists)
            try:
                if os.path.exists('/var/log/auth.log'):
                    auth_failures = subprocess.run(
                        ['grep', '-i', 'failed.*auth', '/var/log/auth.log'],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if auth_failures.returncode == 0 and auth_failures.stdout:
                        failure_count = len(auth_failures.stdout.strip().split('\n'))
                        if failure_count > 5:
                            announcements_list.append({
                                'title': 'Authentication Failures',
                                'message': f'Found {failure_count} authentication failures in logs. Check for unauthorized access attempts.',
                                'type': 'warning',
                                'timestamp': now.isoformat(),
                                'priority': 'high'
                            })
            except Exception:
                pass

            # Check SSL certificate expiration (if openssl and cert exist)
            try:
                cert_file = '/home/tu/docker/ssl/nginx.crt'
                if os.path.exists(cert_file) and (os.path.exists("/usr/bin/openssl") or os.path.exists("/bin/openssl")):
                    cert_info = subprocess.run(
                        ['openssl', 'x509', '-in', cert_file, '-noout', '-dates'],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if cert_info.returncode == 0 and 'notAfter' in (cert_info.stdout or ''):
                        announcements_list.append({
                            'title': 'SSL Certificate Check',
                            'message': 'SSL certificate status checked. Consider renewing self-signed certificates periodically.',
                            'type': 'info',
                            'timestamp': now.isoformat(),
                            'priority': 'low'
                        })
            except Exception:
                pass

        except Exception:
            pass

    # 5) Default system status if nothing else
    if not announcements_list:
        announcements_list.append({
            'title': 'System Status',
            'message': 'All services appear healthy. Power-saving tips: keep Ollama stopped when not using models; prefer mobile-friendly limits.',
            'type': 'info',
            'timestamp': now.isoformat(),
            'priority': 'normal'
        })

    return jsonify({
        'announcements': announcements_list,
        'total': len(announcements_list),
        'last_updated': datetime.datetime.now().isoformat()
    })

@app.route('/control/<service>/<action>', methods=['POST'])
def control_service(service, action):
    """Start/stop a container by name via Docker socket; requires X-Control-Token."""
    try:
        if not _authorized(request):
            return jsonify({'ok': False, 'error': 'unauthorized'}), 401

        # Map logical service names (from compose) to container names and docker-compose service names
        # Compose sets container_name explicitly for core services
        name_map = {
            # Dashboard-controlled services (on-demand)
            'open-webui': ('ai_openwebui', 'open-webui'),
            'n8n': ('ai_n8n', 'n8n'),
            'pihole': ('ai_pihole', 'pihole'),
            'minio': ('ai_minio', 'minio'),
            'ollama': ('ai_ollama', 'ollama'),
            'tika': ('ai_tika', 'tika'),
            'nginx': ('ai_nginx', 'nginx'),
            # Core services (always running, but can be controlled)
            'postgres': ('ai_postgres', 'postgres'),
            'redis': ('ai_redis', 'redis'),
            'qdrant': ('ai_qdrant', 'qdrant'),
            # Helper and processor services
            'helper_index': ('ai_helper_index', 'helper_index'),
            'helper-index': ('ai_helper_index', 'helper_index'),  # Alternative name
            'tika-minio-processor': ('tika_minio_processor', 'tika_minio_processor'),
            'tika_minio_processor': ('tika_minio_processor', 'tika_minio_processor')
        }
        
        container_info = name_map.get(service)
        if container_info:
            container, compose_service = container_info
        else:
            container = service
            compose_service = service

        # Validate action
        if action not in ('start', 'stop'):
            return jsonify({'ok': False, 'error': 'invalid action. Use "start" or "stop"'}), 400

        # Check if container exists before trying to start it
        if action == 'start':
            container_info = docker_inspect(container)
            if not container_info:
                return jsonify({
                    'ok': False,
                    'error': (
                        f'Container {container} does not exist. '
                        f'Create it on the host with: docker compose up -d --no-start {compose_service}'
                    )
                }), 404
            
            # Check if already running
            if container_info.get('State', {}).get('Running', False):
                return jsonify({'ok': True, 'message': f'Container {container} is already running'})
            
            r = docker_post(f"/containers/{container}/start")
        elif action == 'stop':
            container_info = docker_inspect(container)
            if not container_info:
                return jsonify({
                    'ok': False,
                    'error': f'Container {container} not found'
                }), 404
            
            if not container_info.get('State', {}).get('Running', False):
                return jsonify({'ok': True, 'message': f'Container {container} is already stopped'})
            
            r = docker_post(f"/containers/{container}/stop")

        if r.status_code in (204, 304):
            return jsonify({'ok': True, 'message': f'Container {container} {action}ed successfully'})
        
        # Provide better error messages
        try:
            error_body = r.json() if r.text else {}
            error_msg = error_body.get('message', r.text) if r.text else 'Unknown error'
        except:
            error_msg = r.text if r.text else 'Unknown error'
        
        if r.status_code == 404:
            error_msg = f"Container {container} not found. It may need to be created first."
        elif r.status_code == 409:
            error_msg = f"Container {container} is already in the desired state (already {action}ed)"
        elif r.status_code == 500:
            error_msg = f"Internal server error while {action}ing container {container}: {error_msg}"
        
        return jsonify({'ok': False, 'status': r.status_code, 'error': error_msg}), r.status_code if r.status_code >= 400 else 500
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500

# Individual service status endpoints for dashboard
@app.route('/status/oweb', methods=['GET'])
def status_oweb():
    try:
        s = socket.create_connection(('ai_openwebui', 8080), timeout=2)
        s.close()
        return 'ok', 200
    except Exception:
        return 'error', 503

@app.route('/status/n8n', methods=['GET'])
def status_n8n():
    try:
        s = socket.create_connection(('ai_n8n', 5678), timeout=2)
        s.close()
        return 'ok', 200
    except Exception:
        return 'error', 503

@app.route('/status/pihole', methods=['GET'])
def status_pihole():
    try:
        s = socket.create_connection(('ai_pihole', 80), timeout=2)
        s.close()
        return 'ok', 200
    except Exception:
        return 'error', 503

@app.route('/status/ollama', methods=['GET'])
def status_ollama():
    try:
        s = socket.create_connection(('ai_ollama', 11434), timeout=2)
        s.close()
        return 'ok', 200
    except Exception:
        return 'error', 503

@app.route('/status/minio', methods=['GET'])
def status_minio():
    try:
        s = socket.create_connection(('ai_minio', 9000), timeout=2)
        s.close()
        return 'ok', 200
    except Exception:
        return 'error', 503

@app.route('/health', methods=['GET'])
def health():
    return 'ok', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9001)