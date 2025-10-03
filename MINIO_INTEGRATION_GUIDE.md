# MinIO Integration Guide
## TechUties AI Platform - Object Storage Integration

### 🎯 **Overview**
This guide shows how to integrate MinIO object storage with Open WebUI and n8n, and set up automatic file processing with Apache Tika.

---

## 🔗 **1. Open WebUI + MinIO Integration**

### **Configuration Added**
The following environment variables have been added to Open WebUI:

```yaml
# MinIO Object Storage Integration
S3_ENDPOINT_URL: "http://ai_minio:9000"
S3_ACCESS_KEY_ID: "admin"
S3_SECRET_ACCESS_KEY: "${MINIO_ROOT_PASSWORD:-minio123456}"
S3_BUCKET_NAME: "openwebui-files"
S3_REGION: "us-east-1"
```

### **How It Works**
- **File Storage**: Open WebUI will store uploaded files in MinIO
- **S3 Compatible**: Uses S3-compatible API for seamless integration
- **Automatic Processing**: Files are processed by Tika before storage
- **Scalable**: MinIO provides unlimited storage capacity

### **Benefits**
- ✅ **Centralized Storage**: All files in one place
- ✅ **Scalable**: No local disk space limitations
- ✅ **Backup Ready**: Easy to backup and restore
- ✅ **Multi-Service Access**: n8n can access the same files

---

## 🔗 **2. n8n + MinIO Integration**

### **Setup n8n MinIO Connection**

1. **Access n8n**: Go to `https://n8n.tu.local`
2. **Create Credential**:
   - Go to Settings → Credentials
   - Add "MinIO" credential
   - **Endpoint**: `http://ai_minio:9000`
   - **Access Key**: `admin`
   - **Secret Key**: `minio123456` (or your generated password)
   - **Region**: `us-east-1`

3. **Create Workflow**:
   ```javascript
   // Example: File Processing Workflow
   {
     "nodes": [
       {
         "name": "MinIO Trigger",
         "type": "n8n-nodes-base.minio",
         "parameters": {
           "operation": "list",
           "bucketName": "openwebui-files"
         }
       },
       {
         "name": "Process with Tika",
         "type": "n8n-nodes-base.httpRequest",
         "parameters": {
           "url": "http://ai_tika:9998/tika",
           "method": "POST",
           "body": "={{ $json.fileContent }}"
         }
       }
     ]
   }
   ```

### **n8n MinIO Nodes Available**
- **List Files**: Get all files from a bucket
- **Download File**: Retrieve file content
- **Upload File**: Store new files
- **Delete File**: Remove files
- **Create Bucket**: Create new storage buckets

---

## 🔗 **3. Automatic File Processing with Tika**

### **Tika Integration Points**

#### **Open WebUI → Tika → MinIO Flow**
1. **User uploads file** to Open WebUI
2. **Tika processes file** (OCR, text extraction, metadata)
3. **Processed content** stored in MinIO
4. **Original file** also stored in MinIO
5. **Searchable content** indexed in Qdrant

#### **n8n → Tika → MinIO Flow**
1. **n8n workflow** triggers on file upload
2. **Tika processes** the file automatically
3. **Results stored** in MinIO
4. **Notifications sent** via webhook/email

### **Tika Processing Capabilities**
- ✅ **PDF Processing**: Text extraction, OCR, image extraction
- ✅ **Office Documents**: Word, Excel, PowerPoint
- ✅ **Images**: OCR, metadata extraction
- ✅ **Archives**: ZIP, TAR, RAR extraction
- ✅ **Audio/Video**: Metadata extraction
- ✅ **1000+ Formats**: Universal content analysis

---

## 🔗 **4. Workflow Examples**

### **Example 1: Document Processing Pipeline**

```yaml
# n8n Workflow: Auto Document Processing
Trigger: File uploaded to MinIO
↓
Process: Send to Tika for analysis
↓
Extract: Text, metadata, images
↓
Store: Results in MinIO
↓
Index: Content in Qdrant for search
↓
Notify: Send processing results
```

