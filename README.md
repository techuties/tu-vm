## AI Platform Stack (Docker)

> Managed by [techuties.com](https://www.techuties.com), part of the Bastilities ecosystem.

This repository provisions a compact, production-style AI platform using Docker Compose. It brings together:

- PostgreSQL (persistent DB)
- Redis (fast cache)
- Qdrant (vector DB)
- Ollama (local models runtime)
- Open WebUI (chat UI)
- n8n (workflow automation)
- Pi-hole (DNS/ad-blocking for the stack)
- Nginx (reverse proxy and TLS)
- WireGuard (secure remote access)

The stack is optimized for a single host (e.g., Ubuntu Server/VM) and includes safe start/update scripts that manage DNS dependencies and system updates automatically.

### Key Benefits

- **All‑in‑one AI stack**: Databases, models, UI, workflows, cache, and proxy in one Compose project
- **Foolproof startup/update**: Scripts handle DNS ordering (Pi‑hole vs systemd‑resolved) and apt updates
- **Isolation**: Dedicated Docker network with assigned service IPs and Nginx front door
- **Security**: WireGuard, Pi‑hole filtering, reverse proxy TLS, minimal ports exposed
- **Local‑first**: Ollama models run locally; Qdrant stores your vectors

### When to Use

- Personal/SMB AI hub on a single VM/host
- Edge or lab environments with limited/controlled internet
- Teams who want local LLM access (Ollama) with a friendly UI and automations (n8n)

### Not a Fit

- Multi‑tenant production with Kubernetes & horizontal scaling
- Strict zero‑downtime deployment requirements

---

## Architecture Overview

- Compose file: `docker-compose.yml`
- Reverse proxy: `nginx/`
- DNS (Pi‑hole) custom config: `pihole/`
- TLS assets: `ssl/` (auto‑generated self‑signed if none present)
- Helper scripts: `scripts/`
- Logs and backups: `logs/`, `backups/` (git‑ignored)

Service access (defaults):

- Open WebUI: `https://tu.local/`
- n8n: `https://ai.tu.local/`
- Pi‑hole Admin: `http://tu.local:8081/`
- Qdrant: `http://localhost:6333`
- Ollama API: `http://localhost:11434`

Open ports (host): 80/tcp, 443/tcp, 53/tcp+udp, 5678/tcp, 11434/tcp, 6333/tcp, 8081/tcp, 51820/udp

---

## Prerequisites

- Ubuntu Server 22.04+ (or comparable Linux with systemd)
- Docker Engine and Docker Compose plugin
- Host DNS must allow Pi‑hole to bind to port 53 (the scripts handle this)

Install Docker (example for Ubuntu):

```bash
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
# Log out/in or: newgrp docker
```

---

## Installation & First Start

1) Clone and enter the project directory

```bash
git clone <this-repo-url> ai-platform
cd ai-platform
```

2) Copy environment template and adjust

```bash
cp env.example .env
```

Key fields to review in `.env`:

- `HOST_IP` (e.g., your VM IP)
- `DOMAIN` (e.g., `tu.local`)
- Secrets for n8n, WebUI, DB, etc.

3) Ensure local hostnames resolve from your workstation (optional but recommended)

Add entries to your workstation `/etc/hosts` (or local DNS):

```
<HOST_IP> tu.local ai.tu.local
```

4) Start the stack safely

```bash
./scripts/start.sh
```

The script will:

- Generate self‑signed TLS certs if missing
- Ensure DNS/port 53 is free for Pi‑hole
- Start services in dependency order (Pi‑hole → DBs → AI → proxy)
- Verify health and print access URLs

---

## DNS Considerations (Pi‑hole vs systemd‑resolved)

Ubuntu’s systemd‑resolved often binds to 127.0.0.53:53, which conflicts with Pi‑hole. The provided scripts handle the handoff automatically:

- Startup: free port 53 → start Pi‑hole first
- Update: temporarily use host DNS (systemd‑resolved with Cloudflare/Quad9), then return to Pi‑hole

