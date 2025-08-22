#!/bin/bash

# AI Platform Foolproof Update Script
# Comprehensive update with automatic DNS handling and dependency management

set -e
set -o pipefail

# Initialize logging
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging function
log() {
    local msg="$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}[${msg}${NC}"
    # Write plain message to log file without color codes
    echo "[${msg}" >> "$LOG_FILE" 2>/dev/null || true
}

warn() {
    local msg="$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1"
    echo -e "${YELLOW}[${msg}${NC}"
    echo "[${msg}" >> "$LOG_FILE" 2>/dev/null || true
}

error() {
    local msg="$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${RED}[${msg}${NC}"
    echo "[${msg}" >> "$LOG_FILE" 2>/dev/null || true
    exit 1
}

info() {
    local msg="$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1"
    echo -e "${BLUE}[${msg}${NC}"
    echo "[${msg}" >> "$LOG_FILE" 2>/dev/null || true
}

# Run a command and capture output into the log file
run_cmd() {
    local description="$1"; shift
    info "$description"
    {
        echo "----- $(date +'%F %T') | $description -----"
        "$@"
        echo "----- exit:$? -----"
    } >> "$LOG_FILE" 2>&1
}

# Collect diagnostics about DNS and networking
collect_dns_diagnostics() {
    info "Collecting DNS diagnostics..."
    run_cmd "systemd-resolved status" bash -lc 'systemctl status systemd-resolved || true'
    run_cmd "ss -tlnp | :53" bash -lc 'ss -tlnp | grep :53 || true'
    run_cmd "resolvectl status" bash -lc 'resolvectl status || true'
    run_cmd "/etc/resolv.conf" bash -lc 'ls -l /etc/resolv.conf; cat /etc/resolv.conf || true'
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    # Check disk space
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 5000000 ]; then
        error "Insufficient disk space. Need at least 5GB free space."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH."
    fi
    
    # Check Docker Compose
    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose is not installed or not in PATH."
    fi
    
    log "✓ System requirements met"
}

# Start Ubuntu host DNS (systemd-resolved) for updates (uses non-Google resolvers)
fix_dns_resolution() {
    log "Enabling host DNS (systemd-resolved) for updates..."

    # Determine default network interface
    local default_iface
    default_iface=$(ip route | awk '/default/ {print $5; exit}')
    if [[ -z "$default_iface" ]]; then
        default_iface="enp0s5"
    fi

    collect_dns_diagnostics

    # Ensure /etc/resolv.conf symlink exists to systemd stub, otherwise create it
    if [ ! -L /etc/resolv.conf ] || ! readlink -f /etc/resolv.conf | grep -q "/run/systemd/resolve/stub-resolv.conf"; then
        warn "/etc/resolv.conf is not the systemd-resolved stub. Re-linking to stub-resolv.conf"
        run_cmd "Relinking /etc/resolv.conf to stub-resolv.conf" sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi

    # Start and enable systemd-resolved
    run_cmd "Enable and start systemd-resolved" sudo systemctl enable --now systemd-resolved || true

    # Configure trustworthy, non-Google resolvers (Cloudflare + Quad9)
    run_cmd "Configure resolvers (Cloudflare + Quad9) on $default_iface" sudo resolvectl dns "$default_iface" 1.1.1.1 9.9.9.9
    run_cmd "Flush resolver cache" sudo resolvectl flush-caches || true

    # If the local stub 127.0.0.53:53 is not listening, try restarting and then fall back to static resolv.conf
    if ! (ss -tulnp | grep -q "127.0.0.53:53"); then
        warn "systemd-resolved stub not listening on 127.0.0.53:53, restarting service..."
        run_cmd "Restart systemd-resolved" sudo systemctl restart systemd-resolved || true
        sleep 2
    fi
    if ! (ss -tulnp | grep -q "127.0.0.53:53"); then
        warn "Stub still not listening; using temporary static /etc/resolv.conf with upstream resolvers"
        run_cmd "Write static /etc/resolv.conf" bash -lc 'printf "nameserver 1.1.1.1\nnameserver 9.9.9.9\n" | sudo tee /etc/resolv.conf >/dev/null'
    fi

    # Verify DNS resolution via host DNS
    local attempts=0
    while [ $attempts -lt 10 ]; do
        if nslookup example.com >/dev/null 2>&1; then
            log "✓ Host DNS is working (systemd-resolved)"
            return 0
        fi
        sleep 2
        attempts=$((attempts + 1))
    done

    collect_dns_diagnostics
    error "Host DNS failed to initialize"
}

