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
<HOST_IP> tu.local ai.tu.local
```

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

## 🖥️ macOS and Windows Hosts

This stack runs fine on macOS (Docker Desktop) and Windows (Docker Desktop / WSL2). The only difference is DNS handling: Pi‑hole cannot reliably bind host port 53 on those platforms. Use the provided override and keep DNS inside the Docker network.

### Start with mac/win override
```bash
docker compose -f docker-compose.yml -f docker-compose.mac-win.yml up -d
```

Notes:
- Pi‑hole still serves DNS for containers via Docker’s internal DNS. You don’t need to expose 53 on the host.
- Access services via:
  - Open WebUI: https://localhost (accept self‑signed cert)
  - n8n: https://localhost (use Host header ai.tu.local if needed)
  - Pi‑hole Admin: http://localhost:8081/
- The Linux‑specific DNS handoff in `./scripts/start.sh` is skipped automatically on macOS/Windows.

For Windows WSL2 users, you can run this project from WSL and access it from Windows via localhost; DNS port 53 exposure is still discouraged.

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
