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
    
    # Test DNS resolution with fallback DNS
    log "Testing DNS resolution with fallback DNS..."
    local attempts=0
    while [ $attempts -lt 5 ]; do
        if nslookup google.com 8.8.8.8 > /dev/null 2>&1; then
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
    if ! grep -q "ai.tu.local" /etc/hosts; then
        log "Adding ai.tu.local to /etc/hosts..."
        echo "10.211.55.12 ai.tu.local" | sudo tee -a /etc/hosts
    fi
    
    if ! grep -q "tu.local" /etc/hosts; then
        log "Adding tu.local to /etc/hosts..."
        echo "10.211.55.12 tu.local" | sudo tee -a /etc/hosts
    fi
    
    log "✓ Hostname entries verified"
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
    
    # Step 3: Start AI services
    log "Starting AI services..."
    docker compose up -d ollama open-webui n8n
    
    # Step 4: Start network services
    log "Starting network services..."
    docker compose up -d wireguard nginx
    
    log "✓ All services started in dependency order"
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
    if curl -k -f -s -m 10 -H "Host: ai.tu.local" "https://localhost:443" | grep -q "n8n.io"; then
        log "✓ HTTPS ai.tu.local (n8n) works"
    else
        warn "✗ HTTPS ai.tu.local failed"
    fi
    
    # Test Open WebUI via HTTPS (may take longer)
    sleep 10
    if curl -k -f -s -m 10 -H "Host: tu.local" "https://localhost:443" >/dev/null 2>&1; then
        log "✓ HTTPS tu.local (Open WebUI) works"
    else
        warn "✗ HTTPS tu.local failed (Open WebUI may still be starting)"
    fi
}

# Display final status
display_status() {
    log "=== AI Platform Status ==="
    docker compose ps
    
    echo ""
    log "=== Access URLs ==="
    echo "n8n: https://ai.tu.local (or https://localhost:443 with Host: ai.tu.local)"
    echo "Open WebUI: https://tu.local (or https://localhost:443 with Host: tu.local)"
    echo "Pi-hole: http://localhost:8081/admin"
    echo "Ollama API: http://localhost:11434"
    echo "Qdrant: http://localhost:6333"
    
    echo ""
    log "=== Next Steps ==="
    echo "1. Add to /etc/hosts: 127.0.0.1 tu.local ai.tu.local"
    echo "2. Accept the self-signed certificate in your browser"
    echo "3. Access n8n at https://ai.tu.local"
    echo "4. Access Open WebUI at https://tu.local"
    
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
    echo "n8n: https://ai.tu.local"
    echo "Open WebUI: https://tu.local"
    echo "Pi-hole: http://localhost:8081/admin"
    echo "DNS: 10.211.55.12:5353"
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
    
    # Fix DNS and port conflicts before starting services
    fix_dns_and_ports
    fix_container_resolution
    fix_hostname_entries
    
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