from flask import Flask, request, jsonify
import os, requests, socket, shutil, subprocess

app = Flask(__name__)

def get_vm_ip():
    try:
        result = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        result.connect(("8.8.8.8", 80))
        ip = result.getsockname()[0]
        result.close()
        return ip
    except:
        return "127.0.0.1"

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
    
    # External IP
    try:
        ip = requests.get('https://api.ipify.org', timeout=3).text
        res['external_ip'] = ip
    except Exception:
        res['external_ip'] = ''
    
    return jsonify(res)

@app.route('/health', methods=['GET'])
def health():
    return 'ok', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9001)