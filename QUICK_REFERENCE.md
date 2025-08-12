# Quick Reference - AI Platform Updates

## 🚀 Foolproof Update (Single Command)
```bash
./scripts/update.sh
```

## 📋 What the Script Does Automatically

### ✅ Pre-Flight Checks
- Verifies disk space (minimum 5GB)
- Checks Docker and Docker Compose
- Tests DNS resolution
- Validates system requirements

### ✅ Automatic Fixes
- **DNS Issues**: Starts systemd-resolved and configures DNS
- **Container Resolution**: Updates nginx to use IP addresses
- **Hostname Entries**: Adds missing entries to `/etc/hosts`
- **Configuration Backup**: Creates timestamped backups

### ✅ Safe Update Process
- **Backup**: Comprehensive backup with database and configs
- **Shutdown**: Stops services in dependency order
- **Update**: Pulls latest images with retry logic
- **Startup**: Starts services in dependency order (Pi-hole first)
- **Verification**: Tests all services with retries

### ✅ Emergency Recovery
- If services fail, automatically attempts recovery
- Re-fixes DNS issues
- Restarts services in correct order
- Re-tests service health

## 📊 Service Status Commands

### Check All Services:
```bash
docker compose ps
```

### Check Specific Service:
```bash
docker compose logs [service_name]
```

### Test Service Health:
```bash
curl -k https://tu.local/health
curl -k https://ai.tu.local/health
```

## 🌐 Access URLs
- **Open WebUI:** https://tu.local/
- **n8n:** https://ai.tu.local/
- **Pi-hole:** http://tu.local:8081/

## 🔑 Default Credentials
- **n8n:** admin / admin123
- **Pi-hole:** admin / SwissPiHole2024!

## ⚠️ Common Issues & Solutions

### Issue: "host not found in upstream"
**Solution:** Run `./scripts/update.sh` - it fixes this automatically

### Issue: "address already in use" on port 53
**Solution:** Run `./scripts/update.sh` - it handles DNS conflicts automatically

### Issue: Services can't resolve hostnames
**Solution:** Run `./scripts/update.sh` - it updates nginx config automatically

## 📞 Emergency Commands

### If Update Fails:
```bash
# Check DNS
nslookup google.com

# Check services
docker compose ps

# Restart specific service
docker compose restart [service_name]

# Run update again (safe to run multiple times)
./scripts/update.sh
```

### Manual Recovery (if needed):
```bash
# Stop all services
docker compose down

# Start Pi-hole first
docker compose up -d pihole

# Wait for Pi-hole to be ready
sleep 30

# Start other services
docker compose up -d
```

## 🎯 Key Principle
**Use the single update script** - it handles everything automatically and safely!

## 📈 Monitoring During Update

### Watch for:
- **Green ✓** = Success
- **Yellow ⚠** = Warning (non-critical)
- **Red ✗** = Error (handled automatically)

### Progress Indicators:
- System requirements verification
- DNS resolution fixes
- Backup creation
- Service shutdown/startup
- Health verification
- Emergency recovery (if needed)

## 🔄 Update Process Flow

```
1. System Checks → 2. Auto Fixes → 3. Backup → 4. Update → 5. Verify → 6. Summary
```

## 🛡️ Safety Features

- **Idempotent**: Can be run multiple times safely
- **Comprehensive Backup**: Automatic backup before any changes
- **Error Recovery**: Automatic recovery if services fail
- **Graceful Interruption**: Handles Ctrl+C safely
- **Detailed Logging**: Clear progress and error messages

## 📝 After Update

1. **Check the summary** - shows all access information
2. **Verify services** - script tests automatically
3. **Test manually** - visit the web interfaces
4. **Monitor logs** - if needed: `docker compose logs -f`

## 🎉 Success Indicators

After successful update, you should see:
- All services showing "Up" status
- Green checkmarks for all health tests
- Access to all web interfaces
- Detailed summary with URLs and credentials 