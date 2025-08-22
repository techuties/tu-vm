#!/bin/bash

# AI Platform Foolproof Startup Script
# Handles all edge cases and ensures 100% reliable startup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize file logging
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/start_${TIMESTAMP}.log"
# Mirror all stdout/stderr to log file as well
exec > >(tee -a "$LOG_FILE") 2>&1

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Load .env early for functions that need HOST_IP and other vars
if [[ -f ./.env ]]; then set -a; . ./.env; set +a; fi

# Ensure VPN dependencies are installed when VPN is enabled
ensure_vpn_dependencies() {
    if [[ -f ./.env ]]; then set -a; . ./.env; set +a; fi
    local vpn_enabled="${VPN_ENABLED:-false}"
    local vpn_type="${VPN_TYPE:-wireguard}"

    if [[ "$vpn_enabled" != "true" ]]; then
        return 0
    fi

    if ! is_linux; then
        warn "Non-Linux host detected; skipping VPN dependency installation"
        return 0
    fi

    log "Ensuring VPN dependencies are installed (type: ${vpn_type})..."
    sudo apt-get update -y >/dev/null 2>&1 || true

    if [[ "$vpn_type" == "wireguard" ]]; then
        if ! command -v wg >/dev/null 2>&1 || ! command -v wg-quick >/dev/null 2>&1; then
            info "Installing wireguard and wireguard-tools..."
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard wireguard-tools >/dev/null 2>&1 || warn "Failed to install WireGuard tools; continuing"
        fi
        mkdir -p wg-configs
        if [[ -z $(find wg-configs -maxdepth 1 -type f -name '*.conf' 2>/dev/null) ]]; then
            warn "No WireGuard configs found in ./wg-configs. VPN will be skipped until configs are added."
        fi
    elif [[ "$vpn_type" == "openvpn" ]]; then
        if ! command -v openvpn >/dev/null 2>&1; then
            info "Installing openvpn..."
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn >/dev/null 2>&1 || warn "Failed to install OpenVPN; continuing"
        fi
        mkdir -p ovpn-configs
        if [[ -z $(find ovpn-configs -maxdepth 1 -type f -name '*.ovpn' 2>/dev/null) ]]; then
            warn "No OpenVPN profiles found in ./ovpn-configs. VPN will be skipped until profiles are added."
        fi
    else
        warn "Unknown VPN_TYPE: ${vpn_type}. Skipping VPN dependency installation."
    fi
}


# OS detection
HOST_OS="$(uname -s 2>/dev/null || echo Unknown)"
is_linux()   { [[ "$HOST_OS" == "Linux" ]]; }
is_darwin()  { [[ "$HOST_OS" == "Darwin" ]]; }
is_windows() { [[ "$HOST_OS" =~ MINGW|MSYS|CYGWIN ]]; }

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -f, --fresh         Fresh start (cleanup and reset database)"
    echo "  -r, --restart       Restart existing services (default)"
    echo "  -c, --cleanup       Cleanup only (stop and remove containers)"
    echo "  -s, --status        Show status only"
    echo ""
    echo "Examples:"
    echo "  $0                 # Normal restart (preserves data)"
    echo "  $0 --fresh         # Fresh start (clears all data)"
    echo "  $0 --status        # Show current status"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Fix DNS resolution and port conflicts
fix_dns_and_ports() {
    log "Checking and fixing DNS resolution and port conflicts..."
    
    # Check if port 53 is in use by systemd-resolved
    if sudo ss -tlnp | grep -q ":53.*systemd-resolve"; then
        log "Port 53 is in use by systemd-resolved. Stopping it to allow Pi-hole to start..."
        sudo systemctl stop systemd-resolved
        sleep 3
        
        # Kill any remaining systemd-resolve processes
        sudo pkill -f systemd-resolve || true
        sleep 2
    fi
    
    # Verify port 53 is free
    if sudo ss -tlnp | grep -q ":53"; then
        warn "Port 53 is still in use. Attempting to kill the process..."
        sudo pkill -f ":53" || true
        sleep 2
    fi
    
    # Test DNS resolution with independent resolvers (Cloudflare/Quad9)
    log "Testing DNS resolution with fallback DNS (Cloudflare/Quad9)..."
    local attempts=0
    while [ $attempts -lt 5 ]; do
        if nslookup example.com 1.1.1.1 > /dev/null 2>&1 || nslookup example.com 9.9.9.9 > /dev/null 2>&1; then
            log "✓ DNS resolution is working with fallback DNS"
            return 0
        fi
        sleep 2
        attempts=$((attempts + 1))
    done
    
    warn "DNS resolution may not be optimal, but continuing..."
}

