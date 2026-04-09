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
readonly UPDATE_STATUS_FILE="/tmp/tu-vm-update-status.json"

#
# Service configuration
#
# Tier 1: expected to run for "core" platform usage (energy-friendly defaults)
# Tier 2: on-demand services (do NOT auto-start; controlled via dashboard or tu-vm.sh)
#
readonly TIER1_SERVICES=(
    "postgres"
    "redis"
    "open-webui"
    "pihole"
    "nginx"
    "helper_index"
)

readonly TIER2_SERVICES=(
    "ollama"
    "n8n"
    "minio"
    "qdrant"
    "tika"
    "tika_minio_processor"
    "affine"
    "mcp_gateway"
    "langgraph_supervisor"
    "browserless"
)

# Services that require local image builds (and therefore reliable external DNS)
readonly BUILD_REQUIRED_SERVICES=(
    "mcp_gateway"
    "langgraph_supervisor"
    "tika_minio_processor"
)

# Official upstream services that are safe to auto-update from registries.
# Custom/self-managed services are intentionally excluded.
readonly OFFICIAL_UPDATE_SERVICES=(
    "postgres"
    "redis"
    "qdrant"
    "ollama"
    "open-webui"
    "n8n"
    "tika"
    "minio"
    "affine"
    "affine_migration"
    "affine_postgres"
    "affine_redis"
    "browserless"
    "pihole"
    "nginx"
)

# Service -> upstream tag + compose image base used to refresh pinned digests during update.
readonly OFFICIAL_UPDATE_IMAGE_PAIRS=(
    "postgres|postgres:15-alpine|postgres"
    "redis|redis:alpine|redis"
    "qdrant|qdrant/qdrant:latest|qdrant/qdrant"
    "ollama|ollama/ollama:latest|ollama/ollama"
    "open-webui|ghcr.io/open-webui/open-webui:latest|ghcr.io/open-webui/open-webui"
    "n8n|n8nio/n8n:latest|n8nio/n8n"
    "tika|apache/tika:latest|apache/tika"
    "minio|minio/minio:latest|minio/minio"
    "affine|ghcr.io/toeverything/affine:stable|ghcr.io/toeverything/affine"
    "affine_postgres|pgvector/pgvector:pg16|pgvector/pgvector"
    "browserless|ghcr.io/browserless/chromium:v2.46.0|ghcr.io/browserless/chromium"
    "pihole|pihole/pihole:latest|pihole/pihole"
    "nginx|nginx:alpine|nginx"
)

# Map compose service name -> container_name (when it doesn't follow ai_<service>)
declare -A SERVICE_CONTAINER=(
    ["postgres"]="ai_postgres"
    ["redis"]="ai_redis"
    ["qdrant"]="ai_qdrant"
    ["ollama"]="ai_ollama"
    ["open-webui"]="ai_openwebui"
    ["n8n"]="ai_n8n"
    ["pihole"]="ai_pihole"
    ["nginx"]="ai_nginx"
    ["helper_index"]="ai_helper_index"
    ["tika"]="ai_tika"
    ["minio"]="ai_minio"
    ["tika_minio_processor"]="tika_minio_processor"
    ["affine"]="ai_affine"
    ["mcp_gateway"]="ai_mcp_gateway"
    ["langgraph_supervisor"]="ai_langgraph_supervisor"
    ["browserless"]="ai_browserless"
)

# =============================================================================
# ACCESS CONTROL (IP ALLOWLIST)
# =============================================================================

readonly NGINX_ALLOWLIST_FILE="nginx/dynamic/control_allowlist.conf"

reload_nginx() {
    # Reload nginx config/includes without full restart
    docker kill -s HUP ai_nginx >/dev/null 2>&1 || true
}

whitelist_list() {
    if [[ ! -f "$NGINX_ALLOWLIST_FILE" ]]; then
        echo "Allowlist file not found: $NGINX_ALLOWLIST_FILE"
        return 1
    fi
    echo "Allowed IPs:"
    python3 - <<'PY' "$NGINX_ALLOWLIST_FILE"
import sys
from pathlib import Path
import ipaddress

p = Path(sys.argv[1])
for line in p.read_text().splitlines():
    line = line.strip()
    if not line.startswith("allow "):
        continue
    raw = line[len("allow "):].strip().rstrip(";").strip()
    try:
        print(str(ipaddress.ip_address(raw)))
    except Exception:
        continue
PY
}

whitelist_add() {
    local ip="${1:-}"
    if [[ -z "$ip" ]]; then
        # Auto-detect the local IP of the machine running this script (best effort).
        # This is useful when running tu-vm.sh from a local terminal (non-SSH workflows).
        ip=$(get_vm_ip 2>/dev/null || true)
        if [[ -z "$ip" ]]; then
            # Fallback to public IP if local detection fails
            ip=$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)
        fi
        if [[ -z "$ip" ]]; then
            error "No IP provided and could not auto-detect IP. Usage: ./$SCRIPT_NAME whitelist-add <ip>"
        fi
        info "Auto-detected IP: $ip"
    fi

    # Validate IP
    if ! python3 - <<PY >/dev/null 2>&1
import ipaddress,sys
ipaddress.ip_address("$ip")
PY
    then
        error "Invalid IP: $ip"
    fi

    mkdir -p "$(dirname "$NGINX_ALLOWLIST_FILE")"
    python3 - <<'PY' "$NGINX_ALLOWLIST_FILE" "$ip"
import sys
from pathlib import Path
import ipaddress

path = Path(sys.argv[1])
ip = str(ipaddress.ip_address(sys.argv[2]))

existing = []
if path.exists():
    for ln in path.read_text().splitlines():
        ln = ln.strip()
        if ln.startswith("allow "):
            raw = ln[len("allow "):].strip().rstrip(";").strip()
            try:
                existing.append(str(ipaddress.ip_address(raw)))
            except Exception:
                pass

if ip not in existing:
    existing.append(ip)

header = [
    "# Dynamic allowlist for sensitive endpoints (e.g. /control/, /whitelist/*)",
    "# Managed by helper_index and/or tu-vm.sh.",
    "#",
    "# Format:",
    "#   allow 192.0.2.10;",
    "#   allow 2001:db8::1;",
    "#   deny all;",
    "",
]
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text("\n".join(header + [f\"allow {x};\" for x in existing] + [\"deny all;\", \"\"]))
tmp.replace(path)
PY

    reload_nginx
    info "Added to allowlist: $ip (nginx reloaded)"
}

whitelist_remove() {
    local ip="${1:-}"
    if [[ -z "$ip" ]]; then
        error "Usage: ./$SCRIPT_NAME whitelist-remove <ip>"
    fi
    if [[ ! -f "$NGINX_ALLOWLIST_FILE" ]]; then
        error "Allowlist file not found: $NGINX_ALLOWLIST_FILE"
    fi
    python3 - <<'PY' "$NGINX_ALLOWLIST_FILE" "$ip"
import sys
from pathlib import Path
import ipaddress

path = Path(sys.argv[1])
target = str(ipaddress.ip_address(sys.argv[2]))

existing = []
if path.exists():
    for ln in path.read_text().splitlines():
        ln = ln.strip()
        if ln.startswith("allow "):
            raw = ln[len("allow "):].strip().rstrip(";").strip()
            try:
                ip = str(ipaddress.ip_address(raw))
            except Exception:
                continue
            if ip != target:
                existing.append(ip)

header = [
    "# Dynamic allowlist for sensitive endpoints (e.g. /control/, /whitelist/*)",
    "# Managed by helper_index and/or tu-vm.sh.",
    "#",
    "# Format:",
    "#   allow 192.0.2.10;",
    "#   allow 2001:db8::1;",
    "#   deny all;",
    "",
]
tmp = path.with_suffix(path.suffix + ".tmp")
tmp.write_text("\n".join(header + [f\"allow {x};\" for x in existing] + [\"deny all;\", \"\"]))
tmp.replace(path)
PY
    reload_nginx
    info "Removed from allowlist: $ip (nginx reloaded)"
}

# =============================================================================
# LOGGING SYSTEM
# =============================================================================

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Default log level (accepts either numeric or named values, e.g. "INFO")
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}
case "${LOG_LEVEL^^}" in
    DEBUG) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
    INFO)  LOG_LEVEL=$LOG_LEVEL_INFO ;;
    WARN|WARNING) LOG_LEVEL=$LOG_LEVEL_WARN ;;
    ERROR) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
esac

# Fallback to INFO if LOG_LEVEL is not numeric after normalization
if ! [[ "$LOG_LEVEL" =~ ^[0-9]+$ ]]; then
    LOG_LEVEL=$LOG_LEVEL_INFO
fi

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

is_build_required_service() {
    local svc="${1:-}"
    for s in "${BUILD_REQUIRED_SERVICES[@]}"; do
        if [[ "$s" == "$svc" ]]; then
            return 0
        fi
    done
    return 1
}

print_dns_recovery_hint() {
    cat <<EOF
Run this host-level DNS fix:
  sudo rm -f /etc/resolv.conf && printf "nameserver ${HOST_IP:-127.0.0.1}\nnameserver 1.1.1.1\nnameserver 9.9.9.9\n" | sudo tee /etc/resolv.conf >/dev/null && sudo systemctl restart docker
EOF
}

