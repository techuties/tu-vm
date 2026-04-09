#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[pre-push] Running local smoke checks..."

echo "[1/4] docker compose config"
docker compose config >/dev/null

echo "[2/4] ./tu-vm.sh help"
./tu-vm.sh help >/dev/null

echo "[3/4] bash -n tu-vm.sh"
bash -n tu-vm.sh

echo "[4/4] bash -n scripts/*.sh"
while IFS= read -r script_file; do
  bash -n "$script_file"
done < <(ls -1 scripts/*.sh 2>/dev/null)

echo "[pre-push] All checks passed."
