# Open WebUI AI Platform - Version Differences

## Current Version vs GitHub Baseline

### Key Differences from Standard Open WebUI

#### 🔧 **PDF Processing Enhancement**
- **Added**: Apache Tika server integration (`ai_tika` service)
- **Changed**: PDF loader switched from `PyPDFLoader` to `TikaLoader`
- **Added**: Environment variables for Tika configuration:
  - `PDF_LOADER: "TikaLoader"`
  - `PDF_EXTRACT_IMAGES: "true"`
  - `TIKA_SERVER_URL: "http://ai_tika:9998"`

#### 📁 **Object Storage Integration**
- **Added**: MinIO S3-compatible object storage (`ai_minio` service)
- **Added**: MinIO web console at `https://minio.tu.local`
- **Added**: MinIO API at `https://minio.tu.local/api`
- **Added**: Centralized file storage for all services

#### 📁 **New Files Added**
- `scripts/switch-pdf-loader.sh` - PDF processor management utility
- `update-log.md` - This version tracking document
- `PDF-PROCESSING-ANALYSIS.md` - Technical analysis document

#### 🐳 **Docker Compose Changes**
- **Added**: `tika` service definition with Apache Tika server
- **Modified**: `open-webui` service with Tika environment variables
- **Network**: Tika service integrated into `ai_network`

#### 🗄️ **Database Configuration**
- **Set**: `rag.file.pdf_loader` to `"TikaLoader"`
- **Set**: `rag.file.pdf_extract_images` to `true`
- **Set**: `TIKA_SERVER_URL` to `"http://ai_tika:9998"`

#### 🎛️ **Dashboard Enhancements**
- **Added**: Tika health check to VM ACCESS section
- **Added**: MinIO health check to VM ACCESS section
- **Added**: Real-time service monitoring for all components

### Benefits of These Changes
- ✅ **Robust PDF Processing**: No more "reshape array" errors
- ✅ **Full Document Analysis**: OCR, image extraction, table parsing
- ✅ **Universal Format Support**: 1000+ file formats via Tika
- ✅ **Centralized Storage**: MinIO for scalable file management
- ✅ **Multi-Service Access**: All services can access stored files
- ✅ **Easy Management**: Simple switching between processors
- ✅ **Future-Proof**: Handles any document type

### Technical Impact
- **PDF Processing**: Now uses Apache Tika instead of PyPDF
- **Image Extraction**: Enhanced with Tika's robust image processing
- **Document Analysis**: Full OCR and content extraction capabilities
- **Object Storage**: MinIO provides S3-compatible centralized storage
- **File Management**: All services can access and share files
- **Error Handling**: Eliminates reshape errors from problematic PDFs

---
*Last Updated: 2025-10-02*
*Status: ✅ Production Ready - All Features Working*