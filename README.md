## Governance

This project is managed and maintained by [TechUties](https://www.techuties.com). For enterprise support, integrations, and roadmap discussions, please reach out via Techuties.

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
- **OS**: Ubuntu Server 22.04+ (latest LTS recommended) inside a VM on your host machine
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: 20GB+ free space
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+

### Network Requirements
- **Ports**: 80, 443, 5678, 8081, 5353, 51820 (UDP)
- **Domain**: Optional (tu.local as default)

References:
- Ubuntu Server: https://ubuntu.com/server/docs
- Docker Engine (Ubuntu): https://docs.docker.com/engine/install/ubuntu/
- Docker Compose: https://docs.docker.com/compose/
- WireGuard: https://www.wireguard.com/

## 🛠️ Installation (Fresh Ubuntu Server)

### 1) Update OS and install Docker
```bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
sudo reboot
# log out/in or: newgrp docker
```

### 2) Get the code
```bash
git clone https://github.com/techuties/tu-vm.git
cd tu-vm
```

### 3) Configure environment
```bash
cp env.example .env
```
Edit `.env` minimally:
- POSTGRES_PASSWORD, REDIS_PASSWORD
- HOST_IP (server IP), DOMAIN (e.g., tu.local)
- Optional secrets for n8n/Open WebUI

### 4) (Optional) Workstation hostname mapping
Add to your workstation `/etc/hosts`:
```
Linux: sudo nano /etc/hosts

<HOST_IP> tu.local ai.tu.local
```

### 4.1) Find your VM IP (inside the Ubuntu VM)
Use one of the following to get the VM's LAN IP (not 127.0.0.1):
```bash
# Simple: first address shown
hostname -I | awk '{print $1}'

# Alternative:
ip -4 addr show | grep -oP 'inet \K[0-9.]+' | grep -v '^127\.' | head -n1
```
Tips:
- If your VM uses bridged networking, this is the IP your host/LAN can reach.
- Hypervisor GUIs (Parallels/VMware/VirtualBox/Hyper‑V) also show the VM IP.
- Replace `<HOST_IP>` in the hosts mapping above with this VM IP.

### 5) Start the platform (safe sequence)
```bash
./scripts/start.sh
```
The script frees port 53 for Pi‑hole, generates self‑signed TLS if missing, and starts services in dependency order.

### 6) Verify access
```bash
curl -k https://tu.local/health     # Open WebUI
curl -k https://ai.tu.local/health  # n8n
```
If you didn’t add hostnames, browse to the server IP on 443 and set Host header accordingly.

---

## 🖥️ Running on macOS/Windows Hosts (via VM)

This stack is intended to run INSIDE an Ubuntu Server VM (latest LTS). Your macOS/Windows machine acts only as the host of the VM.

Recommended VM setup:

1) Hypervisor: Parallels/VMware/VirtualBox/Hyper‑V
2) OS in VM: Ubuntu Server 22.04+ (latest LTS recommended)
3) Networking: 
      Recommendet: Bridged adapter preferred (VM gets its own LAN IP). Alternatively use NAT and expose required ports.
4) IP: Reserve a static DHCP lease for the VM on your router (stable IP).
5) Workstation hostnames: add to your host OS:
   - macOS: `/etc/hosts`
   - Windows: `C:\\Windows\\System32\\drivers\\etc\\hosts`
   - Map to the VM IP:
   ```
   <VM_IP> tu.local ai.tu.local
   ```

No special Docker overrides are needed on the host. Run all commands inside the Ubuntu VM and follow the Linux instructions above.

## 🌐 Access URLs

### Main Services
- **Open WebUI**: https://tu.local (served via Nginx; container port 8080 is not published on the host)
- **n8n Workflows**: https://ai.tu.local (or http://localhost:5678 or http://<ubuntuIP-address>:5678)
- **Pi-hole Admin**: http://localhost:8081/admin

### Default Credentials
- **Open WebUI**: No default login (first user creates admin)
- **n8n**: admin / admin123
- **Pi-hole**: No username / SwissPiHole2024!

Official docs:
- Open WebUI: https://docs.openwebui.com/
- n8n: https://docs.n8n.io/
- Pi-hole: https://docs.pi-hole.net/

