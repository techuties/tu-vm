# TechUties AI Platform - All In One Self-Hosted AI Workflow Stack

A comprehensive, production-ready AI platform running in Docker containers with PostgreSQL, vector storage, workflow automation, and local AI model support. Optimized for both desktop and mobile environments with **maximum security** and **easy management**.

<img width="1443" height="711" alt="tu-vm dashboard" src="https://github.com/user-attachments/assets/90a29bf9-3ed5-45af-bac2-ae0e7c354a8c" />


## 🎯 Quick Start

### 1. Start Services
```bash
./tu-vm.sh start
```

### 2. Enable Secure Access
```bash
sudo ./tu-vm.sh secure
```

### 3. Check Status
```bash
./tu-vm.sh status
```

**Note**: Tika is configured as the default PDF processor with full capabilities enabled automatically.

## 🚀 Features

### Core Services
- **Open WebUI** - Modern AI chat interface with local model support
- **n8n** - Workflow automation platform with PostgreSQL backend
- **Ollama** - Local AI model inference engine
- **PostgreSQL** - Primary database with optimized settings
- **Qdrant** - Vector database for AI embeddings
- **Redis** - Caching layer for improved performance
- **Apache Tika** - Advanced document processing and content extraction
- **MinIO** - S3-compatible object storage with web GUI

### Security & Network
- **Pi-hole** - DNS ad-blocking and network security (Primary DNS on port 53)
- **Access Control** - Secure access with easy on/off switching
- **Nginx** - Reverse proxy with SSL/TLS and security headers
- **Self-signed SSL certificates** - HTTPS encryption

### Document Processing
- **Apache Tika Default** - Full document processing with OCR and image analysis
- **Multi-format Support** - Handles 1000+ file formats including PDF, DOC, PPT, images
- **Advanced OCR** - Text extraction from scanned documents and images
- **Table Extraction** - Converts tables to structured text with layout preservation
- **Image Analysis** - Describes content in images, charts, and diagrams
- **Layout Understanding** - Maintains document structure and formatting

### Mobile Optimizations
- **Resource limits** - Battery-friendly resource management
- **Telemetry disabled** - Privacy-focused configuration
- **Health checks** - Automatic service monitoring
- **Smart monitoring** - Proactive issue detection with battery-aware recommendations
- **Service control** - Start/stop buttons for individual services
- **Simple control** - One script for everything

## 🗂️ Project Structure

```
.
├── backups/                    # Timestamped backups (auto + manual)
├── helper/                     # Landing page helper API (status/updates)
├── init-scripts/               # Init SQL and setup scripts
├── monitoring/                 # Prometheus/Grafana configuration
├── nginx/                      # Nginx reverse proxy config + landing HTML
├── pihole/                     # Pi-hole dnsmasq configuration
├── scripts/                    # Operational scripts (init, sync, switch, setup)
├── ssl/                        # Self‑signed TLS certificates
├── tika-minio-processor/       # Automated PDF pipeline service
├── docker-compose.yml          # Service orchestration
├── env.example                 # Environment template
├── README.md                   # This documentation
└── tu-vm.sh                    # Main control script
```

## ➕ Additional Services

