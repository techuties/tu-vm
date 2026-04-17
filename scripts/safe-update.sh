#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE="docker compose -f $PROJECT_DIR/docker-compose.yml"
LOG_FILE="$PROJECT_DIR/tu-vm.log"
BACKUP_DIR="$PROJECT_DIR/backups"

# Service -> upstream tag used to refresh pinned digest refs in docker-compose.yml.
# If a service image is pinned by digest (image@sha256:...), we pull this source tag,
# then rewrite that service's image to the new repo digest.
declare -A PINNED_IMAGE_SOURCES=(
    ["postgres"]="postgres:15-alpine"
    ["redis"]="redis:alpine"
    ["qdrant"]="qdrant/qdrant:latest"
    ["ollama"]="ollama/ollama:latest"
    ["open-webui"]="ghcr.io/open-webui/open-webui:latest"
    ["tika"]="apache/tika:latest"
    ["minio"]="minio/minio:latest"
    ["n8n"]="n8nio/n8n:latest"
    ["affine"]="ghcr.io/toeverything/affine:stable"
    ["affine_migration"]="ghcr.io/toeverything/affine:stable"
    ["affine_postgres"]="pgvector/pgvector:pg16"
    ["affine_redis"]="redis:alpine"
    ["browserless"]="ghcr.io/browserless/chromium:v2.46.0"
    ["pihole"]="pihole/pihole:latest"
    ["nginx"]="nginx:alpine"
)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [safe-update] $1" | tee -a "$LOG_FILE"; }

