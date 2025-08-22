#!/usr/bin/env bash
set -euo pipefail

# Unified VPN manager for host-level VPN (WireGuard or OpenVPN)
# Goals:
# - Start: pick a random config, bring up tunnel, apply kill-switch, health-check
# - Rotate: switch to a different config
# - Stop: tear down tunnel, adjust kill-switch per fail-mode
# - Status: show current state

LOG_DIR="logs"; mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/vpn_${TIMESTAMP}.log"

# Load environment from .env if present
if [[ -f ./.env ]]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

# Defaults
VPN_TYPE="${VPN_TYPE:-wireguard}"                     # wireguard|openvpn
VPN_ENABLED="${VPN_ENABLED:-false}"
VPN_FAIL_MODE="${VPN_FAIL_MODE:-closed}"               # closed|open
VPN_HEALTH_URL="${VPN_HEALTH_URL:-https://1.1.1.1}"
GATEWAY_ENABLED="${GATEWAY_ENABLED:-false}"

# WireGuard
WG_CONFIG_DIR="${VPN_CONFIG_DIR:-wg-configs}"

# OpenVPN
OVPN_CONFIG_DIR="${OVPN_CONFIG_DIR:-ovpn-configs}"
OVPN_AUTH_FILE="${OVPN_AUTH_FILE:-ovpn-auth.txt}"
OVPN_DEVICE="${OVPN_DEVICE:-tun0}"
OVPN_PIDFILE="/run/openvpn-client.pid"

green() { echo -e "\033[0;32m$*\033[0m"; }
yellow() { echo -e "\033[1;33m$*\033[0m"; }
red() { echo -e "\033[0;31m$*\033[0m"; }

echo "[vpn-manager] log: $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

require_tools() {
  local tools=(ip iptables curl)
  for t in "${tools[@]}"; do
    command -v "$t" >/dev/null || { red "Missing tool: $t"; exit 1; }
  done
  case "$VPN_TYPE" in
    wireguard)
      for t in wg wg-quick; do command -v "$t" >/dev/null || { red "Missing tool: $t"; exit 1; }; done ;;
    openvpn)
      command -v openvpn >/dev/null || { red "Missing tool: openvpn"; exit 1; } ;;
  esac
}

lan_iface() { ip route | awk '/default/ {print $5; exit}'; }

apply_killswitch() {
  # Allow loopback and established
  iptables -C OUTPUT -o lo -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o lo -j ACCEPT
  iptables -C OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  # Allow LAN ranges on LAN interface
  local ifc; ifc=$(lan_iface || true)
  if [[ -n "${ifc:-}" ]]; then
    iptables -C OUTPUT -o "$ifc" -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o "$ifc" -d 192.168.0.0/16 -j ACCEPT
    iptables -C OUTPUT -o "$ifc" -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o "$ifc" -d 10.0.0.0/8 -j ACCEPT
    iptables -C OUTPUT -o "$ifc" -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o "$ifc" -d 172.16.0.0/12 -j ACCEPT
  fi

  # Always allow RFC1918 destinations on any interface (e.g., Docker bridges)
  iptables -C OUTPUT -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT
  iptables -C OUTPUT -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT
  iptables -C OUTPUT -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT

  # Allow tunnel interface
  local tun_if="wg0"; [[ "$VPN_TYPE" == "openvpn" ]] && tun_if="$OVPN_DEVICE"
  iptables -C OUTPUT -o "$tun_if" -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o "$tun_if" -j ACCEPT

  # Drop everything else (egress)
  iptables -C OUTPUT -j DROP 2>/dev/null || iptables -A OUTPUT -j DROP
}

clear_killswitch() {
  iptables -D OUTPUT -j DROP 2>/dev/null || true
  iptables -D OUTPUT -o lo -j ACCEPT 2>/dev/null || true
  iptables -D OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
  local ifc; ifc=$(lan_iface || true)
  if [[ -n "${ifc:-}" ]]; then
    iptables -D OUTPUT -o "$ifc" -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || true
    iptables -D OUTPUT -o "$ifc" -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || true
    iptables -D OUTPUT -o "$ifc" -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || true
  fi
  iptables -D OUTPUT -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || true
  iptables -D OUTPUT -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || true
  iptables -D OUTPUT -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || true
  local tun_if="wg0"; [[ "$VPN_TYPE" == "openvpn" ]] && tun_if="$OVPN_DEVICE"
  iptables -D OUTPUT -o "$tun_if" -j ACCEPT 2>/dev/null || true
}

health_check() {
  local ifc="wg0"; [[ "$VPN_TYPE" == "openvpn" ]] && ifc="$OVPN_DEVICE"
  curl -m 5 --interface "$ifc" -fsS "$VPN_HEALTH_URL" >/dev/null
}