- **Tika‑MinIO Processor** (`tika_minio_processor`)
  - Watches a MinIO bucket for PDFs, sends to Apache Tika, stores `<same>.txt` back
  - Config: `TIKA_URL`, `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `UPLOADS_BUCKET`, `PROCESSED_BUCKET`
  - Code: `tika-minio-processor/` (Dockerfile, `auto_processor.py`, `tika_processor.py`)

- **Helper Index** (`ai_helper_index`)
  - Lightweight Flask API used by the landing page for service status, updates and announcements
  - Code: `helper/uploader.py`

## 📈 Monitoring & Observability

### 🚨 Intelligent Monitoring System
The platform includes a comprehensive monitoring system optimized for laptop VMs with **proactive issue detection** and **battery-aware recommendations**.

#### **Daily Health Checks** (9:00 AM)
- **Container Health Monitoring**: Detects down, unhealthy, and frequently restarting services
- **Log Error Analysis**: Scans 24h of container logs for critical and warning errors
- **Update Detection**: Checks for OS and Docker image updates without downloading
- **Resource Monitoring**: CPU, memory, disk usage with laptop-specific optimizations

#### **Real-Time Dashboard Alerts**
- **Service Status**: Live monitoring of all container health
- **Resource Pressure**: Memory >80%, CPU load, disk space <2GB warnings
- **Battery Management**: Laptop-specific power-saving recommendations
- **Security Monitoring**: Firewall status, access control, authentication failures

#### **Smart Announcements System**
- **Color-coded alerts**: Red (critical), Orange (warning), Blue (info), Green (updates)
- **Priority-based notifications**: Critical, high, medium, low priority levels
- **Actionable guidance**: Specific commands and recommendations for each alert
- **Badge indicators**: Visual notifications when new alerts are available

#### **Laptop-Optimized Features**
- **Battery detection**: Warns when <20% battery, suggests stopping heavy services
- **Power-saving tips**: Automatic recommendations for battery preservation
- **Resource limits**: Prevents crashes on limited laptop hardware
- **Efficient monitoring**: Daily checks only, no constant resource usage

### **Advanced Monitoring**
- Prometheus and Grafana configuration is provided under `monitoring/`
- Targets include: Docker engine metrics, Pi‑hole, Nginx, Postgres, Redis (when exporters are enabled)
- You can extend the stack by adding exporters and a Grafana container to visualize metrics

## 🧰 Operational Scripts

- `scripts/init-openwebui.sh` – Open WebUI init hook
- `scripts/sync-openwebui-minio.sh` – Bi-directional sync: Open WebUI uploads → MinIO `tika-pipe`, and Tika `.txt` → back into Open WebUI
- `scripts/switch-pdf-loader.sh` – Switch between Tika and PyMuPDF loaders
- `scripts/daily-checkup.sh` – **Daily monitoring system** (runs at 9 AM via cron)
  - Container health checks (down, unhealthy, excessive restarts)
  - Log error analysis (critical vs warning errors)
  - Update detection (OS packages, Docker images)
  - Resource monitoring (CPU, memory, disk, battery)
  - Security monitoring (firewall, access control)
- `extend-disk.sh` – Convenience helper to expand disk on the host

## 🔒 Security First

### Security Objective: "Secure access control with easy management" ✅

The platform implements **secure access control** with three security levels:

| Level | Description | Use Case |
|-------|-------------|----------|
| **🔒 SECURE** | Local network access (recommended) | Daily usage |
| **🔓 PUBLIC** | Access from internet | Testing/development |
| **🚫 LOCKED** | No external access | Maintenance |

### Security Features
- **Container Network Isolation**: All services in isolated Docker containers
- **Custom Network**: 172.20.0.0/16 internal network
- **Firewall Protection**: UFW-based access control
- **TLS Encryption**: HTTPS-only with strong cipher suites
- **Information Disclosure Protection**: Health endpoints secured
- **Credential Management**: Secure key generation and rotation

## 📋 Simple Control Commands

### Basic Operations
```bash
./tu-vm.sh start          # Start all services
./tu-vm.sh stop           # Stop all services
./tu-vm.sh restart        # Restart all services
./tu-vm.sh status         # Show service status
```

### Access Control
```bash
sudo ./tu-vm.sh secure    # Enable secure access (recommended)
sudo ./tu-vm.sh public    # Enable public access (less secure)
sudo ./tu-vm.sh lock      # Block all external access
```

### Maintenance
```bash
sudo ./tu-vm.sh update    # Update system and services
./tu-vm.sh backup         # Create backup
sudo ./tu-vm.sh restore file.tar.gz # Restore from backup
```

## 🔧 Access Setup

### 1. Enable Secure Access
```bash
sudo ./tu-vm.sh secure
```

### 2. Access Services
Access services at:
- **Landing**: `https://10.211.55.12`
- **Open WebUI**: `https://10.211.55.12` (oweb.tu.local)
- **n8n**: `https://10.211.55.12` (n8n.tu.local)
- **Pi-hole**: `https://10.211.55.12` (pihole.tu.local)
- **MinIO Console**: `https://10.211.55.12` (minio.tu.local)
- **MinIO API**: `https://10.211.55.12` (api.minio.tu.local)

## 🌐 Pi-hole DNS Configuration

### How Pi-hole Works

The VM's Pi-hole serves as the primary DNS server on port 53, providing ad-blocking and privacy protection for all DNS queries.

#### Network Flow Diagram
```
Internet
    ↓
Host Machine
    ↓ DNS queries to VM
VM (10.211.55.12)
    ↓ DNS queries to Pi-hole container
Pi-hole Container (172.20.0.16)
    ↓ Filtered/blocked queries
External DNS (1.1.1.1, 1.0.0.1)
```

### Pi-hole Access Levels

| Access Method | Port | Who Can Access | Use Case |
|---------------|------|----------------|----------|
| **Local Network** | 53 (DNS) | Host and local devices | DNS queries, ad-blocking |
| **Localhost** | 8081 (Admin) | Direct VM access | Pi-hole administration |
| **Internet** | 53 | Blocked | No public access |

