#!/usr/bin/env bash
# Validate helper_index JSON contracts (requires ai_helper_index running).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! docker info >/dev/null 2>&1; then
  echo "[contract] SKIP: Docker not available"
  exit 0
fi

if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx ai_helper_index; then
  echo "[contract] SKIP: ai_helper_index not running"
  exit 0
fi

py_validate() {
  local url="$1"
  local expr="$2"
  docker exec ai_helper_index wget -qO- "$url" | python3 -c "$expr"
}

echo "[contract] GET /status"
py_validate "http://127.0.0.1:9001/status" '
import sys, json
d = json.load(sys.stdin)
assert "vm_ip" in d, "missing vm_ip"
assert "services" in d and isinstance(d["services"], dict), "missing services"
assert "landing" in d["services"], "missing services.landing"
assert "postgres" in d, "missing postgres flag"
'

echo "[contract] GET /announcements"
py_validate "http://127.0.0.1:9001/announcements" '
import sys, json
d = json.load(sys.stdin)
assert "announcements" in d, "missing announcements"
assert "total" in d, "missing total"
'

echo "[contract] POST /control without token -> 401"
code="$(docker exec ai_helper_index curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:9001/control/nginx/stop" || echo 000)"
if [[ "$code" != "401" ]]; then
  echo "[contract] ERROR: expected HTTP 401 without token, got: ${code:-unknown}"
  exit 1
fi

echo "[contract] OK"