You normally do not need to manage this manually.

---

## Updating the Stack

Use the foolproof updater:

```bash
./scripts/update.sh
```

What it does:

- Verifies system requirements
- Enables host DNS for downloads (Cloudflare 1.1.1.1, Quad9 9.9.9.9)
- Backs up configs and DB dump (`backups/`)
- Stops app services, stops Pi‑hole
- Runs `apt-get update && apt-get upgrade`
- Pulls latest container images
- Stops host DNS, then starts Pi‑hole and the rest in order
- Verifies health; logs to `logs/update_*.log`

If anything fails, tail the most recent log file for full diagnostics.

```bash
ls -1 logs/update_*.log | tail -n1
tail -f logs/update_YYYYmmdd_HHMMSS.log
```

### Update script (how it works)

- Entry point: `./scripts/update.sh`
- Writes a detailed run log to `logs/update_YYYYmmdd_HHMMSS.log`
- Uses non‑Google DNS resolvers (Cloudflare 1.1.1.1, Quad9 9.9.9.9)

Flow:

1) Pre‑checks: disk space, Docker/Compose availability
2) Prepare DNS: start Ubuntu host DNS (systemd‑resolved) so updates can resolve while Pi‑hole is down
3) Backup: timestamped archive of configs and a DB dump in `backups/`
4) Stop services: stop app services first, then Pi‑hole (to free port 53)
5) OS updates: `apt-get update && apt-get upgrade`
6) Images: `docker compose pull` with retries and logging
7) DNS handoff back: stop host DNS, verify port 53 is free
8) Start services in order: Pi‑hole → databases → AI services → WireGuard/Nginx
9) Health checks: HTTP checks and container health; prints access URLs

Notes:

- If the systemd stub 127.0.0.53 is not listening, the script temporarily writes a static `/etc/resolv.conf` (Cloudflare/Quad9) to guarantee DNS during updates.
- All diagnostics (systemd status, `resolvectl status`, `ss -tlnp :53`, `/etc/resolv.conf`) are logged for troubleshooting.
- Re‑run the script safely any time; it is idempotent and will retry pulls/health checks.

---

## Configuration Notes

- Nginx: `nginx/conf.d/default.conf` proxies to fixed container IPs on the internal Docker network for resilience against DNS timing.
- Pi‑hole: custom dnsmasq snippets can go under `pihole/` (mounted into the container).
- Data: volumes are defined under `volumes:` in Compose and are git‑ignored to protect secrets/state.

---

## Backups & Logs

- Backups: `backups/` contain timestamped archives made by the updater
- Logs: `logs/` holds update logs and diagnostics
- Both are ignored by Git; keep your own off‑host backups for disaster recovery

---

## Troubleshooting

### Pi‑hole fails to start (port 53 already in use)

- Run: `sudo ss -tulnp | grep :53`
- Ensure systemd‑resolved is not grabbing port 53.
- Re-run `./scripts/start.sh` to enforce the proper handoff.

### Local hostnames don’t resolve

- Add `tu.local` and `ai.tu.local` to your workstation `/etc/hosts`, or configure your LAN DNS to resolve them to the host IP.

### Service is unhealthy

- Check: `docker compose ps` and `docker compose logs <service>`
- Re-run update to refresh images and configs: `./scripts/update.sh`

---

## Security

- Self‑signed TLS certs are generated by default. For public use, replace with trusted certs (mount into `ssl/`).
- Change default credentials/secrets in `.env`.
- Expose only required ports.

---

## Uninstallation / Cleanup

```bash
docker compose down -v
sudo rm -rf backups logs postgres_data redis_data qdrant_data ollama_data n8n_data pihole_data pihole_dnsmasq wireguard_config nginx_logs
```

---

## License

This repository is provided as-is under MIT license. Review third‑party images’ licenses (Ollama, Qdrant, n8n, etc.) before production use.

---

## Governance

