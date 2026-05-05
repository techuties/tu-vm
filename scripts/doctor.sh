#!/usr/bin/env bash
# Unified diagnostics for TU-VM (human or JSON).
# Usage: ./scripts/doctor.sh [--json]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

JSON_MODE=0
[[ "${1:-}" == "--json" ]] && JSON_MODE=1

compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "compose: unavailable"
    return 1
  fi
}

sect() {
  [[ "$JSON_MODE" -eq 0 ]] && echo "" && echo "=== $* ==="
}

docker_ok=0
docker info >/dev/null 2>&1 && docker_ok=1 || true

if [[ "$JSON_MODE" -eq 1 ]]; then
  export ROOT_DIR
  python3 <<'PYCODE'
import json, subprocess, os
root = os.environ["ROOT_DIR"]
os.chdir(root)

def sh(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL, text=True).strip()
    except subprocess.CalledProcessError:
        return ""

def compose_ps():
    try:
        r = subprocess.run(
            ["docker", "compose", "ps", "--format", "{{.Service}}:{{.Status}}"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=90,
        )
        if r.returncode != 0:
            return ""
        return "\n".join(r.stdout.strip().splitlines()[:40])
    except Exception:
        return ""

compose_ok = subprocess.call(
    ["docker", "compose", "config", "--quiet"],
    cwd=root,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
) == 0
docker_daemon = subprocess.call("docker info >/dev/null 2>&1", shell=True) == 0
nginx_line = ""
if docker_daemon:
    try:
        nginx_line = subprocess.check_output(
            "docker exec ai_nginx nginx -t 2>&1 | tail -1",
            shell=True,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except subprocess.CalledProcessError:
        nginx_line = ""

data = {
    "docker_daemon": docker_daemon,
    "docker_version": sh("docker version --format '{{.Server.Version}}' 2>/dev/null"),
    "compose_config_ok": compose_ok,
    "env_present": os.path.isfile(os.path.join(root, ".env")),
    "ssl_present": os.path.isfile(os.path.join(root, "ssl/nginx.crt"))
    and os.path.isfile(os.path.join(root, "ssl/nginx.key")),
    "allowlist_present": os.path.isfile(os.path.join(root, "nginx/dynamic/control_allowlist.conf")),
    "compose_ps": compose_ps() if docker_daemon else "",
    "nginx_test": nginx_line,
    "disk_root": sh("df -h / 2>/dev/null | tail -1"),
    "memory": sh("free -h 2>/dev/null | grep -E '^Mem:'"),
}
print(json.dumps(data, indent=2))
PYCODE
  exit 0
fi

echo "TU-VM doctor — $(date -Iseconds)"

sect "Docker"
if [[ "$docker_ok" -eq 1 ]]; then
  docker version --format 'Server: {{.Server.Version}}' 2>/dev/null || docker version | head -3
else
  echo "Docker daemon not reachable"
fi

sect "Compose file"
if compose_cmd config --quiet 2>/dev/null; then
  echo "docker compose config: OK"
else
  echo "docker compose config: FAILED"
fi

sect "Configuration audit"
"$ROOT_DIR/scripts/check-config.sh" || true

sect "Containers (summary)"
if [[ "$docker_ok" -eq 1 ]]; then
  compose_cmd ps --format 'table {{.Name}}\t{{.Status}}\t{{.Service}}' 2>/dev/null | head -35 || true
else
  echo "(skipped)"
fi

sect "Nginx config test"
if [[ "$docker_ok" -eq 1 ]] && docker ps --format '{{.Names}}' | grep -qx ai_nginx; then
  docker exec ai_nginx nginx -t 2>&1 || true
else
  echo "(skipped — ai_nginx not running)"
fi

sect "Disk / memory"
df -h / 2>/dev/null | tail -1 || true
free -h 2>/dev/null | grep -E '^Mem:' || true

sect "Optional next steps"
echo "  ./scripts/smoke-test.sh --live       # HTTPS probes (tier 1 up)"
echo "  ./scripts/helper-contract-check.sh   # helper JSON + control 401"
echo "  ./tu-vm.sh health                    # tier health helper"

echo ""
echo "Doctor finished."
