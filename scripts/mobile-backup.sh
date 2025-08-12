#!/bin/bash
set -e

BACKUP_DIR="backups/mobile_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

source .env

docker compose exec -T postgres pg_dump -U ai_admin ai_platform > "$BACKUP_DIR/database.sql"

tar czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR" n8n_data ssl .env

rm -rf "$BACKUP_DIR"

echo "Mobile backup created: $BACKUP_DIR.tar.gz"