check_dns_resolver_guard() {
    local strict="${1:-false}" # true|false

    if [[ "${TU_VM_SKIP_DNS_GUARD:-0}" == "1" ]]; then
        warn "DNS guard skipped (TU_VM_SKIP_DNS_GUARD=1)"
        return 0
    fi

    local issue=0
    local resolv="/etc/resolv.conf"
    local nameserver_count=0
    local linked_target=""
    local resolved_target=""

    if [[ -L "$resolv" ]]; then
        linked_target="$(readlink "$resolv" 2>/dev/null || true)"
        resolved_target="$(readlink -f "$resolv" 2>/dev/null || true)"
        if [[ -z "$resolved_target" ]] || [[ ! -e "$resolved_target" ]]; then
            issue=1
            warn "DNS resolver appears broken: $resolv -> ${linked_target:-<unknown>} (missing target)"
        fi
    elif [[ ! -f "$resolv" ]]; then
        issue=1
        warn "DNS resolver file not found: $resolv"
    fi

    if [[ -f "$resolv" ]]; then
        nameserver_count="$(awk '/^nameserver[[:space:]]+/ {c++} END {print c+0}' "$resolv" 2>/dev/null || echo 0)"
        if [[ "$nameserver_count" -eq 0 ]]; then
            issue=1
            warn "No nameserver entries found in $resolv"
        fi
    fi

    # Probe public DNS resolution used during image pulls/builds.
    if ! getent hosts registry-1.docker.io >/dev/null 2>&1; then
        issue=1
        warn "Cannot resolve registry-1.docker.io from host resolver"
    fi

    if [[ "$issue" -eq 1 ]]; then
        warn "Image pulls/builds may fail due to DNS resolver issues."
        print_dns_recovery_hint
        if [[ "$strict" == "true" ]]; then
            error "Aborting due to DNS resolver guard (set TU_VM_SKIP_DNS_GUARD=1 to bypass)."
        fi
    fi

    return 0
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
            if grep -q "CHANGE_ME_SECURE_PASSWORD\|CHANGE_ME_32_CHAR_ENCRYPTION_KEY\|CHANGE_ME_SECRET_KEY\|affine_change_me\|CHANGE_ME_MCP_TOKEN" "$ENV_FILE"; then
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
        if grep -q "CHANGE_ME_SECURE_PASSWORD\|CHANGE_ME_32_CHAR_ENCRYPTION_KEY\|CHANGE_ME_SECRET_KEY\|affine_change_me\|CHANGE_ME_MCP_TOKEN" "$ENV_FILE"; then
            warn "Default passwords detected in existing .env file!"
            warn "Run './tu-vm.sh generate-secrets' to generate secure passwords."
        fi
    fi

    # Ensure AFFiNE DB password exists because compose requires it explicitly.
    # This keeps credentials out of git while still enabling one-command startup.
    if ! grep -qE "^AFFINE_DB_PASSWORD=" "$ENV_FILE"; then
        # Clean malformed inline leftovers (e.g. appended without a preceding newline)
        # before writing a proper standalone key.
        sed -i 's/AFFINE_DB_PASSWORD=[^[:space:]]*//g' "$ENV_FILE"

        local affine_pass
        affine_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        printf "\nAFFINE_DB_PASSWORD=%s\n" "$affine_pass" >> "$ENV_FILE"
        chmod 600 "$ENV_FILE" 2>/dev/null || true
        info "Added missing AFFINE_DB_PASSWORD to .env"
    fi
}

# Ensure HOST_IP is configured in .env (auto-detect if missing or placeholder)
ensure_host_ip_configured() {
    if [[ ! -f "$ENV_FILE" ]]; then
        return 0  # Will be created by check_env_file
    fi
    
    # Check if HOST_IP is missing, empty, or looks like a placeholder
    local current_ip=""
    if grep -qE "^HOST_IP=" "$ENV_FILE"; then
        current_ip=$(grep -E "^HOST_IP=" "$ENV_FILE" | sed -E 's/^HOST_IP=//' | tr -d '"' | tr -d "'")
    fi
    
    # If missing, empty, or looks like placeholder (10.211.55.x is likely a VM default)
    if [[ -z "$current_ip" ]] || [[ "$current_ip" == "10.211.55.12" ]] || [[ "$current_ip" == "CHANGE_ME"* ]]; then
        local detected_ip
        detected_ip=$(get_vm_ip 2>/dev/null || echo "")
        
        if [[ -n "$detected_ip" ]]; then
            info "Auto-detecting HOST_IP: $detected_ip"
            if grep -qE "^HOST_IP=" "$ENV_FILE"; then
                # Update existing HOST_IP
                sed -i "s|^HOST_IP=.*|HOST_IP=$detected_ip|" "$ENV_FILE"
            else
                # Add HOST_IP if missing
                echo "HOST_IP=$detected_ip" >> "$ENV_FILE"
            fi
            info "✅ HOST_IP configured in .env"
        else
            warn "Could not auto-detect HOST_IP. Please set HOST_IP in .env manually."
        fi
    fi
}

# Ensure nginx dynamic allowlist file exists for startup
ensure_nginx_allowlist_file() {
    mkdir -p "$(dirname "$NGINX_ALLOWLIST_FILE")" 2>/dev/null || true
    if [[ ! -w "$(dirname "$NGINX_ALLOWLIST_FILE")" ]]; then
        warn "Nginx dynamic dir is not writable: $(dirname "$NGINX_ALLOWLIST_FILE")"
        warn "Skipping allowlist bootstrap from script (container may manage this file)."
        return 0
    fi
    if [[ ! -f "$NGINX_ALLOWLIST_FILE" ]]; then
        cat > "$NGINX_ALLOWLIST_FILE" <<'EOF'
# Dynamic allowlist for sensitive endpoints (e.g. /control/, /whitelist/*)
# Managed by helper_index and/or tu-vm.sh.
#
# Format:
#   allow 192.0.2.10;
#   allow 2001:db8::1;
#   deny all;

deny all;
EOF
        info "Created nginx allowlist file: $NGINX_ALLOWLIST_FILE"
    fi
}

# Resolve MinIO root password for scripts that run outside compose env substitution.
# Precedence:
# 1) exported MINIO_ROOT_PASSWORD
# 2) .env MINIO_ROOT_PASSWORD
# 3) default fallback (minio123456)
resolve_minio_password() {
    local pass="${MINIO_ROOT_PASSWORD:-}"
    if [[ -z "$pass" && -f "$ENV_FILE" ]]; then
        # shellcheck disable=SC1090
        . "$ENV_FILE" 2>/dev/null || true
        pass="${MINIO_ROOT_PASSWORD:-}"
    fi
    echo "${pass:-minio123456}"
}

# Get VM IP address
get_vm_ip() {
    ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1
}

# Get Tailscale IPv4 address (if tailscale is installed and connected)
get_tailscale_ip() {
    if command -v tailscale >/dev/null 2>&1; then
        tailscale ip -4 2>/dev/null | head -1
    else
        echo ""
    fi
}

# Ensure TAILSCALE_IP is configured in .env when available
ensure_tailscale_ip_configured() {
    if [[ ! -f "$ENV_FILE" ]]; then
        return 0
    fi

    local ts_detected
    ts_detected="$(get_tailscale_ip)"
    if [[ -z "$ts_detected" ]]; then
        return 0
    fi

    local current_ts=""
    if grep -qE "^TAILSCALE_IP=" "$ENV_FILE"; then
        current_ts=$(grep -E "^TAILSCALE_IP=" "$ENV_FILE" | sed -E 's/^TAILSCALE_IP=//' | tr -d '"' | tr -d "'")
    fi

    if [[ -z "$current_ts" ]] || [[ "$current_ts" == "CHANGE_ME"* ]]; then
        if grep -qE "^TAILSCALE_IP=" "$ENV_FILE"; then
            sed -i "s|^TAILSCALE_IP=.*|TAILSCALE_IP=$ts_detected|" "$ENV_FILE"
        else
            echo "TAILSCALE_IP=$ts_detected" >> "$ENV_FILE"
        fi
        info "✅ TAILSCALE_IP configured in .env: $ts_detected"
    fi
}

# Resolve which IP should be published for *.tu.lan records in Pi-hole.
# Priority:
# 1) DNS_RECORD_IP in .env (manual override)
# 2) HOST_IP in .env (keeps LAN clients working by default)
# 3) TAILSCALE_IP in .env
# 4) detected VM IP
resolve_dns_record_ip() {
    local dns_record_ip="${DNS_RECORD_IP:-}"
    local tailscale_ip="${TAILSCALE_IP:-}"
    local host_ip="${HOST_IP:-}"

    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck disable=SC1090
        . "$ENV_FILE" 2>/dev/null || true
        dns_record_ip="${DNS_RECORD_IP:-$dns_record_ip}"
        tailscale_ip="${TAILSCALE_IP:-$tailscale_ip}"
        host_ip="${HOST_IP:-$host_ip}"
    fi

    if [[ -n "$dns_record_ip" ]]; then
        echo "$dns_record_ip"
    elif [[ -n "$host_ip" ]]; then
        echo "$host_ip"
    elif [[ -n "$tailscale_ip" ]]; then
        echo "$tailscale_ip"
    else
        get_vm_ip
    fi
}