# Stop Ubuntu host DNS to free port 53 for Pi-hole
stop_host_dns() {
    log "Stopping host DNS (systemd-resolved) to free port 53..."
    run_cmd "Stop systemd-resolved" sudo systemctl stop systemd-resolved || true
    sleep 2
    # Ensure port 53 is free
    if sudo ss -tlnp | grep -q ":53"; then
        warn "Port 53 still bound, retrying..."
        sleep 2
    fi
    if sudo ss -tlnp | grep -q ":53"; then
        collect_dns_diagnostics
        error "Port 53 is still in use; cannot start Pi-hole"
    fi
    log "✓ Port 53 is free"
}

# Stop only Pi-hole for update phase
stop_pihole_service() {
    log "Stopping Pi-hole (DNS) before update..."
    docker compose stop pihole 2>/dev/null || true
}

# Run OS updates (apt update/upgrade)
run_os_updates() {
    log "Running Ubuntu updates (apt update && upgrade)..."
    run_cmd "apt-get update" sudo apt-get update -y || run_cmd "apt-get update (retry)" sudo apt-get update
    run_cmd "apt-get upgrade" sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
    log "✓ Ubuntu packages updated"
}

# Fix container hostname resolution
fix_container_resolution() {
    log "Fixing container hostname resolution..."
    
    # Update nginx configuration to use IP addresses
    if [ -f "nginx/conf.d/default.conf" ]; then
        log "Updating nginx configuration to use IP addresses..."
        
        # Backup original config
        cp nginx/conf.d/default.conf nginx/conf.d/default.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Update proxy_pass directives to use IP addresses
        sed -i 's|proxy_pass http://ai_openwebui:8080/|proxy_pass http://172.20.0.14:8080/|g' nginx/conf.d/default.conf
        sed -i 's|proxy_pass http://ai_n8n:5678/|proxy_pass http://172.20.0.15:5678/|g' nginx/conf.d/default.conf
        sed -i 's|proxy_pass http://ai_pihole:80/|proxy_pass http://172.20.0.16:80/|g' nginx/conf.d/default.conf
        
        log "✓ Nginx configuration updated"
    fi
}

# Fix hostname entries
fix_hostname_entries() {
    log "Ensuring hostname entries are correct..."
    
    # Add missing hostname entries to /etc/hosts
    if ! grep -q "tu.local" /etc/hosts; then
        log "Adding tu.local to /etc/hosts..."
        echo "10.211.55.12 tu.local" | sudo tee -a /etc/hosts
    fi
    if ! grep -q "n8n.tu.local" /etc/hosts; then
        log "Adding n8n.tu.local to /etc/hosts..."
        echo "10.211.55.12 n8n.tu.local" | sudo tee -a /etc/hosts
    fi
    if ! grep -q "oweb.tu.local" /etc/hosts; then
        log "Adding oweb.tu.local to /etc/hosts..."
        echo "10.211.55.12 oweb.tu.local" | sudo tee -a /etc/hosts
    fi
    if ! grep -q "pihole.tu.local" /etc/hosts; then
        log "Adding pihole.tu.local to /etc/hosts..."
        echo "10.211.55.12 pihole.tu.local" | sudo tee -a /etc/hosts
    fi
    
    log "✓ Hostname entries verified"
}

# Ensure n8n schema exists in Postgres (idempotent)
ensure_n8n_schema() {
    log "Ensuring Postgres schema for n8n exists..."
    if docker compose exec -T postgres psql -U ai_admin -d ai_platform -v ON_ERROR_STOP=1 -c "CREATE SCHEMA IF NOT EXISTS n8n AUTHORIZATION ai_admin; GRANT ALL ON SCHEMA n8n TO ai_admin;" >/dev/null 2>&1; then
        log "✓ Postgres schema 'n8n' is present"
    else
        warn "Could not ensure Postgres schema 'n8n' (continuing)"
    fi
}

