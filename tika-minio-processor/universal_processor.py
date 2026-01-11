#!/usr/bin/env python3
"""
Universal MinIO File Processing Pipeline
Handles any file type with appropriate processing:
- PDFs: Tika with OCR
- Office docs: Tika (Word, Excel, PowerPoint)
- Images: Tika OCR + metadata
- Text files: Direct extraction
- Archives: Extraction + recursive processing
- Audio/Video: Metadata extraction (transcription can be added)
"""

import os
import time
import json
import logging
import requests
import boto3
import mimetypes
import zipfile
import tarfile
import io
from pathlib import Path
import socket
from typing import Optional, Dict, Any, List, Tuple
from urllib.parse import quote
from datetime import datetime
from botocore.exceptions import ClientError

# Status file location (shared with helper API)
STATUS_FILE = '/tmp/tika-processing-status.json'

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Supported file extensions and their processing methods
SUPPORTED_EXTENSIONS = {
    # Documents
    '.pdf': 'tika',
    '.doc': 'tika',
    '.docx': 'tika',
    '.xls': 'tika',
    '.xlsx': 'tika',
    '.ppt': 'tika',
    '.pptx': 'tika',
    '.odt': 'tika',
    '.ods': 'tika',
    '.odp': 'tika',
    '.rtf': 'tika',
    '.epub': 'tika',
    '.mobi': 'tika',
    
    # Text files
    '.txt': 'text',
    '.md': 'text',
    '.csv': 'text',
    '.json': 'text',
    '.xml': 'text',
    '.html': 'text',
    '.htm': 'text',
    '.log': 'text',
    
    # Images (OCR + metadata)
    '.jpg': 'tika',
    '.jpeg': 'tika',
    '.png': 'tika',
    '.gif': 'tika',
    '.bmp': 'tika',
    '.tiff': 'tika',
    '.tif': 'tika',
    '.webp': 'tika',
    
    # Archives
    '.zip': 'archive',
    '.tar': 'archive',
    '.tar.gz': 'archive',
    '.tgz': 'archive',
    '.gz': 'archive',
    '.rar': 'archive',
    '.7z': 'archive',
}

# Skip these extensions (already processed or not processable)
SKIP_EXTENSIONS = {
    '.txt',  # Already processed output
    '.processed',  # Status files
    '.lock',  # Lock files
    '.tmp',  # Temporary files
    '.swp',  # Swap files
}


