#!/bin/bash
set -euo pipefail

# Reliable, cron-safe sync of Open WebUI uploads -> MinIO bucket
# - Uses MinIO mc via host-published API (127.0.0.1:9000)
# - Resolves MinIO password deterministically
# - Syncs recursively to bucket: tika-pipe

echo "[sync-openwebui-minio] Starting sync..."

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$SCRIPT_DIR"
ENV_FILE="$ROOT_DIR/.env"
BUCKET="tika-pipe"
ACCESS_KEY="admin"

SRC_VOL="${OPENWEBUI_UPLOADS_VOLUME:-}"
if [ -z "$SRC_VOL" ]; then
  SRC_VOL=$(docker inspect ai_openwebui --format '{{range .Mounts}}{{if eq .Destination "/app/backend/data/uploads"}}{{.Name}}{{end}}{{end}}' 2>/dev/null || true)
fi
SRC_VOL="${SRC_VOL:-tu-vm_openwebui_files}"

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

MC_ENV="MC_HOST_local=http://${ACCESS_KEY}:${MINIO_PASS}@127.0.0.1:9000"

# MinIO must be running (Tier 1)
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
docker run --rm --network host -e "$MC_ENV" minio/mc mb --ignore-existing "local/${BUCKET}" >/dev/null

echo "[sync-openwebui-minio] Syncing uploads -> MinIO bucket '$BUCKET' (excluding .txt outputs)..."
docker run --rm --network host -e "$MC_ENV" -v "$SRC_VOL":/source:ro minio/mc \
  mirror --overwrite --exclude '*.txt' /source "local/${BUCKET}" >/dev/null

echo "[sync-openwebui-minio] Sync completed successfully."

echo "[sync-openwebui-minio] Starting reverse sync (.txt from MinIO -> Open WebUI volume) ..."

echo "[sync-openwebui-minio] Mirroring TXT files from 'local/$BUCKET' to '$SRC_VOL' volume..."
docker run --rm --network host -e "$MC_ENV" -v "$SRC_VOL":/dest minio/mc \
  mirror --overwrite --include '*.txt' "local/${BUCKET}" /dest/ >/dev/null

echo "[sync-openwebui-minio] Reverse sync completed."
