#!/bin/bash

# =============================================================================
# TechUties VM - Professional Control Script
# =============================================================================
# Version: 2.0.0
# Author: TechUties Team
# Description: Comprehensive management script for TechUties AI Platform
# License: MIT
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_NAME="tu-vm.sh"
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_NAME="TechUties AI Platform"
readonly DOCKER_COMPOSE_FILE="docker-compose.yml"
readonly ENV_FILE=".env"
readonly BACKUP_DIR="backups"
readonly LOG_FILE="tu-vm.log"

# Service configuration
readonly SERVICES=(
    "postgres:5432"
    "redis:6379"
    "qdrant:6333"
    "ollama:11434"
    "open-webui:8080"
    "n8n:5678"
    "pihole:80"
    "nginx:80"
    "helper_index:9001"
    "tika:9998"
    "minio:9000"
    "minio:9001"
)

# =============================================================================
# LOGGING SYSTEM
# =============================================================================

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Default log level
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Icons
readonly ICON_SUCCESS="✓"
readonly ICON_WARNING="⚠️"
readonly ICON_ERROR="❌"
readonly ICON_INFO="ℹ️"
readonly ICON_DEBUG="🔍"
readonly ICON_SECURE="🔒"
readonly ICON_PUBLIC="🔓"
readonly ICON_LOCKED="🚫"

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local level_name=""
    local color=""
    local icon=""
    
    case $level in
        $LOG_LEVEL_DEBUG)
            level_name="DEBUG"
            color="$CYAN"
            icon="$ICON_DEBUG"
            ;;
        $LOG_LEVEL_INFO)
            level_name="INFO"
            color="$GREEN"
            icon="$ICON_SUCCESS"
            ;;
        $LOG_LEVEL_WARN)
            level_name="WARN"
            color="$YELLOW"
            icon="$ICON_WARNING"
            ;;
        $LOG_LEVEL_ERROR)
            level_name="ERROR"
            color="$RED"
            icon="$ICON_ERROR"
            ;;
    esac
    
    # Only show if log level is appropriate
    if [[ $level -ge $LOG_LEVEL ]]; then
        echo -e "${color}${icon} [${timestamp}] ${level_name}: ${message}${NC}"
    fi
    
    # Always log to file
    echo "[${timestamp}] ${level_name}: ${message}" >> "$LOG_FILE"
}

debug() { log $LOG_LEVEL_DEBUG "$@"; }
info() { log $LOG_LEVEL_INFO "$@"; }
warn() { log $LOG_LEVEL_WARN "$@"; }
error() { log $LOG_LEVEL_ERROR "$@"; exit 1; }

# Success-level helper (alias to info with success styling)
success() { info "$@"; }

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This command requires root privileges. Run: sudo ./$SCRIPT_NAME $1"
    fi
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running or not accessible. Please start Docker first."
    fi
}

# Check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        error "Docker Compose is not installed or not accessible."
    fi
}

# Get Docker Compose command
get_docker_compose_cmd() {
    if command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}

# Check if .env file exists
check_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        warn ".env file not found. Creating from env.example..."
        if [[ -f "env.example" ]]; then
            cp env.example "$ENV_FILE"
            info "Created .env file from env.example."
            
            # Check for default passwords and generate secrets automatically
            if grep -q "CHANGE_ME_SECURE_PASSWORD\|CHANGE_ME_32_CHAR_ENCRYPTION_KEY\|CHANGE_ME_SECRET_KEY" "$ENV_FILE"; then
                warn "Default passwords detected! Generating secure secrets automatically..."
                generate_secrets
            else
                info "Please review and configure your .env file as needed."
            fi
        else
            error ".env file not found and no env.example available."
        fi
    else
        # Check existing .env file for default passwords
        if grep -q "CHANGE_ME_SECURE_PASSWORD\|CHANGE_ME_32_CHAR_ENCRYPTION_KEY\|CHANGE_ME_SECRET_KEY" "$ENV_FILE"; then
            warn "Default passwords detected in existing .env file!"
            warn "Run './tu-vm.sh generate-secrets' to generate secure passwords."
        fi
    fi
}

# Get VM IP address
get_vm_ip() {
    ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1
}

# Get network prefix
get_network_prefix() {
    local vm_ip=$(get_vm_ip)
    echo "$vm_ip" | cut -d. -f1-3
}

# Check if service is healthy
check_service_health() {
    local service_name="$1"
    local port="$2"
    local max_attempts=5
    local attempt=1
    
    debug "Checking health of $service_name..."
    
    while [[ $attempt -le $max_attempts ]]; do
        # Check Docker health status first
        local health_status=$(docker compose ps --format json | jq -r "select(.Name==\"ai_$service_name\") | .Health" 2>/dev/null)
        
        if [[ "$health_status" == "healthy" ]]; then
            debug "$service_name is healthy (Docker health check)"
            return 0
        fi
        
        # Check if container is running
        local container_status=$(docker compose ps --format json | jq -r "select(.Name==\"ai_$service_name\") | .State" 2>/dev/null)
        
        if [[ "$container_status" == "running" ]]; then
            # For services without health checks, try to connect to their port
            if [[ "$health_status" == "none" || "$health_status" == "null" ]]; then
                if [[ -n "$port" && "$port" != "0" ]]; then
                    if timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null; then
                        debug "$service_name is running and port $port is accessible"
                        return 0
                    else
                        debug "Attempt $attempt/$max_attempts: $service_name running but port $port not accessible yet..."
                    fi
                else
                    debug "$service_name is running (no port check needed)"
                    return 0
                fi
            else
                debug "$service_name is running (Docker status)"
                return 0
            fi
        fi
        
        debug "Attempt $attempt/$max_attempts: $service_name not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    warn "$service_name health check failed after $max_attempts attempts"
    return 1
}

# Wait for services to be ready
wait_for_services() {
    info "Waiting for services to be ready..."
    local failed_services=()
    
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        if ! check_service_health "$service_name" "$port"; then
            failed_services+=("$service_name")
        fi
    done
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        warn "Some services failed health checks: ${failed_services[*]}"
        return 1
    fi
    
    info "All services are ready!"
    return 0
}

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

# Show script information
show_info() {
    echo -e "${WHITE}${PROJECT_NAME} Control Script${NC}"
    echo -e "${CYAN}Version: ${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}Script: ${SCRIPT_NAME}${NC}"
    echo -e "${CYAN}Directory: ${SCRIPT_DIR}${NC}"
    echo ""
}

# Show help
show_help() {
    show_info
    echo -e "${WHITE}Usage:${NC} ./$SCRIPT_NAME [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${WHITE}Basic Commands:${NC}"
    echo "  start                    Start all services"
    echo "  stop                     Stop all services"
    echo "  restart                  Restart all services"
    echo "  status                   Show service status"
    echo "  logs [service]           Show service logs"
    echo "  access                   Show access URLs and information"
    echo ""
    echo -e "${WHITE}Access Control:${NC}"
    echo "  secure                   Enable secure access (recommended)"
    echo "  public                   Enable public access (less secure)"
    echo "  lock                     Block all external access"
    echo ""
    echo -e "${WHITE}Maintenance:${NC}"
    echo "  update                   Update system and services"
    echo "  test-update              Test update process (dry run)"
    echo "  backup [name]            Create backup with optional name"
    echo "  restore <file>           Restore from backup file"
    echo "  cleanup                  Clean up old backups and logs"
    echo "  setup-minio             Setup MinIO buckets for existing installation"
    echo ""
    echo -e "${WHITE}Security:${NC}"
    echo "  generate-secrets         Generate secure passwords and keys"
    echo "  validate-security        Validate security configuration"
    echo ""
    echo -e "${WHITE}Diagnostics:${NC}"
    echo "  health                   Check service health"
    echo "  test                     Test all service endpoints"
    echo "  diagnose                 Run comprehensive diagnostics"
    echo "  info                     Show system information"
    echo ""
    echo -e "${WHITE}PDF Processing:${NC}"
    echo "  pdf-status               Check PDF processing pipeline status"
    echo "  pdf-test                 Test PDF processing with sample file"
    echo "  pdf-logs [service]        Show PDF processing logs (tika/minio/processor)"
    echo "  pdf-reset                Reset PDF processing pipeline"
    echo ""
    echo -e "${WHITE}System:${NC}"
    echo "  version                  Show script version and information"
    echo "  help                     Show this help message"
    echo ""
    echo -e "${WHITE}Security Levels:${NC}"
    echo "  ${ICON_SECURE} SECURE:    Secure access (recommended)"
    echo "  ${ICON_PUBLIC} PUBLIC:    Access from internet"
    echo "  ${ICON_LOCKED} LOCKED:    No external access"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo "  ./$SCRIPT_NAME start                    # Start all services"
    echo "  ./$SCRIPT_NAME status                   # Check service status"
    echo "  ./$SCRIPT_NAME access                   # Show access URLs"
    echo "  ./$SCRIPT_NAME secure                   # Enable secure access"
    echo "  ./$SCRIPT_NAME backup my-backup         # Create named backup"
    echo "  ./$SCRIPT_NAME restore backup.tar.gz    # Restore from backup"
    echo "  ./$SCRIPT_NAME logs nginx               # Show nginx logs"
    echo "  ./$SCRIPT_NAME pdf-status               # Check PDF processing"
    echo "  ./$SCRIPT_NAME health                   # Check service health"
    echo "  ./$SCRIPT_NAME version                  # Show version info"
}

