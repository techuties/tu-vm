#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="logs"; mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/wg_${TIMESTAMP}.log"

VPN_CONFIG_DIR="${VPN_CONFIG_DIR:-wg-configs}"
VPN_FAIL_MODE="${VPN_FAIL_MODE:-closed}"   # closed|open
VPN_HEALTH_URL="${VPN_HEALTH_URL:-https://1.1.1.1}"

echo "[wg-manager] log: $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

green() { echo -e "\033[0;32m$*\033[0m"; }
yellow() { echo -e "\033[1;33m$*\033[0m"; }
red() { echo -e "\033[0;31m$*\033[0m"; }

require_tools() {
  for t in wg wg-quick ip iptables curl; do
    command -v "$t" >/dev/null || { red "Missing tool: $t"; exit 1; }
  done
}

pick_random_config() {
  mapfile -t files < <(find "$VPN_CONFIG_DIR" -maxdepth 1 -type f -name "*.conf" | sort -R)
  if [[ ${#files[@]} -eq 0 ]]; then
    red "No .conf files in $VPN_CONFIG_DIR"; exit 1;
  fi
  printf '%s\n' "${files[@]}"
}

apply_killswitch() {
  # Basic leak protection: allow lo and LAN, allow wg0, drop other outbound
  iptables -C OUTPUT -o lo -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o lo -j ACCEPT
  iptables -C OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  # Detect LAN iface
  local lan_if; lan_if=$(ip route | awk '/default/ {print $5; exit}')
  if [[ -n "$lan_if" ]]; then
    iptables -C OUTPUT -o "$lan_if" -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o "$lan_if" -d 192.168.0.0/16 -j ACCEPT
    iptables -C OUTPUT -o "$lan_if" -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o "$lan_if" -d 10.0.0.0/8 -j ACCEPT
    iptables -C OUTPUT -o "$lan_if" -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o "$lan_if" -d 172.16.0.0/12 -j ACCEPT
  fi
  iptables -C OUTPUT -o wg0 -j ACCEPT 2>/dev/null || iptables -A OUTPUT -o wg0 -j ACCEPT
  iptables -C OUTPUT -j DROP 2>/dev/null || iptables -A OUTPUT -j DROP
}

clear_killswitch() {
  iptables -D OUTPUT -j DROP 2>/dev/null || true
  iptables -D OUTPUT -o wg0 -j ACCEPT 2>/dev/null || true
  iptables -D OUTPUT -o lo -j ACCEPT 2>/dev/null || true
  iptables -D OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
  local lan_if; lan_if=$(ip route | awk '/default/ {print $5; exit}')
  if [[ -n "$lan_if" ]]; then
    iptables -D OUTPUT -o "$lan_if" -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || true
    iptables -D OUTPUT -o "$lan_if" -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || true
    iptables -D OUTPUT -o "$lan_if" -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || true
  fi
}

health_check() {
  curl -m 5 --interface wg0 -fsS "$VPN_HEALTH_URL" >/dev/null
}

bring_up() {
  require_tools
  mkdir -p /etc/wireguard
  local tried=0 success=0 current
  mapfile -t cfgs < <(pick_random_config)
  for f in "${cfgs[@]}"; do
    tried=$((tried+1))
    yellow "Trying config: $f"
    sudo install -m 600 "$f" /etc/wireguard/wg0.conf
    sudo wg-quick down wg0 >/dev/null 2>&1 || true
    if sudo wg-quick up wg0; then
      apply_killswitch
      if health_check; then
        green "VPN up and healthy with: $f"
        echo "$f" > "$LOG_DIR/wg_active.conf"
        success=1
        break
      else
        yellow "Health check failed; tearing down and trying next"
        sudo wg-quick down wg0 || true
      fi
    else
      yellow "wg-quick up failed; trying next"
    fi
  done
  if [[ $success -eq 0 ]]; then
    if [[ "$VPN_FAIL_MODE" == "open" ]]; then
      yellow "All configs failed; fail-open: clearing killswitch"
      clear_killswitch
    else
      red "All configs failed; fail-closed: killswitch active, no WAN egress"
      apply_killswitch
    fi
    return 1
  fi
}

bring_down() {
  sudo wg-quick down wg0 >/dev/null 2>&1 || true
  if [[ "${VPN_FAIL_MODE:-closed}" == "open" ]]; then
    clear_killswitch
  else
    apply_killswitch
  fi
}

rotate() {
  local current; current=$(cat "$LOG_DIR/wg_active.conf" 2>/dev/null || true)
  require_tools
  mkdir -p /etc/wireguard
  mapfile -t cfgs < <(find "$VPN_CONFIG_DIR" -maxdepth 1 -type f -name "*.conf" | sort -R)
  for f in "${cfgs[@]}"; do
    [[ "$f" == "$current" ]] && continue
    yellow "Rotating to: $f"
    sudo install -m 600 "$f" /etc/wireguard/wg0.conf
    sudo wg-quick down wg0 >/dev/null 2>&1 || true
    if sudo wg-quick up wg0; then
      apply_killswitch
      if health_check; then
        green "Rotated and healthy: $f"
        echo "$f" > "$LOG_DIR/wg_active.conf"
        return 0
      else
        sudo wg-quick down wg0 || true
      fi
    fi
  done
  red "Rotation failed; keeping previous state"
  return 1
}

status() {
  echo "=== wg status ==="
  sudo wg show || true
  echo "Active config: $(cat "$LOG_DIR/wg_active.conf" 2>/dev/null || echo none)"
  ip route | sed -n '1,5p'
}

case "${1:-}" in
  start) bring_up ;;
  stop) bring_down ;;
  rotate) rotate ;;
  status) status ;;
  *) echo "Usage: $0 {start|stop|rotate|status}"; exit 1 ;;
esac