### Benefits of Pi-hole DNS

#### ✅ Privacy & Security
- **Ad-blocking** for all DNS queries
- **No DNS leaks** to tracking services
- **Privacy protection** - all traffic filtered through your Pi-hole
- **Custom blocklists** for enhanced protection

#### ✅ Performance
- **Fast DNS resolution** with caching
- **Low latency** - local DNS server
- **Reliable** - direct connection to VM

### Pi-hole Configuration

The VM's Pi-hole is configured with:
- **DNS Server**: `10.211.55.12` (accessible from local network)
- **External DNS**: Cloudflare (`1.1.1.1`, `1.0.0.1`)
- **Blocking**: Enabled for ad and tracking domains
- **Access**: Local network only

## 📊 Data & Vector Features

### Open WebUI
- **Primary DB**: PostgreSQL (users, chats, settings) via `DATABASE_URL`
- **Vector DB**: Qdrant (embeddings, retrieval) via `QDRANT_URL`
- **Cache**: Redis via `REDIS_URL`
- **LLM Backend**: Ollama via `OLLAMA_BASE_URL`
- **Access**: Only via Nginx at `https://oweb.tu.local`
- **Persistence**: `postgres_data` and `qdrant_data` volumes

### n8n
- **Primary DB**: PostgreSQL schema `n8n` (workflows, credentials, executions)
- **Vector Access**: Workflows can call Qdrant directly using `QDRANT_URL`
- **Access**: Only via Nginx at `https://n8n.tu.local`
- **Persistence**: Data stored in PostgreSQL; n8n home at `n8n_data` volume

### MinIO Object Storage
- **Purpose**: Centralized file storage for all services
- **Access**: Web GUI at `https://minio.tu.local`, API at `https://api.minio.tu.local`
- **Benefits**: Scalable storage, multi-service access, S3-compatible
- **Integration**:
  - **n8n**: Uses S3 (MinIO) natively for binary data (`N8N_BINARY_DATA_MODE=s3`)
  - **Open WebUI**: No native S3 backend today — we transparently mount MinIO to the host via rclone and bind-mount that folder into Open WebUI uploads so it “just works”.
- **Persistence**: `minio_data` volume for all object storage

## 📄 Tika + MinIO PDF Pipeline (Active)

Single-bucket mode is enabled and running via the `tika_minio_processor` container.

### Quick Start
1. Open MinIO Console at `http://localhost:9001` and log in (`admin` / `minio123456`).
2. Upload one or more PDFs into the bucket `tika-pipe`.
3. The processor sends each PDF to Apache Tika and writes back `same-name.txt` into the same bucket.
4. Download the `.txt` from MinIO or import it into Open WebUI.

### Configuration (defaults)
```
TIKA_URL=http://ai_tika:9998
MINIO_ENDPOINT=ai_minio:9000
MINIO_ACCESS_KEY=admin
MINIO_SECRET_KEY=minio123456
UPLOADS_BUCKET=tika-pipe
PROCESSED_BUCKET=tika-pipe
```

Notes:
- Single-bucket means inputs and outputs live in `tika-pipe`.
- Outputs are `same path/same name` with `.txt` extension.
- Only `.pdf` files are processed; `.txt` files are ignored to avoid loops.

### Use with Open WebUI
- Automated (enabled): PDFs uploaded to Open WebUI are synced to MinIO `tika-pipe`, processed by Tika into `.txt`, then `.txt` files are synced back into Open WebUI’s uploads volume for immediate use.
- Script: `scripts/sync-openwebui-minio.sh` performs both forward and reverse sync.
- Behavior:
  - Forward: All non-`.txt` files from Open WebUI volume → `tika-pipe`
  - Reverse: Only `.txt` from `tika-pipe` → Open WebUI volume (PDFs excluded)
  - Idempotent: existing objects are skipped; safe to run repeatedly

### Verify & Troubleshoot
```bash
docker logs tika_minio_processor --tail 50
# Look for: "✅ Stored processed content: <name>.txt" and "✅ Successfully processed: <name>.pdf"

curl -s -o /dev/null -w "%{http_code}\n" http://ai_tika:9998/tika   # expect 200
```

#### Open WebUI ↔ MinIO Sync Strategy
- Open WebUI writes to its internal uploads volume (`docker_openwebui_files`).
- A cron job runs `scripts/sync-openwebui-minio.sh` to:
  1) Upload new files to MinIO bucket `tika-pipe`
  2) Mirror Tika-generated `.txt` back into Open WebUI uploads