# Start services
start_services() {
    info "Starting $PROJECT_NAME services..."
    
    check_docker
    check_docker_compose
    check_env_file
    
    local compose_cmd=$(get_docker_compose_cmd)
    
    # Start services
    $compose_cmd up -d
    
    # Wait for services to be ready
    if wait_for_services; then
        info "All services started successfully!"
        
        # Note: Tika is configured as default in docker-compose.yml
        
        # Setup MinIO buckets for first-time installation
        setup_minio_buckets
        
        # Mount MinIO buckets to host via rclone (transparent S3 filesystem)
        mount_minio_storage

        # Ensure cron-based MinIO sync is installed (idempotent)
        ensure_sync_cron_job
        
        # Ensure daily checkup cron job is installed (idempotent)
        ensure_daily_checkup_cron_job
        
        show_access_info
    else
        warn "Some services may not be fully ready yet."
        info "Check status with: ./$SCRIPT_NAME status"
    fi
}

# Setup MinIO buckets for first-time installation
setup_minio_buckets() {
    info "Setting up MinIO buckets for first-time installation..."
    
    # Check if MinIO is running
    if ! docker ps --format "{{.Names}}" | grep -q "^ai_minio$"; then
        warn "MinIO container is not running, skipping bucket setup"
        return 0
    fi
    
    # Wait for MinIO to be ready
    info "Waiting for MinIO to be ready..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec ai_minio mc version >/dev/null 2>&1; then
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        warn "MinIO is not ready, skipping bucket setup"
        return 0
    fi
    
    # Configure MinIO client
    info "Configuring MinIO client..."
    docker exec ai_minio mc alias set local "http://localhost:9000" "admin" "${MINIO_ROOT_PASSWORD:-minio123456}" 2>/dev/null || {
        warn "MinIO client might already be configured"
    }
    
    # Required buckets
    local buckets=(
        "tika-pipe"
        "n8n-workflows"
        "shared-documents"
        "thumbnails"
        "metadata"
    )
    
    # Create buckets
    info "Creating required MinIO buckets..."
    for bucket in "${buckets[@]}"; do
        if docker exec ai_minio mc ls "local/$bucket" >/dev/null 2>&1; then
            info "Bucket $bucket already exists"
        else
            info "Creating bucket: $bucket"
            docker exec ai_minio mc mb "local/$bucket" 2>/dev/null || {
                warn "Failed to create bucket $bucket"
            }
        fi
    done
    
    # Create folder structure
    info "Creating folder structure..."
    docker exec ai_minio mc cp /dev/null "local/tika-pipe/.gitkeep" 2>/dev/null || true
    docker exec ai_minio mc cp /dev/null "local/n8n-workflows/inputs/.gitkeep" 2>/dev/null || true
    docker exec ai_minio mc cp /dev/null "local/n8n-workflows/outputs/.gitkeep" 2>/dev/null || true
    docker exec ai_minio mc cp /dev/null "local/shared-documents/company/.gitkeep" 2>/dev/null || true
    
    info "✅ MinIO buckets setup complete"
}

# Ensure rclone is installed and mount MinIO buckets to host for transparent S3 storage
mount_minio_storage() {
    info "Configuring transparent MinIO mount (rclone) for host access..."
    
    # Install rclone if missing
    if ! command -v rclone >/dev/null 2>&1; then
        info "Installing rclone..."
        sudo apt-get update -y >/dev/null 2>&1 || true
        sudo apt-get install -y rclone fuse3 >/dev/null 2>&1 || true
        echo "user_allow_other" | sudo tee -a /etc/fuse.conf >/dev/null 2>&1 || true
    fi
    
    # Prepare rclone config directory
    local rclone_conf_dir="/etc/rclone"
    local rclone_conf="$rclone_conf_dir/rclone.conf"
    sudo mkdir -p "$rclone_conf_dir"
    
    # Create/update non-interactive rclone config for MinIO
    if ! sudo grep -q "^\[minio\]" "$rclone_conf" 2>/dev/null; then
        info "Writing rclone config for MinIO..."
        sudo tee "$rclone_conf" >/dev/null <<EOF
[minio]
type = s3
provider = Minio
env_auth = false
access_key_id = admin
secret_access_key = ${MINIO_ROOT_PASSWORD:-minio123456}
endpoint = http://127.0.0.1:9000
region = us-east-1
EOF
        sudo chmod 600 "$rclone_conf"
    fi
    
    # Create mount points
    local base_mount="/mnt/minio"
    sudo mkdir -p "$base_mount/openwebui" "$base_mount/n8n" "$base_mount/shared"
    
    # Mount helper (idempotent)
    mount_minio_bucket() {
        local bucket="$1"; local target="$2"
        if mountpoint -q "$target"; then
            info "Mount already active: $target"
            return 0
        fi
        info "Mounting minio:$bucket -> $target"
        # Use daemon mode, path-style, write cache for compatibility
        sudo rclone mount "minio:$bucket" "$target" \
            --daemon \
            --vfs-cache-mode writes \
            --allow-other \
            --dir-cache-time 30s \
            --poll-interval 0 \
            --attr-timeout 1s \
            --config "$rclone_conf" \
            >/dev/null 2>&1 || warn "Failed to mount $bucket"
    }
    
    # Attempt mounts (buckets created earlier)
    mount_minio_bucket "openwebui-files" "$base_mount/openwebui"
    mount_minio_bucket "n8n-workflows" "$base_mount/n8n"
    mount_minio_bucket "shared-documents" "$base_mount/shared"
    
    info "MinIO mounts ready under $base_mount (if buckets exist)."
}

# Ensure a cron job exists to run the Open WebUI -> MinIO sync script
ensure_sync_cron_job() {
    info "Ensuring cron job for MinIO sync is installed..."

    # Resolve MinIO password at install time (dynamic)
    local resolved_pass="${MINIO_ROOT_PASSWORD:-}"
    if [[ -z "$resolved_pass" && -f "$ENV_FILE" ]]; then
        # shellcheck disable=SC1090
        . "$ENV_FILE" 2>/dev/null || true
        resolved_pass="${MINIO_ROOT_PASSWORD:-}"
    fi
    if [[ -z "$resolved_pass" ]] && docker ps --format '{{.Names}}' | grep -q '^ai_minio$'; then
        resolved_pass=$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' ai_minio | awk -F= '$1=="MINIO_ROOT_PASSWORD"{print $2; exit}')
    fi
    if [[ -z "$resolved_pass" ]]; then
        warn "Could not resolve MinIO password for cron install; falling back to literal variable reference."
    fi

    # Build cron line (every 2 minutes) with dynamic MINIO_SYNC_PASSWORD
    local cron_line
    if [[ -n "$resolved_pass" ]]; then
        cron_line="*/2 * * * * MINIO_SYNC_PASSWORD=$resolved_pass $SCRIPT_DIR/scripts/sync-openwebui-minio.sh >> /var/log/sync-openwebui-minio.log 2>&1"
    else
        cron_line="*/2 * * * * MINIO_SYNC_PASSWORD=\${MINIO_ROOT_PASSWORD:-minio123456} $SCRIPT_DIR/scripts/sync-openwebui-minio.sh >> /var/log/sync-openwebui-minio.log 2>&1"
    fi

    # Replace any existing sync lines and install idempotently
    local current_cron
    current_cron=$(crontab -l 2>/dev/null || true)
    # Remove old entries referencing the script
    current_cron=$(echo "$current_cron" | sed '/sync-openwebui-minio\.sh/d')
    # Install new line
    (echo "$current_cron"; echo "$cron_line") | crontab -
    info "Cron job installed/updated: $cron_line"
}