# Fix container hostname resolution
fix_container_resolution() {
    log "Ensuring container hostname resolution is working..."
    
    # Update nginx configuration to use IP addresses
    if [ -f "nginx/conf.d/default.conf" ]; then
        log "Updating nginx configuration to use IP addresses..."
        
        # Backup original config if not already backed up
        if [ ! -f "nginx/conf.d/default.conf.backup" ]; then
            cp nginx/conf.d/default.conf nginx/conf.d/default.conf.backup
        fi
        
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
    local vm_ip="${HOST_IP:-}"
    if [[ -z "$vm_ip" ]]; then
        warn "HOST_IP not set in .env; skipping /etc/hosts edits"
    else
        if ! grep -q "tu.local" /etc/hosts; then
            log "Adding tu.local to /etc/hosts..."
            echo "$vm_ip tu.local" | sudo tee -a /etc/hosts
        fi
        if ! grep -q "n8n.tu.local" /etc/hosts; then
            log "Adding n8n.tu.local to /etc/hosts..."
            echo "$vm_ip n8n.tu.local" | sudo tee -a /etc/hosts
        fi
        if ! grep -q "oweb.tu.local" /etc/hosts; then
            log "Adding oweb.tu.local to /etc/hosts..."
            echo "$vm_ip oweb.tu.local" | sudo tee -a /etc/hosts
        fi
        if ! grep -q "pihole.tu.local" /etc/hosts; then
            log "Adding pihole.tu.local to /etc/hosts..."
            echo "$vm_ip pihole.tu.local" | sudo tee -a /etc/hosts
        fi
    fi
    
    log "✓ Hostname entries verified"
}

# Ensure n8n schema exists in Postgres (idempotent)
ensure_n8n_schema() {
    log "Ensuring Postgres schema for n8n exists..."
    # Create schema n8n if missing and grant to ai_admin
    if docker compose exec -T postgres psql -U ai_admin -d ai_platform -v ON_ERROR_STOP=1 -c "CREATE SCHEMA IF NOT EXISTS n8n AUTHORIZATION ai_admin; GRANT ALL ON SCHEMA n8n TO ai_admin;" >/dev/null 2>&1; then
        log "✓ Postgres schema 'n8n' is present"
    else
        warn "Could not ensure Postgres schema 'n8n' (will not block startup)"
    fi
}

# Generate SSL certificates if they don't exist
generate_ssl_certificates() {
    log "Checking SSL certificates..."
    
    if [[ ! -f "ssl/nginx.key" ]] || [[ ! -f "ssl/nginx.crt" ]]; then
        log "Generating self-signed SSL certificates..."
        mkdir -p ssl
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout ssl/nginx.key \
            -out ssl/nginx.crt \
            -subj "/C=CH/ST=Zurich/L=Zurich/O=AI Platform/CN=tu.local" \
            -addext "subjectAltName=DNS:tu.local,DNS:ai.tu.local,DNS:*.tu.local"
        
        chmod 600 ssl/nginx.key
        chmod 644 ssl/nginx.crt
        
        log "SSL certificates generated successfully"
    else
        log "SSL certificates already exist"
    fi
}

# Stop and clean all services
cleanup_services() {
    log "Stopping and cleaning all services..."
    docker compose down -v 2>/dev/null || true
    docker system prune -f 2>/dev/null || true
    log "Cleanup completed"
}

# Reset database completely
reset_database() {
    log "Resetting database..."
    docker compose up -d postgres
    sleep 10
    
    # Wait for PostgreSQL to be ready
    for i in {1..30}; do
        if docker compose exec postgres pg_isready -U ai_admin -d ai_platform >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
    
    # Drop and recreate database
    docker compose exec postgres psql -U ai_admin -d ai_platform -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" 2>/dev/null || true
    log "Database reset completed"
}

