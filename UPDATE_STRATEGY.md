# AI Platform Foolproof Update Strategy

## Overview

This document explains the foolproof update strategy that prevents DNS and service dependency issues when updating the AI Platform.

## The Problem

The original update script had a **dependency order problem**:

1. **DNS Service Dependency**: All services depend on Pi-hole for DNS resolution
2. **Port 53 Conflict**: systemd-resolved and Pi-hole both try to use port 53
3. **Container Hostname Resolution**: Services can't resolve each other's hostnames without DNS
4. **Update Order**: Services were updated simultaneously, causing DNS failures

## The Solution

### Single Foolproof Update Script (`scripts/update.sh`)

**Use this script for all updates:**

```bash
./scripts/update.sh
```

**Key Features:**
- ✅ **Automatic DNS resolution fixes**
- ✅ **Dependency-aware startup order**
- ✅ **Comprehensive pre-flight checks**
- ✅ **Automatic backup creation**
- ✅ **Service health monitoring with retries**
- ✅ **Emergency recovery if services fail**
- ✅ **Graceful error handling**
- ✅ **System requirements verification**

## What the Script Does Automatically

### 1. Pre-Flight Checks
- Verifies system requirements (disk space, Docker, Docker Compose)
- Checks DNS resolution and fixes if needed
- Validates hostname entries in `/etc/hosts`
- Ensures systemd-resolved is running

### 2. Automatic Fixes
- **DNS Resolution**: Starts systemd-resolved and configures DNS properly
- **Container Resolution**: Updates nginx config to use IP addresses instead of hostnames
- **Hostname Entries**: Adds missing entries to `/etc/hosts`
- **Configuration Backup**: Creates timestamped backups of all config files

### 3. Safe Update Process
- **Backup Creation**: Comprehensive backup with database and config files
- **Service Shutdown**: Stops services in dependency order (DNS-dependent services first)
- **Image Updates**: Pulls latest images with retry logic
- **Service Startup**: Starts services in dependency order (Pi-hole first)
- **Health Verification**: Tests all services with retries

### 4. Emergency Recovery
- If services fail to start, automatically attempts recovery
- Re-fixes DNS issues
- Restarts services in correct order
- Re-tests service health

## Update Process Flow

### Foolproof Update Process:

1. **System Verification**
   - Check disk space (minimum 5GB)
   - Verify Docker and Docker Compose
   - Test DNS resolution

2. **Automatic Fixes**
   - Fix DNS resolution issues
   - Update nginx configuration
   - Verify hostname entries

3. **Comprehensive Backup**
   - Database backup
   - Configuration files backup
   - Compressed backup archive

4. **Safe Service Management**
   - Stop services in dependency order
   - Pull latest images with retry
   - Start services in dependency order

5. **Health Verification**
   - Test each service with retries
   - Verify database connectivity
   - Check endpoint accessibility

6. **Emergency Recovery** (if needed)
   - Automatic DNS fixes
   - Service restart in correct order
   - Re-verification of health

## Service Dependencies

```
Pi-hole (DNS) ← All other services depend on this
    ↓
Databases (PostgreSQL, Redis, Qdrant)
    ↓
AI Services (Ollama, Open WebUI, n8n)
    ↓
Network Services (WireGuard, Nginx)
```

## Configuration Files

### Nginx Configuration
The script automatically updates nginx to use **IP addresses** instead of hostnames:

```nginx
# Automatically updated by script:
proxy_pass http://172.20.0.14:8080/;  # Open WebUI
proxy_pass http://172.20.0.15:5678/;  # n8n
proxy_pass http://172.20.0.16:80/;    # Pi-hole
```

### Hostname Entries
The script automatically adds required entries to `/etc/hosts`:

```
10.211.55.12 tu.local
10.211.55.12 ai.tu.local
```

## Error Handling

### Automatic Recovery
The script includes comprehensive error handling:

- **DNS Issues**: Automatically fixes and retries
- **Service Failures**: Attempts emergency recovery
- **Image Pull Failures**: Retries with exponential backoff
- **Health Check Failures**: Multiple retry attempts

### Graceful Interruption
- Handles Ctrl+C gracefully
- Provides clear error messages
- Maintains system stability

## Usage

### Simple Update Command:
```bash
./scripts/update.sh
```

### What Happens:
1. Script checks system requirements
2. Automatically fixes any DNS issues
3. Creates comprehensive backup
4. Updates all services safely
5. Verifies all services are working
6. Provides detailed summary

## Monitoring

### During Update:
- Watch the colored output for progress
- Green ✓ = Success
- Yellow ⚠ = Warning (non-critical)
- Red ✗ = Error (will be handled automatically)

### After Update:
```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f [service_name]

# Test endpoints
curl -k https://tu.local/health
curl -k https://ai.tu.local/health
```

## Troubleshooting

### If Update Fails:
1. **Check the output** - the script provides detailed error messages
2. **Review logs** - `docker compose logs [service_name]`
3. **Run the script again** - it's designed to be idempotent and safe

### Manual Recovery (if needed):
```bash
# Check DNS
nslookup google.com

# Check services
docker compose ps

# Restart specific service
docker compose restart [service_name]
```

## Best Practices

### Before Updates:
1. **Always use the update script** - it handles everything automatically
2. **Check system resources** - script will warn if insufficient
3. **Monitor the process** - watch for any warnings

### During Updates:
1. **Don't interrupt the process** - let it complete
2. **Monitor the output** - green checkmarks indicate success
3. **Wait for completion** - script will provide summary

### After Updates:
1. **Verify services are healthy** - script tests automatically
2. **Check the summary** - shows all access information
3. **Test manually if needed** - visit the web interfaces

## Access Information

After successful update:
- **Open WebUI (AI Chat):** `https://tu.local/`
- **n8n Workflows:** `https://ai.tu.local/`
- **Pi-hole (Ad Blocker):** `http://tu.local:8081/`

### Default Credentials:
- **n8n:** admin / admin123
- **Pi-hole:** admin / SwissPiHole2024!

## Conclusion

The foolproof update script eliminates the complexity and potential for errors by:

1. **Automatically detecting and fixing issues** before they cause problems
2. **Using proper dependency order** (Pi-hole first)
3. **Implementing comprehensive error handling** with automatic recovery
4. **Providing clear feedback** with colored output and detailed summaries
5. **Being completely safe** - can be run multiple times without issues

This ensures a **robust, reliable, and foolproof update process** for your AI Platform. 