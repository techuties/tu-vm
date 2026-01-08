# Changelog

All notable changes to the TechUties VM project will be documented in this file.

## [2.1.0] - 2026-01-08 - Installation Improvements & System Cleanup

### 🔒 Security
- **IP allowlist for sensitive endpoints**: Locked down dashboard control endpoints with an Nginx-managed allowlist and safe defaults.
- **Self-serve allowlist management**: Dashboard can list/add/remove allowlisted IPs and auto-bootstrap the first real client IP.
- **Safer default exposure**: Moved sensitive service ports to **localhost-only** bindings where appropriate (use Nginx vhosts instead).
- **Less stale frontend state**: Added `Cache-Control: no-store` for the landing page and Open WebUI to reduce “stuck UI” issues after updates.

### 🧰 Operations & Reliability
- **Open WebUI healthcheck**: Updated to use `/health/db` for more reliable startup/readiness.
- **Reduced startup stalls**: Prevented Open WebUI from blocking on embedding model downloads during startup (opt-in instead).
- **MinIO tooling fixes**: Standardized MinIO `mc` usage via a helper container for backups and PDF test uploads.

### 🧹 Cleanup
- **Removed temporary Open WebUI shims/debug**: Reverted short-lived compatibility hacks and debug-only settings.
- **Repository hygiene**: Ignored/removed generated/backup artifacts (Nginx backups, dynamic allowlist file, caches) and added a simple Nginx `50x.html`.

---

## [2.0.0] - 2025-10-09 - Energy Optimization Release

### 🚀 Major Features

#### **Energy Optimization System**
- **85% CPU Reduction**: Idle CPU usage reduced from 30% to 4.6%
- **Tiered Service Architecture**: Always-on vs On-demand service management
- **Dashboard Service Controls**: One-click start/stop for individual services
- **Smart Resource Management**: Optimized for laptop battery life

#### **Service Tier System**
- **Tier 1 (Always Running)**: PostgreSQL, Redis, Qdrant, Open WebUI, Tika, Nginx, Pi-hole, Helper API
- **Tier 2 (Dashboard Controlled)**: Ollama, n8n, MinIO - start/stop via dashboard
- **Automatic Service Separation**: Ollama no longer starts by default

#### **Enhanced Dashboard**
- **Service Control Buttons**: Start/Stop buttons for Ollama, n8n, MinIO
- **Real-time Status Indicators**: Live service status with response times
- **Smart Notifications**: Success/error feedback with auto-hide
- **Status Confirmation**: "Starting..." / "Stopping..." button states
- **Resource Monitoring**: Per-service CPU and memory usage display

### ⚡ Performance Improvements

#### **CPU Optimization**
- **Health Check Intervals**: Increased from 30-60s to 180s (3 minutes)
- **Polling Frequency**: MinIO sync reduced from every 2 min to every 15 min
- **Docker Daemon**: Optimized logging (WARN level, 10MB rotation)
- **Resource Limits**: Tuned for battery-friendly operation

#### **Memory Optimization**
- **Ollama**: 4GB → 3GB memory limit
- **n8n**: 1GB → 768MB memory limit
- **Smart Caching**: 60-second state caching in helper API

#### **Battery Life Improvements**
- **Normal Use**: 3-4 hours → 8-10 hours (150% improvement)
- **Workflow Development**: 3-4 hours → 6-7 hours (75% improvement)
- **AI Work**: 2 hours → 2.5 hours (25% improvement)

### 🔧 Technical Changes

#### **Docker Compose Updates**
- **Service Restart Policies**: Tier 2 services set to manual start only
- **Health Check Optimization**: Disabled for on-demand services
- **Resource Limit Tuning**: Optimized for energy efficiency
- **Environment Variables**: Added CONTROL_TOKEN for dashboard authentication

#### **Dashboard Enhancements**
- **Control API Integration**: Full start/stop functionality via REST API
- **Status Endpoints**: Individual service health monitoring
- **Notification System**: Toast notifications with success/error states
- **Polling Logic**: Smart status verification with timeout handling

#### **Cron Job Optimization**
- **MinIO Sync**: Reduced frequency with runtime checks
- **Conditional Execution**: Skip sync when MinIO container stopped
- **Smart Polling**: Only check running containers

### 🛠️ Configuration Changes

#### **Docker Daemon**
```json
{
  "log-level": "warn",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": false,
  "shutdown-timeout": 30
}
```

#### **Service Resource Limits**
- **Ollama**: 3GB memory, 1.5 CPU (reduced from 4GB/2.0)
- **n8n**: 768MB memory, 0.4 CPU (reduced from 1GB/0.5)
- **Tier 1 Services**: Maintained existing limits for stability

#### **Health Check Intervals**
- **Tier 1 Services**: 180s intervals (PostgreSQL, Redis, Open WebUI, Tika, Nginx, Pi-hole)
- **Tier 2 Services**: Health checks disabled (Ollama, n8n, MinIO)

### 📱 User Experience Improvements