### Database Access
- **PostgreSQL**: localhost:5432 (inside VM; from host use the VM IP)
  - Database: ai_platform
  - User: ai_admin
  - Password: ai_password_2024

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```
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
- **DNS Port**: 53 (host), with Linux handoff from systemd‑resolved handled by scripts
- **Admin Port**: 8081
- **Blocking**: Enabled by default

## 📊 Management Scripts

### What the scripts actually do (foolproof)

#### scripts/start.sh
- Purpose: one-command safe boot of the entire stack on Ubuntu Server.
- Why: Pi‑hole must bind host port 53 before anything else; many services depend on DNS. Start order and DNS handoff are easy to get wrong manually.
- How it works:
  1) Checks and frees port 53 if `systemd-resolved` is holding it
  2) Ensures Nginx upstreams and hosts entries are sane
  3) Starts services in dependency order: Pi‑hole → PostgreSQL/Redis/Qdrant → Ollama/Open WebUI/n8n → WireGuard/Nginx
  4) Verifies health and prints access URLs

#### scripts/update.sh
- Purpose: safe OS + container update with DNS handoff, backups, and logs.
- Why: pulling images and running apt upgrades requires DNS while Pi‑hole is stopped; we hand off to host DNS (systemd‑resolved) then switch back.
- How it works:
  1) Enable host DNS (Cloudflare/Quad9), verify resolution
  2) Create timestamped backups (DB dump + configs)
  3) Stop app services, stop Pi‑hole
  4) Run `apt-get update && apt-get upgrade`, pull images with retries
  5) Stop host DNS, start Pi‑hole, then other services in order
  6) Write a full run log with DNS diagnostics to `logs/update_YYYYmmdd_HHMMSS.log`

#### scripts/cleanup.sh
- Purpose: free space and remove unused Docker artifacts without touching active data.
- How it works:
  - `docker compose down`, prune containers/images/volumes/networks/system
  - Deletes old temp files and rotates backups (keeps newest)

### Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/start.sh` | Safe startup with DNS handoff and dependency order | `./scripts/start.sh` |
| `scripts/update.sh` | OS + image updates with backups and logs | `./scripts/update.sh` |
| `scripts/cleanup.sh` | Prune unused Docker artifacts and rotate backups | `./scripts/cleanup.sh` |

See `scripts/scripts.md` for details on each script.

Note on manual operations:

- For cold starts and restarts, prefer `./scripts/start.sh` so Pi‑hole can bind :53 first and services start in the correct order.
- The commands below are safe for day‑to‑day admin tasks (logs, restarting a single service, stopping the stack), but they do not perform the DNS handoff logic that `start.sh` does.

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

#### DNS (Linux) – Pi-hole cannot bind :53
```bash
sudo ss -tulnp | grep :53       # See who holds 53
systemctl status systemd-resolved
./scripts/start.sh               # Enforces proper DNS handoff and start order
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

What it does (summary):
- Switches DNS to host resolver (systemd‑resolved) using Cloudflare/Quad9
- Creates timestamped backups (DB dump + configs)
- Runs `apt-get update && apt-get upgrade`
- Pulls latest container images with retries
- Stops host DNS and brings Pi‑hole up first, then the rest
- Logs every step to `logs/update_YYYYmmdd_HHMMSS.log`

References:
- systemd‑resolved: https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.service.html

### Manual Updates
```bash
# Pull latest images
docker compose pull

# Recreate containers
docker compose up -d --force-recreate
```

## 📚 Advanced Configuration
### Architecture Overview (High Level)

```
[ macOS/Windows Host ]
       │ (Hypervisor)
       ▼
[ Ubuntu Server VM (tu-vm) ]
  ├─ Docker bridge network (172.20.0.0/16)
  │  ├─ ai_pihole (DNS, 53) ← upstream: Cloudflare/Quad9
  │  ├─ ai_postgres (DB)
  │  ├─ ai_redis (cache)
  │  ├─ ai_qdrant (vector DB)
  │  ├─ ai_ollama (models)
  │  ├─ ai_openwebui (chat UI)
  │  ├─ ai_n8n (workflow)
  │  ├─ ai_wireguard (VPN)
  │  └─ ai_nginx (TLS/Reverse proxy)
  └─ Scripts: start.sh / update.sh (DNS handoff, backups, health)

External access → Nginx (80/443) → Open WebUI/n8n
Internal name resolution → Pi‑hole
```

### Custom AI Models
1. Access Ollama (from within VM): http://localhost:11434 (from host: http://<VM_IP>:11434)
2. Pull models: `ollama pull llama2:7b`
3. Configure in Open WebUI

Official docs:
- Ollama: https://ollama.com/docs
- Qdrant: https://qdrant.tech/documentation/

### Custom Workflows
1. Access n8n: https://ai.tu.local (from host, ensure hosts mapping to VM IP)
2. Create workflows with database nodes
3. Use PostgreSQL for data storage

### DNS Configuration
1. Access Pi-hole: http://localhost:8081/admin (from host: http://<VM_IP>:8081/admin)
2. Add custom blocklists
3. Configure upstream DNS servers

Official docs:
- Pi-hole DNS: https://docs.pi-hole.net/ftldns/configfile/

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
