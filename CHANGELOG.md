# Changelog

All notable changes to the TechUties AI Platform are documented in this file.

## [2.0.0] - 2025-10-09

### 🚨 Added - Smart Monitoring System
- **Daily health checks** (9 AM cron job) for container health monitoring
- **Log error analysis** with critical vs warning error categorization
- **Resource pressure alerts** for CPU, memory, and disk usage
- **Battery detection** with laptop-specific power-saving recommendations
- **Security monitoring** for firewall status and access control
- **Service control buttons** for individual container start/stop operations

### 🎯 Added - Intelligent Announcements System
- **Color-coded alerts** (Red: critical, Orange: warning, Blue: info, Green: updates)
- **Priority-based notifications** with actionable guidance
- **Badge indicators** for new announcement visibility
- **Dropdown interface** with responsive design for mobile devices

### 🔧 Enhanced - Update Detection
- **Pull-free Docker image updates** using `docker buildx imagetools inspect`
- **Cached update status** with 24-hour refresh cycle
- **Detailed update information** including outdated image digests

### 🛡️ Enhanced - Security Features
- **Authentication token system** for service control endpoints
- **Docker socket integration** for secure container management
- **Access control monitoring** with firewall status alerts
- **SSL certificate monitoring** for security compliance

### 📱 Enhanced - Mobile Optimizations
- **Battery-aware recommendations** for laptop usage
- **Resource limit warnings** to prevent crashes
- **Touch-friendly interface** with responsive design
- **Power-saving tips** integrated into announcements

### 🔄 Improved - Container Management
- **Individual service control** via dashboard buttons
- **Health status monitoring** with restart count tracking
- **Service dependency management** with proper startup sequences
- **Container network isolation** with enhanced security

### 📊 Enhanced - Dashboard Interface
- **Real-time status updates** with automatic refresh
- **Service health indicators** with color-coded badges
- **Announcements dropdown** with priority-based styling
- **Mobile-responsive design** for laptop and tablet usage

### 🗂️ Added - Status Files
- `/tmp/tu-vm-health-status.json` - Container health data
- `/tmp/tu-vm-log-status.json` - Log error analysis
- `/tmp/tu-vm-update-status.json` - Update availability status

### 🧰 Enhanced - Operational Scripts
- **`scripts/daily-checkup.sh`** - Comprehensive daily monitoring
- **Enhanced cron integration** with automatic job installation
- **Improved logging** with detailed status reporting
- **Error handling** with graceful failure recovery

### 🔧 Technical Improvements
- **Docker API integration** for programmatic container control
- **System resource monitoring** with `/proc` and `/sys` interfaces
- **JSON status persistence** for monitoring data storage
- **Flask API enhancements** with new endpoints and error handling

---

## [1.0.0] - Initial Release
- Basic AI platform with Open WebUI, n8n, Ollama, PostgreSQL, Redis, Qdrant
- Apache Tika document processing with MinIO integration
- Pi-hole DNS filtering and Nginx reverse proxy
- Security access control with UFW firewall
- Backup and restore functionality
- Mobile-optimized configuration
