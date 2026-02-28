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

PRIORITY_ORDER = {'critical': 0, 'high': 1, 'medium': 2, 'normal': 3, 'low': 4}

TIER1_CONTAINERS = {
    'ai_postgres': 'PostgreSQL',
    'ai_redis': 'Redis',
    'ai_openwebui': 'Open WebUI',
    'ai_pihole': 'Pi-hole',
    'ai_nginx': 'Nginx',
    'ai_helper_index': 'Helper API',
}
TIER2_CONTAINERS = {
    'ai_ollama': 'Ollama',
    'ai_n8n': 'n8n',
    'ai_minio': 'MinIO',
    'ai_qdrant': 'Qdrant',
    'ai_tika': 'Tika',
    'tika_minio_processor': 'Tika-MinIO Processor',
}

def _live_container_health():
    """Query Docker socket for real-time container health of all known services."""
    down = []
    unhealthy = []
    restarting = []
    high_restarts = []
    try:
        r = docker_get("/containers/json?all=true")
        if r.status_code != 200:
            return down, unhealthy, restarting, high_restarts
        containers = r.json()
        known_names = set(TIER1_CONTAINERS) | set(TIER2_CONTAINERS)
        name_lookup = {}
        for c in containers:
            for n in c.get('Names', []):
                clean = n.lstrip('/')
                if clean in known_names:
                    name_lookup[clean] = c
        for cname, label in TIER1_CONTAINERS.items():
            c = name_lookup.get(cname)
            if not c:
                down.append(label)
                continue
            state = c.get('State', '')
            health = (c.get('Status') or '').lower()
            if state == 'restarting':
                restarting.append(label)
            elif state != 'running':
                down.append(label)
            elif 'unhealthy' in health:
                unhealthy.append(label)
        for cname, label in TIER2_CONTAINERS.items():
            c = name_lookup.get(cname)
            if not c:
                continue
            state = c.get('State', '')
            health = (c.get('Status') or '').lower()
            if state == 'restarting':
                restarting.append(label)
            elif state == 'running' and 'unhealthy' in health:
                unhealthy.append(label)
        for cname in list(TIER1_CONTAINERS) + list(TIER2_CONTAINERS):
            try:
                info = docker_inspect(cname)
                if info and info.get('RestartCount', 0) > 5:
                    label = TIER1_CONTAINERS.get(cname) or TIER2_CONTAINERS.get(cname, cname)
                    high_restarts.append((label, info['RestartCount']))
            except Exception:
                pass
    except Exception:
        pass
    return down, unhealthy, restarting, high_restarts


