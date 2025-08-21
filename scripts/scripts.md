## Scripts Overview

This folder contains operational scripts to manage the TechUties VM stack. They follow our philosophy: DNS handoff is explicit, startup is dependency-ordered, access is HTTPS-only behind Nginx, and everything is logged.

### start.sh
- Purpose: Safely start the full stack in the right dependency order.
- Why needed: Pi-hole (DNS) must bind port 53 before other services relying on DNS start. The script frees port 53, handles DNS handoff, generates TLS certs if missing, and starts services in order: Pi‑hole → databases → apps → proxy.
- Key actions:
  - Frees port 53 if taken by systemd‑resolved and verifies DNS fallback
  - Updates Nginx upstreams (static IPs) and ensures `/etc/hosts` entries for `tu.local`, `oweb.tu.local`, `n8n.tu.local`, `pihole.tu.local`
  - Starts services with waits and health checks
  - Enforces HTTPS-only access (HTTP redirects to HTTPS)
  - Logs to `logs/start_*.log` (full stdout/stderr mirrored)

### update.sh
- Purpose: Foolproof updater for OS packages and container images with DNS handoff.
- Why needed: During updates Pi‑hole must stop (releases port 53). The script switches to host DNS (systemd‑resolved with Cloudflare/Quad9), runs apt upgrade and pulls images, then returns DNS to Pi‑hole and restarts services in order.
- Key actions:
  - Creates timestamped backups (configs + DB dump)
  - Collects DNS diagnostics (systemd-resolved status, `ss :53`, `resolvectl`, `/etc/resolv.conf`)
  - Runs `apt-get update && apt-get upgrade`
  - `docker compose pull` with retries
  - Stops host DNS; starts Pi‑hole first, then the rest
  - Tests endpoints: `https://tu.local/`, `https://oweb.tu.local/`, `https://n8n.tu.local/`, `https://pihole.tu.local/health`, `http://localhost:11434/api/tags`
  - Logs to `logs/update_*.log`

### cleanup.sh
- Purpose: Free disk space and remove unused Docker artifacts safely.
- Why needed: Over time images/volumes/logs accumulate. This script prunes Docker and keeps the last 3 backups, freeing space without touching active data.
- Key actions:
  - `docker compose down`, prune containers/images/volumes/networks/system
  - Deletes temp files; preserves most recent backups
  - Logs to `logs/cleanup_*.log`

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

### Access policy (HTTPS-only)
- All host-facing web traffic terminates at Nginx with self-signed TLS.
- Port 80 serves redirects only. Use:
  - Landing: `https://tu.local/`
  - Open WebUI: `https://oweb.tu.local/`
  - n8n: `https://n8n.tu.local/`
  - Pi-hole Admin: `https://pihole.tu.local/`

### Troubleshooting quick checks
```bash
# Verify HTTP->HTTPS redirects and health
for h in tu.local oweb.tu.local n8n.tu.local pihole.tu.local; do \
  curl -sSI http://127.0.0.1/ -H "Host: $h" | head -n1; \
  curl -k -sSI https://127.0.0.1/health -H "Host: $h" | head -n1; \
done

# Service logs
docker compose logs --tail=200 nginx n8n open-webui pihole postgres redis qdrant ollama wireguard

# Most recent script logs
ls -1t logs/start_*.log | head -n1 | xargs -I{} tail -n 200 {}
ls -1t logs/update_*.log | head -n1 | xargs -I{} tail -n 200 {}
```