# Sync Pi-hole local DNS records for the tu.lan service domain.
sync_pihole_dns_records() {
    local dns_file="pihole/01-custom.conf"
    local target_ip
    target_ip="$(resolve_dns_record_ip)"
    local host_line="$target_ip tu.lan oweb.tu.lan n8n.tu.lan affine.tu.lan pihole.tu.lan ollama.tu.lan minio.tu.lan api.minio.tu.lan"

    if [[ -z "$target_ip" ]]; then
        warn "Could not determine DNS target IP. Skipping Pi-hole DNS record sync."
        return 0
    fi

    info "Syncing Pi-hole DNS records (*.tu.lan -> $target_ip)..."
    cat > "$dns_file" <<EOF
# Pi-hole Custom DNS Configuration
# Managed by tu-vm.sh sync_pihole_dns_records()

# Upstream resolvers
server=127.0.0.11
server=1.1.1.1
server=1.0.0.1

# Local service domains (Nginx reverse proxy)
address=/tu.lan/$target_ip
address=/oweb.tu.lan/$target_ip
address=/n8n.tu.lan/$target_ip
address=/affine.tu.lan/$target_ip
address=/pihole.tu.lan/$target_ip
address=/ollama.tu.lan/$target_ip
address=/minio.tu.lan/$target_ip
address=/api.minio.tu.lan/$target_ip
EOF

    # If Pi-hole is running, also write v6 local hosts records and reload DNS.
    if docker ps --format "{{.Names}}" | grep -q "^ai_pihole$"; then
        docker exec ai_pihole sh -lc "mkdir -p /etc/pihole/hosts && printf '%s\n' \"$host_line\" > /etc/pihole/hosts/tu-lan.hosts" >/dev/null 2>&1 || true
        docker exec ai_pihole pihole reloaddns >/dev/null 2>&1 || true
    fi

    info "✅ Pi-hole DNS records synced"
}

# Generate self-signed SSL certificates for Nginx
generate_ssl_certificates() {
    local ssl_dir="ssl"
    local cert_file="$ssl_dir/nginx.crt"
    local key_file="$ssl_dir/nginx.key"
    
    # Check if certificates already exist
    if [[ -f "$cert_file" && -f "$key_file" ]]; then
        debug "SSL certificates already exist"
        return 0
    fi
    
    info "Generating self-signed SSL certificates for HTTPS..."
    
    # Create ssl directory if it doesn't exist
    mkdir -p "$ssl_dir"
    
    # Get domain from .env or use default
    local domain="${DOMAIN:-tu.lan}"
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck disable=SC1090
        . "$ENV_FILE" 2>/dev/null || true
        domain="${DOMAIN:-tu.lan}"
    fi
    
    # Generate self-signed certificate valid for 10 years
    # Include common domain variations for SAN
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout "$key_file" \
        -out "$cert_file" \
        -subj "/C=CH/ST=Zurich/L=Zurich/O=TechUties/CN=$domain" \
        -addext "subjectAltName=DNS:$domain,DNS:*.$domain,DNS:localhost,IP:127.0.0.1" \
        2>/dev/null || {
        error "Failed to generate SSL certificates. Please ensure openssl is installed: sudo apt-get install openssl"
        return 1
    }
    
    # Set secure permissions
    chmod 600 "$key_file"
    chmod 644 "$cert_file"
    
    info "✅ SSL certificates generated successfully"
    warn "⚠️  Using self-signed certificates. Browsers will show security warnings."
    info "   For production, consider using Let's Encrypt or other CA-signed certificates."
}

# Get network prefix
get_network_prefix() {
    local vm_ip=$(get_vm_ip)
    echo "$vm_ip" | cut -d. -f1-3
}

# Get container name for a compose service
get_container_name() {
    local service="$1"
    local c="${SERVICE_CONTAINER[$service]:-}"
    if [[ -n "$c" ]]; then
        echo "$c"
    else
        # Fallback: best effort
        echo "ai_${service}"
    fi
}

# Check if a service container is healthy (or at least running when no healthcheck exists)
check_service_health() {
    local service="$1"
    local container
    container="$(get_container_name "$service")"

    debug "Checking health of $service ($container)..."

    # Does the container exist?
    if ! docker inspect "$container" >/dev/null 2>&1; then
        debug "$service container not found: $container"
        return 1
    fi

    local running
    running="$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null || echo "false")"
    if [[ "$running" != "true" ]]; then
        return 1
    fi

    local health
    health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null || echo "none")"
    case "$health" in
        healthy|none)
            return 0
            ;;
        starting)
            return 1
            ;;
        unhealthy)
            return 1
            ;;
        *)
            # Unknown health state; treat running as "ok" to avoid false negatives.
            return 0
            ;;
    esac
}