# Ensure daily checkup cron job is installed
ensure_daily_checkup_cron_job() {
    info "Ensuring daily checkup cron job is installed..."
    local cron_line="0 9 * * * $SCRIPT_DIR/scripts/daily-checkup.sh"
    # Install user crontab if missing entry
    local current_cron
    current_cron=$(crontab -l 2>/dev/null || true)
    if echo "$current_cron" | grep -Fq "$cron_line"; then
        info "Daily checkup cron job already present"
    else
        (echo "$current_cron"; echo "$cron_line") | crontab -
        info "Daily checkup cron job installed: $cron_line"
    fi
}

# Stop services
stop_services() {
    info "Stopping $PROJECT_NAME services..."
    
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd down
    
    info "Services stopped successfully!"
}

# Restart services
restart_services() {
    info "Restarting $PROJECT_NAME services..."
    
    stop_services
    sleep 2
    start_services
}

# Show service status
show_status() {
    echo -e "${WHITE}$PROJECT_NAME Status${NC}"
    echo "=================="
    echo ""
    
    # Docker services
    echo -e "${WHITE}Docker Services:${NC}"
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Service health
    echo -e "${WHITE}Service Health:${NC}"
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        if check_service_health "$service_name" "$port" 2>/dev/null; then
            echo -e "  ${GREEN}${ICON_SUCCESS}${NC} $service_name"
        else
            echo -e "  ${RED}${ICON_ERROR}${NC} $service_name"
        fi
    done
    echo ""
    
    # Access information
    show_access_info
    
    # System information
    show_system_info
}

# Show access information
show_access_info() {
    local vm_ip=$(get_vm_ip)
    
    echo -e "${WHITE}Access URLs:${NC}"
    echo "  Landing:     https://tu.local (https://$vm_ip)"
    echo "  Open WebUI:  https://oweb.tu.local (https://$vm_ip)"
    echo "  n8n:         https://n8n.tu.local (https://$vm_ip)"
    echo "  Pi-hole:     https://pihole.tu.local (https://$vm_ip)"
    echo "  Ollama API:  https://ollama.tu.local (https://$vm_ip)"
    echo "  MinIO Console: https://minio.tu.local (https://$vm_ip:9001)"
    echo "  MinIO API:   https://api.minio.tu.local (https://$vm_ip:9000)"
    echo ""
    
    # Check if services are accessible
    if curl -k -s -o /dev/null "https://$vm_ip"; then
        echo -e "  ${GREEN}${ICON_SUCCESS}${NC} Services are accessible"
    else
        echo -e "  ${RED}${ICON_ERROR}${NC} Services may not be accessible"
    fi
}

# Show system information
show_system_info() {
    echo -e "${WHITE}System Information:${NC}"
    echo "  VM IP:       $(get_vm_ip)"
    echo "  Network:     $(get_network_prefix).0/24"
    echo "  Docker:      $(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1 || echo 'Not available')"
    echo "  Compose:     $($(get_docker_compose_cmd) version --short 2>/dev/null || echo 'Not available')"
    echo "  Uptime:      $(uptime -p 2>/dev/null || echo 'Not available')"
    echo "  Load:        $(uptime | awk -F'load average:' '{print $2}' || echo 'Not available')"
    echo ""
}

# Show service logs
show_logs() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        info "Available services:"
        local compose_cmd=$(get_docker_compose_cmd)
        $compose_cmd ps --format "table {{.Name}}\t{{.Status}}"
        echo ""
        echo "Usage: ./$SCRIPT_NAME logs <service_name>"
        return 0
    fi
    
    info "Showing logs for: $service"
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd logs -f --tail=100 "$service"
}

# =============================================================================
# SECURITY FUNCTIONS
# =============================================================================

# Enable secure access
enable_secure() {
    check_root "secure"
    
    info "Enabling secure access..."
    
    # Enable UFW if not already enabled
    ufw --force enable 2>/dev/null || true
    
    # Block public access
    ufw deny 80/tcp 2>/dev/null || true
    ufw deny 443/tcp 2>/dev/null || true
    ufw deny 53/tcp 2>/dev/null || true
    ufw deny 53/udp 2>/dev/null || true
    
    # Allow local network access
    local network_prefix=$(get_network_prefix)
    
    ufw allow from "$network_prefix.0/24" to any port 80 2>/dev/null || true
    ufw allow from "$network_prefix.0/24" to any port 443 2>/dev/null || true
    ufw allow from "$network_prefix.0/24" to any port 53 2>/dev/null || true
    
    # Allow localhost for management
    ufw allow from 127.0.0.1 to any port 8081 2>/dev/null || true
    ufw allow from 127.0.0.1 to any port 6333 2>/dev/null || true
    ufw allow from 127.0.0.1 to any port 11434 2>/dev/null || true
    
    info "Secure access enabled!"
    info "Services are now accessible only from local network"
}

# Enable public access
enable_public() {
    check_root "public"
    
    warn "Enabling public access (less secure)..."
    
    # Enable UFW if not already enabled
    ufw --force enable 2>/dev/null || true
    
    # Allow public access
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
    ufw allow 53/tcp 2>/dev/null || true
    ufw allow 53/udp 2>/dev/null || true
    
    info "Public access enabled!"
    warn "⚠️  Services are now accessible from the internet"
}

# Lock all access
lock_access() {
    check_root "lock"
    
    info "Locking all external access..."
    
    # Enable UFW if not already enabled
    ufw --force enable 2>/dev/null || true
    
    # Block all external access
    ufw deny 80/tcp 2>/dev/null || true
    ufw deny 443/tcp 2>/dev/null || true
    ufw deny 53/tcp 2>/dev/null || true
    ufw deny 53/udp 2>/dev/null || true
    
    info "All external access blocked!"
    warn "🚫 Services are only accessible via direct VM access"
}


# =============================================================================
# MAINTENANCE FUNCTIONS
# =============================================================================