#### **Dashboard Interface**
- **Visual Status Indicators**: Color-coded service status (Green: Running, Red: Stopped)
- **Button State Management**: Disabled states during operations
- **Progress Feedback**: "Starting..." / "Stopping..." button text
- **Response Time Display**: Shows actual service response times

#### **Service Management**
- **One-Click Control**: Start/stop services without SSH access
- **Status Confirmation**: Clear feedback on operation success/failure
- **Automatic Refresh**: Dashboard updates when services change state
- **Error Handling**: Detailed error messages for troubleshooting

#### **Energy Awareness**
- **Battery-Friendly Defaults**: Services start only when needed
- **Resource Usage Display**: Clear indication of CPU/memory usage
- **Smart Recommendations**: Dashboard suggests stopping heavy services

### 🔒 Security Enhancements

#### **Authentication**
- **Control Token**: Secure authentication for service control API
- **Token Management**: Automatic token setup in dashboard
- **API Security**: Protected service control endpoints

#### **Access Control**
- **Service Isolation**: Tier 2 services only accessible when running
- **Network Security**: Maintained existing security posture
- **Firewall Protection**: No changes to access control system

### 📊 Monitoring & Observability

#### **Enhanced Status Monitoring**
- **Real-time Status**: Live service health monitoring
- **Resource Tracking**: CPU and memory usage per service
- **Response Time Monitoring**: Service performance metrics
- **Activity Logging**: Service start/stop events

#### **Smart Notifications**
- **Success Notifications**: "Service started successfully"
- **Error Notifications**: "Failed to start service: [reason]"
- **Progress Updates**: "Service starting..." → "Service started"
- **Auto-hide**: Notifications disappear after 3 seconds

### 🐛 Bug Fixes

- **Authentication Issues**: Fixed dashboard control token authentication
- **Status Detection**: Improved service status detection accuracy
- **Button States**: Fixed button state management during operations
- **Error Handling**: Enhanced error message clarity and specificity

### 🔄 Migration Notes

#### **Breaking Changes**
- **Ollama Default State**: No longer starts automatically (manual start required)
- **Service Dependencies**: Open WebUI works without AI backend
- **Dashboard Access**: New service control interface

#### **Backward Compatibility**
- **All Features Available**: No functionality lost, just moved to on-demand
- **Easy Rollback**: Can restore previous behavior via backup
- **Gradual Migration**: Services can be started individually as needed

### 📈 Performance Metrics

#### **Before Optimization**
- **CPU Usage**: 30%+ at idle
- **Load Average**: 4.20 (1 minute)
- **Memory Usage**: 2.8GB
- **Battery Life**: 3-4 hours (normal use)

#### **After Optimization**
- **CPU Usage**: 4.6% at idle (85% reduction)
- **Load Average**: 1.17 (72% reduction)
- **Memory Usage**: 2.1GB (25% reduction)
- **Battery Life**: 8-10 hours (150% improvement)

### 🎯 Success Criteria Met

- ✅ **CPU at idle < 5%** (achieved: 4.6%)
- ✅ **Load average < 1.5** (achieved: 1.17)
- ✅ **Laptop fan silent** during normal operations
- ✅ **Services start within 20 seconds** from dashboard
- ✅ **No functional regressions** - all features available when services started
- ✅ **Battery life 2x improvement** for normal use

### 🔮 Future Enhancements

#### **Planned Features**
- **Quick Action Profiles**: Work Mode, AI Mode, Full Storage, Energy Save
- **Battery Status Integration**: Laptop battery level display
- **Auto-stop for Inactive Services**: Optional idle timeout
- **Resource Usage History**: CPU/memory usage charts
- **Smart Startup Optimization**: Quick-start command for Tier 1 only

#### **Potential Improvements**
- **Service Dependencies**: Auto-start dependencies when needed
- **Usage Analytics**: Service usage patterns and recommendations
- **Power Management**: Advanced battery optimization features
- **Mobile Optimization**: Enhanced mobile dashboard experience

---

## [1.0.0] - 2025-08-23 - Initial Release

### 🚀 Initial Features
- Complete AI platform with Open WebUI, n8n, Ollama
- Document processing with Apache Tika
- MinIO object storage with S3 compatibility
- PostgreSQL database with Qdrant vector storage
- Redis caching layer
- Pi-hole DNS ad-blocking
- Nginx reverse proxy with SSL/TLS
- Comprehensive monitoring and backup system
- Security-first access control
- One-command management via tu-vm.sh

### 🔒 Security Features
- Three-level access control (Secure/Public/Locked)
- Firewall-based network protection
- TLS encryption with strong cipher suites
- Container network isolation
- Secure credential management

### 📊 Monitoring System
- Daily health checks with proactive issue detection
- Real-time dashboard with service status
- Resource monitoring with laptop-specific optimizations
- Smart announcements system with priority-based alerts
- Battery-aware recommendations

### 🛠️ Operational Features
- Automated backup and restore system
- Update management with safety backups
- PDF processing pipeline with Tika-MinIO integration
- Service control and diagnostics
- Comprehensive logging and troubleshooting

---

*For detailed installation and usage instructions, see [README.md](README.md)*