# Wait for a list of services to be ready
wait_for_services() {
    info "Waiting for services to be ready..."
    local -a services=("$@")
    local -a failed_services=()

    for service in "${services[@]}"; do
        local max_attempts=10
        local attempt=1
        while [[ $attempt -le $max_attempts ]]; do
            if check_service_health "$service"; then
                break
            fi
            debug "Attempt $attempt/$max_attempts: $service not ready yet..."
            sleep 2
            ((attempt++))
        done
        if [[ $attempt -gt $max_attempts ]]; then
            failed_services+=("$service")
        fi
    done

    if [[ ${#failed_services[@]} -gt 0 ]]; then
        warn "Some services failed health checks: ${failed_services[*]}"
        return 1
    fi

    info "All required services are ready!"
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
    echo -e "${WHITE}Setup & Initialization:${NC}"
    echo "  setup                    Complete first-time setup (env, SSL, secrets)"
    echo ""
    echo -e "${WHITE}Basic Commands:${NC}"
    echo "  start                    Start in portable mode (default, low resource)"
    echo "  start --portable         Start portable mode (Tier 1 only, low resource)"
    echo "  start --server           Start server mode (Tier 1 + Tier 2, full stack)"
    echo "  start --tier1            Alias for --portable"
    echo "  start --all              Alias for --server"
    echo -e "${WHITE}Runtime Modes:${NC}"
    echo "  portable                 Shortcut for: start --portable"
    echo "  server                   Shortcut for: start --server"
    echo ""

    echo "  stop                     Stop all services"
    echo "  restart                  Restart all services"
    echo "  status                   Show service status"
    echo "  logs [service]           Show service logs"
    echo "  access                   Show access URLs and information"
    echo ""
    echo -e "${WHITE}On-demand Service Control:${NC}"
    echo "  start-service <service>  Start a single service (Tier 2 recommended)"
    echo "  stop-service <service>   Stop a single service (Tier 2 recommended)"
    echo ""
    echo -e "${WHITE}Access Control:${NC}"
    echo "  secure                   Enable secure access (recommended)"
    echo "  public                   Enable public access (less secure)"
    echo "  lock                     Block all external access"
    echo ""
    echo -e "${WHITE}Maintenance:${NC}"
    echo "  update                   Unified safe update (recommended)"
    echo "  update-check             Check available updates (no changes)"
    echo "  update-rollback          Roll back to latest safe-update snapshot"
    echo "  legacy-update            Run legacy in-script update flow"
    echo "  test-update              Test update process (dry run)"
    echo "  backup [name]            Create backup with optional name"
    echo "  restore <file>           Restore from backup file"
    echo "  cleanup                  Clean up old backups and logs"
    echo "  sync-dns                 Sync Pi-hole DNS for *.tu.lan"
    echo "  setup-minio             Setup MinIO buckets for existing installation"
    echo ""
    echo -e "${WHITE}Security:${NC}"
    echo "  generate-secrets         Generate secure passwords and keys"
    echo "  validate-security        Validate security configuration"
    echo ""
    echo -e "${WHITE}IP Allowlist:${NC}"
    echo "  whitelist-list           List allowed IPs for control endpoints"
    echo "  whitelist-add [ip]       Add an IP (auto-detect public IP if omitted)"
    echo "  whitelist-remove <ip>    Remove an IP"
    echo ""
    echo -e "${WHITE}Diagnostics:${NC}"
    echo "  health                   Check service health"
    echo "  test                     Test all service endpoints"
    echo "  diagnose                 Run comprehensive diagnostics"
    echo "  check-openwebui-audio    Validate Open WebUI STT config consistency"
    echo "  fix-openwebui-audio      Repair Open WebUI STT config (DB + Redis)"
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
    echo "  ./$SCRIPT_NAME start                    # Start in portable mode (default)"
    echo "  ./$SCRIPT_NAME start --portable         # Start in portable mode"
    echo "  ./$SCRIPT_NAME start --server           # Start in server mode"
    echo "  ./$SCRIPT_NAME start --all              # Alias for server mode"
    echo "  ./$SCRIPT_NAME start-service ollama     # Start Tier 2 Ollama"
    echo "  ./$SCRIPT_NAME stop-service ollama      # Stop Tier 2 Ollama"
    echo "  ./$SCRIPT_NAME status                   # Check service status"
    echo "  ./$SCRIPT_NAME access                   # Show access URLs"
    echo "  ./$SCRIPT_NAME secure                   # Enable secure access"
    echo "  ./$SCRIPT_NAME backup my-backup         # Create named backup"
    echo "  ./$SCRIPT_NAME restore backup.tar.gz    # Restore from backup"
    echo "  ./$SCRIPT_NAME logs nginx               # Show nginx logs"
    echo "  ./$SCRIPT_NAME pdf-status               # Check PDF processing"
    echo "  ./$SCRIPT_NAME health                   # Check service health"
    echo "  ./$SCRIPT_NAME update-check             # Check what can be updated"
    echo "  ./$SCRIPT_NAME update                   # Apply safe update flow"
    echo "  ./$SCRIPT_NAME update-rollback          # Roll back latest update"
    echo "  ./$SCRIPT_NAME check-openwebui-audio    # Validate Open WebUI audio STT config"
    echo "  ./$SCRIPT_NAME fix-openwebui-audio      # Repair Open WebUI audio STT config"
    echo "  ./$SCRIPT_NAME version                  # Show version info"
}

# Complete first-time setup
setup_platform() {
    info "Running first-time setup for $PROJECT_NAME..."
    
    check_docker
    check_docker_compose
    
    # Step 1: Create .env if missing
    check_env_file
    
    # Step 2: Auto-detect HOST_IP
    ensure_host_ip_configured

    # Step 3: Auto-detect Tailscale IP when available
    ensure_tailscale_ip_configured
    
    # Step 4: Generate secrets if using defaults
    if grep -q "CHANGE_ME\|ai_password_2024\|redis_password_2024\|minio123456\|admin123\|affine_change_me" "$ENV_FILE" 2>/dev/null; then
        info "Generating secure passwords and keys..."
        generate_secrets
    else
        info "Using existing secure credentials"
    fi
    
    # Step 5: Ensure nginx dynamic allowlist exists
    ensure_nginx_allowlist_file

    # Step 6: Sync Pi-hole DNS records for *.tu.lan
    sync_pihole_dns_records

    # Step 7: Generate SSL certificates
    generate_ssl_certificates
    
    info "✅ Setup complete! You can now run: ./$SCRIPT_NAME start"
    echo ""
    show_access_info
}

start_single_service() {
    local svc="${1:-}"
    if [[ -z "$svc" ]]; then
        error "Usage: ./$SCRIPT_NAME start-service <service>"
    fi
    local compose_cmd
    compose_cmd=$(get_docker_compose_cmd)
    if is_build_required_service "$svc"; then
        check_dns_resolver_guard true
    else
        check_dns_resolver_guard false
    fi
    info "Starting service: $svc"
    $compose_cmd up -d "$svc"
}

stop_single_service() {
    local svc="${1:-}"
    if [[ -z "$svc" ]]; then
        error "Usage: ./$SCRIPT_NAME stop-service <service>"
    fi
    local compose_cmd
    compose_cmd=$(get_docker_compose_cmd)
    info "Stopping service: $svc"
    $compose_cmd stop "$svc"
}

# Start services
start_services() {
    local default_mode
    default_mode="$(resolve_env_value TU_VM_DEFAULT_MODE portable)"
    default_mode="${default_mode,,}"

    local mode="portable"
    case "$default_mode" in
        server|all) mode="server" ;;
        portable|tier1|"") mode="portable" ;;
        *)
            warn "Invalid TU_VM_DEFAULT_MODE='$default_mode' in $ENV_FILE; falling back to portable"
            mode="portable"
            ;;
    esac

    case "${1:-}" in
        --server|server|--all) mode="server"; shift ;;
        --portable|portable|--tier1) mode="portable"; shift ;;
        "") ;;
        *)
            error "Unknown start mode: ${1:-}"
            echo "Usage: ./$SCRIPT_NAME start [--portable|--server]"
            ;;
    esac

    if [[ "$mode" == "server" ]]; then
        info "Starting $PROJECT_NAME services in SERVER mode (full stack)..."
    else
        info "Starting $PROJECT_NAME services in PORTABLE mode (low-resource core)..."
    fi

    check_docker
    check_docker_compose
    check_dns_resolver_guard false
    check_env_file
    ensure_nginx_allowlist_file
    
    # Auto-detect and update HOST_IP in .env if needed
    ensure_host_ip_configured
    # Auto-detect Tailscale IP when available
    ensure_tailscale_ip_configured
    # Keep Pi-hole records aligned with current IP strategy
    sync_pihole_dns_records
    
    # Generate SSL certificates if missing (required for nginx)
    generate_ssl_certificates
    
    local compose_cmd=$(get_docker_compose_cmd)

    if [[ "$mode" == "server" ]]; then
        # Start everything (Tier 2 services will be started as well)
        $compose_cmd up -d
    else
        # Start only Tier 1 services, and ensure Tier 2 containers exist but remain stopped
        $compose_cmd up -d "${TIER1_SERVICES[@]}"
        $compose_cmd up -d --no-start "${TIER2_SERVICES[@]}" >/dev/null 2>&1 || true
    fi

    # Wait for required services to be ready
    if wait_for_services "${TIER1_SERVICES[@]}"; then
        info "Tier 1 services are ready!"
        # Re-sync now that Pi-hole is running so local hosts entries are applied live.
        sync_pihole_dns_records
        
        # Note: Tier 2 services (Qdrant, Tika, MinIO, etc.) can be started on-demand via dashboard
        
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

    local minio_pass
    minio_pass="$(resolve_minio_password)"
    
    # Wait for MinIO to be ready (probe via mc container; MinIO server image often lacks mc)
    info "Waiting for MinIO to be ready..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker run --rm --network docker_ai_network minio/mc \
            sh -c "mc alias set local http://ai_minio:9000 admin '${minio_pass}' >/dev/null && mc ls local >/dev/null" \
            >/dev/null 2>&1; then
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        warn "MinIO is not ready, skipping bucket setup"
        return 0
    fi
    
    # Required buckets
    local buckets=(
        "tika-pipe"
        "n8n-workflows"
        "shared-documents"
        "thumbnails"
        "metadata"
        "processed-documents"
    )
    
    # Create buckets
    info "Creating required MinIO buckets..."
    for bucket in "${buckets[@]}"; do
        if docker run --rm --network docker_ai_network minio/mc \
            sh -c "mc alias set local http://ai_minio:9000 admin '${minio_pass}' >/dev/null && mc ls local/'$bucket' >/dev/null" \
            >/dev/null 2>&1; then
            info "Bucket $bucket already exists"
        else
            info "Creating bucket: $bucket"
            docker run --rm --network docker_ai_network minio/mc \
                sh -c "mc alias set local http://ai_minio:9000 admin '${minio_pass}' >/dev/null && mc mb local/'$bucket' >/dev/null" \
                >/dev/null 2>&1 || {
                warn "Failed to create bucket $bucket"
            }
        fi
    done
    
    # Create folder structure
    info "Creating folder structure..."
    docker run --rm --network docker_ai_network minio/mc sh -c "mc alias set local http://ai_minio:9000 admin '${minio_pass}' >/dev/null && mc cp /dev/null local/tika-pipe/.gitkeep >/dev/null 2>&1 || true"
    docker run --rm --network docker_ai_network minio/mc sh -c "mc alias set local http://ai_minio:9000 admin '${minio_pass}' >/dev/null && mc cp /dev/null local/n8n-workflows/inputs/.gitkeep >/dev/null 2>&1 || true"
    docker run --rm --network docker_ai_network minio/mc sh -c "mc alias set local http://ai_minio:9000 admin '${minio_pass}' >/dev/null && mc cp /dev/null local/n8n-workflows/outputs/.gitkeep >/dev/null 2>&1 || true"
    docker run --rm --network docker_ai_network minio/mc sh -c "mc alias set local http://ai_minio:9000 admin '${minio_pass}' >/dev/null && mc cp /dev/null local/shared-documents/company/.gitkeep >/dev/null 2>&1 || true"
    
    info "✅ MinIO buckets setup complete"
}