usage() {
    cat <<'EOF'
Usage: safe-update.sh [--check | --apply | --rollback]

  --check     Show available updates without applying
  --apply     Back up, update all compose services, refresh node types
  --rollback  Restore docker-compose.yml from last backup and restart

Scope: all services in docker-compose.yml

This script:
  1. Backs up docker-compose.yml, DB dumps, model profiles, and pipe functions
  2. Pulls latest images and rebuilds build-based services
  3. Recreates running services and refreshes stopped services without starting them
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

list_compose_services() {
    $COMPOSE config --services 2>/dev/null
}

list_running_services() {
    $COMPOSE ps --services --status running 2>/dev/null || true
}

list_service_specs() {
    $COMPOSE config --format json | python3 -c '
import json,sys
cfg=json.load(sys.stdin)
for name, svc in sorted(cfg.get("services", {}).items()):
    image = svc.get("image", "")
    has_build = "yes" if "build" in svc else "no"
    print(f"{name}|{image}|{has_build}")
'
}

update_service_image_in_compose() {
    local service="$1"
    local new_ref="$2"
    python3 - "$PROJECT_DIR/docker-compose.yml" "$service" "$new_ref" <<'PY'
import re
import sys
from pathlib import Path

compose_path = Path(sys.argv[1])
service = sys.argv[2]
new_ref = sys.argv[3]
content = compose_path.read_text()

pattern = re.compile(
    rf"(^\s{{2}}{re.escape(service)}:\n(?:\s{{4}}.*\n)*?\s{{4}}image:\s*)([^\n]+)",
    re.MULTILINE,
)
match = pattern.search(content)
if not match:
    print(f"WARN: could not find image line for service {service}")
    sys.exit(0)

updated = content[:match.start(2)] + new_ref + content[match.end(2):]
compose_path.write_text(updated)
print(f"Updated {service} image to {new_ref}")
PY
}

refresh_service_image_if_pinned() {
    local service="$1"
    local image_ref="$2"
    local source_tag="${PINNED_IMAGE_SOURCES[$service]:-}"

    if [[ "$image_ref" != *"@sha256:"* ]] || [[ -z "$source_tag" ]]; then
        return 0
    fi

    docker pull "$source_tag" --quiet >/dev/null 2>&1 || {
        log "WARNING: Failed to pull source tag for $service: $source_tag"
        return 1
    }

    local new_ref
    new_ref=$(docker image inspect "$source_tag" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)
    if [[ -n "$new_ref" ]] && [[ "$new_ref" != "$image_ref" ]]; then
        update_service_image_in_compose "$service" "$new_ref" >/dev/null
        log "  Pinned $service to $new_ref"
    fi
}

check_updates() {
    log "Checking for available updates..."
    local updates_found=0

    while IFS='|' read -r svc image_ref has_build; do
        if [[ "$has_build" == "yes" ]]; then
            log "  Build-based service: $svc (will rebuild on --apply)"
            continue
        fi
        if [[ -z "$image_ref" ]]; then
            log "  No image configured for $svc (skipped)"
            continue
        fi

        if [[ "$image_ref" == *"@sha256:"* ]]; then
            local source_tag="${PINNED_IMAGE_SOURCES[$svc]:-}"
            if [[ -z "$source_tag" ]]; then
                log "  Pinned image without source mapping: $svc ($image_ref)"
                continue
            fi
            docker pull "$source_tag" --quiet >/dev/null 2>&1 || {
                log "  WARNING: Failed to pull source for $svc ($source_tag)"
                continue
            }
            local new_ref
            new_ref=$(docker image inspect "$source_tag" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)
            if [[ -n "$new_ref" ]] && [[ "$new_ref" != "$image_ref" ]]; then
                log "  UPDATE AVAILABLE: $svc -> $new_ref"
                updates_found=$((updates_found + 1))
            else
                log "  Up to date: $svc"
            fi
            continue
        fi

        local old_id new_id
        old_id=$(docker image inspect "$image_ref" --format '{{.Id}}' 2>/dev/null || echo "none")
        docker pull "$image_ref" --quiet >/dev/null 2>&1 || {
            log "  WARNING: Failed to pull $svc image ($image_ref)"
            continue
        }
        new_id=$(docker image inspect "$image_ref" --format '{{.Id}}' 2>/dev/null || echo "none")
        if [[ "$old_id" != "$new_id" ]]; then
            log "  UPDATE AVAILABLE: $svc ($image_ref)"
            updates_found=$((updates_found + 1))
        else
            log "  Up to date: $svc"
        fi
    done < <(list_service_specs)

    if [[ "$updates_found" -eq 0 ]]; then
        log "All services are up to date."
    else
        log "$updates_found update(s) available. Run with --apply to update."
    fi
}

apply_updates() {
    log "=== Starting safe update ==="

    backup_compose
    backup_db
    backup_custom_config
    record_digests

    log "Capturing current runtime state..."
    local -a all_services running_services stopped_services build_services
    local running_set

    mapfile -t all_services < <(list_compose_services)
    mapfile -t running_services < <(list_running_services)
    running_set="$(printf "%s\n" "${running_services[@]}")"

    for svc in "${all_services[@]}"; do
        if printf "%s\n" "$running_set" | grep -x "$svc" >/dev/null; then
            continue
        fi
        stopped_services+=("$svc")
    done

    log "Updating service images..."
    while IFS='|' read -r svc image_ref has_build; do
        if [[ "$has_build" == "yes" ]]; then
            build_services+=("$svc")
            continue
        fi
        if [[ -z "$image_ref" ]]; then
            continue
        fi

        if [[ "$image_ref" == *"@sha256:"* ]]; then
            refresh_service_image_if_pinned "$svc" "$image_ref" || true
        else
            docker pull "$image_ref" --quiet >/dev/null 2>&1 || log "WARNING: Failed to pull $image_ref"
        fi
    done < <(list_service_specs)

    if [[ ${#build_services[@]} -gt 0 ]]; then
        log "Rebuilding build-based services..."
        for svc in "${build_services[@]}"; do
            log "  Building $svc..."
            $COMPOSE build --pull "$svc" >/dev/null 2>&1 || log "WARNING: Build failed for $svc"
        done
    fi

    log "Recreating previously running services..."
    if [[ ${#running_services[@]} -gt 0 ]]; then
        $COMPOSE up -d "${running_services[@]}" 2>&1 | grep -v "^$" || true
    fi

    log "Refreshing stopped services without starting them..."
    if [[ ${#stopped_services[@]} -gt 0 ]]; then
        for svc in "${stopped_services[@]}"; do
            $COMPOSE up -d --no-start "$svc" >/dev/null 2>&1 || log "WARNING: Failed to refresh stopped service $svc"
        done
    fi

    if printf "%s\n" "${running_services[@]}" | grep -x "n8n" >/dev/null && \
        docker inspect ai_n8n --format '{{.State.Running}}' 2>/dev/null | grep -q "true"; then
        log "n8n is running. Refreshing node types..."
        "$SCRIPT_DIR/extract-n8n-node-types.sh" 2>&1 | grep -v "^$" | tail -2
    fi

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
