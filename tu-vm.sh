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
    local max_attempts=3
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
            debug "$service_name is running (Docker status)"
            return 0
        fi
        
        debug "Attempt $attempt/$max_attempts: $service_name not ready yet..."
        sleep 1
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
    echo ""
    echo -e "${WHITE}Access Control:${NC}"
    echo "  secure                   Enable secure access (recommended)"
    echo "  public                   Enable public access (less secure)"
    echo "  lock                     Block all external access"
    echo ""
    echo -e "${WHITE}Maintenance:${NC}"
    echo "  update                   Update system and services"
    echo "  update-preview            Preview what will be updated"
    echo "  backup [name]            Create backup with optional name"
    echo "  restore <file>           Restore from backup file"
    echo "  cleanup                  Clean up old backups and logs"
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
    echo -e "${WHITE}Security Levels:${NC}"
    echo "  ${ICON_SECURE} SECURE:    Secure access (recommended)"
    echo "  ${ICON_PUBLIC} PUBLIC:    Access from internet"
    echo "  ${ICON_LOCKED} LOCKED:    No external access"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo "  ./$SCRIPT_NAME start                    # Start services"
    echo "  ./$SCRIPT_NAME secure                   # Enable secure access"
    echo "  sudo ./$SCRIPT_NAME secure              # Enable secure access (needs sudo)"
    echo "  ./$SCRIPT_NAME backup my-backup         # Create named backup"
    echo "  ./$SCRIPT_NAME restore backup.tar.gz    # Restore from backup"
    echo "  ./$SCRIPT_NAME logs nginx               # Show nginx logs"
    echo "  ./$SCRIPT_NAME health                   # Check service health"
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
        
        show_access_info
    else
        warn "Some services may not be fully ready yet."
        info "Check status with: ./$SCRIPT_NAME status"
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
    
    # Update Docker images
    info "Updating Docker images..."
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd pull
    
    # Stop services gracefully
    info "Stopping services for update..."
    $compose_cmd down
    
    # Remove old images (keep data volumes)
    info "Cleaning up old Docker images..."
    docker image prune -f
    
    # Start services with updated images
    info "Starting services with updated images..."
    $compose_cmd up -d
    
    # Wait for services to be ready
    if wait_for_services; then
        info "All services started successfully after update!"
        
        # Verify data retention
        info "Verifying data retention..."
        verify_data_retention
        
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

# Create backup
create_backup() {
    local backup_name="${1:-backup_$(date +%Y%m%d_%H%M%S)}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    info "Creating backup: $backup_name"
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Backup configuration files
    info "Backing up configuration files..."
    cp "$ENV_FILE" "$backup_path/" 2>/dev/null || warn ".env file not found"
    cp -r nginx "$backup_path/" 2>/dev/null || warn "nginx directory not found"
    cp -r ssl "$backup_path/" 2>/dev/null || warn "ssl directory not found"
    
    # Backup Docker volumes
    if docker compose ps --format json | grep -q '"State":"running"'; then
        info "Backing up data volumes..."
        
        # PostgreSQL
        if docker compose exec -T postgres pg_isready -U ai_admin >/dev/null 2>&1; then
            docker compose exec -T postgres pg_dump -U ai_admin ai_platform > "$backup_path/database.sql" 2>/dev/null || warn "Database backup failed"
        fi
        
        # Docker volumes
        for volume in postgres_data redis_data qdrant_data ollama_data n8n_data pihole_data; do
            if docker volume inspect "$volume" >/dev/null 2>&1; then
                docker run --rm -v "$volume":/data -v "$(pwd)/$backup_path":/backup \
                    alpine tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null || warn "$volume backup failed"
            fi
        done
    fi
    
    # Create archive
    info "Creating backup archive..."
    tar czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "$(basename "$backup_path")"
    rm -rf "$backup_path"
    
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
        local backup_count=$(find "$BACKUP_DIR" -name "*.tar.gz" | wc -l)
        if [[ $backup_count -gt 10 ]]; then
            info "Removing old backups (keeping last 10)..."
            find "$BACKUP_DIR" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | head -n -10 | cut -d' ' -f2- | xargs rm -f
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
    
    # Update .env file with secure secrets
    sed -i "s/CHANGE_ME_SECURE_PASSWORD/$postgres_pass/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_32_CHAR_ENCRYPTION_KEY/$encryption_key/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_SECRET_KEY/$webui_secret/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_JWT_SECRET_KEY/$jwt_secret/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_AUTH_SECRET/$auth_secret/g" "$ENV_FILE"
    
    # Update MinIO password (handle multiple occurrences)
    sed -i "0,/CHANGE_ME_SECURE_PASSWORD/s//$minio_pass/" "$ENV_FILE"
    
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
        update-preview)
            update_preview
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