# Update system
update_system() {
    check_root "update"
    
    info "Updating $PROJECT_NAME..."
    
    # Create backup before update
    info "Creating backup before update..."
    local backup_name="pre_update_$(date +%Y%m%d_%H%M%S)"
    create_backup "$backup_name"
    
    # Update OS packages
    info "Updating system packages..."
    apt-get update
    apt-get upgrade -y
    
    # Clean up old packages
    info "Cleaning up old packages..."
    apt-get autoremove -y
    apt-get autoclean
    
    # Handle Pi-hole DNS replacement BEFORE stopping services
    info "🌐 Handling Pi-hole DNS service..."
    handle_pihole_dns_replacement "stop"
    
    # Verify internet connectivity before proceeding
    info "Verifying internet connectivity..."
    if ! verify_dns_connectivity; then
        error "Internet connectivity verification failed. Cannot proceed with update."
        error "Please check your network connection and try again."
        exit 1
    fi
    success "Internet connectivity verified"
    
    # Defer service stop and cleanup until after user confirms update scope
    local compose_cmd=$(get_docker_compose_cmd)
    
    # Pull latest images in one batch (parallel) and detect updated services from output
    info "Pulling latest images for all services (showing live progress)..."
    local pull_log_file="/tmp/tu-compose-pull.log"
    : > "$pull_log_file"
    local pull_cmd="$compose_cmd pull"
    # Detect support for --progress flag and prefer it if available
    if $compose_cmd pull --help 2>&1 | grep -q -- "--progress"; then
        pull_cmd="$compose_cmd pull --progress=plain"
    fi
    # Stream progress to console and log to file for parsing; retry without flags on failure
    set +e
    $pull_cmd 2>&1 | tee "$pull_log_file"
    local pull_ec=${PIPESTATUS[0]}
    if [[ $pull_ec -ne 0 ]]; then
        warn "compose pull failed with exit code $pull_ec. Retrying without extra flags..."
        $compose_cmd pull 2>&1 | tee "$pull_log_file"
        pull_ec=${PIPESTATUS[0]}
        if [[ $pull_ec -ne 0 ]]; then
            error "Image pull failed (exit code $pull_ec). Aborting update."
        fi
    fi
    set -e
    # Build list of compose services to validate matches
    local -a all_services
    mapfile -t all_services < <($compose_cmd config --services)

    local updated_services=()
    # Detect lines that indicate a service "Pulled" and map to valid service names
    while IFS= read -r line; do
        if echo "$line" | grep -qE "\bPulled\b"; then
            local svc=""
            # Handle formats like: "✔ service Pulled" or "service Pulled"
            if echo "$line" | grep -q "✔"; then
                svc=$(echo "$line" | awk '{print $2}')
            else
                svc=$(echo "$line" | awk '{print $1}')
            fi
            if [[ -n "$svc" ]] && printf '%s\n' "${all_services[@]}" | grep -qx "$svc"; then
                updated_services+=("$svc")
            fi
        fi
    done < "$pull_log_file"

    # De-duplicate services list
    if [[ ${#updated_services[@]} -gt 0 ]]; then
        mapfile -t updated_services < <(printf "%s\n" "${updated_services[@]}" | sort -u)
        info "Services with new images: ${updated_services[*]}"
    else
        # If pull succeeded and no updated services parsed, report up-to-date
        info "All images are already up to date."
    fi

    # Ask whether to update all services or only those with updates (interactive)
    local update_choice="all"
    if [[ -t 0 ]]; then
        if [[ ${#updated_services[@]} -gt 0 ]]; then
            echo ""
            echo "Update options:"
            echo "  [1] Update only services with new images: ${updated_services[*]}"
            echo "  [2] Update all services"
            echo "  [c] Cancel update"
            read -p "Choose [1/2/c] (default: 1): " -r choice
            case "$choice" in
                2) update_choice="all" ;;
                c|C) info "Update cancelled by user"; return 0 ;;
                *) update_choice="only" ;;
            esac
        else
            # Nothing to update; allow user to proceed or skip
            read -p "No new images detected. Start services anyway? [Y/n]: " -r choice2
            case "$choice2" in
                n|N) info "Update skipped (nothing to do)."; return 0 ;;
                *) update_choice="all" ;;
            esac
        fi
    fi
    
    # Stop services gracefully (only after user decision)
    info "Stopping services for update..."
    $compose_cmd down

    # Restore Pi-hole DNS BEFORE starting services: start Pi-hole first
    info "Restoring Pi-hole DNS before starting services..."
    # Stop systemd-resolved to free port 53
    if command -v systemctl >/dev/null 2>&1; then
        systemctl stop systemd-resolved 2>/dev/null || true
        systemctl disable systemd-resolved 2>/dev/null || true
    fi
    # Ensure port 53 is free
    info "Ensuring port 53 is free for Pi-hole..."
    local port_attempts=10
    local port_attempt=0
    while [[ $port_attempt -lt $port_attempts ]]; do
        if ! netstat -tuln | grep -q ":53 "; then
            break
        fi
        sleep 2
        port_attempt=$((port_attempt + 1))
    done
    # Start Pi-hole first
    info "Starting Pi-hole service first..."
    $compose_cmd up -d pihole || warn "Pi-hole failed to start"
    # Wait briefly for Pi-hole
    sleep 5
    # Configure resolv.conf to use Pi-hole if available
    chattr -i /etc/resolv.conf 2>/dev/null || true
    cat > /etc/resolv.conf << EOF
# Pi-hole DNS configuration
nameserver 127.0.0.1
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
    chattr +i /etc/resolv.conf 2>/dev/null || true

    # Start services according to user's choice
    info "Starting services with updated images..."
    if [[ "$update_choice" == "only" && ${#updated_services[@]} -gt 0 ]]; then
        $compose_cmd up -d "${updated_services[@]}"
    else
        $compose_cmd up -d
    fi

    # Wait for critical services to be ready
    info "Waiting for critical services to be ready..."
    sleep 10
    
    # Restore Pi-hole DNS after services are running
    info "🌐 Restoring Pi-hole DNS service..."
    handle_pihole_dns_replacement "start"
    
    # Post-update cleanup (optional): prune dangling items now that new images are in use
    info "Performing post-update Docker cleanup..."
    perform_docker_cleanup
    
    # Wait for services to be ready
    if wait_for_services; then
        info "All services started successfully after update!"
        
        # Verify data retention
        info "Verifying data retention..."
        verify_data_retention
        
        # Show update summary
        show_update_summary
        
        show_access_info
    else
        warn "Some services may not be fully ready yet."
        info "Check status with: ./$SCRIPT_NAME status"
    fi
    
    info "Update completed successfully!"
    info "Backup created: $backup_name"
}

# Verify data retention after update
verify_data_retention() {
    info "Verifying data retention..."
    
    local issues=()
    
    # Check Docker volumes
    if ! docker volume ls | grep -q "postgres_data"; then
        issues+=("PostgreSQL data volume missing")
    fi
    
    if ! docker volume ls | grep -q "redis_data"; then
        issues+=("Redis data volume missing")
    fi
    
    if ! docker volume ls | grep -q "qdrant_data"; then
        issues+=("Qdrant data volume missing")
    fi
    
    if ! docker volume ls | grep -q "ollama_data"; then
        issues+=("Ollama data volume missing")
    fi
    
    if ! docker volume ls | grep -q "minio_data"; then
        issues+=("MinIO data volume missing")
    fi
    
    if ! docker volume ls | grep -q "n8n_data"; then
        issues+=("n8n data volume missing")
    fi
    
    # Check if services can access their data
    if ! docker exec ai_postgres psql -U ai_admin -d ai_platform -c "SELECT 1;" >/dev/null 2>&1; then
        issues+=("PostgreSQL database not accessible")
    fi
    
    if ! docker exec ai_redis redis-cli ping >/dev/null 2>&1; then
        issues+=("Redis not accessible")
    fi
    
    if [ ${#issues[@]} -eq 0 ]; then
        info "✅ All data volumes and services are accessible"
    else
        warn "⚠️  Data retention issues detected:"
        for issue in "${issues[@]}"; do
            warn "  - $issue"
        done
        warn "Consider restoring from backup if issues persist"
    fi
}

# Preview what will be updated
update_preview() {
    info "Previewing what will be updated..."
    
    echo -e "${BLUE}📋 Update Preview:${NC}"
    echo "=================="
    echo ""
    
    # Check for OS updates
    echo -e "${YELLOW}🖥️  System Updates:${NC}"
    local updates=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ "$updates" -gt 1 ]; then
        echo "  - $((updates-1)) packages can be updated"
    else
        echo "  - System is up to date"
    fi
    echo ""
    
    # Check for Docker image updates
    echo -e "${YELLOW}🐳 Docker Images:${NC}"
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd config --services | while read service; do
        echo "  - $service: Checking for updates..."
    done
    echo ""
    
    # Show data retention info
    echo -e "${YELLOW}💾 Data Retention:${NC}"
    echo "  - All data volumes will be preserved"
    echo "  - Database data will be retained"
    echo "  - User configurations will be kept"
    echo "  - Backup will be created before update"
    echo ""
    
    # Show DNS handling info
    echo -e "${YELLOW}🌐 DNS Handling:${NC}"
    echo "  - Pi-hole DNS will be temporarily replaced"
    echo "  - Independent DNS servers will be used during update"
    echo "  - Pi-hole DNS will be restored after update"
    echo "  - No DNS resolution interruption"
    echo ""
    
    # Show services that will be updated
    echo -e "${YELLOW}🔄 Services to Update:${NC}"
    echo "  - Open WebUI (AI chat interface)"
    echo "  - n8n (workflow automation)"
    echo "  - Ollama (AI models)"
    echo "  - PostgreSQL (database)"
    echo "  - Redis (caching)"
    echo "  - Qdrant (vector database)"
    echo "  - MinIO (object storage)"
    echo "  - Apache Tika (document processing)"
    echo "  - Pi-hole (DNS)"
    echo "  - Nginx (reverse proxy)"
    echo ""
    
    echo -e "${GREEN}✅ Update process is safe and preserves all data${NC}"
    echo -e "${YELLOW}⚠️  Services will be briefly unavailable during update${NC}"
}

# Handle Pi-hole DNS replacement during updates
handle_pihole_dns_replacement() {
    local action="$1"
    
    case "$action" in
        "stop")
            info "🌐 Temporarily replacing Pi-hole DNS with system DNS..."
            
            # Check if Pi-hole DNS is currently active
            if check_pihole_dns_status; then
                info "Pi-hole DNS is currently active, switching to system DNS..."
            else
                # Check if we have any working DNS configuration
                if [ -f /etc/resolv.conf ] && verify_dns_connectivity; then
                    info "System DNS is already active and working, no change needed"
                    return 0
                else
                    info "No working DNS configuration found, setting up system DNS..."
                fi
            fi
            
            # Backup current resolv.conf (once) if it exists
            if [ -f /etc/resolv.conf ] && [ ! -f /etc/resolv.conf.pihole.backup ]; then
                cp /etc/resolv.conf /etc/resolv.conf.pihole.backup 2>/dev/null || true
                info "Backed up current DNS configuration"
            fi

            # Remove immutable flag if present (only if file exists)
            if [ -f /etc/resolv.conf ]; then
                chattr -i /etc/resolv.conf 2>/dev/null || true
            fi
            
            # Try to enable systemd-resolved first
            if command -v systemctl >/dev/null 2>&1; then
                systemctl enable --now systemd-resolved 2>/dev/null || true
                sleep 2
            fi
            
            # Create resolv.conf with public DNS servers directly
            info "Creating DNS configuration with public servers..."
            cat > /etc/resolv.conf << EOF
# Temporary DNS configuration during update
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 9.9.9.9
nameserver 8.8.8.8
EOF

            # Ensure Docker daemon uses public DNS during pulls
            configure_docker_dns set
            
            # Verify DNS connectivity
            info "Verifying DNS connectivity..."
            if verify_dns_connectivity; then
                success "System DNS is working correctly"
            else
                warn "DNS connectivity verification failed"
                info "Attempting to fix DNS configuration..."
                # Try alternative DNS servers
                cat > /etc/resolv.conf << EOF
# Alternative DNS configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
                sleep 3
                if verify_dns_connectivity; then
                    success "DNS fixed with alternative servers"
                else
                    error "DNS connectivity verification failed. Cannot proceed with update."
                    error "Please check your network connection and try again."
                    exit 1
                fi
            fi
            
            info "✅ System DNS active via systemd-resolved; Docker DNS overridden for update"
            ;;
        "start")
            info "🌐 Restoring Pi-hole DNS configuration..."
            
            # Stop systemd-resolved to free up port 53
            if command -v systemctl >/dev/null 2>&1; then
                systemctl stop systemd-resolved 2>/dev/null || true
                systemctl disable systemd-resolved 2>/dev/null || true
            fi
            
            # Restore Docker DNS and restart Docker
            configure_docker_dns restore

            # Remove immutable flag
            chattr -i /etc/resolv.conf 2>/dev/null || true
            
            # Wait for port 53 to be free
            info "Waiting for port 53 to be free..."
            local port_attempts=10
            local port_attempt=0
            
            while [ $port_attempt -lt $port_attempts ]; do
                if ! netstat -tuln | grep -q ":53 "; then
                    info "Port 53 is now free"
                    break
                fi
                sleep 2
                port_attempt=$((port_attempt + 1))
            done
            
            # Wait for Pi-hole container to be running
            info "Waiting for Pi-hole container to be ready..."
            local max_attempts=30
            local attempt=0
            
            while [ $attempt -lt $max_attempts ]; do
                if docker ps | grep -q "ai_pihole.*Up"; then
                    info "Pi-hole container is running"
                    break
                fi
                sleep 2
                attempt=$((attempt + 1))
            done
            
            # Restore Pi-hole DNS configuration
            cat > /etc/resolv.conf << EOF
# Pi-hole DNS configuration
nameserver 127.0.0.1
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
            
            # Make resolv.conf immutable again
            chattr +i /etc/resolv.conf 2>/dev/null || true
            
            # Wait for Pi-hole service to be ready
            info "Waiting for Pi-hole DNS service to be ready..."
            attempt=0
            max_attempts=30
            
            while [ $attempt -lt $max_attempts ]; do
                if docker exec ai_pihole pihole status >/dev/null 2>&1; then
                    success "Pi-hole DNS service is ready"
                    
                    # Final DNS connectivity test
                    if verify_dns_connectivity; then
                        success "Pi-hole DNS is working correctly"
                        return 0
                    else
                        warn "Pi-hole DNS may not be fully ready yet"
                    fi
                    return 0
                fi
                sleep 2
                attempt=$((attempt + 1))
            done
            
            warn "Pi-hole may not be fully ready yet, but DNS is configured"
            ;;
        *)
            error "Invalid action for Pi-hole DNS replacement: $action"
            ;;
    esac
}

# Configure Docker daemon DNS temporarily during updates
configure_docker_dns() {
    local action="$1"
    local docker_daemon_conf="/etc/docker/daemon.json"
    local docker_daemon_conf_backup="/etc/docker/daemon.json.tu-backup"

    case "$action" in
        set)
            info "Configuring Docker daemon to use public DNS during update..."
            if [ -f "$docker_daemon_conf" ] && [ ! -f "$docker_daemon_conf_backup" ]; then
                cp "$docker_daemon_conf" "$docker_daemon_conf_backup" 2>/dev/null || true
            fi
            mkdir -p /etc/docker
            cat > "$docker_daemon_conf" << EOF
{
    "dns": ["1.1.1.1", "1.0.0.1", "9.9.9.9", "8.8.8.8"]
}
EOF
            ;;
        restore)
            info "Restoring Docker daemon DNS configuration..."
            if [ -f "$docker_daemon_conf_backup" ]; then
                mv -f "$docker_daemon_conf_backup" "$docker_daemon_conf" 2>/dev/null || true
            else
                if [ -f "$docker_daemon_conf" ] && grep -q '"dns"' "$docker_daemon_conf" 2>/dev/null; then
                    echo "{}" > "$docker_daemon_conf"
                fi
            fi
            ;;
        *)
            warn "Unknown docker DNS action: $action"
            ;;
    esac

    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart docker 2>/dev/null || true
    else
        service docker restart 2>/dev/null || true
    fi
}