# Ensure rclone is installed and mount MinIO buckets to host for transparent S3 storage
mount_minio_storage() {
    # Only meaningful when MinIO is running (Tier 2 / on-demand)
    if ! docker ps --format "{{.Names}}" | grep -q "^ai_minio$"; then
        info "MinIO is not running; skipping rclone mount setup."
        return 0
    fi

    # rclone mount requires root privileges (fuse config, /etc/rclone, /mnt)
    if [[ $EUID -ne 0 ]]; then
        warn "MinIO mount setup requires root. Run: sudo ./$SCRIPT_NAME start-service minio"
        return 0
    fi

    # Resolve MinIO password from env/.env (used for rclone config)
    local minio_pass
    minio_pass="$(resolve_minio_password)"

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
secret_access_key = ${minio_pass}
endpoint = http://127.0.0.1:9000
region = us-east-1
EOF
        sudo chmod 600 "$rclone_conf"
    fi
    
    # Create mount points
    local base_mount="/mnt/minio"
    sudo mkdir -p "$base_mount/tika-pipe" "$base_mount/n8n" "$base_mount/shared"
    
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
    mount_minio_bucket "tika-pipe" "$base_mount/tika-pipe"
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
    echo -e "  ${WHITE}Tier 1 (required):${NC}"
    for service in "${TIER1_SERVICES[@]}"; do
        if check_service_health "$service" 2>/dev/null; then
            echo -e "    ${GREEN}${ICON_SUCCESS}${NC} $service"
        else
            echo -e "    ${RED}${ICON_ERROR}${NC} $service"
        fi
    done
    echo -e "  ${WHITE}Tier 2 (on-demand):${NC}"
    for service in "${TIER2_SERVICES[@]}"; do
        local container running
        container="$(get_container_name "$service")"
        running="$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null || echo "false")"
        if [[ "$running" == "true" ]]; then
            echo -e "    ${GREEN}${ICON_SUCCESS}${NC} $service (running)"
        else
            echo -e "    ${YELLOW}${ICON_WARNING}${NC} $service (stopped)"
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
    local tailscale_ip
    tailscale_ip="$(get_tailscale_ip)"
    
    echo -e "${WHITE}Access URLs:${NC}"
    echo "  Landing:       https://tu.lan (IP fallback: https://$vm_ip)"
    echo "  Open WebUI:    https://oweb.tu.lan"
    echo "  MCP Gateway:   https://oweb.tu.lan/api/mcp/"
    echo "  LangGraph API: https://oweb.tu.lan/api/langgraph/"
    echo "  n8n:           https://n8n.tu.lan"
    echo "  AFFiNE:        https://affine.tu.lan"
    echo "  Pi-hole:       https://pihole.tu.lan/admin"
    echo "  Ollama API:    https://ollama.tu.lan"
    echo "  MinIO Console: https://minio.tu.lan"
    echo "  MinIO API:     https://api.minio.tu.lan"
    if [[ -n "$tailscale_ip" ]]; then
        echo "  Tailscale IP:  https://$tailscale_ip"
    fi
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

    # Unified update entrypoint: prefer safe-update workflow.
    # Set TU_VM_USE_LEGACY_UPDATE=1 to force legacy in-script update logic.
    local safe_update_script="$SCRIPT_DIR/scripts/safe-update.sh"
    if [[ "${TU_VM_USE_LEGACY_UPDATE:-0}" != "1" ]] && [[ -x "$safe_update_script" ]]; then
        info "Using unified safe update workflow..."
        "$safe_update_script" --apply
        return $?
    fi
    warn "safe-update.sh not executable or legacy mode enabled; using legacy update logic."
    
    info "Updating $PROJECT_NAME..."
    
    # ============================================================================
    # PHASE 1: Preparation
    # ============================================================================
    
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
    
    # ============================================================================
    # PHASE 2: DNS Setup (before pulling images)
    # ============================================================================
    
    # Switch to system DNS before pulling images (Pi-hole might be down)
    info "🌐 Switching to system DNS for image pulls..."
    handle_pihole_dns_replacement "stop"
    
    # Verify internet connectivity
    info "Verifying internet connectivity..."
    if ! verify_dns_connectivity; then
        error "Internet connectivity verification failed. Cannot proceed with update."
        error "Please check your network connection and try again."
        exit 1
    fi
    success "Internet connectivity verified"
    
    # ============================================================================
    # PHASE 3: Pull Images and Detect Updates
    # ============================================================================
    
    local compose_cmd=$(get_docker_compose_cmd)
    
    # Pull latest official images and detect updated services.
    # Custom/self-managed services are excluded from auto update on purpose.
    info "Pulling latest official service images..."
    local pull_log_file="/tmp/tu-compose-pull.log"
    : > "$pull_log_file"
    local pull_cmd="$compose_cmd pull ${OFFICIAL_UPDATE_SERVICES[*]}"
    
    # Detect support for --progress flag
    if $compose_cmd pull --help 2>&1 | grep -q -- "--progress"; then
        pull_cmd="$compose_cmd pull --progress=plain"
    fi
    
    # Pull images with retry logic (always pulls latest for :latest, :alpine tags)
    set +e
    $pull_cmd 2>&1 | tee "$pull_log_file"
    local pull_ec=${PIPESTATUS[0]}
    if [[ $pull_ec -ne 0 ]]; then
        warn "compose pull failed with exit code $pull_ec. Retrying..."
        $compose_cmd pull "${OFFICIAL_UPDATE_SERVICES[@]}" 2>&1 | tee "$pull_log_file"
        pull_ec=${PIPESTATUS[0]}
        if [[ $pull_ec -ne 0 ]]; then
            error "Image pull failed (exit code $pull_ec). Aborting update."
            exit 1
        fi
    fi
    set -e

    # Refresh pinned image digests in compose so official services can actually move forward
    # even when docker-compose.yml uses tag@sha256 references.
    info "Refreshing pinned digests for official services..."
    local digest_changed_services=()
    for pair in "${OFFICIAL_UPDATE_IMAGE_PAIRS[@]}"; do
        local svc="${pair%%|*}"
        local rest="${pair#*|}"
        local img="${rest%%|*}"
        local compose_base="${pair##*|}"

        # Pull upstream tag explicitly (independent of pinned digest in compose)
        if ! docker pull "$img" >/dev/null 2>&1; then
            warn "Failed to pull upstream image for $svc ($img); keeping current pinned digest."
            continue
        fi

        local new_ref=""
        new_ref=$(docker image inspect "$img" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)
        if [[ -z "$new_ref" ]]; then
            continue
        fi

        # Replace only when digest differs; keep tag semantics stable.
        if ! grep -qF "$new_ref" "$DOCKER_COMPOSE_FILE"; then
            python3 - <<PY
import re
path = "$DOCKER_COMPOSE_FILE"
compose_base = "$compose_base"
new_ref = "$new_ref"
text = open(path, "r", encoding="utf-8").read()
# Match:
# - repo
# - repo:tag
# - repo@sha256:...
# - repo:tag@sha256:...
pattern = re.escape(compose_base) + r'(?::[^@\\s]+)?(?:@sha256:[a-f0-9]+)?'
new_text, n = re.subn(pattern, new_ref, text)
if n:
    open(path, "w", encoding="utf-8").write(new_text)
PY
            digest_changed_services+=("$svc")
            info "Pinned $svc -> $new_ref"
        fi
    done
    
    info "Skipping auto-rebuild of custom services (self-managed policy)."
    
    # Build list of all services for validation
    local -a all_services
    mapfile -t all_services < <($compose_cmd config --services)
    
    # Detect which services were updated
    local updated_services=()
    while IFS= read -r line; do
        if echo "$line" | grep -qE "\bPulled\b"; then
            local svc=""
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
    
    # Merge with services that changed due to digest refresh.
    if [[ ${#digest_changed_services[@]} -gt 0 ]]; then
        updated_services+=("${digest_changed_services[@]}")
    fi

    # De-duplicate services list
    if [[ ${#updated_services[@]} -gt 0 ]]; then
        mapfile -t updated_services < <(printf "%s\n" "${updated_services[@]}" | sort -u)
        info "Services with new images: ${updated_services[*]}"
    else
        info "All images are already up to date."
    fi
    
    # ============================================================================
    # PHASE 4: User Confirmation
    # ============================================================================
    
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
            read -p "No new images detected. Restart services anyway? [Y/n]: " -r choice2
            case "$choice2" in
                n|N) info "Update skipped (nothing to do)."; return 0 ;;
                *) update_choice="all" ;;
            esac
        fi
    fi
    
    # ============================================================================
    # PHASE 5: Stop Services
    # ============================================================================
    
    info "Stopping services for update..."
    $compose_cmd down
    
    # ============================================================================
    # PHASE 6: Restore Pi-hole DNS and Start Services
    # ============================================================================
    
    # Restore Pi-hole DNS before starting services
    info "🌐 Restoring Pi-hole DNS configuration..."
    handle_pihole_dns_replacement "start"
    
    # Start services in proper order
    info "Starting services with updated images..."
    
    if [[ "$update_choice" == "only" && ${#updated_services[@]} -gt 0 ]]; then
        # Start only updated services
        $compose_cmd up -d "${updated_services[@]}"
        
        # Always recreate on-demand services (n8n, ollama, minio) in stopped state
        # These have restart: "no" so they won't auto-start, but containers must exist
        info "Recreating on-demand service containers (will remain stopped)..."
        for ondemand_svc in n8n ollama minio; do
            # Only recreate if not already in updated_services
            if ! printf '%s\n' "${updated_services[@]}" | grep -qx "$ondemand_svc"; then
                $compose_cmd up -d --no-start "$ondemand_svc" 2>/dev/null || warn "Failed to recreate $ondemand_svc container"
            fi
        done
    else
        # Start all services (on-demand services will be created but not started due to restart: "no")
        $compose_cmd up -d
    fi
    
    # ============================================================================
    # PHASE 7: Wait for Services and Verify
    # ============================================================================
    
    info "Waiting for services to be ready..."
    if wait_for_services; then
        info "All services started successfully after update!"
        
        # Verify data retention
        info "Verifying data retention..."
        if verify_data_retention; then
            write_update_notification_entry \
                false \
                "Update completed successfully" \
                "All required services are running and data volumes are accessible."
        else
            write_update_notification_entry \
                false \
                "Update completed with warnings" \
                "Services started, but data-retention checks reported warnings. Review tu-vm.log for details."
        fi
        
        # Show update summary
        show_update_summary
        
        show_access_info
    else
        warn "Some services may not be fully ready yet."
        info "Check status with: ./$SCRIPT_NAME status"
        write_update_notification_entry \
            true \
            "Update may be incomplete" \
            "Some services were not ready after update. Run './$SCRIPT_NAME status' and inspect logs."
    fi
    
    # ============================================================================
    # PHASE 8: Cleanup (at the end, after everything is verified)
    # ============================================================================
    
    info "Performing post-update Docker cleanup..."
    perform_docker_cleanup
    
    # ============================================================================
    # PHASE 9: Summary
    # ============================================================================
    
    info "Update completed successfully!"
    info "Backup created: $backup_name"
}

update_check() {
    local safe_update_script="$SCRIPT_DIR/scripts/safe-update.sh"
    if [[ -x "$safe_update_script" ]]; then
        "$safe_update_script" --check
    else
        error "Missing executable: $safe_update_script"
    fi
}

update_rollback() {
    check_root "update-rollback"
    local safe_update_script="$SCRIPT_DIR/scripts/safe-update.sh"
    if [[ -x "$safe_update_script" ]]; then
        "$safe_update_script" --rollback
    else
        error "Missing executable: $safe_update_script"
    fi
}

# Write status for dashboard/announcement system immediately after update.
write_update_notification_entry() {
    local updates_available="$1"
    local message="$2"
    local details="$3"
    local status_file_target="$UPDATE_STATUS_FILE"

    if { [ -e "$UPDATE_STATUS_FILE" ] && [ ! -w "$UPDATE_STATUS_FILE" ]; } || { [ ! -e "$UPDATE_STATUS_FILE" ] && [ ! -w "$(dirname "$UPDATE_STATUS_FILE")" ]; }; then
        status_file_target="/tmp/tu-vm-update-status-${USER}.json"
        warn "Update status file not writable at $UPDATE_STATUS_FILE, using fallback: $status_file_target"
    fi

    local message_json details_json
    message_json=$(printf "%s" "$message" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
    details_json=$(printf "%s" "$details" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

    cat > "$status_file_target" << EOF
{
    "updates_available": $updates_available,
    "last_check": "$(date -Iseconds)",
    "message": $message_json,
    "details": $details_json,
    "os_updates": 0,
    "docker_updates": 0,
    "docker_outdated": []
}
EOF
    info "Update notification entry written: $status_file_target"
}

# Verify data retention after update
verify_data_retention() {
    info "Verifying data retention..."
    
    local issues=()
    local volume_names
    volume_names="$(docker volume ls --format '{{.Name}}' 2>/dev/null || true)"
    has_volume() {
        local suffix="$1"
        if printf "%s\n" "$volume_names" | grep -Eq "(^|_)${suffix}$"; then
            return 0
        fi
        return 1
    }
    
    # Check Docker volumes
    if ! has_volume "postgres_data"; then
        issues+=("PostgreSQL data volume missing")
    fi
    
    if ! has_volume "redis_data"; then
        issues+=("Redis data volume missing")
    fi
    
    if ! has_volume "qdrant_data"; then
        issues+=("Qdrant data volume missing")
    fi
    
    if ! has_volume "ollama_data"; then
        issues+=("Ollama data volume missing")
    fi
    
    if ! has_volume "minio_data"; then
        issues+=("MinIO data volume missing")
    fi
    
    if ! has_volume "n8n_data"; then
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
        return 0
    else
        warn "⚠️  Data retention issues detected:"
        for issue in "${issues[@]}"; do
            warn "  - $issue"
        done
        warn "Consider restoring from backup if issues persist"
        return 1
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
                local port_in_use=1
                if command -v ss >/dev/null 2>&1; then
                    ss -tuln 2>/dev/null | grep -Eq "[:.]53[[:space:]]" || port_in_use=0
                elif command -v netstat >/dev/null 2>&1; then
                    netstat -tuln 2>/dev/null | grep -Eq "[:.]53[[:space:]]" || port_in_use=0
                elif command -v lsof >/dev/null 2>&1; then
                    lsof -nP -i :53 >/dev/null 2>&1 || port_in_use=0
                else
                    # If no socket inspection tool exists, do not fail update flow.
                    warn "No port inspection tool found (ss/netstat/lsof); skipping strict port 53 wait."
                    port_in_use=0
                fi

                if [ "$port_in_use" -eq 0 ]; then
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
        
        # PostgreSQL (non-interactive): pass password explicitly to avoid hanging on prompt
        local pg_password=""
        if [[ -f "$ENV_FILE" ]]; then
            pg_password="$(grep -E '^POSTGRES_PASSWORD=' "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
        fi
        if docker compose exec -T -e PGPASSWORD="$pg_password" postgres pg_isready -U ai_admin >/dev/null 2>&1; then
            docker compose exec -T -e PGPASSWORD="$pg_password" postgres pg_dump -U ai_admin ai_platform > "$backup_path/database.sql" 2>/dev/null || warn "Database backup failed"
        fi
        
        # Docker volumes
        # Note: compose-managed volumes are usually prefixed with the project name (default: docker_*)
        for volume in docker_postgres_data docker_redis_data docker_qdrant_data docker_n8n_data docker_pihole_data docker_minio_data docker_openwebui_files docker_nginx_logs docker_pihole_dnsmasq; do
            if docker volume inspect "$volume" >/dev/null 2>&1; then
                docker run --rm -v "$volume":/data -v "$(pwd)/$backup_path":/backup \
                    alpine tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null || warn "$volume backup failed"
            fi
        done
        
        # Service-specific data backups
        info "Backing up service-specific configurations..."
        
        # MinIO buckets list (via mc container; MinIO server image often lacks mc)
        if docker ps --format "{{.Names}}" | grep -q "^ai_minio$"; then
            info "Backing up MinIO buckets list..."
            docker run --rm --network docker_ai_network minio/mc \
                sh -c "mc alias set local http://ai_minio:9000 admin '${MINIO_ROOT_PASSWORD:-minio123456}' >/dev/null && mc ls local" \
                > "$backup_path/minio-buckets.txt" 2>/dev/null || warn "MinIO buckets list failed"
        fi
        
        # Pi-hole configuration
        if docker exec ai_pihole pihole -v >/dev/null 2>&1; then
            info "Backing up Pi-hole configuration..."
            docker exec ai_pihole pihole -a -t > "$backup_path/pihole-config.txt" 2>/dev/null || warn "Pi-hole config backup failed"
            docker exec ai_pihole pihole -g > "$backup_path/pihole-gravity.txt" 2>/dev/null || warn "Pi-hole gravity backup failed"
        fi
        
        # Open WebUI configuration (if accessible)
        # Use backend health endpoint (not /api/health which is served by the frontend SPA)
        if docker exec ai_openwebui curl -s -f http://localhost:8080/health/db >/dev/null 2>&1; then
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
    
    # Automatic backup rotation - keep only latest backup
    info "Managing backup rotation (keeping latest backup only)..."
    local backup_count=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
    
    if [[ $backup_count -gt 1 ]]; then
        local backups_to_remove=$((backup_count - 1))
        info "Removing $backups_to_remove old backup(s)..."
        
        # Sort by modification time (oldest first) and remove excess
        ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +2 | while read -r old_backup; do
            if [[ -f "$old_backup" ]]; then
                info "Removing old backup: $(basename "$old_backup")"
                rm -f "$old_backup"
            fi
        done
        
        info "✅ Backup rotation complete"
    else
        info "✅ No rotation needed (current backups: $backup_count)"
    fi

    # Remove leftover extracted backup directories from interrupted runs
    find "$BACKUP_DIR" -maxdepth 1 -type d \( -name 'backup_*' -o -name 'pre_update_*' -o -name 'restore_*' \) -exec rm -rf {} + 2>/dev/null || true
    
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
    
    # Clean up old backups (keep latest only)
    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_count=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
        if [[ $backup_count -gt 1 ]]; then
            local backups_to_remove=$((backup_count - 1))
            info "Removing $backups_to_remove old backup(s) (keeping latest only)..."
            
            # Sort by modification time (oldest first) and remove excess
            ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +2 | while read -r old_backup; do
                if [[ -f "$old_backup" ]]; then
                    info "Removing old backup: $(basename "$old_backup")"
                    rm -f "$old_backup"
                fi
            done
            
            info "✅ Backup cleanup complete"
        else
            info "✅ No backup cleanup needed (current backups: $backup_count)"
        fi

        # Remove leftover extracted backup directories from interrupted runs
        find "$BACKUP_DIR" -maxdepth 1 -type d \( -name 'backup_*' -o -name 'pre_update_*' -o -name 'restore_*' \) -exec rm -rf {} + 2>/dev/null || true
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
    
    # Show official services that are auto-updated
    echo -e "${YELLOW}🔄 Services to Update:${NC}"
    for service in "${OFFICIAL_UPDATE_SERVICES[@]}"; do
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
    local affine_db_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local webui_secret=$(openssl rand -hex 32)
    local jwt_secret=$(openssl rand -hex 32)
    local auth_secret=$(openssl rand -hex 32)
    local encryption_key=$(openssl rand -hex 32)
    local control_token=$(openssl rand -hex 32)
    local mcp_gateway_token=$(openssl rand -hex 32)
    
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
    sed -i "s/CHANGE_ME_CONTROL_TOKEN/$control_token/g" "$ENV_FILE"
    sed -i "s/CHANGE_ME_MCP_TOKEN/$mcp_gateway_token/g" "$ENV_FILE"

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
    set_env_var_if_default "MCP_GATEWAY_TOKEN" "" "$mcp_gateway_token"
    set_env_var_if_default "AFFINE_DB_PASSWORD" "affine_change_me" "$affine_db_pass"
    
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
    echo "  URL: https://oweb.tu.lan"
    echo "  Admin: First user to register"
    echo ""
    echo -e "${YELLOW}n8n Workflow Automation:${NC}"
    echo "  URL: https://n8n.tu.lan"
    echo "  Username: admin"
    echo "  Password: $n8n_pass"
    echo ""
    echo -e "${YELLOW}MinIO Object Storage:${NC}"
    echo "  Console: https://minio.tu.lan"
    echo "  API: https://api.minio.tu.lan"
    echo "  Username: admin"
    echo "  Password: $minio_pass"
    echo ""
    echo -e "${YELLOW}Pi-hole DNS:${NC}"
    echo "  URL: https://pihole.tu.lan/admin"
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
    if docker ps --format "{{.Names}}" | grep -q "^ai_minio$"; then
        if docker run --rm --network docker_ai_network minio/mc \
            sh -c "mc alias set local http://ai_minio:9000 admin '${MINIO_ROOT_PASSWORD:-minio123456}' >/dev/null && mc ls local/tika-pipe/ >/dev/null" \
            >/dev/null 2>&1; then
            local file_count
            file_count=$(docker run --rm --network docker_ai_network minio/mc \
                sh -c "mc alias set local http://ai_minio:9000 admin '${MINIO_ROOT_PASSWORD:-minio123456}' >/dev/null && mc ls local/tika-pipe/ | wc -l" \
            ) || file_count="0"
            echo "  ✅ Bucket exists with $file_count files"
        else
            echo "  ❌ tika-pipe bucket not found"
        fi
    else
        echo "  ⚠️  MinIO is not running (bucket check skipped)"
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
    if ! docker ps --format "{{.Names}}" | grep -q "^ai_minio$"; then
        warn "MinIO is not running; start it first (dashboard or: docker compose up -d minio) then retry."
        return 1
    fi
    local key="test-$(date +%s).pdf"
    if docker run --rm --network docker_ai_network -v "$test_pdf":/test.pdf:ro minio/mc \
        sh -c "mc alias set local http://ai_minio:9000 admin '${MINIO_ROOT_PASSWORD:-minio123456}' >/dev/null && mc mb --ignore-existing local/tika-pipe >/dev/null && mc cp /test.pdf local/tika-pipe/'$key' >/dev/null"; then
        info "✅ Test PDF uploaded successfully as $key"
        info "⏳ Waiting for Tika processing (30 seconds)..."
        sleep 30
        
        # Check for processed file
        if docker run --rm --network docker_ai_network minio/mc \
            sh -c "mc alias set local http://ai_minio:9000 admin '${MINIO_ROOT_PASSWORD:-minio123456}' >/dev/null && mc ls local/tika-pipe/ | grep -q '\.txt'"; then
            info "✅ PDF processing likely successful - .txt output detected"
        else
            warn "⚠️  No .txt output detected yet - processing may still be running or failed"
        fi
    else
        error "❌ Failed to upload test PDF to MinIO"
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
    if docker ps --format "{{.Names}}" | grep -q "^ai_minio$"; then
        local minio_pass="${MINIO_ROOT_PASSWORD:-}"
        if [[ -z "$minio_pass" && -f "$ENV_FILE" ]]; then
            # shellcheck disable=SC1090
            . "$ENV_FILE" 2>/dev/null || true
            minio_pass="${MINIO_ROOT_PASSWORD:-}"
        fi
        minio_pass="${minio_pass:-minio123456}"
        docker run --rm --network docker_ai_network minio/mc \
            sh -c "mc alias set local http://ai_minio:9000 admin '$minio_pass' >/dev/null && mc rm --recursive --force local/tika-pipe/ >/dev/null 2>&1 || true" \
            >/dev/null 2>&1 || true
    else
        warn "MinIO is not running; bucket cleanup skipped"
    fi
    
    # Restart processor
    info "Restarting Tika-MinIO processor..."
    docker start tika_minio_processor 2>/dev/null || {
        info "Starting processor from docker-compose..."
        local compose_cmd
        compose_cmd=$(get_docker_compose_cmd)
        $compose_cmd up -d tika_minio_processor
    }
    
    info "✅ PDF processing pipeline reset complete"
}

# =============================================================================
# DIAGNOSTIC FUNCTIONS
# =============================================================================

resolve_env_value() {
    local key="$1"
    local default_value="${2:-}"
    local value="${!key:-}"

    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    fi

    if [[ -f "$ENV_FILE" ]]; then
        value=$(grep -E "^${key}=" "$ENV_FILE" | head -1 | sed -E "s/^${key}=//" | tr -d '"' | tr -d "'" || true)
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi

    echo "$default_value"
}

normalize_json_string_value() {
    local value="${1:-}"
    if [[ "$value" == \"*\" ]]; then
        value="${value#\"}"
        value="${value%\"}"
    fi
    echo "$value"
}

is_container_stuck() {
    local container="$1"
    if ! docker inspect "$container" >/dev/null 2>&1; then
        return 1
    fi

    local running pid exec_err
    running="$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null || echo "false")"
    pid="$(docker inspect -f '{{.State.Pid}}' "$container" 2>/dev/null || echo "0")"

    if [[ "$running" != "true" ]]; then
        return 1
    fi

    if [[ "$pid" == "0" ]]; then
        return 0
    fi

    exec_err="$(docker exec "$container" sh -c 'true' 2>&1 >/dev/null || true)"
    if [[ "$exec_err" == *"BaseFS of container"* ]] || [[ "$exec_err" == *"unexpectedly empty"* ]]; then
        return 0
    fi

    return 1
}

recover_openwebui_container() {
    info "Attempting Open WebUI stuck-container recovery..."

    if ! docker inspect ai_openwebui >/dev/null 2>&1; then
        error "Container ai_openwebui not found."
    fi

    local pid compose_cmd
    pid="$(docker inspect -f '{{.State.Pid}}' ai_openwebui 2>/dev/null || echo "0")"
    compose_cmd="$(get_docker_compose_cmd)"

    if [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$pid" -gt 0 ]]; then
        info "Attempting hard kill of host PID $pid via privileged helper..."
        docker run --rm --privileged --pid=host alpine sh -c "kill -9 $pid" >/dev/null 2>&1 || warn "PID kill helper failed (continuing)"
    fi

    if command -v sudo >/dev/null 2>&1; then
        if sudo -n true >/dev/null 2>&1; then
            info "Restarting Docker daemon to clear stale state..."
            sudo systemctl restart docker >/dev/null 2>&1 || warn "Docker daemon restart failed (continuing)"
            sleep 3
        else
            warn "sudo requires interactive password. If recovery fails, run: sudo systemctl restart docker"
        fi
    fi

    # Best-effort recreate. If old container cannot stop, compose may leave it untouched.
    $compose_cmd rm -f open-webui >/dev/null 2>&1 || true
    $compose_cmd up -d --force-recreate open-webui >/dev/null 2>&1 || true

    # If compose created a replacement container but the old one is still named ai_openwebui,
    # swap names so the healthy replacement becomes canonical.
    if is_container_stuck "ai_openwebui"; then
        local replacement
        replacement="$(docker ps -a --format '{{.Names}}' | awk '/_ai_openwebui$/ {print; exit}')"
        if [[ -n "$replacement" ]]; then
            local stuck_name="ai_openwebui_stuck_$(date +%s)"
            docker rename ai_openwebui "$stuck_name" >/dev/null 2>&1 || true
            docker rename "$replacement" ai_openwebui >/dev/null 2>&1 || true
            docker start ai_openwebui >/dev/null 2>&1 || true
        fi
    fi

    info "Recovery attempt complete. Current Open WebUI status:"
    $compose_cmd ps open-webui
}

check_openwebui_audio_config() {
    info "Checking Open WebUI audio transcription configuration..."

    local pg_user pg_db pg_pass redis_pass
    pg_user="$(resolve_env_value POSTGRES_USER ai_admin)"
    pg_db="$(resolve_env_value POSTGRES_DB ai_platform)"
    pg_pass="$(resolve_env_value POSTGRES_PASSWORD ai_password_2024)"
    redis_pass="$(resolve_env_value REDIS_PASSWORD redis_password_2024)"

    if ! docker inspect ai_postgres >/dev/null 2>&1; then
        warn "PostgreSQL container not found (ai_postgres)."
        return 1
    fi
    if ! docker inspect ai_redis >/dev/null 2>&1; then
        warn "Redis container not found (ai_redis)."
        return 1
    fi

    local db_row
    db_row="$(docker exec -e PGPASSWORD="$pg_pass" ai_postgres psql -U "$pg_user" -d "$pg_db" -At -F '|' -c "SELECT coalesce(data #>> '{audio,stt,engine}',''), coalesce(data #>> '{audio,stt,model}',''), coalesce(data #>> '{audio,stt,openai,api_base_url}',''), coalesce((data #> '{audio,stt,supported_content_types}')::text,'') FROM config WHERE id=1;" 2>/dev/null || true)"

    if [[ -z "$db_row" ]]; then
        warn "Could not read Open WebUI config row from PostgreSQL."
        return 1
    fi

    local db_engine db_model db_base_url db_types
    IFS='|' read -r db_engine db_model db_base_url db_types <<< "$db_row"

    local redis_values redis_engine redis_model redis_base_url redis_types
    mapfile -t redis_values < <(docker exec -e REDISCLI_AUTH="$redis_pass" ai_redis redis-cli --raw MGET open-webui:config:STT_ENGINE open-webui:config:STT_MODEL open-webui:config:STT_OPENAI_API_BASE_URL open-webui:config:STT_SUPPORTED_CONTENT_TYPES 2>/dev/null || true)

    redis_engine="${redis_values[0]:-}"
    redis_model="$(normalize_json_string_value "${redis_values[1]:-}")"
    redis_base_url="${redis_values[2]:-}"
    redis_types="${redis_values[3]:-}"

    echo ""
    echo -e "${WHITE}Open WebUI STT Config:${NC}"
    echo "  DB engine:        ${db_engine:-<empty>}"
    echo "  DB model:         ${db_model:-<empty>}"
    echo "  DB base URL:      ${db_base_url:-<empty>}"
    echo "  DB content types: ${db_types:-<empty>}"
    echo "  Redis engine:     ${redis_engine:-<empty>}"
    echo "  Redis model:      ${redis_model:-<empty>}"
    echo "  Redis base URL:   ${redis_base_url:-<empty>}"
    echo "  Redis types:      ${redis_types:-<empty>}"
    echo ""

    local issues=()
    if [[ "$db_engine" == "openai" && -z "$db_model" ]]; then
        issues+=("DB STT model is empty while STT engine is openai")
    fi
    if [[ "$redis_engine" == "openai" && -z "$redis_model" ]]; then
        issues+=("Redis STT model is empty while STT engine is openai")
    fi
    if [[ -n "$db_model" && -n "$redis_model" && "$db_model" != "$redis_model" ]]; then
        issues+=("DB/Redis STT model mismatch (${db_model} != ${redis_model})")
    fi
    if [[ "$db_types" == "[]" || "$db_types" == "[\"\"]" || -z "$db_types" ]]; then
        issues+=("DB STT supported content types are empty/invalid")
    fi
    if [[ "$redis_types" == "[]" || "$redis_types" == "[\"\"]" || -z "$redis_types" ]]; then
        issues+=("Redis STT supported content types are empty/invalid")
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        info "Open WebUI STT configuration looks consistent."
        return 0
    fi

    warn "Open WebUI STT configuration issues detected:"
    for issue in "${issues[@]}"; do
        warn "  - $issue"
    done
    warn "Run: ./$SCRIPT_NAME fix-openwebui-audio [model]"
    return 1
}

fix_openwebui_audio_config() {
    local desired_model="${1:-whisper-1}"
    local desired_types='["audio/*","video/webm"]'

    info "Repairing Open WebUI STT configuration (DB + Redis)..."
    info "Target STT engine=openai, model=${desired_model}"

    local pg_user pg_db pg_pass redis_pass
    pg_user="$(resolve_env_value POSTGRES_USER ai_admin)"
    pg_db="$(resolve_env_value POSTGRES_DB ai_platform)"
    pg_pass="$(resolve_env_value POSTGRES_PASSWORD ai_password_2024)"
    redis_pass="$(resolve_env_value REDIS_PASSWORD redis_password_2024)"

    docker exec -e PGPASSWORD="$pg_pass" ai_postgres psql -U "$pg_user" -d "$pg_db" -c "UPDATE config
SET data = jsonb_set(
            jsonb_set(
                jsonb_set(data::jsonb, '{audio,stt,engine}', '\"openai\"', true),
                '{audio,stt,model}', '\"${desired_model}\"', true
            ),
            '{audio,stt,supported_content_types}', '${desired_types}'::jsonb, true
          )::json
WHERE id = 1;" >/dev/null

    docker exec -e REDISCLI_AUTH="$redis_pass" ai_redis redis-cli --raw SET open-webui:config:STT_ENGINE "\"openai\"" >/dev/null
    docker exec -e REDISCLI_AUTH="$redis_pass" ai_redis redis-cli --raw SET open-webui:config:STT_MODEL "\"${desired_model}\"" >/dev/null
    docker exec -e REDISCLI_AUTH="$redis_pass" ai_redis redis-cli --raw SET open-webui:config:STT_SUPPORTED_CONTENT_TYPES "${desired_types}" >/dev/null

    info "Restarting Open WebUI to apply repaired config..."
    docker restart ai_openwebui >/dev/null
    sleep 6

    check_openwebui_audio_config
}

# Check service health
check_health() {
    info "Checking service health..."
    
    local failed_services=()
    local healthy_services=()
    local tier2_running=()
    local tier2_stopped=()

    for service in "${TIER1_SERVICES[@]}"; do
        if check_service_health "$service"; then
            healthy_services+=("$service")
        else
            failed_services+=("$service")
        fi
    done

    if printf '%s\n' "${failed_services[@]}" | grep -qx "open-webui"; then
        if is_container_stuck "ai_openwebui"; then
            warn "Detected stuck Open WebUI container (Docker BaseFS/exec failure pattern)."
            warn "Run: ./$SCRIPT_NAME recover-openwebui"
        fi
    fi

    for service in "${TIER2_SERVICES[@]}"; do
        local container running
        container="$(get_container_name "$service")"
        running="$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null || echo "false")"
        if [[ "$running" == "true" ]]; then
            tier2_running+=("$service")
        else
            tier2_stopped+=("$service")
        fi
    done
    
    echo ""
    echo -e "${WHITE}Health Summary:${NC}"
    echo "  Tier 1 healthy: ${#healthy_services[@]} services"
    echo "  Tier 1 failed:  ${#failed_services[@]} services"
    echo "  Tier 2 running: ${#tier2_running[@]} services"
    echo "  Tier 2 stopped: ${#tier2_stopped[@]} services"
    echo ""
    
    if [[ ${#healthy_services[@]} -gt 0 ]]; then
        echo -e "${GREEN}${ICON_SUCCESS}${NC} Tier 1 healthy services:"
        for service in "${healthy_services[@]}"; do
            echo "    - $service"
        done
        echo ""
    fi
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        echo -e "${RED}${ICON_ERROR}${NC} Tier 1 failed services:"
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

    local vm_ip
    local failed_tests=()
    local status_code=""
    vm_ip=$(get_vm_ip)

    # Test main landing page
    status_code="$(curl -k -s -o /dev/null -w '%{http_code}' -H "Host: tu.lan" "https://$vm_ip/")"
    if [[ "$status_code" =~ ^[23][0-9][0-9]$ ]]; then
        info "✓ Landing page accessible"
    else
        failed_tests+=("Landing page ($status_code)")
    fi

    # Test Open WebUI
    status_code="$(curl -k -s -o /dev/null -w '%{http_code}' -H "Host: oweb.tu.lan" "https://$vm_ip/")"
    if [[ "$status_code" =~ ^[23][0-9][0-9]$ ]]; then
        info "✓ Open WebUI accessible"
    else
        failed_tests+=("Open WebUI ($status_code)")
    fi

    # Test n8n
    status_code="$(curl -k -s -o /dev/null -w '%{http_code}' -H "Host: n8n.tu.lan" "https://$vm_ip/")"
    if [[ "$status_code" =~ ^[23][0-9][0-9]$ ]]; then
        info "✓ n8n accessible"
    else
        failed_tests+=("n8n ($status_code)")
    fi

    # Test AFFiNE
    status_code="$(curl -k -s -o /dev/null -w '%{http_code}' -H "Host: affine.tu.lan" "https://$vm_ip/")"
    if [[ "$status_code" =~ ^[23][0-9][0-9]$ ]]; then
        info "✓ AFFiNE accessible"
    else
        failed_tests+=("AFFiNE ($status_code)")
    fi

    # Test Pi-hole admin page (root "/" intentionally returns 403)
    status_code="$(curl -k -s -o /dev/null -w '%{http_code}' -H "Host: pihole.tu.lan" "https://$vm_ip/admin/")"
    if [[ "$status_code" =~ ^[23][0-9][0-9]$ ]]; then
        info "✓ Pi-hole accessible"
    else
        failed_tests+=("Pi-hole ($status_code)")
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

    # Open WebUI audio STT consistency
    if ! check_openwebui_audio_config; then
        warn "Open WebUI STT configuration needs repair."
    fi
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
                check_env_file
            fi
            
            # Execute command
            case "$1" in
                setup)
                    setup_platform
                    ;;
                start)
                    start_services "${2:-}"
                    ;;
                portable)
                    start_services --portable
                    ;;
                server)
                    start_services --server
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
                update-check)
                    update_check
                    ;;
                update-rollback)
                    update_rollback
                    ;;
                legacy-update)
                    TU_VM_USE_LEGACY_UPDATE=1 update_system
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
                sync-dns)
                    sync_pihole_dns_records
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
                check-openwebui-audio)
                    check_openwebui_audio_config
                    ;;
                fix-openwebui-audio)
                    fix_openwebui_audio_config "${2:-whisper-1}"
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
                whitelist-list)
                    whitelist_list
                    ;;
                whitelist-add)
                    whitelist_add "${2:-}"
                    ;;
                whitelist-remove)
                    whitelist_remove "${2:-}"
                    ;;
                start-service)
                    start_single_service "${2:-}"
                    ;;
                stop-service)
                    stop_single_service "${2:-}"
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