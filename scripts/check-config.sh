#!/usr/bin/env bash
# Pre-flight configuration validation for TU-VM (no secret values printed).
# Usage:
#   ./scripts/check-config.sh           # warnings default; exit 0 unless --strict
#   ./scripts/check-config.sh --strict  # exit 1 on insecure placeholders / missing keys
#   ./scripts/check-config.sh --ci      # CI: assume .env prepared from env.example; skip strict secrets
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STRICT=0
CI_MODE=0
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    --ci) CI_MODE=1 ;;
  esac
done

compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "[check-config] ERROR: docker compose not available"
    exit 1
  fi
}

errs=0
warn() { echo "[check-config] WARN: $*"; [[ "$STRICT" -eq 1 ]] && errs=$((errs + 1)) || true; }
die() { echo "[check-config] ERROR: $*"; exit 1; }

echo "[check-config] Repository root: $ROOT_DIR"

required_files=(
  "docker-compose.yml"
  "env.example"
  "tu-vm.sh"
  "nginx/conf.d/default.conf"
)
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || die "missing required file: $f"
done

allowlist="nginx/dynamic/control_allowlist.conf"
if [[ ! -f "$allowlist" ]]; then
  warn "missing $allowlist (Nginx will fail to start until created)"
else
  echo "[check-config] OK: $allowlist exists"
fi

ssl_crt="ssl/nginx.crt"
ssl_key="ssl/nginx.key"
if [[ ! -f "$ssl_crt" || ! -f "$ssl_key" ]]; then
  warn "TLS files missing ($ssl_crt / $ssl_key) — HTTPS will not start until generated"
else
  echo "[check-config] OK: TLS keypair present"
fi

echo "[check-config] docker compose config"
compose_cmd config --quiet || die "docker compose config failed"

echo "[check-config] bash -n tu-vm.sh"
bash -n tu-vm.sh || die "tu-vm.sh syntax error"

while IFS= read -r script_file; do
  bash -n "$script_file" || die "syntax error in $script_file"
done < <(find scripts -maxdepth 1 -name '*.sh' -type f 2>/dev/null | sort)

if [[ ! -f .env ]]; then
  echo "[check-config] WARN: no .env (copy env.example and configure before runtime)"
  [[ "$CI_MODE" -eq 1 ]] || [[ "$STRICT" -eq 0 ]] || die ".env required in strict mode"
else
  echo "[check-config] validating .env key presence (values hidden)"
  # Required non-empty keys for compose interpolation / runtime
  keys=(
    POSTGRES_PASSWORD
    REDIS_PASSWORD
    AFFINE_DB_PASSWORD
    WEBUI_SECRET_KEY
    CONTROL_TOKEN
  )
  for k in "${keys[@]}"; do
    if ! grep -qE "^${k}=[^[:space:]]+" .env 2>/dev/null; then
      warn ".env missing or empty: $k="
    fi
  done
  if grep -qE '^(POSTGRES_PASSWORD|REDIS_PASSWORD|WEBUI_SECRET_KEY|CONTROL_TOKEN|MCP_GATEWAY_TOKEN|MINIO_ROOT_PASSWORD)=$' .env 2>/dev/null; then
    warn ".env contains empty values for critical keys"
  fi
  if grep -qE '^[^#]*=(CHANGE_ME|PLACEHOLDER)' .env 2>/dev/null; then
    warn ".env still contains CHANGE_ME / PLACEHOLDER style values"
  fi
fi

if [[ "$errs" -gt 0 ]]; then
  echo "[check-config] FAILED strict checks ($errs issue(s))"
  exit 1
fi

echo "[check-config] OK"