gateway_apply() {
  [[ "$GATEWAY_ENABLED" != "true" ]] && return 0
  local ifc_vpn="wg0"; [[ "$VPN_TYPE" == "openvpn" ]] && ifc_vpn="$OVPN_DEVICE"
  local ifc_lan; ifc_lan=$(lan_iface || true)
  echo "[vpn-manager] Applying gateway mode (LAN $ifc_lan → VPN $ifc_vpn)"
  # Enable forwarding
  sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
  # NAT egress via VPN
  sudo iptables -t nat -C POSTROUTING -o "$ifc_vpn" -j MASQUERADE 2>/dev/null || \
    sudo iptables -t nat -A POSTROUTING -o "$ifc_vpn" -j MASQUERADE
  # Allow forward LAN→VPN and return
  if [[ -n "$ifc_lan" ]]; then
    sudo iptables -C FORWARD -i "$ifc_lan" -o "$ifc_vpn" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
      sudo iptables -A FORWARD -i "$ifc_lan" -o "$ifc_vpn" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -C FORWARD -i "$ifc_vpn" -o "$ifc_lan" -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
      sudo iptables -A FORWARD -i "$ifc_vpn" -o "$ifc_lan" -m state --state ESTABLISHED,RELATED -j ACCEPT
  fi
}

policy_exempt_local_networks() {
  # Ensure local/container networks bypass wg policy routing and use main table
  for cidr in 10.0.0.0/8 172.16.0.0/12 172.17.0.0/16 172.20.0.0/16 192.168.0.0/16; do
    sudo ip -4 rule add to "$cidr" table main pref 100 2>/dev/null || true
  done
}

policy_clear_local_exemptions() {
  for cidr in 10.0.0.0/8 172.16.0.0/12 172.17.0.0/16 172.20.0.0/16 192.168.0.0/16; do
    sudo ip -4 rule del to "$cidr" table main pref 100 2>/dev/null || true
  done
}

gateway_clear() {
  [[ "$GATEWAY_ENABLED" != "true" ]] && return 0
  local ifc_vpn="wg0"; [[ "$VPN_TYPE" == "openvpn" ]] && ifc_vpn="$OVPN_DEVICE"
  local ifc_lan; ifc_lan=$(lan_iface || true)
  echo "[vpn-manager] Clearing gateway mode"
  sudo iptables -t nat -D POSTROUTING -o "$ifc_vpn" -j MASQUERADE 2>/dev/null || true
  if [[ -n "$ifc_lan" ]]; then
    sudo iptables -D FORWARD -i "$ifc_lan" -o "$ifc_vpn" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
    sudo iptables -D FORWARD -i "$ifc_vpn" -o "$ifc_lan" -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
  fi
}

