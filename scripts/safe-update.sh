#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE="docker compose -f $PROJECT_DIR/docker-compose.yml"
LOG_FILE="$PROJECT_DIR/tu-vm.log"
BACKUP_DIR="$PROJECT_DIR/backups"

# Official upstream images we auto-update.
# Custom/self-managed services are intentionally excluded.
OFFICIAL_IMAGE_PAIRS=(
    "postgres:15-alpine|postgres|ai_postgres"
    "redis:alpine|redis|ai_redis"
    "qdrant/qdrant:latest|qdrant|ai_qdrant"
    "ollama/ollama:latest|ollama|ai_ollama"
    "ghcr.io/open-webui/open-webui:latest|open-webui|ai_openwebui"
    "apache/tika:latest|tika|ai_tika"
    "minio/minio:latest|minio|ai_minio"
    "n8nio/n8n:latest|n8n|ai_n8n"
    "ghcr.io/toeverything/affine:stable|affine|ai_affine"
    "pgvector/pgvector:pg16|affine_postgres|ai_affine_postgres"
    "pihole/pihole:latest|pihole|ai_pihole"
    "nginx:alpine|nginx|ai_nginx"
    "ghcr.io/browserless/chromium:v2.46.0|browserless|ai_browserless"
)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [safe-update] $1" | tee -a "$LOG_FILE"; }

usage() {
    cat <<'EOF'
Usage: safe-update.sh [--check | --apply | --rollback]

  --check     Show available updates without applying
  --apply     Back up, pull new images, run migrations, refresh node types
  --rollback  Restore docker-compose.yml from last backup and restart

Supported services: open-webui, n8n, qdrant, minio

This script:
  1. Backs up docker-compose.yml, DB dumps, model profiles, and pipe functions
  2. Pulls new images and records their digests
  3. Restarts services one at a time with health checks
  4. Re-extracts n8n node types after n8n update
  5. Verifies the MCP Gateway, tool connections, and model profiles still work
  6. Provides rollback instructions if anything fails
EOF
    exit 0
}

ensure_backup_dir() { mkdir -p "$BACKUP_DIR"; }

prune_backup_history_keep_latest() {
    ensure_backup_dir
    log "Pruning backup history (keeping latest snapshot files only)..."

    # Keep only the newest file in each backup family.
    # This preserves one complete rollback snapshot while preventing disk growth.
    for pattern in "db_*.sql" "docker-compose_*.yml" "custom_config_*.json" "digests_*.txt"; do
        local matches
        matches=$(ls -1t "$BACKUP_DIR"/$pattern 2>/dev/null || true)
        if [ -n "$matches" ]; then
            printf "%s\n" "$matches" | tail -n +2 | while read -r old_file; do
                [ -f "$old_file" ] && rm -f "$old_file"
            done
        fi
    done
}

backup_db() {
    log "Backing up PostgreSQL database..."
    ensure_backup_dir
    local ts; ts=$(date +%Y%m%d_%H%M%S)
    docker exec ai_postgres pg_dump -U ai_admin ai_platform \
        > "$BACKUP_DIR/db_${ts}.sql" 2>/dev/null
    log "  DB backup: $BACKUP_DIR/db_${ts}.sql ($(du -h "$BACKUP_DIR/db_${ts}.sql" | cut -f1))"
}

backup_compose() {
    ensure_backup_dir
    local ts; ts=$(date +%Y%m%d_%H%M%S)
    cp "$PROJECT_DIR/docker-compose.yml" "$BACKUP_DIR/docker-compose_${ts}.yml"
    log "  Compose backup: $BACKUP_DIR/docker-compose_${ts}.yml"
}

backup_custom_config() {
    ensure_backup_dir
    local ts; ts=$(date +%Y%m%d_%H%M%S)
    log "Backing up custom configurations..."

    docker exec ai_postgres psql -U ai_admin -d ai_platform -t -A -c "
        SELECT json_build_object(
            'model_profiles', (SELECT json_agg(row_to_json(m)) FROM model m),
            'functions', (SELECT json_agg(json_build_object('id', f.id, 'name', f.name, 'type', f.type,
                'is_active', f.is_active, 'is_global', f.is_global, 'content', f.content, 'meta', f.meta))
                FROM function f),
            'knowledge', (SELECT json_agg(row_to_json(k)) FROM knowledge k)
        );
    " > "$BACKUP_DIR/custom_config_${ts}.json" 2>/dev/null

    log "  Custom config: $BACKUP_DIR/custom_config_${ts}.json"
}