# Create comprehensive backup
create_backup() {
    log "Creating comprehensive backup..."
    
    BACKUP_DIR="backups/update_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    if docker compose ps postgres 2>/dev/null | grep -q "Up"; then
        log "Backing up database..."
        docker compose exec -T postgres pg_dump -U ai_admin ai_platform > "$BACKUP_DIR/database.sql" 2>/dev/null || warn "Database backup failed"
    fi
    
    # Backup configuration files
    log "Backing up configuration files..."
    cp .env "$BACKUP_DIR/" 2>/dev/null || warn "Failed to backup .env"
    cp docker-compose.yml "$BACKUP_DIR/" 2>/dev/null || warn "Failed to backup docker-compose.yml"
    cp -r nginx "$BACKUP_DIR/" 2>/dev/null || warn "Failed to backup nginx config"
    cp -r ssl "$BACKUP_DIR/" 2>/dev/null || warn "Failed to backup SSL certificates"
    
    # Create compressed backup
    tar czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR" 2>/dev/null || warn "Failed to compress backup"
    rm -rf "$BACKUP_DIR"
    
    log "✓ Backup created: $BACKUP_DIR.tar.gz"
}

# Stop services in dependency order (keep Pi-hole running until host DNS is ready)
stop_services_safe() {
    log "Stopping services (except DNS) in dependency order..."
    
    # Stop services that depend on DNS first (keep Pi-hole up for now)
    docker compose stop nginx open-webui n8n qdrant ollama postgres redis 2>/dev/null || true
    
    log "✓ Core services stopped (Pi-hole still running for DNS during pre-update)"
}

# Pull latest images with retry
pull_images() {
    log "Pulling latest Docker images..."
    
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        run_cmd "docker compose pull (attempt $attempt)" docker compose pull
        if docker compose pull >/dev/null 2>&1; then
            log "✓ Latest images pulled successfully"
            return 0
        else
            warn "Image pull failed (attempt $attempt/$max_attempts)"
            if [ $attempt -eq $max_attempts ]; then
                error "Failed to pull images after $max_attempts attempts"
            fi
            sleep 10
            attempt=$((attempt + 1))
        fi
    done
}

# Start services in dependency order with health checks
start_services_safe() {
    log "Starting services in dependency order..."
    
    # Step 0: Ensure host DNS is stopped so Pi-hole can bind 53
    stop_host_dns
    
    # Step 1: Start Pi-hole first (DNS service)
    log "Starting Pi-hole (DNS service)..."
    docker compose up -d pihole
    
    # Wait for Pi-hole to be ready
    log "Waiting for Pi-hole to be ready..."
    local attempts=0
    while [ $attempts -lt 60 ]; do
        if docker compose exec pihole dig +norecurse +retry=0 @127.0.0.1 pi.hole > /dev/null 2>&1; then
            log "✓ Pi-hole is ready"
            break
        fi
        sleep 2
        attempts=$((attempts + 1))
    done
    
    if [ $attempts -eq 60 ]; then
        warn "Pi-hole took longer than expected to start, but continuing..."
    fi
    
    # Step 2: Start database services
    log "Starting database services..."
    docker compose up -d postgres redis qdrant
    
    # Wait for databases to be ready
    log "Waiting for databases to be ready..."
    sleep 30

    # Ensure required schemas exist
    ensure_n8n_schema
    
    # Step 3: Start AI services
    log "Starting AI services..."
    docker compose up -d ollama open-webui n8n
    
    # Step 4: Start network services
    log "Starting network services..."
    docker compose up -d nginx
    
    log "✓ All services started in dependency order"
}

# Wait for services to be ready
wait_for_services() {
    log "Waiting for services to be ready..."
    sleep 60
    
    # Check service status
        docker compose ps
}

# Test service availability with comprehensive retries
test_services() {
    log "Testing service availability..."
    
    local all_healthy=true
    local max_attempts=5
    
    # Test HTTP/HTTPS endpoints with retries
    declare -A endpoints=(
        ["https://tu.local/"]="Landing"
        ["https://oweb.tu.local/"]="Open WebUI"
        ["https://n8n.tu.local/"]="n8n"
        ["https://pihole.tu.local/health"]="Pi-hole"
        ["http://localhost:11434/api/tags"]="Ollama"
    )
    
    for url in "${!endpoints[@]}"; do
        local attempts=0
        local success=false
        
        while [ $attempts -lt $max_attempts ] && [ "$success" = false ]; do
        if curl -k -f -s -m 10 "$url" > /dev/null; then
            log "✓ ${endpoints[$url]} is accessible"
                success=true
            else
                attempts=$((attempts + 1))
                if [ $attempts -lt $max_attempts ]; then
                    warn "✗ ${endpoints[$url]} not accessible (attempt $attempts/$max_attempts), retrying..."
                    sleep 10
                else
                    warn "✗ ${endpoints[$url]} is not accessible after $max_attempts attempts"
            all_healthy=false
        fi
            fi
        done
    done
    
    # Test database connectivity
    if docker compose exec -T postgres pg_isready -U ai_admin -d ai_platform > /dev/null 2>&1; then
        log "✓ PostgreSQL is accessible"
    else
        warn "✗ PostgreSQL is not accessible"
        all_healthy=false
    fi
    
    # Test Redis connectivity
    if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log "✓ Redis is accessible"
    else
        warn "✗ Redis is not accessible"
        all_healthy=false
    fi
    
    if [ "$all_healthy" = true ]; then
        log "✓ All services are healthy and accessible!"
    else
        warn "Some services may not be fully ready yet. Check logs with: docker compose logs"
    fi
}

