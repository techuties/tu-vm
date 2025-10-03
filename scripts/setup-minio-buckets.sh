#!/bin/bash
# =============================================================================
# MinIO Bucket Setup Script
# =============================================================================
# Description: Creates required buckets for Open WebUI and n8n integration
# Usage: ./scripts/setup-minio-buckets.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# MinIO configuration
MINIO_ENDPOINT="http://ai_minio:9000"
MINIO_ACCESS_KEY="admin"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minio123456}"

# Required buckets
BUCKETS=(
    "openwebui-files"
    "n8n-workflows"
    "shared-documents"
    "processed-files"
    "thumbnails"
    "metadata"
)

# Function to create bucket
create_bucket() {
    local bucket_name="$1"
    
    echo -e "${BLUE}Creating bucket: $bucket_name${NC}"
    
    # Create bucket using MinIO client
    docker exec ai_minio mc mb "local/$bucket_name" 2>/dev/null || {
        echo -e "${YELLOW}Bucket $bucket_name might already exist${NC}"
    }
    
    # Set bucket policy for public read (if needed)
    docker exec ai_minio mc anonymous set public "local/$bucket_name" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Bucket $bucket_name created${NC}"
}

# Function to setup MinIO client
setup_mc() {
    echo -e "${BLUE}Setting up MinIO client...${NC}"
    
    # Configure MinIO client
    docker exec ai_minio mc alias set local "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" 2>/dev/null || {
        echo -e "${YELLOW}MinIO client might already be configured${NC}"
    }
    
    echo -e "${GREEN}✅ MinIO client configured${NC}"
}

# Function to test MinIO connection
test_connection() {
    echo -e "${BLUE}Testing MinIO connection...${NC}"
    
    if docker exec ai_minio mc ls local >/dev/null 2>&1; then
        echo -e "${GREEN}✅ MinIO connection successful${NC}"
        return 0
    else
        echo -e "${RED}❌ MinIO connection failed${NC}"
        return 1
    fi
}

# Function to create folder structure
create_folders() {
    local bucket_name="$1"
    
    echo -e "${BLUE}Creating folder structure for $bucket_name...${NC}"
    
    case "$bucket_name" in
        "openwebui-files")
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/uploads/.gitkeep" 2>/dev/null || true
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/processed/.gitkeep" 2>/dev/null || true
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/thumbnails/.gitkeep" 2>/dev/null || true
            ;;
        "n8n-workflows")
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/inputs/.gitkeep" 2>/dev/null || true
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/outputs/.gitkeep" 2>/dev/null || true
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/temp/.gitkeep" 2>/dev/null || true
            ;;
        "shared-documents")
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/company/.gitkeep" 2>/dev/null || true
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/templates/.gitkeep" 2>/dev/null || true
            docker exec ai_minio mc cp /dev/null "local/$bucket_name/archives/.gitkeep" 2>/dev/null || true
            ;;
    esac
    
    echo -e "${GREEN}✅ Folder structure created for $bucket_name${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 MinIO Bucket Setup${NC}"
    echo "=========================="
    
    # Check if MinIO is running
    if ! docker ps | grep -q ai_minio; then
        echo -e "${RED}❌ MinIO container is not running${NC}"
        echo -e "${YELLOW}Please start MinIO first: ./tu-vm.sh start${NC}"
        exit 1
    fi
    
    # Wait for MinIO to be ready
    echo -e "${BLUE}Waiting for MinIO to be ready...${NC}"
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
        echo -e "${RED}❌ MinIO is not ready after $max_attempts attempts${NC}"
        exit 1
    fi
    
    # Setup MinIO client
    setup_mc
    
    # Test connection
    if ! test_connection; then
        echo -e "${RED}❌ Cannot connect to MinIO${NC}"
        exit 1
    fi
    
    # Create buckets
    echo -e "${BLUE}Creating required buckets...${NC}"
    for bucket in "${BUCKETS[@]}"; do
        create_bucket "$bucket"
        create_folders "$bucket"
    done
    
    # Show bucket list
    echo -e "${BLUE}📋 Created Buckets:${NC}"
    docker exec ai_minio mc ls local
    
    echo ""
    echo -e "${GREEN}🎉 MinIO bucket setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Restart services: ./tu-vm.sh restart"
    echo "2. Access MinIO Console: https://minio.tu.local"
    echo "3. Configure Open WebUI and n8n integrations"
    echo "4. Test file uploads and processing"
}

# Run main function
main "$@"