# Start all services in dependency order
start_services() {
    log "Starting all services in dependency order..."
    
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

    # Warn if Upload API key left as default
    if [[ -n "${UPLOAD_API_KEY:-}" && "${UPLOAD_API_KEY}" == "change-me-upload-key" ]]; then
        warn "UPLOAD_API_KEY is using the default value; set a strong key in .env"
    fi
    if [[ -n "${VPN_WEBHOOK_TOKEN:-}" && "${VPN_WEBHOOK_TOKEN}" == "change-me-strong-token" ]]; then
        warn "VPN_WEBHOOK_TOKEN is using the default value; set a strong token in .env"
    fi

    # Optional: Start VPN client if enabled
    if [[ "${VPN_ENABLED:-false}" == "true" ]]; then
        # Install dependencies on first run to make it fool-proof
        ensure_vpn_dependencies
        if [[ "${VPN_SYSTEMD_ENABLE:-false}" == "true" ]]; then
            log "Installing and enabling systemd unit for VPN manager..."
            bash scripts/vpn-manager.sh systemd-install || warn "Failed to install systemd unit"
            sudo systemctl enable --now tu-vpn.service || warn "Failed to start systemd VPN service"
            sudo systemctl status --no-pager tu-vpn.service | sed -n '1,5p' || true
        else
            log "Starting VPN client (host-level) via vpn-manager"
            bash scripts/vpn-manager.sh start || warn "VPN failed to start; fail mode: ${VPN_FAIL_MODE:-closed}"
        fi
    fi

    # Remove orphaned old WireGuard container if present
    if docker ps -a --format '{{.Names}}' | grep -q '^ai_wireguard$'; then
        warn "Removing orphaned ai_wireguard container (no longer used)"
        docker rm -f ai_wireguard >/dev/null 2>&1 || true
    fi

    # Proxy disabled/removed
}

# Restart existing services in dependency order (preserves data)
restart_services() {
    log "Restarting existing services in dependency order (preserving data)..."
    
    # Stop all services first
    docker compose down
    
    # Start services in dependency order
    start_services
}

# Check if services are running
check_services_running() {
    if docker compose ps --format json | grep -q '"State":"running"'; then
        return 0
    else
        return 1
    fi
}

# Check service health
check_service_health() {
    log "Checking service health..."
    
    # Check PostgreSQL
    if docker compose exec postgres pg_isready -U ai_admin -d ai_platform >/dev/null 2>&1; then
        log "✓ PostgreSQL is healthy"
    else
        warn "✗ PostgreSQL is not healthy"
    fi
    
    # Check Redis
    if docker compose exec redis redis-cli ping >/dev/null 2>&1; then
        log "✓ Redis is healthy"
    else
        warn "✗ Redis is not healthy"
    fi
    
    # Check n8n
    if curl -f -s -m 5 "http://localhost:5678" >/dev/null 2>&1; then
        log "✓ n8n is accessible"
    else
        warn "✗ n8n is not accessible"
    fi
    
    # Check Open WebUI (may take longer to start)
    sleep 30
    if curl -f -s -m 5 "http://localhost:8080" >/dev/null 2>&1; then
        log "✓ Open WebUI is accessible"
    else
        warn "✗ Open WebUI is not accessible (may still be starting)"
    fi
    
    # Check Nginx
    if docker compose exec nginx nginx -t >/dev/null 2>&1; then
        log "✓ Nginx configuration is valid"
    else
        warn "✗ Nginx configuration has issues"
    fi
}

