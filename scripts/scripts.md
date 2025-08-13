## Scripts Overview

This folder contains operational scripts to manage the AI Platform lifecycle. Each script is designed to be idempotent and safe.

### start.sh
- Purpose: Safely start the full stack in the right dependency order.
- Why needed: Pi-hole (DNS) must bind port 53 before other services relying on DNS start. The script ensures port 53 is free, adjusts DNS handoff, generates TLS certs if missing, and brings up services in order: Pi‑hole → databases → AI → proxy.
- Key actions:
  - Frees port 53 if taken by systemd‑resolved
  - Updates nginx upstreams and /etc/hosts entries if needed
  - Starts services with waits and health checks

### update.sh
- Purpose: Foolproof updater for OS packages and container images with DNS handoff.
- Why needed: During updates Pi‑hole must stop (releases port 53). The script switches to host DNS (systemd‑resolved, Cloudflare/Quad9), runs apt upgrade and pulls images, then returns DNS to Pi‑hole and restarts services in order.
- Key actions:
  - Creates timestamped backups (configs + DB dump)
  - Starts host DNS and verifies resolution
  - Runs `apt-get update && apt-get upgrade`
  - `docker compose pull` with retries
  - Stops host DNS; starts Pi‑hole first, then the rest
  - Logs to `logs/update_*.log` with DNS diagnostics

### cleanup.sh
- Purpose: Free disk space and remove unused Docker artifacts safely.
- Why needed: Over time images/volumes/logs accumulate. This script prunes Docker and keeps the last 3 backups, freeing space without touching active data.
- Key actions:
  - `docker compose down`, prune containers/images/volumes/networks/system
  - Deletes temp files; preserves most recent backups

### Removed scripts
- setup.sh: Redundant with start/update scripts (TLS generation, checks already handled). Functionality consolidated.
- mobile-backup.sh: Superseded by automated backups in `update.sh`. For custom backups, use `docker exec pg_dump` and archive volumes as needed.

---

### Usage quick reference
```bash
# Start stack safely
./scripts/start.sh

# Update OS + images, with DNS handoff and logs
./scripts/update.sh

# Cleanup unused Docker artifacts and old backups
./scripts/cleanup.sh
```


