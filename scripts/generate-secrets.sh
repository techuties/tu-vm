#!/bin/bash
# =============================================================================
# TechUties AI Platform - Secret Generation Script
# =============================================================================
# Description: Generates secure passwords and keys for all services
# Usage: ./scripts/generate-secrets.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to generate random password
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to generate random key
generate_key() {
    local length=${1:-32}
    openssl rand -hex $length
}

# Function to check if .env exists
check_env_file() {
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
        cp env.example .env
        echo -e "${GREEN}✅ Created .env file from template${NC}"
    fi
}

# Function to check for default passwords
check_default_passwords() {
    local has_defaults=false
    
    if grep -q "CHANGE_ME_SECURE_PASSWORD" .env; then
        has_defaults=true
    fi
    
    if grep -q "CHANGE_ME_32_CHAR_ENCRYPTION_KEY" .env; then
        has_defaults=true
    fi
    
    if grep -q "CHANGE_ME_SECRET_KEY" .env; then
        has_defaults=true
    fi
    
    if [ "$has_defaults" = true ]; then
        echo -e "${RED}🚨 WARNING: Default passwords detected!${NC}"
        echo -e "${YELLOW}Generating secure passwords automatically...${NC}"
        return 0
    else
        echo -e "${GREEN}✅ All passwords appear to be customized${NC}"
        return 1
    fi
}

# Function to generate and update passwords
generate_secrets() {
    echo -e "${BLUE}🔐 Generating secure secrets...${NC}"
    
    # Generate passwords
    POSTGRES_PASSWORD=$(generate_password 32)
    REDIS_PASSWORD=$(generate_password 32)
    N8N_PASSWORD=$(generate_password 32)
    N8N_ENCRYPTION_KEY=$(generate_key 32)
    WEBUI_SECRET_KEY=$(generate_key 32)
    WEBUI_JWT_SECRET_KEY=$(generate_key 32)
    WEBUI_AUTH_SECRET=$(generate_key 32)
    MINIO_ROOT_PASSWORD=$(generate_password 32)
    PIHOLE_PASSWORD=$(generate_password 32)
    
    # Update .env file
    sed -i "s/CHANGE_ME_SECURE_PASSWORD/$POSTGRES_PASSWORD/g" .env
    sed -i "s/CHANGE_ME_SECURE_PASSWORD/$REDIS_PASSWORD/g" .env
    sed -i "s/CHANGE_ME_SECURE_PASSWORD/$N8N_PASSWORD/g" .env
    sed -i "s/CHANGE_ME_32_CHAR_ENCRYPTION_KEY/$N8N_ENCRYPTION_KEY/g" .env
    sed -i "s/CHANGE_ME_SECRET_KEY/$WEBUI_SECRET_KEY/g" .env
    sed -i "s/CHANGE_ME_JWT_SECRET_KEY/$WEBUI_JWT_SECRET_KEY/g" .env
    sed -i "s/CHANGE_ME_AUTH_SECRET/$WEBUI_AUTH_SECRET/g" .env
    sed -i "s/CHANGE_ME_SECURE_PASSWORD/$MINIO_ROOT_PASSWORD/g" .env
    sed -i "s/CHANGE_ME_SECURE_PASSWORD/$PIHOLE_PASSWORD/g" .env
    
    echo -e "${GREEN}✅ All secrets generated and updated${NC}"
}

# Function to display generated credentials
display_credentials() {
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
    echo "  Password: $N8N_PASSWORD"
    echo ""
    echo -e "${YELLOW}MinIO Object Storage:${NC}"
    echo "  Console: https://minio.tu.local"
    echo "  API: https://api.minio.tu.local"
    echo "  Username: admin"
    echo "  Password: $MINIO_ROOT_PASSWORD"
    echo ""
    echo -e "${YELLOW}Pi-hole DNS:${NC}"
    echo "  URL: https://pihole.tu.local/admin"
    echo "  Password: $PIHOLE_PASSWORD"
    echo ""
    echo -e "${YELLOW}Database Access:${NC}"
    echo "  Host: ai_postgres:5432"
    echo "  Database: ai_platform"
    echo "  Username: ai_admin"
    echo "  Password: $POSTGRES_PASSWORD"
    echo ""
    echo -e "${YELLOW}Redis Access:${NC}"
    echo "  Host: ai_redis:6379"
    echo "  Password: $REDIS_PASSWORD"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT SECURITY NOTES:${NC}"
    echo "• Store these credentials securely"
    echo "• Change passwords after first login"
    echo "• Never share these credentials"
    echo "• Consider using a password manager"
    echo ""
    echo -e "${GREEN}🎉 Installation complete! All services are ready.${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 TechUties AI Platform - Secret Generation${NC}"
    echo "=============================================="
    
    # Check if .env exists, create if not
    check_env_file
    
    # Check for default passwords
    if check_default_passwords; then
        # Generate new secrets
        generate_secrets
        
        # Display credentials
        display_credentials
        
        echo -e "${YELLOW}💾 Credentials saved to: .env${NC}"
        echo -e "${YELLOW}📝 Backup your .env file securely!${NC}"
    else
        echo -e "${GREEN}✅ Passwords already customized, skipping generation${NC}"
    fi
}

# Run main function
main "$@"