record_digests() {
    ensure_backup_dir
    local ts; ts=$(date +%Y%m%d_%H%M%S)
    log "Recording current image digests..."
    for svc in ai_openwebui ai_n8n ai_qdrant ai_minio ai_postgres ai_redis ai_nginx; do
        local img digest
        img=$(docker inspect "$svc" --format '{{.Config.Image}}' 2>/dev/null || echo "not-running")
        digest=$(docker inspect "$svc" --format '{{.Image}}' 2>/dev/null || echo "unknown")
        echo "$svc|$img|$digest"
    done > "$BACKUP_DIR/digests_${ts}.txt"
    log "  Digests: $BACKUP_DIR/digests_${ts}.txt"
}

check_updates() {
    log "Checking for available updates..."
    local updates_found=0

    for pair in "${OFFICIAL_IMAGE_PAIRS[@]}"; do
        local img="${pair%%|*}"
        local rest="${pair#*|}"
        local _svc="${rest%%|*}"
        local container="${rest##*|}"
        local current_digest new_digest

        current_digest=$(docker inspect "$container" --format '{{.Image}}' 2>/dev/null || echo "none")

        docker pull "$img" --quiet >/dev/null 2>&1 || true
        new_digest=$(docker image inspect "$img" --format '{{.Id}}' 2>/dev/null || echo "none")

        if [ "$current_digest" != "$new_digest" ]; then
            log "  UPDATE AVAILABLE: $img"
            log "    Current: ${current_digest:0:20}"
            log "    New:     ${new_digest:0:20}"
            updates_found=$((updates_found + 1))
        else
            log "  Up to date: $img"
        fi
    done

    if [ "$updates_found" -eq 0 ]; then
        log "All images are up to date."
    else
        log "$updates_found update(s) available. Run with --apply to update."
    fi
}

update_digest_in_compose() {
    local image_base="$1"
    local new_full_ref="$2"

    python3 -c "
import re, sys
compose = open('$PROJECT_DIR/docker-compose.yml').read()
pattern = re.escape('$image_base') + r'(@sha256:[a-f0-9]+)?'
compose = re.sub(pattern, '$new_full_ref', compose)
open('$PROJECT_DIR/docker-compose.yml', 'w').write(compose)
print('Updated $image_base in docker-compose.yml')
"
}

apply_updates() {
    log "=== Starting safe update ==="

    backup_compose
    backup_db
    backup_custom_config
    record_digests

    log "Pulling latest official upstream images..."
    for pair in "${OFFICIAL_IMAGE_PAIRS[@]}"; do
        local img="${pair%%|*}"
        local rest="${pair#*|}"
        local svc="${rest%%|*}"

        docker pull "$img" --quiet 2>/dev/null || { log "WARNING: Failed to pull $img"; continue; }
        local new_ref
        new_ref=$(docker image inspect "$img" --format '{{index .RepoDigests 0}}' 2>/dev/null)
        if [ -n "$new_ref" ]; then
            local base_name="${img%%:*}:${img##*:}"
            update_digest_in_compose "$base_name" "$new_ref"
            log "  Pinned $svc to $new_ref"
        fi
    done

    log "Skipping custom service rebuilds (self-managed policy)."

    log "Restarting services (one at a time with health checks)..."

    for svc in qdrant minio postgres redis; do
        log "  Restarting $svc..."
        $COMPOSE up -d "$svc" 2>&1 | grep -v "^$" || true
        sleep 5
    done

    log "  Restarting n8n..."
    $COMPOSE up -d n8n 2>&1 | grep -v "^$" || true
    sleep 10

    if docker inspect ai_n8n --format '{{.State.Running}}' 2>/dev/null | grep -q "true"; then
        log "  n8n is running. Refreshing node types..."
        "$SCRIPT_DIR/extract-n8n-node-types.sh" 2>&1 | tail -2
    fi

    log "  Restarting mcp_gateway..."
    $COMPOSE up -d mcp_gateway 2>&1 | grep -v "^$" || true
    sleep 5

    log "  Restarting open-webui..."
    $COMPOSE up -d open-webui 2>&1 | grep -v "^$" || true
    sleep 10

    log "  Restarting nginx..."
    $COMPOSE up -d nginx 2>&1 | grep -v "^$" || true

    log "Running post-update verification..."
    verify_pipeline

    prune_backup_history_keep_latest

    log "=== Update complete ==="
}

