#!/bin/bash

# AI Platform Mobile Setup Script
# Foolproof version: checks for port conflicts, required tools, and system resources
# Optimized for battery life, host security, and minimal resource usage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check for required tools
check_tools() {
    # Check for docker
    if ! command -v docker &>/dev/null; then
        error "docker is not installed. Please install it first."
    fi
    
    # Check for docker compose
    if ! docker compose version &>/dev/null; then
        error "docker compose is not available. Please install Docker Compose."
    fi
    
    # Check for openssl
    if ! command -v openssl &>/dev/null; then
        error "openssl is not installed. Please install it first."
    fi
    
    log "All required tools are installed."
}

# Check for port conflicts
check_ports() {
    declare -A ports
    ports=(
        [80]="Nginx (HTTP)"
        [443]="Nginx (HTTPS)"
        [5353]="Pi-hole (DNS)"
        [8081]="Pi-hole Web UI"
        [5678]="n8n"
        [6333]="Qdrant"
        [11434]="Ollama"
        [51820]="WireGuard VPN"
    )
    local conflict=0
    for port in "${!ports[@]}"; do
        if lsof -i :$port -sTCP:LISTEN -t &>/dev/null || ss -ltnup | grep -q ":$port "; then
            warn "Port $port (${ports[$port]}) is already in use!"
            conflict=1
        fi
    done
    if [ $conflict -eq 1 ]; then
        error "One or more required ports are in use. Please stop the conflicting services or change the port assignments in docker-compose.yml."
    else
        log "No port conflicts detected."
    fi
}

# Check system resources for mobile usage
check_mobile_requirements() {
    log "Checking mobile system requirements..."
    
    # Check available memory
    MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEMORY_GB=$((MEMORY_KB / 1024 / 1024))
    
    if [ $MEMORY_GB -lt 3 ]; then
        error "System has less than 3GB RAM. Mobile AI platform requires at least 3GB."
    elif [ $MEMORY_GB -lt 4 ]; then
        warn "System has ${MEMORY_GB}GB RAM. Performance may be limited with less than 4GB."
    fi
    
    # Check available disk space
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $DISK_SPACE -lt 10 ]; then
        error "Less than 10GB free disk space available. Please free up space."
    fi
    
    # Check if running in VM
    if grep -q "VMware\|VirtualBox\|QEMU" /sys/class/dmi/id/product_name 2>/dev/null; then
        warn "Running in VM - battery optimizations may be limited"
    fi
    
    log "Mobile system requirements check passed."
}

# Setup mobile environment
setup_mobile_environment() {
    log "Setting up mobile-optimized environment..."
    
    # Copy environment file if it doesn't exist
    if [ ! -f .env ]; then
        cp env.example .env
        log "Created .env file from template."
    fi
    
    # Create necessary directories
    mkdir -p ssl nginx/conf.d logs backups
    
    # Set proper permissions
    chmod 600 .env
    chmod 755 scripts/
    chmod 644 nginx/conf.d/*
    
    log "Environment setup completed."
}

# Setup SSL certificates
setup_ssl() {
    log "Setting up SSL certificates..."
    
    if [ -f "ssl/nginx.key" ] && [ -f "ssl/nginx.crt" ]; then
        log "SSL certificates already exist."
        return 0
    fi
    
    mkdir -p ssl
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/nginx.key \
        -out ssl/nginx.crt \
        -subj "/C=CH/ST=Zurich/L=Zurich/O=AI Platform/CN=tu.local" \
        -addext "subjectAltName=DNS:tu.local,DNS:ai.tu.local,DNS:*.tu.local"
    
    chmod 600 ssl/nginx.key
    chmod 644 ssl/nginx.crt
    
    log "SSL certificates created successfully."
}

# Setup hosts file
setup_hosts() {
    log "Setting up hosts file entry..."
    
    VM_IP=$(hostname -I | awk '{print $1}')
    
    if ! grep -q "tu.local" /etc/hosts; then
        echo "$VM_IP tu.local" | sudo tee -a /etc/hosts
        log "Added tu.local entry to /etc/hosts"
    else
        log "Hosts file entry already exists."
    fi
}

# Setup mobile firewall
setup_mobile_firewall() {
    log "Setting up mobile-optimized firewall..."
    
    sudo ufw --force reset
    
    # Allow essential services
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 5353/tcp
    sudo ufw allow 5353/udp
    sudo ufw allow 51820/udp
    
    # Allow local services only
    sudo ufw allow from 127.0.0.1 to any port 8081
    sudo ufw allow from 127.0.0.1 to any port 6333
    sudo ufw allow from 127.0.0.1 to any port 11434
    
    sudo ufw --force enable
    
    log "Mobile firewall configured."
}

# Start mobile services
start_mobile_services() {
    log "Starting services..."
    
    docker compose pull
    docker compose up -d
    
    sleep 60
    log "Services started."
}

# Setup mobile backup
setup_mobile_backup() {
    log "Setting up mobile backup system..."
    
    cat > scripts/mobile-backup.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="backups/mobile_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

source .env

docker compose exec -T postgres pg_dump -U ai_admin ai_platform > "$BACKUP_DIR/database.sql"

tar czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR" n8n_data ssl .env

rm -rf "$BACKUP_DIR"

echo "Mobile backup created: $BACKUP_DIR.tar.gz"
EOF
    
    chmod +x scripts/mobile-backup.sh
    log "Mobile backup system configured."
}

# Display access information
show_mobile_access_info() {
    log "Mobile AI Platform setup completed!"
    echo
    echo -e "${BLUE}=== Mobile Access Information ===${NC}"
    echo -e "Open WebUI (AI Chat): ${GREEN}https://tu.local/${NC}"
    echo -e "n8n Workflows: ${GREEN}https://ai.tu.local/${NC}"
    echo -e "Pi-hole (Ad Blocker): ${GREEN}http://tu.local:8080/${NC}"
    echo -e "Qdrant Vector DB: ${GREEN}http://tu.local:6333${NC}"
    echo
    echo -e "${BLUE}=== Mobile Security Features ===${NC}"
    echo -e "✓ DNS Ad Blocking (Pi-hole)"
    echo -e "✓ VPN Protection (WireGuard)"
    echo -e "✓ Firewall Protection"
    echo -e "✓ SSL Encryption"
    echo
    echo -e "${BLUE}=== Default Credentials ===${NC}"
    echo -e "n8n: admin / admin123"
    echo -e "Pi-hole: admin / SwissPiHole2024!"
    echo
    echo -e "${YELLOW}Mobile Optimizations:${NC}"
    echo -e "• Reduced resource usage for battery life"
    echo -e "• Minimal monitoring to save power"
    echo -e "• Local workflow development and testing"
    echo -e "• Host security with ad blocking and VPN"
}

# Main execution
main() {
    log "Starting Mobile AI Platform setup..."
    
    check_root
    check_tools
    check_ports
    check_mobile_requirements
    setup_mobile_environment
    setup_ssl
    setup_hosts
    setup_mobile_firewall
    start_mobile_services
    setup_mobile_backup
    show_mobile_access_info
    
    log "Mobile setup completed successfully!"
}

main "$@" 