- Recommended cron (example, every 2 minutes):
```bash
*/2 * * * * MINIO_SYNC_PASSWORD=minio123456 /home/tu/docker/scripts/sync-openwebui-minio.sh >> /var/log/sync-openwebui-minio.log 2>&1
```

## 💾 Backup & Restore

### Automatic Backups
Backups are created automatically during updates and manually:

```bash
./tu-vm.sh backup
```

### Backup Contents
- **Database**: Full PostgreSQL dump
- **Configuration**: `.env`, `docker-compose.yml`, `nginx/`, `ssl/`
- **Volumes**: PostgreSQL, Redis, Qdrant, Pi-hole data
- **Compressed**: Timestamped `.tar.gz` files

### Restore from Backup
```bash
sudo ./tu-vm.sh restore backups/backup_20250823_143353.tar.gz
```

### Backup Location
```
backups/
├── backup_YYYYMMDD_HHMMSS.tar.gz
└── update_YYYYMMDD_HHMMSS.tar.gz
```

## 🧭 Command Reference (tu-vm.sh)

Use the control script to manage the entire platform. Syntax:

```bash
./tu-vm.sh [COMMAND] [OPTIONS]
```

### Basic Commands
- start: Start all services
- stop: Stop all services
- restart: Restart all services
- status: Show service status
- logs [service]: Show service logs
- access: Show access URLs and information

### Access Control
- secure: Enable secure access (recommended)
- public: Enable public access (less secure)
- lock: Block all external access

### Maintenance
- update: Update system and services
- test-update: Test update process (dry run)
- backup [name]: Create backup (keeps last 2 automatically)
- restore <file>: Restore from a backup file
- cleanup: Clean old backups/logs and prune Docker
- setup-minio: One-time setup of MinIO buckets

### Diagnostics
- health: Check service health
- test: Test all service endpoints
- diagnose: Run comprehensive diagnostics
- info: Show system information

### PDF Processing
- pdf-status: Check Tika/MinIO/processor status and bucket
- pdf-test: Process a sample PDF through the pipeline
- pdf-logs [service]: Logs for tika|minio|processor
- pdf-reset: Reset the Tika-MinIO pipeline

### System
- version: Show script version and information
- help: Show help

### Examples
```bash
./tu-vm.sh start                 # Start services
./tu-vm.sh access                # Show access URLs
./tu-vm.sh backup nightly        # Create named backup (auto-rotate last 2)
./tu-vm.sh pdf-status            # Check PDF pipeline
./tu-vm.sh cleanup               # Enforce backup rotation + prune
./tu-vm.sh version               # Show script version
```

## 🛠️ Installation

### Prerequisites
- **Host OS**: Windows or macOS
- **VM Software**: Parallels Desktop, VirtualBox, etc.
- **VM OS**: Ubuntu Server 22.04+ (latest LTS recommended)
- **RAM**: Minimum 4GB, Recommended 8GB+
- **Storage**: 20GB+ free space
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+

### Network Requirements
- **Ports**: 80, 443 (public/LAN), 53 (DNS) if running Pi-hole for LAN
- **Domain**: Optional (tu.local as default)

### Installation Steps