This project is managed and maintained by [techuties.com](https://www.techuties.com) and is part of the Bastilities ecosystem. For enterprise support, integrations, and roadmap discussions, please reach out via Techuties.

# 🤖 AI Platform - Professional Docker Setup

A comprehensive, production-ready AI platform running in Docker containers with PostgreSQL, vector storage, workflow automation, and local AI model support. Optimized for both desktop and mobile environments.

## 🚀 Features

### Core Services
- **Open WebUI** - Modern AI chat interface with local model support
- **n8n** - Workflow automation platform with PostgreSQL backend
- **Ollama** - Local AI model inference engine
- **PostgreSQL** - Primary database with optimized settings
- **Qdrant** - Vector database for AI embeddings
- **Redis** - Caching layer for improved performance

### Security & Network
- **Pi-hole** - DNS ad-blocking and network security
- **WireGuard VPN** - Secure remote access
- **Nginx** - Reverse proxy with SSL/TLS support
- **Self-signed SSL certificates** - HTTPS encryption

### Mobile Optimizations
- **Resource limits** - Battery-friendly resource management
- **Telemetry disabled** - Privacy-focused configuration
- **Health checks** - Automatic service monitoring
- **Foolproof scripts** - One-command setup and management

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04+ / macOS / Windows with WSL2
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: 20GB+ free space
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+

### Network Requirements
- **Ports**: 80, 443, 5678, 8081, 5353, 51820 (UDP)
- **Domain**: Optional (tu.local for local development)

## 🛠️ Installation

### Quick Start (Recommended)

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd docker
   ```

2. **Run the automated setup:**
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

3. **Start the platform:**
   ```bash
   chmod +x scripts/start.sh
   ./scripts/start.sh
   ```

### Manual Installation

1. **Install Docker and Docker Compose:**
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install docker.io docker-compose
   sudo usermod -aG docker $USER
   ```

2. **Configure environment:**
   ```bash
   cp env.example .env
   # Edit .env with your preferences
   ```

3. **Generate SSL certificates:**
   ```bash
   mkdir -p ssl
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout ssl/nginx.key -out ssl/nginx.crt \
     -subj "/C=CH/ST=Zurich/L=Zurich/O=AI Platform/CN=tu.local"
   ```

4. **Start services:**
   ```bash
   docker compose up -d
   ```

## 🌐 Access URLs

### Main Services
- **Open WebUI**: https://tu.local (or http://localhost:8080)
- **n8n Workflows**: https://ai.tu.local (or http://localhost:5678)
- **Pi-hole Admin**: http://localhost:8081/admin

### Default Credentials
- **Open WebUI**: No default login (first user creates admin)
- **n8n**: admin / admin123
- **Pi-hole**: No username / SwissPiHole2024!

### Database Access
- **PostgreSQL**: localhost:5432
  - Database: ai_platform
  - User: ai_admin
  - Password: ai_password_2024

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# Database
POSTGRES_DB=ai_platform
POSTGRES_USER=ai_admin
POSTGRES_PASSWORD=ai_password_2024

# AI Services
WEBUI_SECRET_KEY=your_secret_key
N8N_USER=admin
N8N_PASSWORD=admin123

# Security
PIHOLE_PASSWORD=SwissPiHole2024!
```

### Service Configuration

#### Open WebUI
- **Model Management**: Access via web interface
- **Database**: PostgreSQL with vector storage
- **Authentication**: JWT-based with configurable secrets

#### n8n
- **Database**: PostgreSQL backend
- **Authentication**: Basic auth enabled
- **Webhooks**: HTTPS support with SSL

#### Pi-hole
- **DNS Port**: 5353 (to avoid system conflicts)
- **Admin Port**: 8081
- **Blocking**: Enabled by default

## 📊 Management Scripts

### Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/setup.sh` | Initial setup and configuration | `./scripts/setup.sh` |
| `scripts/start.sh` | Start all services with checks | `./scripts/start.sh` |
| `scripts/update.sh` | Update containers and images | `./scripts/update.sh` |
| `scripts/cleanup.sh` | Clean unused Docker resources | `./scripts/cleanup.sh` |

### Service Management

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f [service_name]

# Restart specific service
docker compose restart [service_name]

# Check service status
docker compose ps
```

## 🔒 Security Features

### Network Security
- **Pi-hole DNS**: Blocks ads and malicious domains
- **WireGuard VPN**: Secure remote access
- **SSL/TLS**: HTTPS encryption for all web services
- **Firewall**: Containerized network isolation

### Access Control
- **Authentication**: Required for all admin interfaces
- **Rate Limiting**: Protection against abuse
- **Resource Limits**: Prevents resource exhaustion
- **Health Monitoring**: Automatic service recovery

### Privacy
- **Local Processing**: AI models run locally
- **No Telemetry**: All telemetry disabled
- **Query Logging**: Configurable privacy settings
- **Data Encryption**: Database and communication encryption

## 🚨 Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check Docker status
docker compose ps

# View service logs
docker compose logs [service_name]

# Check port conflicts
sudo lsof -i :[port_number]
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
docker compose logs postgres

# Reset database (WARNING: Data loss)
docker compose down -v
docker compose up -d postgres
```

#### SSL Certificate Issues
```bash
# Regenerate certificates
rm -rf ssl/*
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/nginx.key -out ssl/nginx.crt \
  -subj "/C=CH/ST=Zurich/L=Zurich/O=AI Platform/CN=tu.local"
```

#### Port Conflicts
```bash
# Check what's using a port
sudo ss -tlnp | grep :[port]

# Use cleanup script
./scripts/cleanup.sh
```

### Performance Issues

#### High Memory Usage
```bash
# Check resource usage
docker stats

# Restart memory-intensive services
docker compose restart ollama open-webui
```

#### Slow AI Responses
```bash
# Check Ollama status
docker compose logs ollama

# Verify model availability
curl http://localhost:11434/api/tags
```

## 📈 Monitoring & Maintenance

### Health Checks
All services include health checks that automatically restart failed containers.

### Log Management
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f [service_name]

# Export logs
docker compose logs > platform.log
```

### Backup & Recovery
```bash
# Backup data volumes
docker run --rm -v ai_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup.tar.gz -C /data .

# Restore from backup
docker run --rm -v ai_postgres_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/postgres_backup.tar.gz -C /data
```

## 🔄 Updates

### Automatic Updates
```bash
# Update all services
./scripts/update.sh

# Update specific service
docker compose pull [service_name]
docker compose up -d [service_name]
```

### Manual Updates
```bash
# Pull latest images
docker compose pull

# Recreate containers
docker compose up -d --force-recreate
```

## 📚 Advanced Configuration

### Custom AI Models
1. Access Ollama: http://localhost:11434
2. Pull models: `ollama pull llama2:7b`
3. Configure in Open WebUI

### Custom Workflows
1. Access n8n: https://ai.tu.local
2. Create workflows with database nodes
3. Use PostgreSQL for data storage

### DNS Configuration
1. Access Pi-hole: http://localhost:8081/admin
2. Add custom blocklists
3. Configure upstream DNS servers

## 🤝 Support

### Documentation
- [Open WebUI Documentation](https://docs.openwebui.com/)
- [n8n Documentation](https://docs.n8n.io/)
- [Ollama Documentation](https://ollama.ai/docs)
- [Pi-hole Documentation](https://docs.pi-hole.net/)

### Community
- GitHub Issues for bug reports
- Discord/Slack for community support
- Stack Overflow for technical questions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Open WebUI team for the excellent AI interface
- n8n team for powerful workflow automation
- Ollama team for local AI model support
- Pi-hole team for network security
- Docker community for containerization tools

---

**⚠️ Important Notes:**
- This setup is designed for development and personal use
- For production deployment, review security settings
- Regular backups are recommended
- Keep Docker and images updated for security 