@app.route('/announcements', methods=['GET'])
def announcements():
    """Dynamic announcements based on real-time container state, resource usage, and daily status files."""
    announcements_list = []
    now = datetime.datetime.now()

    # ── 1) Real-time container health (live Docker socket query) ──
    try:
        down, unhealthy, restarting, high_restarts = _live_container_health()

        if down:
            announcements_list.append({
                'title': 'Core Services Down',
                'message': f'{", ".join(down)} {"is" if len(down)==1 else "are"} not running. '
                           f'Run "./tu-vm.sh restart" or use the Start buttons above.',
                'type': 'critical',
                'timestamp': now.isoformat(),
                'priority': 'critical'
            })

        if restarting:
            announcements_list.append({
                'title': 'Services Crash-Looping',
                'message': f'{", ".join(restarting)} {"is" if len(restarting)==1 else "are"} restarting repeatedly. '
                           f'Check logs: docker logs <container>',
                'type': 'critical',
                'timestamp': now.isoformat(),
                'priority': 'critical'
            })

        if unhealthy:
            announcements_list.append({
                'title': 'Unhealthy Services',
                'message': f'{", ".join(unhealthy)} failed health checks. '
                           f'They may recover automatically, or check logs for errors.',
                'type': 'warning',
                'timestamp': now.isoformat(),
                'priority': 'high'
            })

        if high_restarts:
            names = ', '.join(f'{n} ({c}x)' for n, c in high_restarts)
            announcements_list.append({
                'title': 'Excessive Restarts',
                'message': f'High restart counts detected: {names}. '
                           f'This may indicate resource limits or config issues.',
                'type': 'warning',
                'timestamp': now.isoformat(),
                'priority': 'high'
            })
    except Exception:
        pass

    # ── 2) Daily log errors (from cached status file) ──
    try:
        log_file = '/tmp/tu-vm-log-status.json'
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                log_status = json.load(f)
            critical_errors = log_status.get('critical_errors', 0)
            warning_errors = log_status.get('warning_errors', 0)

            if critical_errors > 0:
                sample = (log_status.get('error_details') or '')[:120]
                announcements_list.append({
                    'title': 'Critical Log Errors',
                    'message': f'{critical_errors} critical errors in last 24 h. '
                               f'{("Sample: " + sample) if sample else "Check logs immediately."}',
                    'type': 'critical',
                    'timestamp': log_status.get('last_check') or now.isoformat(),
                    'priority': 'critical'
                })
            elif warning_errors > 0:
                announcements_list.append({
                    'title': 'Log Warnings',
                    'message': f'{warning_errors} warnings in the last 24 h. '
                               f'Run "docker logs <container>" to investigate.',
                    'type': 'warning',
                    'timestamp': log_status.get('last_check') or now.isoformat(),
                    'priority': 'high'
                })
    except Exception:
        pass

    # ── 3) Updates available (from daily status file) ──
    try:
        status_file = '/tmp/tu-vm-update-status.json'
        if os.path.exists(status_file):
            with open(status_file, 'r') as f:
                ustatus = json.load(f)
            if bool(ustatus.get('updates_available')):
                os_n = ustatus.get('os_updates', 0)
                dk_n = ustatus.get('docker_updates', 0)
                parts = []
                if os_n:
                    parts.append(f'{os_n} OS packages')
                if dk_n:
                    parts.append(f'{dk_n} Docker images')
                detail = ' and '.join(parts) if parts else 'Updates'
                announcements_list.append({
                    'title': 'Updates Available',
                    'message': f'{detail} can be updated. Run: sudo ./tu-vm.sh update',
                    'type': 'update',
                    'timestamp': ustatus.get('last_check') or now.isoformat(),
                    'priority': 'high'
                })
    except Exception:
        pass

    # ── 4) Resource pressure (real-time) ──
    try:
        la1, la5, la15 = (0.0, 0.0, 0.0)
        if hasattr(os, 'getloadavg'):
            la1, la5, la15 = os.getloadavg()
        cores = os.cpu_count() or 1

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

        st = os.statvfs('/')
        free_d = (st.f_bavail * st.f_frsize) // (1024 * 1024)

        if la5 > max(1.5, cores):
            announcements_list.append({
                'title': 'High CPU Load',
                'message': f'Load average {la5:.1f} on {cores} cores. '
                           f'Stop idle Tier 2 services to reduce load.',
                'type': 'warning',
                'timestamp': now.isoformat(),
                'priority': 'high'
            })

        if total_mb > 0 and (used_mb / max(1, total_mb)) > 0.85:
            announcements_list.append({
                'title': 'Memory Pressure',
                'message': f'Using {used_mb}/{total_mb} MB ({100*used_mb//total_mb}%). '
                           f'Stop unused services or increase VM memory.',
                'type': 'warning',
                'timestamp': now.isoformat(),
                'priority': 'high'
            })

        if free_d < 2048:
            announcements_list.append({
                'title': 'Low Disk Space',
                'message': f'Only {free_d} MB free. Run: ./tu-vm.sh cleanup',
                'type': 'warning',
                'timestamp': now.isoformat(),
                'priority': 'high'
            })

        try:
            with open('/sys/class/power_supply/BAT0/status', 'r') as f:
                bat_status = f.read().strip()
            with open('/sys/class/power_supply/BAT0/capacity', 'r') as f:
                bat_cap = int(f.read().strip())
            if bat_status == 'Discharging' and bat_cap < 20:
                announcements_list.append({
                    'title': 'Low Battery',
                    'message': f'Battery at {bat_cap}%. Stop Ollama and heavy services to extend runtime.',
                    'type': 'warning',
                    'timestamp': now.isoformat(),
                    'priority': 'high'
                })
            elif bat_status == 'Discharging' and bat_cap < 50:
                announcements_list.append({
                    'title': 'On Battery Power',
                    'message': f'Battery at {bat_cap}%. Tier 2 services consume extra power when running.',
                    'type': 'info',
                    'timestamp': now.isoformat(),
                    'priority': 'medium'
                })
        except (FileNotFoundError, ValueError, OSError):
            pass
    except Exception:
        pass

    # ── 5) Optional host-level security checks ──
    if ENABLE_HOST_CHECKS:
        try:
            try:
                if any(os.path.exists(p) for p in ["/usr/sbin/ufw", "/sbin/ufw", "/usr/bin/ufw"]):
                    ufw_res = subprocess.run(['ufw', 'status'], capture_output=True, text=True, timeout=5)
                    if ufw_res.returncode == 0:
                        out = (ufw_res.stdout or "").lower()
                        if 'inactive' in out:
                            announcements_list.append({
                                'title': 'Firewall Disabled',
                                'message': 'UFW is inactive. Run: sudo ./tu-vm.sh secure',
                                'type': 'warning',
                                'timestamp': now.isoformat(),
                                'priority': 'high'
                            })
                        elif 'allow 80/tcp' in out and 'allow 443/tcp' in out:
                            announcements_list.append({
                                'title': 'Public Access Enabled',
                                'message': 'Services reachable from the internet. '
                                           'Switch to secure mode: sudo ./tu-vm.sh secure',
                                'type': 'warning',
                                'timestamp': now.isoformat(),
                                'priority': 'medium'
                            })
            except Exception:
                pass
        except Exception:
            pass

    # ── 6) Sort by priority (critical first) then deduplicate by title ──
    seen_titles = set()
    unique = []
    for a in sorted(announcements_list, key=lambda x: PRIORITY_ORDER.get(x.get('priority', 'normal'), 3)):
        if a['title'] not in seen_titles:
            seen_titles.add(a['title'])
            unique.append(a)
    announcements_list = unique

    # ── 7) Default healthy status if nothing to report ──
    if not announcements_list:
        announcements_list.append({
            'title': 'All Systems Operational',
            'message': 'All core services are running and healthy.',
            'type': 'info',
            'timestamp': now.isoformat(),
            'priority': 'normal'
        })

    return jsonify({
        'announcements': announcements_list,
        'total': len(announcements_list),
        'last_updated': now.isoformat()
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
            'tika_minio_processor': ('tika_minio_processor', 'tika_minio_processor'),
            'mcp-playwright': ('mcp_playwright', 'mcp-playwright'),
            'mcp-filesystem': ('mcp_filesystem', 'mcp-filesystem'),
            'mcp-fetch': ('mcp_fetch', 'mcp-fetch'),
            'mcp-memory': ('mcp_memory', 'mcp-memory')
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

@app.route('/status/pdf-processing', methods=['GET'])
def status_pdf_processing():
    """Get current PDF processing status from tika-minio-processor"""
    try:
        status_file = '/tmp/tika-processing-status.json'
        if os.path.exists(status_file):
            try:
                with open(status_file, 'r') as f:
                    status = json.load(f)
                # Check if status is recent (within last 30 minutes)
                last_update_str = status.get('last_update') or '1970-01-01T00:00:00'
                try:
                    last_update = datetime.datetime.fromisoformat(last_update_str.replace('Z', '+00:00'))
                except ValueError:
                    # Fallback for older Python versions
                    last_update = datetime.datetime.strptime(last_update_str.split('.')[0], '%Y-%m-%dT%H:%M:%S')
                
                # If status is stale (older than 30 minutes), mark as idle
                if datetime.datetime.now() - last_update < datetime.timedelta(minutes=30):
                    return jsonify(status)
                else:
                    # Stale status - return idle
                    return jsonify({
                        'processing': False,
                        'current_file': None,
                        'progress': 0,
                        'status': 'idle',
                        'error': None
                    })
            except (json.JSONDecodeError, ValueError) as e:
                # Invalid JSON or date format
                return jsonify({
                    'processing': False,
                    'current_file': None,
                    'progress': 0,
                    'status': 'idle',
                    'error': f'Invalid status file format: {str(e)}'
                })
            except (IOError, OSError) as e:
                # File read error
                return jsonify({
                    'processing': False,
                    'current_file': None,
                    'progress': 0,
                    'status': 'idle',
                    'error': f'Failed to read status file: {str(e)}'
                })
        
        # Return empty status if no file
        return jsonify({
            'processing': False,
            'current_file': None,
            'progress': 0,
            'status': 'idle',
            'error': None
        })
    except Exception as e:
        return jsonify({
            'processing': False,
            'current_file': None,
            'progress': 0,
            'status': 'idle',
            'error': f'Unexpected error: {str(e)}'
        }), 500

@app.route('/health', methods=['GET'])
def health():
    return 'ok', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9001)