class UniversalMinIOProcessor:
    """Universal file processor for MinIO with support for multiple file types"""
    
    def __init__(self,
                 tika_url: Optional[str] = None,
                 minio_endpoint: Optional[str] = None,
                 minio_access_key: Optional[str] = None,
                 minio_secret_key: Optional[str] = None,
                 uploads_bucket: Optional[str] = None,
                 processed_bucket: Optional[str] = None,
                 max_retries: int = 3,
                 retry_delay: int = 5):
        
        # Resolve configuration from function args or environment variables
        self.tika_url = tika_url or os.getenv("TIKA_URL", "http://ai_tika:9998")
        minio_endpoint = minio_endpoint or os.getenv("MINIO_ENDPOINT", "ai_minio:9000")
        minio_access_key = minio_access_key or os.getenv("MINIO_ACCESS_KEY", "admin")
        minio_secret_key = minio_secret_key or os.getenv("MINIO_SECRET_KEY", "minio123456")
        self.uploads_bucket = uploads_bucket or os.getenv("UPLOADS_BUCKET", "tika-pipe")
        self.processed_bucket = processed_bucket or os.getenv("PROCESSED_BUCKET", "tika-pipe")
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        
        # Normalize endpoint URL - resolve hostname to IP for boto3 compatibility
        # boto3 validates endpoint URLs and doesn't accept hostnames with underscores
        raw = minio_endpoint
        if raw.startswith("http://") or raw.startswith("https://"):
            raw = raw.split("://", 1)[1]
        host_port = raw
        if ':' in host_port:
            host, port = host_port.split(':', 1)
        else:
            host, port = host_port, '9000'
        
        # Resolve hostname to IP (required for boto3 endpoint validation)
        # Try multiple resolution methods for Docker network compatibility
        resolved_ip = None
        try:
            # Method 1: Standard DNS resolution
            resolved_ip = socket.gethostbyname(host)
            logger.debug(f"Resolved MinIO endpoint: {host} -> {resolved_ip}:{port}")
        except (socket.gaierror, OSError):
            # Method 2: Try with .local suffix (mDNS)
            try:
                resolved_ip = socket.gethostbyname(f"{host}.local")
                logger.debug(f"Resolved MinIO endpoint via .local: {host} -> {resolved_ip}:{port}")
            except (socket.gaierror, OSError):
                # Method 3: Use known Docker network IP (from docker-compose.yml)
                if host == 'ai_minio':
                    resolved_ip = '172.20.0.21'  # Static IP from docker-compose
                    logger.info(f"Using static IP for MinIO: {resolved_ip}:{port}")
                else:
                    raise
        
        if resolved_ip:
            endpoint_url = f"http://{resolved_ip}:{port}"
        else:
            # Fallback: use hostname (may fail with boto3 validation)
            endpoint_url = f"http://{host}:{port}"
            logger.warning(f"⚠️ Using hostname directly (may cause boto3 validation issues): {endpoint_url}")

        # Initialize MinIO client
        self.s3_client = boto3.client(
            's3',
            endpoint_url=endpoint_url,
            aws_access_key_id=minio_access_key,
            aws_secret_access_key=minio_secret_key,
            region_name='us-east-1',
            use_ssl=endpoint_url.startswith("https")
        )
        
        # Ensure buckets exist
        self._ensure_buckets_exist()
        
        # Health check
        self._check_tika_health()
        
        # Initialize status tracking
        self._update_status(processing=False, current_file=None, progress=0, status='idle')
    
    def _ensure_buckets_exist(self):
        """Create buckets if they don't exist"""
        for bucket in [self.uploads_bucket, self.processed_bucket]:
            try:
                self.s3_client.head_bucket(Bucket=bucket)
                logger.info(f"✅ Bucket '{bucket}' exists")
            except ClientError:
                try:
                    self.s3_client.create_bucket(Bucket=bucket)
                    logger.info(f"✅ Created bucket '{bucket}'")
                except ClientError as e:
                    logger.error(f"❌ Failed to create bucket '{bucket}': {e}")
            except Exception as e:
                logger.warning(f"⚠️ Unexpected error checking bucket '{bucket}': {e}")
    
    def _check_tika_health(self):
        """Check if Tika service is available"""
        try:
            response = requests.get(f"{self.tika_url}/tika", timeout=5)
            if response.status_code == 200:
                logger.info("✅ Tika service is available")
                return True
            else:
                logger.warning(f"⚠️ Tika service returned status {response.status_code}")
                return False
        except Exception as e:
            logger.warning(f"⚠️ Tika service health check failed: {e}")
            return False
    
    def _update_status(self, processing: bool = False, current_file: Optional[str] = None, 
                       progress: int = 0, status: str = 'idle', error: Optional[str] = None):
        """Update processing status file for dashboard notifications (atomic write)"""
        try:
            status_data = {
                'processing': processing,
                'current_file': current_file,
                'progress': max(0, min(100, progress)),  # Clamp progress to 0-100
                'status': status,
                'error': error,
                'last_update': datetime.now().isoformat()
            }
            # Atomic write: write to temp file first, then rename
            temp_file = f"{STATUS_FILE}.tmp"
            with open(temp_file, 'w') as f:
                json.dump(status_data, f, indent=2)
            os.replace(temp_file, STATUS_FILE)  # Atomic on most filesystems
        except (IOError, OSError, json.JSONEncodeError) as e:
            logger.warning(f"⚠️ Failed to update status file: {e}")
        except Exception as e:
            logger.warning(f"⚠️ Unexpected error updating status file: {e}")
    
    def _get_file_type(self, filename: str) -> Tuple[str, Optional[str]]:
        """Determine file type and processing method"""
        path = Path(filename.lower())
        
        # Check for skip extensions
        if path.suffix in SKIP_EXTENSIONS:
            return 'skip', None
        
        # Check for known extensions
        for ext in sorted(SUPPORTED_EXTENSIONS.keys(), key=len, reverse=True):
            if filename.lower().endswith(ext):
                return SUPPORTED_EXTENSIONS[ext], ext
        
        # Try to guess from MIME type
        mime_type, _ = mimetypes.guess_type(filename)
        if mime_type:
            if mime_type.startswith('text/'):
                return 'text', path.suffix
            elif mime_type.startswith('image/'):
                return 'tika', path.suffix
            elif mime_type in ['application/pdf', 'application/msword', 
                               'application/vnd.openxmlformats-officedocument']:
                return 'tika', path.suffix
        
        # Unknown type - try Tika as fallback
        logger.warning(f"⚠️ Unknown file type for {filename}, attempting Tika processing")
        return 'tika', path.suffix
    
    def _process_with_tika(self, file_content: bytes, filename: str, 
                          content_type: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Process file using Tika service"""
        try:
            # Determine content type
            if not content_type:
                mime_type, _ = mimetypes.guess_type(filename)
                content_type = mime_type or 'application/octet-stream'
            
            logger.info(f"🔄 Processing with Tika: {filename} ({content_type})")
            
            # Update status: processing started
            self._update_status(processing=True, current_file=filename, progress=10, status='processing')
            
            # Determine if OCR should be enabled (for PDFs and images)
            enable_ocr = False
            ocr_strategy = None
            if content_type == 'application/pdf':
                enable_ocr = True
                ocr_strategy = 'ocr_and_text_extraction'
            elif content_type.startswith('image/'):
                enable_ocr = True
                ocr_strategy = 'ocr_and_text_extraction'
            
            # Prepare headers
            headers = {
                'Content-Type': content_type,
                'Accept': 'text/plain'
            }
            if enable_ocr and ocr_strategy:
                headers['X-Tika-PDFOcrStrategy'] = ocr_strategy
                # Set Tika timeout to 15 minutes (900000 ms) - matches server config
                headers['X-Tika-Timeout-Millis'] = '900000'
            
            # Process with retries
            # Use longer timeout for OCR (15 minutes) to match Tika's server timeout setting
            request_timeout = 900 if enable_ocr else 60
            for attempt in range(self.max_retries):
                try:
                    # Update status: sending to Tika
                    self._update_status(processing=True, current_file=filename, progress=30, 
                                      status=f'processing (attempt {attempt + 1}/{self.max_retries})')
                    
                    response = requests.put(
                        f"{self.tika_url}/tika",
                        data=file_content,
                        headers=headers,
                        timeout=request_timeout
                    )
                    
                    if response.status_code == 200:
                        # Update status: text extraction complete, getting metadata
                        self._update_status(processing=True, current_file=filename, progress=70, 
                                          status='extracting metadata')
                        
                        text_content = response.text.strip()
                        
                        # Get metadata
                        metadata = {}
                        try:
                            metadata_headers = {'Content-Type': content_type}
                            if enable_ocr:
                                # Use longer timeout for metadata extraction with OCR (15 minutes max)
                                metadata_headers['X-Tika-Timeout-Millis'] = '900000'
                            metadata_response = requests.put(
                                f"{self.tika_url}/meta",
                                data=file_content,
                                headers=metadata_headers,
                                timeout=900 if enable_ocr else 30
                            )
                            if metadata_response.status_code == 200:
                                metadata = metadata_response.json()
                        except Exception as e:
                            logger.warning(f"⚠️ Could not fetch metadata: {e}")
                        
                        # Check for empty content
                        if not text_content or len(text_content) < 10:
                            if enable_ocr:
                                text_content = f"[No extractable text found. OCR was attempted but may require better image quality or different language support.]"
                            else:
                                text_content = f"[No extractable text content found in {Path(filename).suffix} file.]"
                        
                        # Update status: processing complete
                        self._update_status(processing=True, current_file=filename, progress=90, 
                                          status='finalizing')
                        
                        return {
                            'text': text_content,
                            'metadata': metadata,
                            'status': 'success',
                            'filename': filename,
                            'content_type': content_type,
                            'processing_method': 'tika',
                            'ocr_used': enable_ocr
                        }
                    else:
                        error_msg = f"Tika returned status {response.status_code}"
                        logger.warning(f"⚠️ {error_msg} (attempt {attempt + 1}/{self.max_retries})")
                        if attempt < self.max_retries - 1:
                            # Update status with retry info
                            self._update_status(processing=True, current_file=filename, 
                                              progress=30 + (attempt * 5), 
                                              status=f'retrying after error (attempt {attempt + 1}/{self.max_retries})')
                            time.sleep(self.retry_delay)
                            continue
                        # Final attempt failed
                        self._update_status(processing=False, current_file=None, progress=0,
                                          status='idle', error=f"{error_msg} after {self.max_retries} attempts")
                        return None
                        
                except requests.Timeout:
                    error_msg = f"Tika timeout after {request_timeout}s"
                    logger.warning(f"⚠️ {error_msg} (attempt {attempt + 1}/{self.max_retries})")
                    if attempt < self.max_retries - 1:
                        # Update status with retry info
                        self._update_status(processing=True, current_file=filename,
                                          progress=30 + (attempt * 5),
                                          status=f'retrying after timeout (attempt {attempt + 1}/{self.max_retries})')
                        time.sleep(self.retry_delay)
                        continue
                    # Final attempt failed
                    self._update_status(processing=False, current_file=None, progress=0,
                                      status='idle', error=f"{error_msg} after {self.max_retries} attempts")
                    return None
                except (requests.RequestException, ConnectionError) as e:
                    error_msg = f"Connection error: {str(e)}"
                    logger.error(f"❌ {error_msg}")
                    if attempt < self.max_retries - 1:
                        # Update status with retry info
                        self._update_status(processing=True, current_file=filename,
                                          progress=30 + (attempt * 5),
                                          status=f'retrying after connection error (attempt {attempt + 1}/{self.max_retries})')
                        time.sleep(self.retry_delay)
                        continue
                    # Final attempt failed
                    self._update_status(processing=False, current_file=None, progress=0,
                                      status='idle', error=f"{error_msg} after {self.max_retries} attempts")
                    return None
                except Exception as e:
                    error_msg = f"Unexpected error: {str(e)}"
                    logger.error(f"❌ {error_msg}")
                    if attempt < self.max_retries - 1:
                        self._update_status(processing=True, current_file=filename,
                                          progress=30 + (attempt * 5),
                                          status=f'retrying after error (attempt {attempt + 1}/{self.max_retries})')
                        time.sleep(self.retry_delay)
                        continue
                    # Final attempt failed
                    self._update_status(processing=False, current_file=None, progress=0,
                                      status='idle', error=f"{error_msg} after {self.max_retries} attempts")
                    return None
            
            return None
                
        except Exception as e:
            error_msg = f"Error processing file with Tika: {str(e)}"
            logger.error(f"❌ {error_msg}")
            self._update_status(processing=False, current_file=None, progress=0,
                              status='idle', error=error_msg)
            return None
    
    def _process_text_file(self, file_content: bytes, filename: str) -> Optional[Dict[str, Any]]:
        """Process plain text file"""
        try:
            logger.info(f"🔄 Processing text file: {filename}")
            
            # Try to decode as UTF-8, fallback to latin-1, then replace errors
            try:
                text_content = file_content.decode('utf-8')
            except UnicodeDecodeError:
                try:
                    text_content = file_content.decode('latin-1')
                except UnicodeDecodeError:
                    text_content = file_content.decode('utf-8', errors='replace')
            
            return {
                'text': text_content.strip(),
                'metadata': {
                    'Content-Type': 'text/plain',
                    'encoding': 'utf-8'
                },
                'status': 'success',
                'filename': filename,
                'processing_method': 'text'
            }
        except Exception as e:
            logger.error(f"❌ Error processing text file: {e}")
            return None
    
    def _process_archive(self, file_content: bytes, filename: str) -> Optional[Dict[str, Any]]:
        """Extract and process archive files"""
        try:
            logger.info(f"🔄 Processing archive: {filename}")
            
            extracted_files = []
            all_text = []
            
            # Determine archive type
            path = Path(filename.lower())
            if path.suffix == '.zip':
                with zipfile.ZipFile(io.BytesIO(file_content)) as zip_ref:
                    for member in zip_ref.namelist():
                        if not member.endswith('/'):  # Skip directories
                            try:
                                content = zip_ref.read(member)
                                extracted_files.append({
                                    'name': member,
                                    'size': len(content)
                                })
                                # Try to extract text if it's a text file
                                if any(member.lower().endswith(ext) for ext in ['.txt', '.md', '.csv', '.json', '.xml']):
                                    try:
                                        text = content.decode('utf-8')
                                        all_text.append(f"=== {member} ===\n{text}\n")
                                    except (UnicodeDecodeError, AttributeError):
                                        # Skip files that can't be decoded as text
                                        pass
                            except Exception as e:
                                logger.warning(f"⚠️ Could not extract {member}: {e}")
            
            elif path.suffix in ['.tar', '.tar.gz', '.tgz']:
                mode = 'r:gz' if path.suffix in ['.tar.gz', '.tgz'] else 'r'
                with tarfile.open(fileobj=io.BytesIO(file_content), mode=mode) as tar_ref:
                    for member in tar_ref.getmembers():
                        if member.isfile():
                            try:
                                content = tar_ref.extractfile(member).read()
                                extracted_files.append({
                                    'name': member.name,
                                    'size': len(content)
                                })
                                # Try to extract text
                                if any(member.name.lower().endswith(ext) for ext in ['.txt', '.md', '.csv', '.json', '.xml']):
                                    try:
                                        text = content.decode('utf-8')
                                        all_text.append(f"=== {member.name} ===\n{text}\n")
                                    except (UnicodeDecodeError, AttributeError):
                                        # Skip files that can't be decoded as text
                                        pass
                            except Exception as e:
                                logger.warning(f"⚠️ Could not extract {member.name}: {e}")
            
            result_text = f"Archive: {filename}\n"
            result_text += f"Extracted {len(extracted_files)} files:\n"
            for f in extracted_files[:20]:  # Limit to first 20 files
                result_text += f"  - {f['name']} ({f['size']} bytes)\n"
            if len(extracted_files) > 20:
                result_text += f"  ... and {len(extracted_files) - 20} more files\n"
            
            if all_text:
                result_text += "\n=== Extracted Text Content ===\n"
                result_text += "\n".join(all_text)
            
            return {
                'text': result_text,
                'metadata': {
                    'archive_type': path.suffix,
                    'files_count': len(extracted_files),
                    'extracted_files': extracted_files[:50]  # Limit metadata
                },
                'status': 'success',
                'filename': filename,
                'processing_method': 'archive'
            }
        except Exception as e:
            logger.error(f"❌ Error processing archive: {e}")
            return None
    
    def process_file(self, file_content: bytes, filename: str) -> Optional[Dict[str, Any]]:
        """Process any file type with appropriate method"""
        file_type, ext = self._get_file_type(filename)
        
        if file_type == 'skip':
            logger.info(f"⏭️  Skipping {filename} (skip extension)")
            return None
        
        if file_type == 'text':
            return self._process_text_file(file_content, filename)
        elif file_type == 'archive':
            return self._process_archive(file_content, filename)
        elif file_type == 'tika':
            return self._process_with_tika(file_content, filename)
        else:
            logger.warning(f"⚠️ Unknown processing method for {filename}")
            return None
    
    def store_processed_content(self, content: str, original_object_key: str, 
                                metadata: Dict = None, processing_info: Dict = None) -> bool:
        """Store processed content in MinIO"""
        try:
            timestamp = int(time.time())
            
            # Derive output key
            p = Path(original_object_key)
            stem = p.stem
            parent = str(p.parent).strip('.')
            object_key = f"{stem}.txt" if parent == '' else f"{parent}/{stem}.txt"
            
            # Prepare metadata
            original_filename = Path(original_object_key).name
            s3_metadata = {
                'Content-Type': 'text/plain',
                'processed-by': 'universal-processor',
                'original-filename': quote(original_filename, safe=''),
                'processing-timestamp': str(timestamp),
                'processing-date': datetime.now().isoformat()
            }
            
            if processing_info:
                s3_metadata['processing-method'] = processing_info.get('processing_method', 'unknown')
                if processing_info.get('ocr_used'):
                    s3_metadata['ocr-used'] = 'true'
                if processing_info.get('content_type'):
                    s3_metadata['original-content-type'] = quote(processing_info['content_type'], safe='')
            
            if metadata:
                # Store metadata as JSON (ensure ASCII-only)
                try:
                    # S3 user metadata is size-limited; keep it small to avoid failed uploads.
                    metadata_json = json.dumps(metadata, ensure_ascii=True)
                    max_len = 1500  # conservative to stay under header limits after quoting
                    if len(metadata_json) > max_len:
                        metadata_json = metadata_json[:max_len] + "...(truncated)"
                    s3_metadata['extracted-metadata'] = quote(metadata_json, safe='')
                except (TypeError, ValueError, json.JSONEncodeError) as e:
                    logger.warning(f"⚠️ Could not serialize metadata: {e}")
            
            # Upload to MinIO
            self.s3_client.put_object(
                Bucket=self.processed_bucket,
                Key=object_key,
                Body=content.encode('utf-8'),
                Metadata=s3_metadata
            )
            
            logger.info(f"✅ Stored processed content: {object_key} ({len(content)} chars)")
            return True
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            logger.error(f"❌ Failed to store processed content (S3 error {error_code}): {e}")
            return False
        except Exception as e:
            logger.error(f"❌ Failed to store processed content: {e}")
            return False
    
    def process_file_from_minio(self, object_key: str) -> bool:
        """Process a file from MinIO uploads bucket"""
        try:
            # Skip if processed output already exists
            p = Path(object_key)
            parent = str(p.parent).strip('.')
            output_key = f"{p.stem}.txt" if parent == '' else f"{parent}/{p.stem}.txt"
            
            try:
                self.s3_client.head_object(Bucket=self.processed_bucket, Key=output_key)
                logger.info(f"⏭️  Skipping, already processed: {output_key}")
                return True
            except ClientError:
                # File doesn't exist, proceed with processing
                pass
            except Exception as e:
                logger.warning(f"⚠️ Error checking if file already processed: {e}")
                # Continue processing anyway
            
            filename = Path(object_key).name
            
            # Update status: file detected, downloading
            self._update_status(processing=True, current_file=filename, progress=5, 
                              status='downloading from MinIO')
            
            # Download file from uploads bucket
            try:
                response = self.s3_client.get_object(
                    Bucket=self.uploads_bucket,
                    Key=object_key
                )
                file_content = response['Body'].read()
            except ClientError as e:
                error_code = e.response.get('Error', {}).get('Code', 'Unknown')
                error_msg = f"Failed to download file from MinIO (S3 error {error_code}): {str(e)}"
                logger.error(f"❌ {error_msg}")
                self._update_status(processing=False, current_file=None, progress=0,
                                  status='idle', error=error_msg)
                return False
            except Exception as e:
                error_msg = f"Failed to download file from MinIO: {str(e)}"
                logger.error(f"❌ {error_msg}")
                self._update_status(processing=False, current_file=None, progress=0,
                                  status='idle', error=error_msg)
                return False
            
            # Process file
            result = self.process_file(file_content, filename)
            
            if not result or result['status'] != 'success':
                logger.error(f"❌ Processing failed for {filename}")
                self._update_status(processing=False, current_file=None, progress=0, 
                                  status='idle', error=f"Processing failed: {filename}")
                return False
            
            # Update status: storing result
            self._update_status(processing=True, current_file=filename, progress=95, 
                              status='storing processed content')
            
            # Store processed content
            success = self.store_processed_content(
                content=result['text'],
                original_object_key=object_key,
                metadata=result.get('metadata', {}),
                processing_info=result
            )
            
            if success:
                logger.info(f"✅ Successfully processed: {filename}")
                logger.info(f"📄 Text length: {len(result['text'])} characters")
                logger.info(f"🔧 Method: {result.get('processing_method', 'unknown')}")
                
                # Update status: complete
                self._update_status(processing=False, current_file=None, progress=100, 
                                  status='completed')
                return True
            else:
                logger.error(f"❌ Failed to store processed content")
                self._update_status(processing=False, current_file=None, progress=0, 
                                  status='idle', error=f"Failed to store: {filename}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Error processing file from MinIO: {e}")
            self._update_status(processing=False, current_file=None, progress=0, 
                              status='idle', error=str(e))
            return False
    
    def get_processing_stats(self) -> Dict[str, Any]:
        """Get statistics about processed files"""
        try:
            stats = {
                'total_processed': 0,
                'by_type': {},
                'by_method': {},
                'total_size': 0
            }
            
            # List all processed files
            continuation_token = None
            while True:
                kwargs = {'Bucket': self.processed_bucket}
                if continuation_token:
                    kwargs['ContinuationToken'] = continuation_token
                
                response = self.s3_client.list_objects_v2(**kwargs)
                for obj in response.get('Contents', []):
                    if obj['Key'].lower().endswith('.txt'):
                        stats['total_processed'] += 1
                        stats['total_size'] += obj['Size']
                        
                        # Try to get metadata
                        try:
                            meta_response = self.s3_client.head_object(
                                Bucket=self.processed_bucket,
                                Key=obj['Key']
                            )
                            metadata = meta_response.get('Metadata', {})
                            method = metadata.get('processing-method', 'unknown')
                            stats['by_method'][method] = stats['by_method'].get(method, 0) + 1
                        except (KeyError, TypeError, AttributeError):
                            # Metadata key doesn't exist or wrong type, skip
                            pass
                
                if response.get('IsTruncated'):
                    continuation_token = response.get('NextContinuationToken')
                else:
                    break
            
            return stats
            
        except Exception as e:
            logger.error(f"❌ Failed to get stats: {e}")
            return {}
