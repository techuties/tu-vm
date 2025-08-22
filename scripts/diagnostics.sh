#!/usr/bin/env bash
set -euo pipefail

YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log(){ echo -e "${GREEN}[OK]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
fail(){ echo -e "${RED}[FAIL]${NC} $*"; }

cd "$(dirname "$0")/.."

# .env sanity
if [[ -f .env ]]; then
  grep -q '^UPLOAD_API_KEY=' .env && log ".env: UPLOAD_API_KEY present" || warn ".env: UPLOAD_API_KEY missing"
  if grep -q '^UPLOAD_API_KEY=change-me-upload-key' .env; then warn "UPLOAD_API_KEY uses default"; fi
  if grep -q '^VPN_WEBHOOK_TOKEN=change-me-strong-token' .env; then warn "VPN_WEBHOOK_TOKEN uses default"; fi
else
  warn ".env not found"
fi

# Nginx config test
if docker compose exec -T nginx nginx -t >/dev/null 2>&1; then log "nginx config valid"; else fail "nginx config invalid"; fi

# Helper reachability to webhook
TOKEN=$(awk -F= '/^VPN_WEBHOOK_TOKEN=/{print $2}' .env 2>/dev/null | tr -d '"' || true)
if [[ -n "${TOKEN:-}" ]]; then
  if docker compose exec -T helper_index sh -lc "apk add -q --no-cache curl >/dev/null 2>&1 || true; curl -s -m 3 -X POST -H 'Authorization: Bearer $TOKEN' http://host.docker.internal:9099/status_json >/dev/null"; then
    log "helper -> webhook reachable"
  else
    warn "helper -> webhook NOT reachable"
  fi
fi

# VPN status
if curl -sk https://localhost/status/full | grep -q '"vpn": true'; then log "VPN status: up"; else warn "VPN status: down"; fi

# Service health quick checks
curl -sk -H 'Host: ollama.tu.local' https://localhost/health >/dev/null && log "Ollama proxy ok" || warn "Ollama proxy fail"
curl -sk -H 'Host: oweb.tu.local' https://localhost/health >/dev/null && log "Open WebUI proxy ok" || warn "Open WebUI proxy fail"
curl -sk -H 'Host: n8n.tu.local' https://localhost/health >/dev/null && log "n8n proxy ok" || warn "n8n proxy fail"

# UFW rules for webhook
if sudo ufw status | grep -q '9099'; then log "UFW allows 9099"; else warn "UFW may block 9099"; fi

# File perms for configs
stat -c '%a %n' wg-configs/* 2>/dev/null | awk '$1>600{print}' | sed 's/^/PERM-WARN: /' || true

# Summarize compose state
docker compose ps
