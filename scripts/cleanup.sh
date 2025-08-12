#!/bin/bash

# AI Platform Cleanup Script
set -e

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] WARNING: $1${NC}"; }

log "Starting comprehensive cleanup..."

# Stop services
log "Stopping services..."
docker compose down 2>/dev/null || true
docker compose -f  down 2>/dev/null || true

# Prune Docker resources
log "Pruning Docker resources..."
docker container prune -f
docker image prune -a -f
docker volume prune -f
docker network prune -f
docker system prune -a -f --volumes
docker builder prune -a -f

# Clean up old files
log "Cleaning up old files..."
find . -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
find . -name "*.tmp" -type f -delete 2>/dev/null || true
find . -name "*.temp" -type f -delete 2>/dev/null || true

# Keep only last 3 backups
if [ -d "backups" ]; then
    find backups -name "*.tar.gz" -type f -printf "%T@ %p\n" | sort -n | head -n -3 | cut -d" " -f2- | xargs rm -f 2>/dev/null || true
fi

log "Cleanup completed!"
echo "Disk usage after cleanup:"
df -h .
echo "Docker usage after cleanup:"
docker system df