### **Example 2: Open WebUI File Enhancement**

```yaml
# Open WebUI Integration
User uploads PDF
↓
Tika extracts text and images
↓
Content stored in MinIO
↓
Searchable in Open WebUI
↓
Available to n8n workflows
```

---

## 🔗 **5. MinIO Bucket Structure**

### **Recommended Bucket Organization**

```
openwebui-files/
├── uploads/           # Original uploaded files
├── processed/         # Tika-processed content
├── thumbnails/       # Generated thumbnails
└── metadata/         # Extracted metadata

n8n-workflows/
├── inputs/           # Workflow input files
├── outputs/          # Workflow results
└── temp/            # Temporary processing files

shared-documents/
├── company/         # Shared company documents
├── templates/       # Document templates
└── archives/        # Archived documents
```

---

## 🔗 **6. API Integration Examples**

### **Python Script Example**

```python
import boto3
import requests

# MinIO Client
s3_client = boto3.client(
    's3',
    endpoint_url='http://ai_minio:9000',
    aws_access_key_id='admin',
    aws_secret_access_key='minio123456'
)

# Upload file to MinIO
s3_client.upload_file('document.pdf', 'openwebui-files', 'document.pdf')

# Process with Tika
with open('document.pdf', 'rb') as f:
    response = requests.post('http://ai_tika:9998/tika', data=f)
    extracted_text = response.text

# Store processed content
s3_client.put_object(
    Bucket='openwebui-files',
    Key='processed/document.txt',
    Body=extracted_text
)
```

### **n8n HTTP Request Example**

```javascript
// n8n HTTP Request Node
{
  "url": "http://ai_tika:9998/tika",
  "method": "POST",
  "headers": {
    "Content-Type": "application/octet-stream"
  },
  "body": "={{ $json.fileContent }}"
}
```

---

## 🔗 **7. Monitoring & Health Checks**

### **Service Health**
- **MinIO**: `https://minio.tu.local` (Console)
- **Tika**: `http://ai_tika:9998/tika` (API)
- **Dashboard**: All services monitored in real-time

### **Health Check Endpoints**
- **MinIO API**: `https://api.minio.tu.local`
- **Tika Health**: `http://ai_tika:9998/tika`
- **Integration Status**: Dashboard shows all connections

---

## 🔗 **8. Security & Access Control**

### **MinIO Access Control**
- **Admin Access**: Full control over all buckets
- **Service Access**: Open WebUI and n8n have dedicated access
- **Bucket Policies**: Configure per-bucket permissions
- **SSL/TLS**: All communication encrypted

### **File Security**
- **Encryption**: Files encrypted at rest
- **Access Logs**: All access logged
- **Backup**: Regular backups to external storage
- **Retention**: Configurable file retention policies

---

## 🚀 **Getting Started**

### **Step 1: Restart Services**
```bash
./tu-vm.sh restart
```

### **Step 2: Create Buckets**
1. Go to `https://minio.tu.local`
2. Login with admin credentials
3. Create buckets:
   - `openwebui-files`
   - `n8n-workflows`
   - `shared-documents`

### **Step 3: Test Integration**
1. Upload a file to Open WebUI
2. Check MinIO console for the file
3. Verify Tika processing works
4. Test n8n workflows

### **Step 4: Configure n8n**
1. Add MinIO credentials in n8n
2. Create test workflows
3. Set up file processing automation

---

## 📚 **Additional Resources**

- **MinIO Documentation**: https://docs.min.io
- **Tika Documentation**: https://tika.apache.org
- **n8n MinIO Node**: https://docs.n8n.io/integrations/builtin/cluster-nodes/n8n-nodes-base.minio/
- **Open WebUI S3**: https://docs.openwebui.com/configuration/environment-variables

---

*This integration provides a complete file processing pipeline with MinIO storage, Tika analysis, and n8n automation!* 🎉