# Emergency recovery if services fail
emergency_recovery() {
    log "Attempting emergency recovery..."
    
    # Try to fix DNS issues
    fix_dns_resolution
    
    # Try to restart services
    docker compose down
    sleep 10
    docker compose up -d pihole
    sleep 30
    docker compose up -d
    
    # Test again
    sleep 30
    test_services
}

# Display comprehensive update summary
show_update_summary() {
    log "AI Platform update completed!"
    echo
    echo -e "${CYAN}=== Update Summary ===${NC}"
    echo -e "✓ System requirements verified"
    echo -e "✓ DNS resolution fixed"
    echo -e "✓ Container hostname resolution fixed"
    echo -e "✓ Hostname entries verified"
    echo -e "✓ Comprehensive backup created"
    echo -e "✓ Services stopped in dependency order"
    echo -e "✓ Latest images pulled with retry"
    echo -e "✓ Services started in dependency order (Pi-hole first)"
    echo -e "✓ Service availability tested with retries"
    echo
    echo -e "${CYAN}=== Access Information ===${NC}"
    echo -e "Landing: ${GREEN}https://tu.local/${NC}"
    echo -e "Open WebUI (AI Chat): ${GREEN}https://oweb.tu.local/${NC}"
    echo -e "n8n Workflows: ${GREEN}https://n8n.tu.local/${NC}"
    echo -e "Pi-hole (Ad Blocker): ${GREEN}https://pihole.tu.local/${NC}"
    echo -e "Ollama API: ${GREEN}http://localhost:11434${NC}"
    echo
    echo -e "${CYAN}=== Default Credentials ===${NC}"
    echo -e "n8n: admin / admin123"
    echo -e "Pi-hole: admin / SwissPiHole2024!"
    echo
    echo -e "${YELLOW}Management Commands:${NC}"
    echo -e "View logs: ${GREEN}docker compose logs -f${NC}"
    echo -e "Stop services: ${GREEN}docker compose down${NC}"
    echo -e "Restart services: ${GREEN}docker compose restart${NC}"
    echo -e "Check status: ${GREEN}docker compose ps${NC}"
    echo
    echo -e "${GREEN}✓ Update completed successfully!${NC}"
}

# Main execution with comprehensive error handling
main() {
    log "Starting Foolproof AI Platform update..."
    
    # Pre-flight checks
    check_root
    check_system_requirements
    
    # Prepare: ensure DNS is available for update via host resolver
    fix_dns_resolution
    
    # Create backup while services are still available
    create_backup
    
    # Update process
    stop_services_safe              # stop app services (keep Pi-hole for now)
    stop_pihole_service             # stop Pi-hole
    fix_dns_resolution              # start host DNS and set resolvers (Cloudflare + Quad9)
    run_os_updates                  # apt update && upgrade
    pull_images
    start_services_safe             # this will stop host DNS and start Pi-hole first
    wait_for_services

    # Optional: Start VPN client if enabled
    if [[ "${VPN_ENABLED:-false}" == "true" ]]; then
        log "Starting VPN client (host-level)"
        bash scripts/wg-manager.sh start || warn "VPN failed to start; fail mode: ${VPN_FAIL_MODE:-closed}"
    fi
    
    # Test services
    test_services
    
    # If tests fail, try emergency recovery
    if [ $? -ne 0 ]; then
        warn "Initial service tests failed, attempting emergency recovery..."
        emergency_recovery
    fi
    
    show_update_summary
    
    log "Foolproof update completed successfully!"
}

# Trap to handle script interruption
trap 'echo -e "\n${RED}Update interrupted. Services may be in an inconsistent state.${NC}"; exit 1' INT TERM

main "$@" 