# Test HTTPS endpoints
test_https_endpoints() {
    log "Testing HTTPS endpoints..."
    
    # Test HTTP to HTTPS redirect
    if curl -f -s -m 5 "http://localhost:80" | grep -q "301 Moved Permanently"; then
        log "✓ HTTP to HTTPS redirect works"
    else
        warn "✗ HTTP to HTTPS redirect failed"
    fi
    
    # Test n8n via HTTPS
    if curl -k -f -s -m 10 -H "Host: n8n.tu.local" "https://localhost:443/health" >/dev/null 2>&1; then
        log "✓ HTTPS n8n.tu.local works"
    else
        warn "✗ HTTPS n8n.tu.local failed"
    fi
    
    # Test Open WebUI via HTTPS (may take longer)
    sleep 10
    if curl -k -f -s -m 10 -H "Host: oweb.tu.local" "https://localhost:443/health" >/dev/null 2>&1; then
        log "✓ HTTPS oweb.tu.local works"
    else
        warn "✗ HTTPS oweb.tu.local failed (service may still be starting)"
    fi
}

# Display final status
display_status() {
    log "=== AI Platform Status ==="
    docker compose ps
    
    echo ""
    log "=== Access URLs ==="
    echo "Landing: https://tu.local (or https://localhost:443 with Host: tu.local)"
    echo "Open WebUI: https://oweb.tu.local (or https://localhost:443 with Host: oweb.tu.local)"
    echo "n8n: https://n8n.tu.local (or https://localhost:443 with Host: n8n.tu.local)"
    echo "Pi-hole Admin: https://pihole.tu.local (proxied via Nginx)"
    echo "Ollama API: https://ollama.tu.local"
    
    echo ""
    log "=== Next Steps ==="
    echo "1. Add to /etc/hosts: <VM_IP> tu.local oweb.tu.local n8n.tu.local pihole.tu.local ollama.tu.local"
    echo "2. Accept the self-signed certificate in your browser"
    echo "3. Access n8n at https://n8n.tu.local"
    echo "4. Access Open WebUI at https://oweb.tu.local"
    
    echo ""
    log "=== Troubleshooting ==="
    echo "If Open WebUI is not accessible, check logs with:"
    echo "docker compose logs open-webui"
    echo ""
    echo "If n8n is not accessible, check logs with:"
    echo "docker compose logs n8n"
}

# Show status only
show_status_only() {
    log "=== AI Platform Status ==="
    docker compose ps
    
    echo ""
    log "=== Service Health ==="
    check_service_health
    
    echo ""
    log "=== Access URLs ==="
    echo "Landing: https://tu.local"
    echo "Open WebUI: https://oweb.tu.local"
    echo "n8n: https://n8n.tu.local"
    echo "Pi-hole: https://pihole.tu.local"
}

# Main execution
main() {
    # Parse command line arguments
    FRESH_START=false
    CLEANUP_ONLY=false
    STATUS_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--fresh)
                FRESH_START=true
                shift
                ;;
            -r|--restart)
                FRESH_START=false
                shift
                ;;
            -c|--cleanup)
                CLEANUP_ONLY=true
                shift
                ;;
            -s|--status)
                STATUS_ONLY=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    log "Starting AI Platform Foolproof Startup..."
    
    check_root
    
    # Fix DNS and port conflicts before starting services (Linux only)
    if is_linux; then
        fix_dns_and_ports
        fix_container_resolution
        fix_hostname_entries
    else
        warn "Non-Linux host detected ($HOST_OS). Skipping host DNS adjustments."
        warn "If Pi-hole port 53 conflicts on your host, use the mac/win override file to avoid exposing 53."
        warn "Start command example: docker compose -f docker-compose.yml -f docker-compose.mac-win.yml up -d"
    fi
    
    generate_ssl_certificates
    
    if [[ "$STATUS_ONLY" == true ]]; then
        show_status_only
        exit 0
    fi
    
    if [[ "$CLEANUP_ONLY" == true ]]; then
        cleanup_services
        log "Cleanup completed. Run without --cleanup to start services."
        exit 0
    fi
    
    if [[ "$FRESH_START" == true ]]; then
        log "Performing fresh start (will clear all data)..."
        cleanup_services
        reset_database
        start_services
    else
        if check_services_running; then
            log "Services are running, performing restart..."
            restart_services
        else
            log "No services running, starting fresh..."
            start_services
        fi
    fi
    
    check_service_health
    test_https_endpoints
    display_status
    
    log "Foolproof startup completed!"
}

# Run main function
main "$@" 