wg_pick_and_up() {
  mapfile -t files < <(find "$WG_CONFIG_DIR" -maxdepth 1 -type f -name "*.conf" | sort -R)
  if [[ ${#files[@]} -eq 0 ]]; then
    yellow "No WireGuard .conf files in $WG_CONFIG_DIR — skipping VPN bring-up"
    return 2
  fi
  mkdir -p /etc/wireguard
  for f in "${files[@]}"; do
    yellow "Trying WG config: $f"
    sudo install -m 600 "$f" /etc/wireguard/wg0.conf
    sudo wg-quick down wg0 >/dev/null 2>&1 || true
    if sudo wg-quick up wg0; then
      apply_killswitch
      policy_exempt_local_networks
      if health_check; then
        green "WG VPN up and healthy: $f"
        echo "$f" > "$LOG_DIR/vpn_active.conf"
        gateway_apply
        return 0
      else
        yellow "WG health check failed; tearing down"
        sudo wg-quick down wg0 || true
      fi
    fi
  done
  return 1
}

ovpn_pick_and_up() {
  mapfile -t files < <(find "$OVPN_CONFIG_DIR" -maxdepth 1 -type f -name "*.ovpn" | sort -R)
  if [[ ${#files[@]} -eq 0 ]]; then
    yellow "No OpenVPN .ovpn files in $OVPN_CONFIG_DIR — skipping VPN bring-up"
    return 2
  fi
  for f in "${files[@]}"; do
    yellow "Trying OVPN config: $f"
    sudo pkill -f "openvpn --config" >/dev/null 2>&1 || true
    sudo rm -f "$OVPN_PIDFILE" >/dev/null 2>&1 || true

    # Start OpenVPN in background
    if [[ -f "$OVPN_AUTH_FILE" ]] && grep -q "auth-user-pass" "$f"; then
      sudo openvpn --config "$f" \
        --daemon \
        --writepid "$OVPN_PIDFILE" \
        --auth-user-pass "$OVPN_AUTH_FILE" \
        --log-append "logs/ovpn_${TIMESTAMP}.log" || true
    else
      sudo openvpn --config "$f" \
        --daemon \
        --writepid "$OVPN_PIDFILE" \
        --log-append "logs/ovpn_${TIMESTAMP}.log" || true
    fi

    # Wait for device
    for i in {1..20}; do
      if ip link show "$OVPN_DEVICE" >/dev/null 2>&1; then break; fi
      sleep 1
    done
    if ! ip link show "$OVPN_DEVICE" >/dev/null 2>&1; then
      yellow "OVPN device $OVPN_DEVICE did not appear; trying next"
      continue
    fi

    apply_killswitch
    policy_exempt_local_networks
    if health_check; then
      green "OVPN up and healthy: $f"
      echo "$f" > "$LOG_DIR/vpn_active.conf"
      gateway_apply
      return 0
    else
      yellow "OVPN health check failed; stopping and trying next"
      sudo pkill -f "openvpn --config" >/dev/null 2>&1 || true
      sudo rm -f "$OVPN_PIDFILE" >/dev/null 2>&1 || true
    fi
  done
  return 1
}

vpn_start() {
  require_tools
  if [[ "$VPN_ENABLED" != "true" ]]; then
    yellow "VPN_ENABLED=false — skipping VPN bring-up"
    return 0
  fi
  case "$VPN_TYPE" in
    wireguard)
      if wg_pick_and_up; then return 0; fi
      rc=$? ;;
    openvpn)
      if ovpn_pick_and_up; then return 0; fi
      rc=$? ;;
    *) red "Unknown VPN_TYPE: $VPN_TYPE"; return 1 ;;
  esac

  if [[ $rc -eq 2 ]]; then
    # No configs found — for fool-proof first run, do not engage kill-switch
    yellow "No VPN configs found; continuing without VPN (no kill-switch)"
    return 0
  fi

  if [[ "$VPN_FAIL_MODE" == "open" ]]; then
    yellow "All configs failed; fail-open — clearing kill-switch"
    clear_killswitch
    return 1
  else
    red "All configs failed; fail-closed — kill-switch active (no WAN egress)"
    apply_killswitch
    return 1
  fi
}

vpn_stop() {
  case "$VPN_TYPE" in
    wireguard)
      sudo wg-quick down wg0 >/dev/null 2>&1 || true ;;
    openvpn)
      sudo pkill -f "openvpn --config" >/dev/null 2>&1 || true
      sudo rm -f "$OVPN_PIDFILE" >/dev/null 2>&1 || true ;;
  esac
  gateway_clear || true
  policy_clear_local_exemptions || true
  if [[ "$VPN_FAIL_MODE" == "open" ]]; then
    clear_killswitch
  else
    apply_killswitch
  fi
}

vpn_rotate() {
  # Simple strategy: stop then start; pick-and-up functions already randomize
  vpn_stop || true
  sleep 1
  vpn_start
}

vpn_status() {
  echo "=== VPN status ==="
  echo "Type: $VPN_TYPE | Enabled: $VPN_ENABLED | Fail mode: $VPN_FAIL_MODE"
  if [[ "$VPN_TYPE" == "wireguard" ]]; then
    sudo wg show || true
    ip a show dev wg0 || true
  else
    ip a show dev "$OVPN_DEVICE" || true
    pgrep -af openvpn || true
  fi
  echo "Active config: $(cat "$LOG_DIR/vpn_active.conf" 2>/dev/null || echo none)"
}

case "${1:-}" in
  start) vpn_start ;;
  stop) vpn_stop ;;
  rotate) vpn_rotate ;;
  status) vpn_status ;;
  systemd-install)
    # Install a systemd unit for vpn-manager (host-level)
    sudo bash -lc 'cat > /etc/systemd/system/tu-vpn.service <<UNIT
[Unit]
Description=TechUties VM VPN Manager
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
Group=root
WorkingDirectory=/home/tu/docker
EnvironmentFile=/home/tu/docker/.env
ExecStart=/home/tu/docker/scripts/vpn-manager.sh start
ExecReload=/home/tu/docker/scripts/vpn-manager.sh rotate
ExecStop=/home/tu/docker/scripts/vpn-manager.sh stop

[Install]
WantedBy=multi-user.target
UNIT'
    sudo systemctl daemon-reload
    echo "Systemd unit installed: tu-vpn.service. Use: sudo systemctl enable --now tu-vpn.service" ;;
  systemd-uninstall)
    sudo rm -f /etc/systemd/system/tu-vpn.service
    sudo systemctl daemon-reload
    echo "Systemd unit removed: tu-vpn.service" ;;
  systemd-install-webhook)
    # Install a systemd unit for the webhook
    sudo bash -lc 'cat > /etc/systemd/system/tu-vpn-webhook.service <<UNIT
