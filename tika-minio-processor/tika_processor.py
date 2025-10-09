#!/usr/bin/env python3
"""
Professional MinIO + Tika PDF Processing Pipeline
Transforms PDFs into high-quality text files via Tika
"""

import os
import time
import json
import logging
import requests
import boto3
from pathlib import Path
import socket
from typing import Optional, Dict, Any
from botocore.exceptions import ClientError

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TikaMinIOProcessor:
    def __init__(self,
                 tika_url: Optional[str] = None,
                 minio_endpoint: Optional[str] = None,
                 minio_access_key: Optional[str] = None,
                 minio_secret_key: Optional[str] = None,
                 uploads_bucket: Optional[str] = None,
                 processed_bucket: Optional[str] = None):

        # Resolve configuration from function args or environment variables
        tika_url = tika_url or os.getenv("TIKA_URL", "http://ai_tika:9998")
        minio_endpoint = minio_endpoint or os.getenv("MINIO_ENDPOINT", "ai_minio:9000")
        minio_access_key = minio_access_key or os.getenv("MINIO_ACCESS_KEY", "admin")
        minio_secret_key = minio_secret_key or os.getenv("MINIO_SECRET_KEY", "minio123456")
        # Prefer existing bucket names in your MinIO
        uploads_bucket = uploads_bucket or os.getenv("UPLOADS_BUCKET", "uploads")
        processed_bucket = processed_bucket or os.getenv("PROCESSED_BUCKET", "processed-files")

        # Normalize endpoint URL and avoid underscores in hostname (botocore validation)
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
            # Fallback to plain host if resolution fails
            endpoint_url = f"http://{host}:{port}"

        self.tika_url = tika_url
        self.uploads_bucket = uploads_bucket
        self.processed_bucket = processed_bucket

        # Initialize MinIO client
        self.s3_client = boto3.client(
            's3',
            endpoint_url=endpoint_url,
            aws_access_key_id=minio_access_key,
            aws_secret_access_key=minio_secret_key,
            region_name='us-east-1',
            use_ssl=endpoint_url.startswith("https")  # enable SSL only when endpoint uses https
        )
        
        # Ensure buckets exist
        self._ensure_buckets_exist()
    
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
    
    def process_pdf_with_tika(self, pdf_content: bytes, filename: str) -> Optional[Dict[str, Any]]:
        """Process PDF using Tika service"""
        try:
            logger.info(f"🔄 Processing PDF with Tika: {filename}")
            
            # Send to Tika for processing (use PUT for text extraction)
            response = requests.put(
                f"{self.tika_url}/tika",
                data=pdf_content,
                headers={'Content-Type': 'application/pdf'},
                timeout=60
            )
            
            if response.status_code == 200:
                # Extract text content
                text_content = response.text
                
                # Get metadata (use PUT for metadata extraction)
                metadata_response = requests.put(
                    f"{self.tika_url}/meta",
                    data=pdf_content,
                    headers={'Content-Type': 'application/pdf'},
                    timeout=30
                )
                
                metadata = {}
                if metadata_response.status_code == 200:
                    try:
                        metadata = metadata_response.json()
                    except Exception as e:
                        logger.warning(f"⚠️ Could not parse metadata JSON: {e}")
                        metadata = {}
                
                return {
                    'text': text_content,
                    'metadata': metadata,
                    'status': 'success',
                    'filename': filename
                }
            else:
                logger.error(f"❌ Tika processing failed: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"❌ Error processing PDF with Tika: {e}")
            return None
    
    def store_processed_content(self, content: str, original_object_key: str, metadata: Dict = None) -> bool:
        """Store processed content in MinIO (same or different bucket).
        If uploads and processed buckets are the same, write alongside the
        original path using the same basename with .txt extension.
        """
        try:
            # Create timestamp
            timestamp = int(time.time())
            
            # Derive output key
            # Preserve path prefix; change extension to .txt; no extra suffix
            p = Path(original_object_key)
            stem = p.stem  # base name without extension
            parent = str(p.parent).strip('.')
            object_key = f"{stem}.txt" if parent == '' else f"{parent}/{stem}.txt"
            
            # Prepare metadata
            s3_metadata = {
                'Content-Type': 'text/plain',
                'processed-by': 'tika',
                'original-filename': Path(original_object_key).name,
                'processing-timestamp': str(timestamp)
            }
            
            if metadata:
                s3_metadata.update({
                    'tika-metadata': json.dumps(metadata),
                    'content-length': str(len(content))
                })
            
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
    
    def process_pdf_from_minio(self, object_key: str) -> bool:
        """Process a PDF from MinIO uploads bucket"""
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

            # Download PDF from uploads bucket
            response = self.s3_client.get_object(
                Bucket=self.uploads_bucket,
                Key=object_key
            )
            
            pdf_content = response['Body'].read()
            filename = Path(object_key).name
            
            # Process with Tika
            result = self.process_pdf_with_tika(pdf_content, filename)
            
            if not result or result['status'] != 'success':
                logger.error(f"❌ Tika processing failed for {filename}")
                return False
            
            # Store processed content
            success = self.store_processed_content(
                content=result['text'],
                original_object_key=object_key,
                metadata=result['metadata']
            )
            
            if success:
                logger.info(f"✅ Successfully processed: {filename}")
                logger.info(f"📄 Text length: {len(result['text'])} characters")
                return True
            else:
                logger.error(f"❌ Failed to store processed content")
                return False
                
        except Exception as e:
            logger.error(f"❌ Error processing PDF from MinIO: {e}")
            return False
    
    def list_processed_files(self) -> list:
        """List all processed files in MinIO"""
        try:
            # List all objects and filter to .txt results only
            continuation_token = None
            files = []
            while True:
                kwargs = {'Bucket': self.processed_bucket}
                if continuation_token:
                    kwargs['ContinuationToken'] = continuation_token
                response = self.s3_client.list_objects_v2(**kwargs)
                for obj in response.get('Contents', []):
                    if obj['Key'].lower().endswith('.txt'):
                        files.append({
                            'key': obj['Key'],
                            'size': obj['Size'],
                            'last_modified': obj['LastModified']
                        })
                if response.get('IsTruncated'):
                    continuation_token = response.get('NextContinuationToken')
                else:
                    break

            return files
            
        except Exception as e:
            logger.error(f"❌ Failed to list processed files: {e}")
            return []
    
    def get_processed_content(self, object_key: str) -> Optional[str]:
        """Retrieve processed content from MinIO"""
        try:
            response = self.s3_client.get_object(
                Bucket=self.processed_bucket,
                Key=object_key
            )
            
            return response['Body'].read().decode('utf-8')
            
        except Exception as e:
            logger.error(f"❌ Failed to retrieve processed content: {e}")
            return None

def main():
    """Test the Tika + MinIO processor"""
    processor = TikaMinIOProcessor()
    
    # List processed files
    files = processor.list_processed_files()
    print(f"📁 Processed files: {len(files)}")
    
    for file in files:
        print(f"  - {file['key']} ({file['size']} bytes)")

if __name__ == "__main__":
    main()
