#!/usr/bin/env python3
"""
Automatic MinIO + Tika PDF Processing Pipeline
Watches MinIO uploads bucket and processes PDFs automatically
"""

import os
import time
import logging
from pathlib import Path
from tika_processor import TikaMinIOProcessor

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MinIOWatcher:
    def __init__(self, processor):
        self.processor = processor
        self.processed_files = set()
        
    def check_for_new_pdfs(self):
        """Check MinIO uploads bucket for new PDFs"""
        try:
            # List objects in uploads bucket
            response = self.processor.s3_client.list_objects_v2(
                Bucket=self.processor.uploads_bucket
            )
            
            new_files = []
            for obj in response.get('Contents', []):
                object_key = obj['Key']
                # Process only raw PDFs; skip already-produced .txt files
                if (object_key.lower().endswith('.pdf') and
                    object_key not in self.processed_files):
                    new_files.append(object_key)
            
            return new_files
            
        except Exception as e:
            logger.error(f"❌ Error checking for new PDFs: {e}")
            return []
    
    def process_new_pdfs(self):
        """Process any new PDFs found in uploads bucket"""
        new_files = self.check_for_new_pdfs()
        
        if not new_files:
            return
        
        logger.info(f"🔄 Found {len(new_files)} new PDFs to process")
        
        for object_key in new_files:
            logger.info(f"🔄 Processing: {object_key}")
            
            # Process the PDF
            success = self.processor.process_pdf_from_minio(object_key)
            
            if success:
                logger.info(f"✅ Successfully processed: {object_key}")
                self.processed_files.add(object_key)
            else:
                logger.error(f"❌ Failed to process: {object_key}")

def main():
    """Start the automatic PDF processing pipeline"""
    logger.info("🚀 Starting MinIO + Tika Auto-Processing Pipeline")
    
    # Initialize processor
    processor = TikaMinIOProcessor()
    
    # Setup watcher
    watcher = MinIOWatcher(processor)
    
    logger.info("👀 Watching MinIO uploads bucket for new PDFs")
    logger.info(f"📁 Uploads bucket: {processor.uploads_bucket}")
    logger.info(f"📁 Processed bucket: {processor.processed_bucket}")
    
    try:
        while True:
            # Check for new PDFs every 10 seconds
            watcher.process_new_pdfs()
            time.sleep(10)
            
    except KeyboardInterrupt:
        logger.info("🛑 Stopping MinIO + Tika processor...")

if __name__ == "__main__":
    main()