#### 1. Update OS and Install Docker
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
```

#### 2. Get the Code
```bash
git clone https://github.com/techuties/tu-vm.git
cd tu-vm
```

#### 3. Configure Environment
```bash
cp env.example .env
# Edit .env with your settings
```

#### 4. Start Services
```bash
./tu-vm.sh start
```

#### 5. Enable Secure Access
```bash
sudo ./tu-vm.sh secure
```

## 🔍 Troubleshooting

### Services Not Starting
```bash
./tu-vm.sh status
docker compose logs
```

### Can't Access Services
```bash
sudo ./tu-vm.sh secure
./tu-vm.sh status
```

### Backup/Restore Issues
```bash
./tu-vm.sh backup
sudo ./tu-vm.sh restore backup_file.tar.gz
```

### Docker Compose Validation

If `docker compose` shows a validation error, ensure all service definitions are under the `services:` section and volumes are under `volumes:`. A common mistake is placing service fields (like `build`, `restart`, `environment`) under `volumes:`.

```bash
# Validate and view the fully rendered config
docker compose config
```

### Health Check Notes

- Open WebUI may briefly fail health checks during startup while UI assets load; this resolves automatically.
- Verify directly from inside the container:

```bash
docker exec ai_openwebui curl -sf http://localhost:8080/api/health || echo "ui not ready"
```

## 🚨 Security Considerations

### Before Implementation
- ❌ Services exposed to internet
- ❌ DNS amplification risk
- ❌ Information disclosure
- ❌ No access control
- ❌ Default credentials

### After Implementation
- ✅ Services isolated from internet
- ✅ DNS protected from amplification
- ✅ Information disclosure removed
- ✅ Strong access control
- ✅ Secure credentials
- ✅ Easy on/off switching

## 📚 Documentation

### Quick References
- **Quick Reference**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

### External References
- [Ubuntu Server](https://ubuntu.com/server/docs)
- [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose](https://docs.docker.com/compose/)
- [WireGuard](https://www.wireguard.com/)

## 🎯 Security Objective Verification

### ✅ Achieved Goals
1. **Secure Communication**: Local network access with firewall protection
2. **Internet Isolation**: Services not accessible from internet by default
3. **Easy Control**: Simple commands to switch access modes
4. **Maximum Security**: Secure access by default
5. **Flexibility**: Can enable public access when needed

### 🔒 Security Posture
- **Attack Surface**: Minimized through secure access control
- **Access Control**: Strong firewall-based access control
- **Network Security**: Isolated from internet threats
- **Monitoring**: Easy status checking and control

## 🚨 Smart Monitoring System

### **Dashboard Features**
- **Service Control**: Start/stop buttons for individual services (Open WebUI, n8n, Pi-hole, MinIO)
- **Health Monitoring**: Real-time container status with color-coded indicators
- **Resource Alerts**: CPU, memory, disk usage warnings with laptop-specific guidance
- **Announcements Dropdown**: Centralized alert system with priority-based notifications

### **Daily Monitoring** (9:00 AM Cron Job)
```bash
# Manual execution
./scripts/daily-checkup.sh

# Check status files
cat /tmp/tu-vm-health-status.json    # Container health
cat /tmp/tu-vm-log-status.json       # Log error analysis  
cat /tmp/tu-vm-update-status.json    # Update availability
```

### **Alert Types & Priorities**
| Priority | Color | Examples |
|----------|-------|----------|
| **Critical** | 🔴 Red | Services down, critical errors, low battery |
| **High** | 🟠 Orange | Unhealthy services, memory pressure, firewall disabled |
| **Medium** | 🔵 Blue | Public access enabled, battery mode warnings |
| **Low** | 🟢 Green | System status, power-saving tips |

### **Laptop-Specific Features**
- **Battery Detection**: Automatic power-saving recommendations
- **Resource Optimization**: Prevents crashes on limited hardware
- **Efficient Monitoring**: Daily checks only, no constant resource usage
- **Mobile-Friendly**: Responsive dashboard with touch-friendly controls

## 📄 Document Processing

### PDF Processing Options
The platform supports two powerful PDF processing engines:

#### **Apache Tika (Default - Recommended)**
- 🌐 **Universal** - Handles 1000+ file formats
- 🔍 **Advanced OCR** - Reads scanned documents and images
- 📊 **Table extraction** - Converts tables to structured text
- 🖼️ **Image analysis** - Describes charts, diagrams, and visual content
- 📈 **Layout understanding** - Preserves document structure and formatting
- ✅ **No reshape errors** - Robust handling of all PDF types

#### **PyMuPDF (Alternative)**
- ⚡ **Fast and lightweight** - Optimized for speed
- 🎯 **PDF-focused** - Excellent text extraction
- 💾 **Minimal resources** - Lower memory usage
- 📝 **Text-only** - No image processing capabilities

### Switching PDF Processors
```bash
# Switch to Tika (recommended - full document processing)
./scripts/switch-pdf-loader.sh tika

# Switch to PyMuPDF (fast, text-only)
./scripts/switch-pdf-loader.sh pymupdf

# Check current configuration
./scripts/switch-pdf-loader.sh
```

### Troubleshooting PDF Issues
If you encounter PDF processing errors:
1. **Switch to Tika**: `./scripts/switch-pdf-loader.sh tika`
2. **Check logs**: `docker logs ai_openwebui`
3. **Verify Tika**: `docker logs ai_tika`

## 🎉 Conclusion

The TechUties VM provides a **secure, private AI platform** with:
- **One simple script** for all operations
- **Secure access** by default
- **Easy security control** with three levels
- **Comprehensive backup/restore** system
- **Advanced document processing** with PyMuPDF and Apache Tika
- **Production-ready** architecture

**Perfect for**: Private AI development, secure automation workflows, and isolated AI research environments.

---

**Security Level**: 🔒 **HIGH** - Secure access with easy control  
**Complexity**: 🟢 **LOW** - One script for everything  
**Maintenance**: 🟢 **EASY** - Simple commands and automatic backups 
