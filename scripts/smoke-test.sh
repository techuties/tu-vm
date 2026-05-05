#!/usr/bin/env bash
# TU-VM smoke checks: static validation + optional live HTTPS probes.
# Usage:
#   ./scripts/smoke-test.sh           # static only (compose render, bash -n, check-config)
#   ./scripts/smoke-test.sh --live    # also curl Nginx via localhost (tier 1 assumed up)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LIVE=0
[[ "${1:-}" == "--live" ]] && LIVE=1

compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "[smoke] ERROR: docker compose not available"
    exit 1
  fi
}

echo "[smoke] Phase A — compose + shell syntax"
compose_cmd config --quiet
bash -n tu-vm.sh
while IFS= read -r script_file; do
  bash -n "$script_file"
done < <(find scripts -maxdepth 1 -name '*.sh' -type f 2>/dev/null | sort)

echo "[smoke] Phase B — check-config (non-strict)"
"$ROOT_DIR/scripts/check-config.sh"

if [[ "$LIVE" -eq 1 ]]; then
  echo "[smoke] Phase C — live probes (127.0.0.1, SNI tu.lan / oweb.tu.lan)"
  curl -fsSk -o /dev/null -w "tu.lan /health -> %{http_code}\n" -H "Host: tu.lan" "https://127.0.0.1/health" || {
    echo "[smoke] WARN: landing /health failed (is Nginx up?)"
    exit 1
  }
  curl -fsSk -o /dev/null -w "oweb /health/db -> %{http_code}\n" -H "Host: oweb.tu.lan" "https://127.0.0.1/health/db" || {
    echo "[smoke] WARN: Open WebUI health failed"
    exit 1
  }
  code="$(curl -fsSk -o /dev/null -w '%{http_code}' -H "Host: tu.lan" "https://127.0.0.1/status/full" || echo 000)"
  if [[ "$code" != "200" ]]; then
    echo "[smoke] ERROR: /status/full -> $code"
    exit 1
  fi
  echo "[smoke] /status/full -> 200"
fi

echo "[smoke] OK"
