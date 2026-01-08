#!/bin/bash
set -euo pipefail

# Reliable, cron-safe sync of Open WebUI uploads -> MinIO bucket
# - Uses MinIO container's internal mc client via pipe
# - Resolves MinIO password deterministically
# - Syncs recursively to bucket: tika-pipe

echo "[sync-openwebui-minio] Starting sync..."

# Config
# Auto-detect script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$SCRIPT_DIR"
ENV_FILE="$ROOT_DIR/.env"
SRC_VOL="docker_openwebui_files"
BUCKET="tika-pipe"
ACCESS_KEY="admin"

# Resolve MinIO password with precedence:
# 1) MINIO_SYNC_PASSWORD env
# 2) .env MINIO_ROOT_PASSWORD
# 3) env of ai_minio container
MINIO_PASS="${MINIO_SYNC_PASSWORD:-}"
if [ -z "$MINIO_PASS" ] && [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  MINIO_PASS="${MINIO_ROOT_PASSWORD:-}"
fi
if [ -z "$MINIO_PASS" ]; then
  MINIO_PASS=$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' ai_minio | awk -F= '$1=="MINIO_ROOT_PASSWORD"{print $2; exit}') || true
fi
if [ -z "$MINIO_PASS" ]; then
  echo "[sync-openwebui-minio] ERROR: Could not resolve MinIO password. Set MINIO_SYNC_PASSWORD or MINIO_ROOT_PASSWORD in .env" >&2
  exit 1
fi

# MinIO must be running (this stack treats it as on-demand / Tier 2)
if ! docker ps --format "{{.Names}}" | grep -q "^ai_minio$"; then
  echo "[sync-openwebui-minio] MinIO container is not running. Skipping sync."
  exit 0
fi

# Quick check: source volume may be empty; do not treat as error
HAS_FILES=$(docker run --rm -v "$SRC_VOL":/src:ro alpine:latest sh -c 'ls -A /src 2>/dev/null | head -n1 || true') || true
if [ -z "$HAS_FILES" ]; then
  echo "[sync-openwebui-minio] No files found in source volume '$SRC_VOL'. Nothing to sync."
  exit 0
fi

echo "[sync-openwebui-minio] Ensuring bucket '$BUCKET' exists..."
docker run --rm --network docker_ai_network minio/mc \
  sh -c "mc alias set local http://ai_minio:9000 '$ACCESS_KEY' '$MINIO_PASS' >/dev/null && mc mb --ignore-existing local/'$BUCKET' >/dev/null"

echo "[sync-openwebui-minio] Syncing uploads -> MinIO bucket '$BUCKET' (excluding .txt outputs)..."
docker run --rm --network docker_ai_network -v "$SRC_VOL":/source:ro minio/mc \
  sh -c "mc alias set local http://ai_minio:9000 '$ACCESS_KEY' '$MINIO_PASS' >/dev/null && mc mirror --overwrite --exclude '*.txt' /source local/'$BUCKET' >/dev/null"

echo "[sync-openwebui-minio] Sync completed successfully."

echo "[sync-openwebui-minio] Starting reverse sync (.txt from MinIO -> Open WebUI volume) ..."

# Mirror only .txt files back to the Open WebUI volume, exclude PDFs
echo "[sync-openwebui-minio] Mirroring TXT files from 'local/$BUCKET' to '$SRC_VOL' volume..."
docker run --rm --network docker_ai_network -v "$SRC_VOL":/dest minio/mc \
  sh -c "mc alias set local http://ai_minio:9000 '$ACCESS_KEY' '$MINIO_PASS' >/dev/null && mc mirror --overwrite --include '*.txt' local/'$BUCKET' /dest/ >/dev/null"

echo "[sync-openwebui-minio] Reverse sync completed."
