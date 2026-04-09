#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$SCRIPT_DIR/helper/chat-context"
DEST_VOL="docker_openwebui_files"
DEST_DIR="/context-pack"

echo "[seed-chat-context] Seeding context files into Open WebUI uploads volume..."

if [ ! -d "$SRC_DIR" ]; then
  echo "[seed-chat-context] ERROR: source directory not found: $SRC_DIR" >&2
  exit 1
fi

docker run --rm \
  -v "$DEST_VOL":/dest \
  -v "$SRC_DIR":/src:ro \
  alpine:latest sh -c "
    mkdir -p '/dest$DEST_DIR' &&
    cp -f /src/* '/dest$DEST_DIR/' &&
    ls -l '/dest$DEST_DIR'
  "

echo "[seed-chat-context] Done. Files are now available in Open WebUI uploads volume under $DEST_DIR."
echo "[seed-chat-context] Optional: run ./scripts/sync-openwebui-minio.sh if you also want MinIO copies."
