#!/bin/bash

# Simple and reliable sync script for Open WebUI to MinIO
# This script uses direct file operations

echo "Starting file sync from Open WebUI to MinIO bucket..."

# Check if Open WebUI is running
if ! docker ps | grep -q ai_openwebui; then
    echo "Error: Open WebUI container is not running"
    exit 1
fi

# Check if MinIO is running
if ! docker ps | grep -q ai_minio; then
    echo "Error: MinIO container is not running"
    exit 1
fi

# Create a temporary directory for file operations
TEMP_DIR="/tmp/openwebui-sync-$$"
mkdir -p "$TEMP_DIR"

echo "Extracting files from Open WebUI volume..."

# Extract files from the Docker volume to temporary directory
docker run --rm -v docker_openwebui_files:/source -v "$TEMP_DIR":/dest alpine:latest sh -c "
    cp -r /source/* /dest/ 2>/dev/null || echo 'No files to copy'
    ls -la /dest/
"

# Check if we have files to sync
if [ ! "$(ls -A $TEMP_DIR)" ]; then
    echo "No files found in Open WebUI volume"
    rm -rf "$TEMP_DIR"
    exit 0
fi

echo "Syncing files to MinIO bucket..."

# Copy each file to MinIO container and then to bucket
for file in "$TEMP_DIR"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "Syncing $filename to MinIO bucket..."
        
        # Copy file to MinIO container
        docker cp "$file" ai_minio:/tmp/
        
        # Upload to MinIO bucket
        docker exec ai_minio mc cp "/tmp/$filename" local/openwebui-files/
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully synced $filename"
        else
            echo "✗ Failed to sync $filename"
        fi
        
        # Clean up temporary file in MinIO container
        docker exec ai_minio rm -f "/tmp/$filename"
    fi
done

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "Sync completed."
echo "Check MinIO bucket: docker exec ai_minio mc ls local/openwebui-files/"
