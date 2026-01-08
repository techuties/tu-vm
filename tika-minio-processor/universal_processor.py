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
        
        # Normalize endpoint URL
        raw = minio_endpoint
        if raw.startswith("http://") or raw.startswith("https://"):
            raw = raw.split("://", 1)[1]
        host_port = raw
        if ':' in host_port:
            host, port = host_port.split(':', 1)
        else:
            host, port = host_port, '9000'
        try:
            resolved_ip = socket.gethostbyname(host)
            endpoint_url = f"http://{resolved_ip}:{port}"
        except Exception:
            endpoint_url = f"http://{host}:{port}"

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
    
    def _ensure_buckets_exist(self):
        """Create buckets if they don't exist"""
        for bucket in [self.uploads_bucket, self.processed_bucket]:
            try:
                self.s3_client.head_bucket(Bucket=bucket)
                logger.info(f"✅ Bucket '{bucket}' exists")
            except:
                try:
                    self.s3_client.create_bucket(Bucket=bucket)
                    logger.info(f"✅ Created bucket '{bucket}'")
                except Exception as e:
                    logger.error(f"❌ Failed to create bucket '{bucket}': {e}")
    
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
            
            # Process with retries
            for attempt in range(self.max_retries):
                try:
                    response = requests.put(
                        f"{self.tika_url}/tika",
                        data=file_content,
                        headers=headers,
                        timeout=120 if enable_ocr else 60
                    )
                    
                    if response.status_code == 200:
                        text_content = response.text.strip()
                        
                        # Get metadata
                        metadata = {}
                        try:
                            metadata_response = requests.put(
                                f"{self.tika_url}/meta",
                                data=file_content,
                                headers={'Content-Type': content_type},
                                timeout=30
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
                        logger.warning(f"⚠️ Tika returned status {response.status_code} (attempt {attempt + 1}/{self.max_retries})")
                        if attempt < self.max_retries - 1:
                            time.sleep(self.retry_delay)
                            continue
                        return None
                        
                except requests.Timeout:
                    logger.warning(f"⚠️ Tika timeout (attempt {attempt + 1}/{self.max_retries})")
                    if attempt < self.max_retries - 1:
                        time.sleep(self.retry_delay)
                        continue
                    return None
                except Exception as e:
                    logger.error(f"❌ Error calling Tika: {e}")
                    if attempt < self.max_retries - 1:
                        time.sleep(self.retry_delay)
                        continue
                    return None
            
            return None
                
        except Exception as e:
            logger.error(f"❌ Error processing file with Tika: {e}")
            return None
    
    def _process_text_file(self, file_content: bytes, filename: str) -> Optional[Dict[str, Any]]:
        """Process plain text file"""
        try:
            logger.info(f"🔄 Processing text file: {filename}")
            
            # Try to decode as UTF-8, fallback to latin-1
            try:
                text_content = file_content.decode('utf-8')
            except UnicodeDecodeError:
                try:
                    text_content = file_content.decode('latin-1')
                except:
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
                                    except:
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
                                    except:
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
                except:
                    pass
            
            # Upload to MinIO
            self.s3_client.put_object(
                Bucket=self.processed_bucket,
                Key=object_key,
                Body=content.encode('utf-8'),
                Metadata=s3_metadata
            )
            
            logger.info(f"✅ Stored processed content: {object_key}")
            return True
            
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
            except Exception:
                pass
            
            # Download file from uploads bucket
            response = self.s3_client.get_object(
                Bucket=self.uploads_bucket,
                Key=object_key
            )
            
            file_content = response['Body'].read()
            filename = Path(object_key).name
            
            # Process file
            result = self.process_file(file_content, filename)
            
            if not result or result['status'] != 'success':
                logger.error(f"❌ Processing failed for {filename}")
                return False
            
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
                return True
            else:
                logger.error(f"❌ Failed to store processed content")
                return False
                
        except Exception as e:
            logger.error(f"❌ Error processing file from MinIO: {e}")
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
                        except:
                            pass
                
                if response.get('IsTruncated'):
                    continuation_token = response.get('NextContinuationToken')
                else:
                    break
            
            return stats
            
        except Exception as e:
            logger.error(f"❌ Failed to get stats: {e}")
            return {}