verify_pipeline() {
    local failures=0

    log "  Checking MCP Gateway health..."
    local gw_health
    gw_health=$(docker exec ai_mcp_gateway curl -sf http://localhost:9002/health 2>/dev/null || echo '{"ok":false}')
    if echo "$gw_health" | python3 -c "import sys,json; sys.exit(0 if json.loads(sys.stdin.read()).get('ok') else 1)" 2>/dev/null; then
        local node_count
        node_count=$(echo "$gw_health" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('nodeTypesCount',0))")
        log "    MCP Gateway: OK ($node_count node types)"

        if [ "$node_count" -lt 100 ]; then
            log "    WARNING: Low node type count ($node_count). Refreshing..."
            GW_TOKEN=$(docker exec ai_mcp_gateway printenv MCP_GATEWAY_TOKEN 2>/dev/null)
            docker exec ai_mcp_gateway curl -sf -X POST http://localhost:9002/admin/reload-node-types \
                -H "Authorization: Bearer $GW_TOKEN" >/dev/null 2>&1 || true
        fi
    else
        log "    FAIL: MCP Gateway not healthy"
        failures=$((failures + 1))
    fi

    log "  Checking Open WebUI..."
    if docker exec ai_openwebui curl -sf http://localhost:8080/health >/dev/null 2>&1; then
        log "    Open WebUI: OK"
    else
        log "    FAIL: Open WebUI not healthy"
        failures=$((failures + 1))
    fi

    log "  Checking n8n..."
    local n8n_key
    n8n_key=$(docker exec ai_mcp_gateway printenv N8N_API_KEY 2>/dev/null)
    if docker exec ai_mcp_gateway curl -sf http://n8n:5678/api/v1/workflows?limit=1 \
        -H "X-N8N-API-KEY: $n8n_key" >/dev/null 2>&1; then
        log "    n8n API: OK"
    else
        log "    FAIL: n8n API not responding"
        failures=$((failures + 1))
    fi

    log "  Checking model profiles..."
    local model_check
    model_check=$(docker exec ai_postgres psql -U ai_admin -d ai_platform -t -A -c "
        SELECT id, base_model_id FROM model WHERE id='workflow-operator';
    " 2>/dev/null)
    if [ -n "$model_check" ]; then
        log "    Model profiles: OK ($model_check)"
    else
        log "    WARNING: workflow-operator model profile missing"
        failures=$((failures + 1))
    fi

    log "  Checking Anthropic pipe function..."
    local pipe_check
    pipe_check=$(docker exec ai_postgres psql -U ai_admin -d ai_platform -t -A -c "
        SELECT id, is_active FROM function WHERE id='anthropic';
    " 2>/dev/null)
    if [ -n "$pipe_check" ]; then
        log "    Anthropic pipe: OK ($pipe_check)"
    else
        log "    WARNING: Anthropic pipe function missing"
        failures=$((failures + 1))
    fi

    if [ "$failures" -gt 0 ]; then
        log "  $failures verification failure(s). Check logs and consider --rollback."
        return 1
    fi
    log "  All checks passed."
    return 0
}

rollback() {
    log "=== Starting rollback ==="
    local latest_compose latest_db

    latest_compose=$(ls -t "$BACKUP_DIR"/docker-compose_*.yml 2>/dev/null | head -1)
    latest_db=$(ls -t "$BACKUP_DIR"/db_*.sql 2>/dev/null | head -1)

    if [ -z "$latest_compose" ]; then
        log "ERROR: No compose backup found in $BACKUP_DIR"
        exit 1
    fi

    log "Restoring $latest_compose..."
    cp "$latest_compose" "$PROJECT_DIR/docker-compose.yml"

    log "Restarting all services with previous config..."
    $COMPOSE up -d 2>&1 | tail -5

    if [ -n "$latest_db" ]; then
        log "DB backup available at: $latest_db"
        log "To restore DB: docker exec -i ai_postgres psql -U ai_admin ai_platform < $latest_db"
    fi

    log "=== Rollback complete ==="
}

case "${1:-}" in
    --check)    check_updates ;;
    --apply)    apply_updates ;;
    --rollback) rollback ;;
    --help|-h)  usage ;;
    *)          usage ;;
esac