# Check if Pi-hole DNS is currently active
check_pihole_dns_status() {
    if [ -f /etc/resolv.conf ] && grep -q "127.0.0.1" /etc/resolv.conf; then
        return 0  # Pi-hole DNS is active
    else
        return 1  # System DNS is active
    fi
}

# Verify DNS connectivity
verify_dns_connectivity() {
    local test_domains=("google.com" "cloudflare.com" "github.com")
    local success_count=0
    
    # Wait a moment for DNS to be ready
    sleep 2
    
    debug "Testing DNS connectivity with domains: ${test_domains[*]}"
    
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" >/dev/null 2>&1 || dig +short "$domain" >/dev/null 2>&1 || getent hosts "$domain" >/dev/null 2>&1; then
            debug "✓ DNS resolution successful for $domain"
            success_count=$((success_count + 1))
        else
            debug "✗ DNS resolution failed for $domain"
        fi
    done
    
    debug "DNS test results: $success_count/${#test_domains[@]} successful"
    
    # Consider DNS working if at least 1 out of 3 tests pass
    if [ $success_count -ge 1 ]; then
        return 0
    else
        return 1
    fi
}

# Create backup
create_backup() {
    local backup_name="${1:-backup_$(date +%Y%m%d_%H%M%S)}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    info "Creating backup: $backup_name"
    info "Note: Ollama models (docker_ollama_data) are excluded to keep backups small; models can be re-downloaded."
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Backup configuration files
    info "Backing up configuration files..."
    cp "$ENV_FILE" "$backup_path/" 2>/dev/null || warn ".env file not found"
    cp -r nginx "$backup_path/" 2>/dev/null || warn "nginx directory not found"
    cp -r ssl "$backup_path/" 2>/dev/null || warn "ssl directory not found"
    cp -r helper "$backup_path/" 2>/dev/null || warn "helper directory not found"
    cp -r pihole "$backup_path/" 2>/dev/null || warn "pihole directory not found"
    cp -r tika-minio-processor "$backup_path/" 2>/dev/null || warn "tika-minio-processor directory not found"
    
    # Backup Docker volumes
    if docker compose ps --format json | grep -q '"State":"running"'; then
        info "Backing up data volumes..."
        
        # PostgreSQL
        if docker compose exec -T postgres pg_isready -U ai_admin >/dev/null 2>&1; then
            docker compose exec -T postgres pg_dump -U ai_admin ai_platform > "$backup_path/database.sql" 2>/dev/null || warn "Database backup failed"
        fi
        
        # Docker volumes
        for volume in docker_postgres_data docker_redis_data docker_qdrant_data docker_n8n_data docker_pihole_data minio_data docker_openwebui_files docker_nginx_logs docker_pihole_dnsmasq; do
            if docker volume inspect "$volume" >/dev/null 2>&1; then
                docker run --rm -v "$volume":/data -v "$(pwd)/$backup_path":/backup \
                    alpine tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null || warn "$volume backup failed"
            fi
        done
        
        # Service-specific data backups
        info "Backing up service-specific configurations..."
        
        # MinIO bucket configuration
        if docker exec ai_minio mc ls local/ >/dev/null 2>&1; then
            info "Backing up MinIO configuration..."
            docker exec ai_minio mc admin config export local > "$backup_path/minio-config.json" 2>/dev/null || warn "MinIO config backup failed"
            docker exec ai_minio mc ls local/ > "$backup_path/minio-buckets.txt" 2>/dev/null || warn "MinIO buckets list failed"
        fi
        
        # Pi-hole configuration
        if docker exec ai_pihole pihole -v >/dev/null 2>&1; then
            info "Backing up Pi-hole configuration..."
            docker exec ai_pihole pihole -a -t > "$backup_path/pihole-config.txt" 2>/dev/null || warn "Pi-hole config backup failed"
            docker exec ai_pihole pihole -g > "$backup_path/pihole-gravity.txt" 2>/dev/null || warn "Pi-hole gravity backup failed"
        fi
        
        # Open WebUI configuration (if accessible)
        if docker exec ai_openwebui curl -s -f http://localhost:8080/api/health >/dev/null 2>&1; then
            info "Backing up Open WebUI configuration..."
            docker exec ai_openwebui curl -s http://localhost:8080/api/config > "$backup_path/openwebui-config.json" 2>/dev/null || warn "Open WebUI config backup failed"
        fi
        
        # n8n workflows export (if accessible)
        if docker exec ai_n8n curl -s -f http://localhost:5678/healthz >/dev/null 2>&1; then
            info "Backing up n8n workflows..."
            # Note: n8n workflows are stored in the n8n_data volume, but we can also export them via API if needed
            docker exec ai_n8n find /home/node/.n8n -name "*.json" -exec cat {} \; > "$backup_path/n8n-workflows.json" 2>/dev/null || warn "n8n workflows backup failed"
        fi
    fi
    
    # Create archive
    info "Creating backup archive..."
    tar czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "$(basename "$backup_path")"
    rm -rf "$backup_path"
    
    # Automatic backup rotation - keep only last 10 backups
    info "Managing backup rotation (keeping last 10 backups)..."
    local backup_count=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
    
    if [[ $backup_count -gt 10 ]]; then
        local backups_to_remove=$((backup_count - 10))
        info "Removing $backups_to_remove old backup(s)..."
        
        # Sort by modification time (oldest first) and remove excess
        ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +11 | while read -r old_backup; do
            if [[ -f "$old_backup" ]]; then
                info "Removing old backup: $(basename "$old_backup")"
                rm -f "$old_backup"
            fi
        done
        
        info "✅ Backup rotation complete"
    else
        info "✅ No rotation needed (current backups: $backup_count)"
    fi
    
    info "Backup created: ${backup_path}.tar.gz"
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        error "Please specify backup file: ./$SCRIPT_NAME restore backup_file.tar.gz"
    fi
    
    check_root "restore"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
    fi
    
    warn "This will restore from backup. Current data will be replaced."
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Restore cancelled"
    fi
    
    info "Restoring from backup: $backup_file"
    
    # Stop services
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd down
    
    # Extract backup
    local extract_dir="$BACKUP_DIR/restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$extract_dir"
    tar xzf "$backup_file" -C "$extract_dir"
    
    # Restore files
    info "Restoring configuration files..."
    cp "$extract_dir"/*/.env . 2>/dev/null || warn ".env restore failed"
    cp -r "$extract_dir"/*/nginx . 2>/dev/null || warn "nginx restore failed"
    cp -r "$extract_dir"/*/ssl . 2>/dev/null || warn "ssl restore failed"
    
    # Restart services
    info "Restarting services..."
    $compose_cmd up -d
    
    # Restore database if exists
    if [[ -f "$extract_dir"/*/database.sql ]]; then
        info "Restoring database..."
        sleep 10  # Wait for PostgreSQL to start
        docker compose exec -T postgres psql -U ai_admin -d ai_platform < "$extract_dir"/*/database.sql 2>/dev/null || warn "Database restore failed"
    fi
    
    rm -rf "$extract_dir"
    
    info "Restore completed successfully!"
}

# Cleanup old files
cleanup() {
    info "Cleaning up old backups and logs..."
    
    # Clean up old backups (keep last 10)
    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_count=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
        if [[ $backup_count -gt 10 ]]; then
            local backups_to_remove=$((backup_count - 10))
            info "Removing $backups_to_remove old backup(s) (keeping last 10)..."
            
            # Sort by modification time (oldest first) and remove excess
            ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +11 | while read -r old_backup; do
                if [[ -f "$old_backup" ]]; then
                    info "Removing old backup: $(basename "$old_backup")"
                    rm -f "$old_backup"
                fi
            done
            
            info "✅ Backup cleanup complete"
        else
            info "✅ No backup cleanup needed (current backups: $backup_count)"
        fi
    fi
    
    # Clean up old logs
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [[ $log_size -gt 10485760 ]]; then  # 10MB
            info "Rotating log file..."
            mv "$LOG_FILE" "${LOG_FILE}.old"
            touch "$LOG_FILE"
        fi
    fi
    
    # Clean up Docker system
    info "Cleaning up Docker system..."
    docker system prune -f >/dev/null 2>&1 || warn "Docker cleanup failed"
    
    info "Cleanup completed!"
}

# Comprehensive Docker cleanup during update
perform_docker_cleanup() {
    info "Performing comprehensive Docker cleanup..."
    
    # Show current disk usage
    info "Current Docker disk usage:"
    docker system df
    
    # Remove stopped containers
    info "Removing stopped containers..."
    docker container prune -f
    
    # Remove unused images (including dangling images)
    info "Removing unused images..."
    docker image prune -a -f
    
    # Remove unused volumes (be careful not to remove data volumes)
    info "Removing unused volumes (preserving data volumes)..."
    docker volume prune -f
    
    # Remove unused networks
    info "Removing unused networks..."
    docker network prune -f
    
    # Remove build cache
    info "Removing build cache..."
    docker builder prune -a -f
    
    # Show cleanup results
    info "Docker cleanup completed. New disk usage:"
    docker system df
}


# Show update summary
show_update_summary() {
    info "Update Summary:"
    echo ""
    
    # Show Docker system info
    echo -e "${GREEN}🐳 Docker System Status:${NC}"
    docker system df
    echo ""
    
    # Show running services
    echo -e "${GREEN}🔄 Running Services:${NC}"
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Show image versions
    echo -e "${GREEN}📦 Current Image Versions:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -20
    echo ""
    
    # Show resource usage
    echo -e "${GREEN}📊 Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | head -10
    echo ""
}

# Test update process (dry run)
test_update() {
    info "Testing update process (dry run)..."
    echo ""
    
    # Show what would be cleaned up
    echo -e "${YELLOW}🧹 Docker Cleanup Preview:${NC}"
    echo "  - Stopped containers: $(docker ps -a --filter status=exited --format '{{.Names}}' | wc -l)"
    echo "  - Unused images: $(docker images -f dangling=true -q | wc -l)"
    echo "  - Unused volumes: $(docker volume ls -f dangling=true -q | wc -l)"
    echo "  - Unused networks: $(docker network ls -f dangling=true -q | wc -l)"
    echo ""
    
    # Show current disk usage
    echo -e "${YELLOW}💾 Current Disk Usage:${NC}"
    docker system df
    echo ""
    
    # Show services that would be updated
    echo -e "${YELLOW}🔄 Services to Update:${NC}"
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd config --services | while read service; do
        echo "  - $service"
    done
    echo ""
    
    # Show services that would be updated
    echo -e "${YELLOW}📦 Services to Update:${NC}"
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd config --services | while read service; do
        echo "  - $service"
    done
    echo ""
    
    info "Dry run completed. Use 'sudo ./tu-vm.sh update' to perform actual update."
}

# Show DNS status
show_dns_status() {
    info "DNS Status Information:"
    echo ""
    
    # Show current DNS configuration
    echo -e "${GREEN}🌐 Current DNS Configuration:${NC}"
    if [ -f /etc/resolv.conf ]; then
        cat /etc/resolv.conf
    else
        echo "  No resolv.conf found"
    fi
    echo ""
    
    # Show DNS type
    echo -e "${GREEN}🔍 DNS Type:${NC}"
    if check_pihole_dns_status; then
        echo "  ✅ Pi-hole DNS is active (127.0.0.1)"
    else
        echo "  🌍 System DNS is active (public DNS servers)"
    fi
    echo ""
    
    # Test DNS connectivity
    echo -e "${GREEN}🔗 DNS Connectivity Test:${NC}"
    if verify_dns_connectivity; then
        echo "  ✅ DNS resolution is working correctly"
    else
        echo "  ❌ DNS resolution is not working"
    fi
    echo ""
    
    # Show Pi-hole container status
    echo -e "${GREEN}🐳 Pi-hole Container Status:${NC}"
    if docker ps | grep -q "ai_pihole"; then
        echo "  ✅ Pi-hole container is running"
        if docker exec ai_pihole pihole status >/dev/null 2>&1; then
            echo "  ✅ Pi-hole service is ready"
        else
            echo "  ⚠️  Pi-hole service is not ready yet"
        fi
    else
        echo "  ❌ Pi-hole container is not running"
    fi
    echo ""
    
    # Show backup status
    if [ -f /etc/resolv.conf.pihole.backup ]; then
        echo -e "${GREEN}💾 DNS Backup:${NC}"
        echo "  ✅ DNS configuration backup exists"
        echo "  📁 Backup file: /etc/resolv.conf.pihole.backup"
    else
        echo -e "${GREEN}💾 DNS Backup:${NC}"
        echo "  ℹ️  No DNS backup found (normal if no updates have been performed)"
    fi
    echo ""
}

# =============================================================================
# SECURITY FUNCTIONS
# =============================================================================

# Generate secure secrets
generate_secrets() {
    info "Generating secure secrets for TechUties AI Platform..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        if [[ -f "env.example" ]]; then
            cp env.example "$ENV_FILE"
            info "Created .env file from env.example"
        else
            error "No env.example file found to create .env from"
        fi
    fi
    
    # Generate secure passwords and keys
    local postgres_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local redis_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local n8n_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local pihole_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local minio_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local webui_secret=$(openssl rand -hex 32)
    local jwt_secret=$(openssl rand -hex 32)
    local auth_secret=$(openssl rand -hex 32)
    local encryption_key=$(openssl rand -hex 32)
    local control_token=$(openssl rand -hex 32)
    
    # Helper: set or update a key in .env if it is missing or equals an insecure default
    set_env_var_if_default() {
        local key="$1"; local default_val="$2"; local new_val="$3";
        if grep -qE "^${key}=" "$ENV_FILE"; then
            local current_val
            current_val=$(grep -E "^${key}=" "$ENV_FILE" | sed -E "s/^${key}=//")
            if [[ -z "$current_val" || "$current_val" == "$default_val" ]]; then
                sed -i "s|^${key}=.*|${key}=${new_val}|" "$ENV_FILE"
            fi
        else
            echo "${key}=${new_val}" >> "$ENV_FILE"
        fi
    }

    # Backward-compat replacements for explicit CHANGE_ME markers
    sed -i "s/CHANGE_ME_SECURE_PASSWORD/$postgres_pass/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_32_CHAR_ENCRYPTION_KEY/$encryption_key/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_SECRET_KEY/$webui_secret/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_JWT_SECRET_KEY/$jwt_secret/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_AUTH_SECRET/$auth_secret/g" "$ENV_FILE"

    # MinIO root password (first occurrence if using template)
    sed -i "0,/CHANGE_ME_SECURE_PASSWORD/s//$minio_pass/" "$ENV_FILE"

    # Ensure presence of keys referenced by docker-compose with secure defaults on first run
    set_env_var_if_default "POSTGRES_PASSWORD" "ai_password_2024" "$postgres_pass"
    set_env_var_if_default "REDIS_PASSWORD" "redis_password_2024" "$redis_pass"
    set_env_var_if_default "MINIO_ROOT_PASSWORD" "minio123456" "$minio_pass"
    set_env_var_if_default "WEBUI_SECRET_KEY" "webui_secret_key_2024" "$webui_secret"
    set_env_var_if_default "WEBUI_JWT_SECRET_KEY" "jwt_secret_key_2024" "$jwt_secret"
    set_env_var_if_default "WEBUI_AUTH_SECRET" "auth_secret_2024" "$auth_secret"
    set_env_var_if_default "N8N_PASSWORD" "admin123" "$n8n_pass"
    set_env_var_if_default "N8N_ENCRYPTION_KEY" "1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b" "$encryption_key"
    set_env_var_if_default "PIHOLE_PASSWORD" "SwissPiHole2024!" "$pihole_pass"
    set_env_var_if_default "CONTROL_TOKEN" "" "$control_token"
    
    # Set proper permissions
    chmod 600 "$ENV_FILE"
    
    info "Secure secrets generated and saved to .env"
    info "File permissions set to 600 (owner read/write only)"
    
    # Display generated credentials
    echo ""
    echo -e "${BLUE}📋 Generated Credentials:${NC}"
    echo "=================================="
    echo -e "${GREEN}🔑 Service Access Credentials:${NC}"
    echo ""
    echo -e "${YELLOW}Open WebUI:${NC}"
    echo "  URL: https://oweb.tu.local"
    echo "  Admin: First user to register"
    echo ""
    echo -e "${YELLOW}n8n Workflow Automation:${NC}"
    echo "  URL: https://n8n.tu.local"
    echo "  Username: admin"
    echo "  Password: $n8n_pass"
    echo ""
    echo -e "${YELLOW}MinIO Object Storage:${NC}"
    echo "  Console: https://minio.tu.local"
    echo "  API: https://api.minio.tu.local"
    echo "  Username: admin"
    echo "  Password: $minio_pass"
    echo ""
    echo -e "${YELLOW}Pi-hole DNS:${NC}"
    echo "  URL: https://pihole.tu.local/admin"
    echo "  Password: $pihole_pass"
    echo ""
    echo -e "${YELLOW}Database Access:${NC}"
    echo "  Host: ai_postgres:5432"
    echo "  Database: ai_platform"
    echo "  Username: ai_admin"
    echo "  Password: $postgres_pass"
    echo ""
    echo -e "${YELLOW}Redis Access:${NC}"
    echo "  Host: ai_redis:6379"
    echo "  Password: $redis_pass"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT SECURITY NOTES:${NC}"
    echo "• Store these credentials securely"
    echo "• Change passwords after first login"
    echo "• Never share these credentials"
    echo "• Consider using a password manager"
    echo ""
    echo -e "${GREEN}🎉 Installation complete! All services are ready.${NC}"
    warn "⚠️  Keep your .env file secure and never commit it to version control!"
}

# Validate security configuration
validate_security() {
    info "Validating security configuration..."
    
    local issues=()
    
    # Check if .env file exists and has proper permissions
    if [[ ! -f "$ENV_FILE" ]]; then
        issues+=("Missing .env file")
    elif [[ $(stat -c %a "$ENV_FILE") != "600" ]]; then
        issues+=("Insecure .env file permissions (should be 600)")
    fi
    
    # Check for default passwords
    if grep -q "CHANGE_ME" "$ENV_FILE" 2>/dev/null; then
        issues+=("Default passwords detected in .env file")
    fi
    
    # Check for weak passwords
    if grep -q "password_2024\|admin123\|test123" "$ENV_FILE" 2>/dev/null; then
        issues+=("Weak passwords detected in .env file")
    fi
    
    # Check SSL certificate
    if [[ ! -f "ssl/nginx.crt" ]] || [[ ! -f "ssl/nginx.key" ]]; then
        issues+=("Missing SSL certificates")
    fi
    
    # Check firewall status
    if ! command -v ufw >/dev/null 2>&1; then
        issues+=("UFW firewall not installed")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        info "Security validation passed!"
        return 0
    else
        warn "Security issues found:"
        for issue in "${issues[@]}"; do
            warn "  - $issue"
        done
        return 1
    fi
}


# =============================================================================
# PDF PROCESSING FUNCTIONS
# =============================================================================

# Check PDF processing status
check_pdf_processing_status() {
    info "Checking PDF processing pipeline status..."
    echo ""
    
    # Check Tika service
    echo -e "${GREEN}🔍 Apache Tika Service:${NC}"
    if docker ps | grep -q "ai_tika.*Up"; then
        echo "  ✅ Tika container is running"
        if curl -s -f "http://localhost:9998/tika" >/dev/null 2>&1; then
            echo "  ✅ Tika API is responding"
        else
            echo "  ⚠️  Tika API not responding"
        fi
    else
        echo "  ❌ Tika container is not running"
    fi
    echo ""
    
    # Check MinIO service
    echo -e "${GREEN}🗄️ MinIO Object Storage:${NC}"
    if docker ps | grep -q "ai_minio.*Up"; then
        echo "  ✅ MinIO container is running"
        if curl -s -f "http://localhost:9000/minio/health/live" >/dev/null 2>&1; then
            echo "  ✅ MinIO API is responding"
        else
            echo "  ⚠️  MinIO API not responding"
        fi
    else
        echo "  ❌ MinIO container is not running"
    fi
    echo ""
    
    # Check Tika-MinIO processor
    echo -e "${GREEN}⚙️ Tika-MinIO Processor:${NC}"
    if docker ps | grep -q "tika_minio_processor.*Up"; then
        echo "  ✅ Processor container is running"
        echo "  📊 Recent activity:"
        docker logs tika_minio_processor --tail 5 2>/dev/null | grep -E "(✅|❌|🔄)" || echo "    No recent activity"
    else
        echo "  ❌ Processor container is not running"
    fi
    echo ""
    
    # Check tika-pipe bucket
    echo -e "${GREEN}📁 Tika-Pipe Bucket:${NC}"
    if docker exec ai_minio mc ls local/tika-pipe/ >/dev/null 2>&1; then
        local file_count=$(docker exec ai_minio mc ls local/tika-pipe/ | wc -l)
        echo "  ✅ Bucket exists with $file_count files"
    else
        echo "  ❌ tika-pipe bucket not found"
    fi
    echo ""
}

# Test PDF processing
test_pdf_processing() {
    info "Testing PDF processing pipeline..."
    
    # Create a test PDF
    local test_pdf="/tmp/test.pdf"
    echo "Creating test PDF..."
    cat > /tmp/test.tex << 'EOF'
\documentclass{article}
\begin{document}
\title{Test Document}
\author{TechUties AI Platform}
\date{\today}
\maketitle

This is a test document for PDF processing pipeline validation.

\section{Test Content}
The Tika-MinIO pipeline should process this document and extract the text content.

\subsection{Features}
\begin{itemize}
\item Text extraction
\item Metadata processing
\item MinIO storage
\end{itemize}

\end{document}
EOF
    
    # Check if pdflatex is available
    if ! command -v pdflatex >/dev/null 2>&1; then
        warn "pdflatex not available, using simple test file"
        echo "Test PDF content" > "$test_pdf"
    else
        cd /tmp && pdflatex test.tex >/dev/null 2>&1 && mv test.pdf "$test_pdf" || {
            warn "PDF generation failed, using simple test file"
            echo "Test PDF content" > "$test_pdf"
        }
    fi
    
    # Upload to MinIO
    info "Uploading test PDF to tika-pipe bucket..."
    if docker run --rm -v "$test_pdf":/test.pdf -v minio_data:/data alpine sh -c "cp /test.pdf /data/tika-pipe/test-$(date +%s).pdf"; then
        info "✅ Test PDF uploaded successfully"
        info "⏳ Waiting for Tika processing (30 seconds)..."
        sleep 30
        
        # Check for processed file
        if docker exec ai_minio mc ls local/tika-pipe/ | grep -q "\.txt"; then
            info "✅ PDF processing successful - .txt file found"
        else
            warn "⚠️  No .txt file found - processing may have failed"
        fi
    else
        error "❌ Failed to upload test PDF"
    fi
    
    # Cleanup
    rm -f /tmp/test.tex /tmp/test.aux /tmp/test.log "$test_pdf" 2>/dev/null || true
}

# Show PDF processing logs
show_pdf_logs() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        info "Available PDF processing services:"
        echo "  - tika (Apache Tika service)"
        echo "  - minio (MinIO object storage)"
        echo "  - processor (Tika-MinIO processor)"
        echo ""
        echo "Usage: ./$SCRIPT_NAME pdf-logs <service_name>"
        return 0
    fi
    
    case "$service" in
        tika)
            info "Showing Tika service logs..."
            docker logs ai_tika --tail=50 -f
            ;;
        minio)
            info "Showing MinIO service logs..."
            docker logs ai_minio --tail=50 -f
            ;;
        processor)
            info "Showing Tika-MinIO processor logs..."
            docker logs tika_minio_processor --tail=50 -f
            ;;
        *)
            error "Unknown PDF processing service: $service"
            echo "Available services: tika, minio, processor"
            ;;
    esac
}

# Reset PDF processing pipeline
reset_pdf_pipeline() {
    warn "Resetting PDF processing pipeline..."
    
    # Stop processor
    info "Stopping Tika-MinIO processor..."
    docker stop tika_minio_processor 2>/dev/null || true
    
    # Clear tika-pipe bucket
    info "Clearing tika-pipe bucket..."
    docker exec ai_minio mc rm --recursive --force local/tika-pipe/ 2>/dev/null || true
    
    # Restart processor
    info "Restarting Tika-MinIO processor..."
    docker start tika_minio_processor 2>/dev/null || {
        info "Starting processor from docker-compose..."
        docker compose up -d tika_minio_processor
    }
    
    info "✅ PDF processing pipeline reset complete"
}

# =============================================================================
# DIAGNOSTIC FUNCTIONS
# =============================================================================

# Check service health
check_health() {
    info "Checking service health..."
    
    local failed_services=()
    local healthy_services=()
    
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        if check_service_health "$service_name" "$port"; then
            healthy_services+=("$service_name")
        else
            failed_services+=("$service_name")
        fi
    done
    
    echo ""
    echo -e "${WHITE}Health Summary:${NC}"
    echo "  Healthy: ${#healthy_services[@]} services"
    echo "  Failed:  ${#failed_services[@]} services"
    echo ""
    
    if [[ ${#healthy_services[@]} -gt 0 ]]; then
        echo -e "${GREEN}${ICON_SUCCESS}${NC} Healthy services:"
        for service in "${healthy_services[@]}"; do
            echo "    - $service"
        done
        echo ""
    fi
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        echo -e "${RED}${ICON_ERROR}${NC} Failed services:"
        for service in "${failed_services[@]}"; do
            echo "    - $service"
        done
        echo ""
        return 1
    fi
    
    return 0
}

# Test service endpoints
test_endpoints() {
    info "Testing service endpoints..."
    
    local vm_ip=$(get_vm_ip)
    local failed_tests=()
    
    # Test main landing page
    if curl -k -s -o /dev/null "https://$vm_ip"; then
        info "✓ Landing page accessible"
    else
        failed_tests+=("Landing page")
    fi
    
    # Test Open WebUI
    if curl -k -s -o /dev/null -H "Host: oweb.tu.local" "https://$vm_ip"; then
        info "✓ Open WebUI accessible"
    else
        failed_tests+=("Open WebUI")
    fi
    
    # Test n8n
    if curl -k -s -o /dev/null -H "Host: n8n.tu.local" "https://$vm_ip"; then
        info "✓ n8n accessible"
    else
        failed_tests+=("n8n")
    fi
    
    # Test Pi-hole
    if curl -k -s -o /dev/null -H "Host: pihole.tu.local" "https://$vm_ip"; then
        info "✓ Pi-hole accessible"
    else
        failed_tests+=("Pi-hole")
    fi
    
    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        warn "Failed endpoint tests: ${failed_tests[*]}"
        return 1
    fi
    
    info "All endpoint tests passed!"
    return 0
}

# Run comprehensive diagnostics
run_diagnostics() {
    info "Running comprehensive diagnostics..."
    echo ""
    
    # System information
    show_system_info
    
    # Service health
    check_health
    echo ""
    
    # Endpoint tests
    test_endpoints
    echo ""
    
    # Docker system info
    info "Docker system information:"
    docker system df
    echo ""
    
    # Disk usage
    info "Disk usage:"
    df -h
    echo ""
    
    # Memory usage
    info "Memory usage:"
    free -h
    echo ""
    
    info "Diagnostics completed!"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Handle special cases
    case "${1:-}" in
        help|--help|-h|"")
            show_help
            ;;
        version|--version|-v)
            show_info
            ;;
        *)
            # Check prerequisites for most commands
            if [[ "$1" != "help" && "$1" != "version" ]]; then
                check_docker
                check_docker_compose
            fi
            
            # Execute command
            case "$1" in
                start)
                    start_services
                    ;;
                stop)
                    stop_services
                    ;;
                restart)
                    restart_services
                    ;;
                status)
                    show_status
                    ;;
                logs)
                    show_logs "$2"
                    ;;
                access)
                    show_access_info
                    ;;
                secure)
                    enable_secure
                    ;;
                public)
                    enable_public
                    ;;
                lock)
                    lock_access
                    ;;
                update)
                    update_system
                    ;;
                test-update)
                    test_update
                    ;;
                backup)
                    create_backup "$2"
                    ;;
                restore)
                    restore_backup "$2"
                    ;;
                cleanup)
                    cleanup
                    ;;
                health)
                    check_health
                    ;;
                test)
                    test_endpoints
                    ;;
                diagnose)
                    run_diagnostics
                    ;;
                info)
                    show_info
                    show_system_info
                    ;;
                generate-secrets)
                    generate_secrets
                    ;;
                validate-security)
                    validate_security
                    ;;
                setup-minio)
                    setup_minio_buckets
                    ;;
                pdf-status)
                    check_pdf_processing_status
                    ;;
                pdf-test)
                    test_pdf_processing
                    ;;
                pdf-logs)
                    show_pdf_logs "$2"
                    ;;
                pdf-reset)
                    reset_pdf_pipeline
                    ;;
                version)
                    show_version
                    ;;
                *)
                    error "Unknown command: $1"
                    echo ""
                    show_help
                    ;;
            esac
            ;;
    esac
}

# Run main function
main "$@"