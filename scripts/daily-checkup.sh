#!/bin/bash
# Daily checkup script for TechUties VM
# This script runs once per day to check for updates and store the status

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATUS_FILE="/tmp/tu-vm-update-status.json"
LOG_FILE="$SCRIPT_DIR/tu-vm.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check container health and service status
check_container_health() {
    local unhealthy_services=()
    local down_services=()
    local ondemand_stopped=()
    local restart_count=0
    local health_details=""
    
    # Tier 2 (on-demand) services are allowed to be stopped; do not treat as "down".
    local ondemand=("ai_ollama" "ai_n8n" "ai_minio" "ai_qdrant" "ai_tika" "tika_minio_processor")
    local containers=("ai_postgres" "ai_redis" "ai_qdrant" "ai_ollama" "ai_openwebui" "ai_n8n" "ai_tika" "ai_minio" "ai_pihole" "ai_nginx" "ai_helper_index" "tika_minio_processor")

    is_ondemand() {
        local c="$1"
        for x in "${ondemand[@]}"; do
            if [[ "$x" == "$c" ]]; then
                return 0
            fi
        done
        return 1
    }
    
    for container in "${containers[@]}"; do
        # Check if container exists
        if ! docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            continue
        fi
        
        # Get container status
        local status=$(docker ps --format "{{.Status}}" --filter "name=${container}" 2>/dev/null || echo "not running")
        local health=$(docker inspect --format='{{.State.Health.Status}}' "${container}" 2>/dev/null || echo "none")
        local restart_count_container=$(docker inspect --format='{{.RestartCount}}' "${container}" 2>/dev/null || echo "0")
        
        # Check for unhealthy containers
        if [[ "$health" == "unhealthy" ]]; then
            unhealthy_services+=("${container}")
            health_details="${health_details}${container}: unhealthy; "
        fi
        
        # Check for down containers
        if [[ "$status" == "not running" ]] || [[ "$status" == *"Exited"* ]]; then
            if is_ondemand "$container"; then
                ondemand_stopped+=("${container}")
                health_details="${health_details}${container}: stopped (on-demand); "
            else
                down_services+=("${container}")
                health_details="${health_details}${container}: down; "
            fi
        fi
        
        # Check for excessive restarts
        if [[ "$restart_count_container" -gt 3 ]]; then
            restart_count=$((restart_count + restart_count_container))
            health_details="${health_details}${container}: ${restart_count_container} restarts; "
        fi
    done
    
    # Create health status file
    cat > "/tmp/tu-vm-health-status.json" << EOF
{
    "unhealthy_services": [$(printf '"%s",' "${unhealthy_services[@]}" | sed 's/,$//')],
    "down_services": [$(printf '"%s",' "${down_services[@]}" | sed 's/,$//')],
    "ondemand_stopped": [$(printf '"%s",' "${ondemand_stopped[@]}" | sed 's/,$//')],
    "total_restarts": $restart_count,
    "last_check": "$(date -Iseconds)",
    "health_details": "$health_details",
    "containers_checked": ${#containers[@]}
}
EOF
    
    if [ ${#unhealthy_services[@]} -gt 0 ] || [ ${#down_services[@]} -gt 0 ] || [ $restart_count -gt 0 ]; then
        log "Container health check: Found ${#unhealthy_services[@]} unhealthy, ${#down_services[@]} down, $restart_count total restarts"
    else
        log "Container health check: All containers healthy"
    fi
}

# Function to check container logs for errors
check_log_errors() {
    local error_count=0
    local error_details=""
    local critical_errors=0
    local warning_errors=0
    local containers=("ai_postgres" "ai_redis" "ai_qdrant" "ai_ollama" "ai_openwebui" "ai_n8n" "ai_tika" "ai_minio" "ai_pihole" "ai_nginx" "tika_minio_processor")
    
    for container in "${containers[@]}"; do
        # Check if container exists and is running
        if ! docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            continue
        fi
        
        # Get last 24 hours of logs and check for error patterns
        local critical=$(docker logs --since 24h "${container}" 2>&1 | grep -i -E "(fatal|panic|out of memory|disk full|connection refused)" | wc -l)
        local warnings=$(docker logs --since 24h "${container}" 2>&1 | grep -i -E "(error|exception|failed|timeout)" | wc -l)
        
        if [ "$critical" -gt 0 ] || [ "$warnings" -gt 0 ]; then
            error_count=$((error_count + critical + warnings))
            critical_errors=$((critical_errors + critical))
            warning_errors=$((warning_errors + warnings))
            
            # Get a sample error for context
            local sample_error=$(docker logs --since 24h "${container}" 2>&1 | grep -i -E "(fatal|panic|out of memory|disk full|connection refused|error|exception|failed|timeout)" | tail -1 | cut -c1-100)
            if [ -n "$sample_error" ]; then
                error_details="${error_details}${container}: ${sample_error}...; "
            fi
        fi
    done
    
    # Create log status file
    cat > "/tmp/tu-vm-log-status.json" << EOF
{
    "errors_found": $error_count,
    "critical_errors": $critical_errors,
    "warning_errors": $warning_errors,
    "last_check": "$(date -Iseconds)",
    "error_details": "$error_details",
    "containers_checked": ${#containers[@]}
}
EOF
    
    if [ "$error_count" -gt 0 ]; then
        log "Daily log check: Found $error_count errors ($critical_errors critical, $warning_errors warnings) across containers"
    else
        log "Daily log check: No errors found in container logs"
    fi
}

# Function to check for updates using remote digests (no image downloads)
check_for_updates() {
    local updates_available=false
    local message=""
    local details_msg=""
    local platform="linux/amd64"

    case "$(uname -m)" in
        x86_64) platform="linux/amd64" ;;
        aarch64|arm64) platform="linux/arm64" ;;
        armv7l) platform="linux/arm/v7" ;;
    esac

    # Check for OS updates
    local os_updates=$(apt list --upgradable 2>/dev/null | wc -l)
    local os_updates_num=$((os_updates-1))
    if [ "$os_updates_num" -gt 0 ]; then
        updates_available=true
        message="System updates available"
        details_msg="$os_updates_num packages can be updated"
    fi

    # Images to check
    local docker_images=(
        "postgres:15-alpine"
        "redis:7-alpine"
        "qdrant/qdrant:latest"
        "ollama/ollama:latest"
        "ghcr.io/open-webui/open-webui:latest"
        "apache/tika:latest"
        "minio/minio:latest"
        "n8nio/n8n:latest"
        "pihole/pihole:latest"
        "nginx:alpine"
    )

    # Helper: get local image digest (ID) without pulling
    get_local_digest() {
        local img="$1"
        docker inspect --format='{{.Id}}' "$img" 2>/dev/null || true
    }

    # Helper: get remote digest for platform without pulling
    get_remote_digest() {
        local img="$1"
        local plat="$2"
        # Prefer buildx imagetools if available
        if command -v docker >/dev/null 2>&1 && docker buildx imagetools inspect "$img" >/dev/null 2>&1; then
            docker buildx imagetools inspect "$img" 2>/dev/null | awk -v p="$plat" '
                $1=="Platform:" && $2==p {found=1} 
                found && $1=="Digest:" {print $2; exit}
            '
            return
        fi
        # Fallback to docker manifest inspect (outputs JSON)
        if command -v docker >/dev/null 2>&1 && docker manifest inspect "$img" >/dev/null 2>&1; then
            local json
            json=$(docker manifest inspect "$img" 2>/dev/null)
            python3 - "$plat" << 'PY'
import json,sys
plat=sys.argv[1]
data=json.load(sys.stdin)
manifests=data.get('manifests',[])
for m in manifests:
    platObj=m.get('platform',{})
    p=f"{platObj.get('os')}/{platObj.get('architecture')}"
    if platObj.get('variant') and platObj['architecture']=='arm':
        p=f"{platObj.get('os')}/arm/{platObj.get('variant')}"
    if p==plat:
        print(m.get('digest',''))
        break
PY
            return
        fi
        echo ""
    }

    local updates_json="[]"
    local docker_updates=0

    for image in "${docker_images[@]}"; do
        # Skip if image not present locally (no update needed yet)
        local local_digest
        local_digest=$(get_local_digest "$image")
        if [ -z "$local_digest" ]; then
            continue
        fi
        local remote_digest
        remote_digest=$(get_remote_digest "$image" "$platform")
        if [ -n "$remote_digest" ] && [ "$local_digest" != "$remote_digest" ]; then
            updates_available=true
            docker_updates=$((docker_updates+1))
            # Append to JSON list
            updates_json=$(python3 - <<PY
import json
arr=json.loads('''$updates_json''')
arr.append({
  "image": "$image",
  "platform": "$platform",
  "local_digest": "$local_digest",
  "remote_digest": "$remote_digest"
})
print(json.dumps(arr))
PY
)
        fi
    done

    if [ "$docker_updates" -gt 0 ]; then
        if [ -n "$message" ]; then
            message="$message, Docker image updates available"
        else
            message="Docker image updates available"
        fi
        if [ -n "$details_msg" ]; then
            details_msg="$details_msg, $docker_updates images outdated"
        else
            details_msg="$docker_updates images outdated"
        fi
    fi

    # Create status JSON
    cat > "$STATUS_FILE" << EOF
{
    "updates_available": $updates_available,
    "last_check": "$(date -Iseconds)",
    "message": "$message",
    "details": "$details_msg",
    "os_updates": $os_updates_num,
    "docker_updates": $docker_updates,
    "docker_outdated": $updates_json
}
EOF

    if [ "$updates_available" = true ]; then
        log "Daily checkup: Updates available - $message"
    else
        log "Daily checkup: No updates available"
    fi
}

# Main execution
log "Starting daily checkup..."
check_container_health
check_log_errors
check_for_updates
log "Daily checkup completed"