[Unit]
Description=TechUties VM VPN Manager Webhook
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/home/tu/docker
EnvironmentFile=/home/tu/docker/.env
ExecStart=/home/tu/docker/scripts/vpn-manager.sh webhook
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
UNIT'
    sudo systemctl daemon-reload
    echo "Systemd unit installed: tu-vpn-webhook.service. Use: sudo systemctl enable --now tu-vpn-webhook.service" ;;
  systemd-uninstall-webhook)
    sudo rm -f /etc/systemd/system/tu-vpn-webhook.service
    sudo systemctl daemon-reload
    echo "Systemd unit removed: tu-vpn-webhook.service" ;;
  webhook)
    # Minimal webhook server for localhost control
    # Requires: VPN_WEBHOOK_ENABLED=true in .env, token in VPN_WEBHOOK_TOKEN
    if [[ "${VPN_WEBHOOK_ENABLED:-false}" != "true" ]]; then echo "webhook disabled"; exit 0; fi
    addr="${VPN_WEBHOOK_ADDR:-0.0.0.0}"; port="${VPN_WEBHOOK_PORT:-9099}"; token="${VPN_WEBHOOK_TOKEN:-}"
    ADDR="$addr" PORT="$port" TOKEN="$token" python3 - <<'PY'
import http.server, socketserver, os, json, subprocess
addr=os.environ.get('ADDR','127.0.0.1'); port=int(os.environ.get('PORT','9099'))
token=os.environ.get('TOKEN','')
class H(http.server.BaseHTTPRequestHandler):
  def _ok(self, d):
    b=json.dumps(d).encode(); self.send_response(200); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(b))); self.end_headers(); self.wfile.write(b)
  def _unauth(self):
    self.send_response(401); self.end_headers()
  def do_POST(self):
    if self.headers.get('Authorization')!=f'Bearer {token}': return self._unauth()
    ln=int(self.headers.get('Content-Length','0') or 0); body=self.rfile.read(ln) if ln else b''
    try: data=json.loads(body or b'{}')
    except: data={}
    if self.path=='/start': rc=subprocess.call(['bash','scripts/vpn-manager.sh','start']); return self._ok({'ok':rc==0})
    if self.path=='/stop': rc=subprocess.call(['bash','scripts/vpn-manager.sh','stop']); return self._ok({'ok':rc==0})
    if self.path=='/rotate': rc=subprocess.call(['bash','scripts/vpn-manager.sh','rotate']); return self._ok({'ok':rc==0})
    if self.path=='/status':
      try:
        out=subprocess.check_output(['bash','scripts/vpn-manager.sh','status'], stderr=subprocess.STDOUT, timeout=5)
        return self._ok({'ok':True,'output':out.decode('utf-8',errors='ignore')})
      except subprocess.CalledProcessError as e:
        return self._ok({'ok':False,'output':e.output.decode('utf-8',errors='ignore') if hasattr(e,'output') else ''})
    if self.path=='/status_json':
      try:
        # Determine type and iface
        vtype=os.environ.get('VPN_TYPE','wireguard')
        iface='wg0' if vtype!='openvpn' else os.environ.get('OVPN_DEVICE','tun0')
        # Interface up? (check link flags)
        up=False
        try:
          link=subprocess.check_output(['ip','-o','link','show','dev',iface], stderr=subprocess.DEVNULL).decode('utf-8','ignore')
          if ('UP' in link) or ('LOWER_UP' in link):
            up=True
        except Exception:
          up=False
        # Active config
        try:
          with open('logs/vpn_active.conf','r') as f:
            active=f.read().strip()
        except Exception:
          active=''
        # External IP via interface
        vpn_ip=''
        if up:
          try:
            # if curl fails, try extracting assigned inet address
            vpn_ip=subprocess.check_output(['curl','-fsS','-m','4','--interface',iface,'https://api.ipify.org']).decode('utf-8').strip()
          except Exception:
            try:
              cmd = f"ip -4 addr show dev {iface} | awk '/inet /{{print $2}}' | cut -d/ -f1 | head -n1"
              inet=subprocess.check_output(['bash','-lc', cmd]).decode('utf-8').strip()
              vpn_ip=inet
            except Exception:
              vpn_ip=''
        # Local IP (first IPv4)
        try:
          local_ip=subprocess.check_output(['bash','-lc','hostname -I | awk "{print $1}"']).decode('utf-8').strip()
        except Exception:
          local_ip=''
        return self._ok({'ok':True,'type':vtype,'iface':iface,'up':up,'active':active,'vpn_ip':vpn_ip,'local_ip':local_ip})
      except Exception as e:
        return self._ok({'ok':False,'error':str(e)})
    self.send_response(404); self.end_headers()
with socketserver.TCPServer((addr,port),H) as httpd:
  print(f'vpn webhook on http://{addr}:{port}'); httpd.serve_forever()
PY
    ;;
  *) echo "Usage: $0 {start|stop|rotate|status}"; exit 1 ;;
esac


