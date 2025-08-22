from flask import Flask, request, jsonify
import os, base64, re, subprocess, requests, socket

app = Flask(__name__)

UPLOAD_API_KEY = os.environ.get('UPLOAD_API_KEY', 'change-me-upload-key')
WG_DIR = '/data/wg-configs'
OVPN_DIR = '/data/ovpn-configs'

os.makedirs(WG_DIR, exist_ok=True)
os.makedirs(OVPN_DIR, exist_ok=True)

SAFE_NAME = re.compile(r'^[A-Za-z0-9_.\-]{1,64}$')

def auth_ok(req):
    tok = req.headers.get('Authorization','')
    return tok == f'Bearer {UPLOAD_API_KEY}'

def write_file(dirpath, name, data_b64):
    if not SAFE_NAME.match(name):
        return False, 'invalid name'
    try:
        raw = base64.b64decode(data_b64)
        p = os.path.join(dirpath, name)
        with open(p, 'wb') as f:
            f.write(raw)
        os.chmod(p, 0o600)
        return True, p
    except Exception as e:
        return False, str(e)

@app.route('/upload/wg', methods=['POST'])
def upload_wg():
    if not auth_ok(request):
        return ('', 401)
    j = request.get_json(force=True, silent=True) or {}
    name = j.get('name','')
    data = j.get('data','')
    if not name.endswith('.conf'):
        return jsonify({'ok': False, 'error': 'must end with .conf'}), 400
    ok, res = write_file(WG_DIR, name, data)
    return jsonify({'ok': ok, 'path': res if ok else None, 'error': None if ok else res})

@app.route('/upload/ovpn', methods=['POST'])
def upload_ovpn():
    if not auth_ok(request):
        return ('', 401)
    j = request.get_json(force=True, silent=True) or {}
    name = j.get('name','')
    data = j.get('data','')
    if not name.endswith('.ovpn'):
        return jsonify({'ok': False, 'error': 'must end with .ovpn'}), 400
    ok, res = write_file(OVPN_DIR, name, data)
    return jsonify({'ok': ok, 'path': res if ok else None, 'error': None if ok else res})

@app.route('/vpn/rotate', methods=['POST'])
def rotate():
    if not auth_ok(request):
        return ('', 401)
    # Call host webhook to rotate
    try:
        token=os.environ.get('VPN_WEBHOOK_TOKEN','')
        for host in ['host.docker.internal','172.17.0.1','172.20.0.1','127.0.0.1']:
            try:
                r = requests.post(f'http://{host}:9099/rotate', headers={'Authorization': f'Bearer {token}'}, timeout=2)
                if r.status_code==200:
                    return jsonify({'ok': True})
            except Exception:
                continue
        return jsonify({'ok': False}), 502
    except Exception:
        return jsonify({'ok': False}), 500

@app.route('/health', methods=['GET'])
def health():
    return 'ok', 200

@app.route('/status', methods=['GET'])
def status():
    # Check key services
    res = {}
    # Ollama via Nginx (service name) with host header
    try:
        r = requests.get('https://nginx/health', headers={'Host':'ollama.tu.local'}, verify=False, timeout=2)
        res['ollama'] = r.ok
    except Exception:
        res['ollama'] = False
    # Postgres
    try:
        # simple TCP connect
        s=socket.create_connection(('postgres',5432),timeout=2); s.close(); res['postgres']=True
    except Exception:
        res['postgres']=False
    # Redis
    try:
        s=socket.create_connection(('redis',6379),timeout=2); s.close(); res['redis']=True
    except Exception:
        res['redis']=False
    # Qdrant
    try:
        s=socket.create_connection(('qdrant',6333),timeout=2); s.close(); res['qdrant']=True
    except Exception:
        res['qdrant']=False
    # VPN status via webhook
    try:
        token=os.environ.get('VPN_WEBHOOK_TOKEN','')
        j = {}
        for host in ['host.docker.internal','172.17.0.1','172.20.0.1','127.0.0.1']:
            try:
                r = requests.post(f'http://{host}:9099/status_json', headers={'Authorization': f'Bearer {token}'}, timeout=2)
                if r.headers.get('content-type','').startswith('application/json'):
                    j = r.json(); break
            except Exception:
                continue
        res['vpn'] = bool(j.get('ok') and j.get('up'))
        res['vpn_output'] = f"type={j.get('type','')}, iface={j.get('iface','')}, active={j.get('active','')}, vpn_ip={j.get('vpn_ip','')}"
        res['local_ip'] = j.get('local_ip','')
        res['vpn_type'] = j.get('type','')
        res['vpn_active'] = j.get('active','')
        res['vpn_iface'] = j.get('iface','')
        res['vpn_ip'] = j.get('vpn_ip','')
        res['gateway'] = os.environ.get('GATEWAY_ENABLED','false').lower() == 'true'
        res['upload_key_default'] = (os.environ.get('UPLOAD_API_KEY','') == 'change-me-upload-key')
    except Exception:
        res['vpn']=False
    # External IP via ipify (through VM route/VPN)
    try:
        ip = requests.get('https://api.ipify.org', timeout=3).text
        res['ip'] = ip
    except Exception:
        res['ip'] = ''
    return jsonify(res)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9001)


