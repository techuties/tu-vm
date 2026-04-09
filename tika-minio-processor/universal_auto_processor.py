#!/usr/bin/env python3
"""
Universal MinIO Auto-Processing Pipeline
Automatically watches MinIO bucket and processes any supported file type
"""

import os
import time
import logging
from pathlib import Path
from universal_processor import UniversalMinIOProcessor

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class UniversalMinIOWatcher:
    """Watches MinIO bucket(s) for new files and processes them automatically"""
    
    def __init__(self, processor: UniversalMinIOProcessor, check_interval: int = 10, watch_buckets: list = None):
        self.processor = processor
        self.check_interval = check_interval
        self.processed_files = set()
        self.failed_files = {}  # file_id -> {"count": int, "next_retry_at": epoch}
        # 0 means unlimited attempts: keep retrying until success.
        self.max_file_attempts = int(os.getenv("PROCESSOR_MAX_FILE_ATTEMPTS", "0"))
        self.retry_backoff_seconds = int(os.getenv("PROCESSOR_RETRY_BACKOFF_SECONDS", "30"))
        
        # Support multiple buckets (comma-separated string or list)
        if watch_buckets is None:
            # Parse from environment or use single bucket
            buckets_env = os.getenv("WATCH_BUCKETS", "")
            if buckets_env:
                self.watch_buckets = [b.strip() for b in buckets_env.split(",") if b.strip()]
            else:
                self.watch_buckets = [processor.uploads_bucket]
        elif isinstance(watch_buckets, str):
            self.watch_buckets = [b.strip() for b in watch_buckets.split(",") if b.strip()]
        else:
            self.watch_buckets = watch_buckets if watch_buckets else [processor.uploads_bucket]
        
        logger.info(f"👀 Watching buckets: {', '.join(self.watch_buckets)}")
        
    def check_for_new_files(self) -> list:
        """Check all watched MinIO buckets for new files to process"""
        all_new_files = []
        
        for bucket in self.watch_buckets:
            try:
                response = self.processor.s3_client.list_objects_v2(
                    Bucket=bucket
                )
                
                for obj in response.get('Contents', []):
                    object_key = obj['Key']
                    # Store bucket:key for tracking
                    file_id = f"{bucket}:{object_key}"
                    
                    # Skip already processed files
                    if file_id in self.processed_files:
                        continue

                    # Respect retry backoff for previously failed files.
                    fail_state = self.failed_files.get(file_id)
                    if fail_state and time.time() < float(fail_state.get("next_retry_at", 0)):
                        continue
                    
                    # Skip .txt files (processed outputs)
                    if object_key.lower().endswith('.txt'):
                        continue
                    
                    # Skip lock/temp files
                    if any(object_key.lower().endswith(ext) for ext in ['.lock', '.tmp', '.swp', '.processed']):
                        continue
                    
                    # Check if file type is supported
                    file_type, _ = self.processor._get_file_type(object_key)
                    if file_type != 'skip':
                        all_new_files.append((bucket, object_key))
            
            except Exception as e:
                logger.error(f"❌ Error checking bucket '{bucket}' for new files: {e}")
                continue
        
        return all_new_files
    
    def process_new_files(self):
        """Process any new files found in watched buckets"""
        new_files = self.check_for_new_files()
        
        if not new_files:
            return
        
        logger.info(f"🔄 Found {len(new_files)} new file(s) to process")
        
        for bucket, object_key in new_files:
            file_id = f"{bucket}:{object_key}"
            logger.info(f"🔄 Processing: {bucket}/{object_key}")
            
            try:
                original_uploads = self.processor.uploads_bucket
                original_processed = self.processor.processed_bucket
                self.processor.uploads_bucket = bucket
                self.processor.processed_bucket = bucket
                
                success = self.processor.process_file_from_minio(object_key)
                
                self.processor.uploads_bucket = original_uploads
                self.processor.processed_bucket = original_processed
                
                if success:
                    logger.info(f"✅ Successfully processed: {bucket}/{object_key}")
                    self.processed_files.add(file_id)
                    # Remove from failed files if it was there
                    self.failed_files.pop(file_id, None)
                else:
                    # Track failed files
                    state = self.failed_files.setdefault(file_id, {"count": 0, "next_retry_at": 0.0})
                    state["count"] = int(state.get("count", 0)) + 1
                    state["next_retry_at"] = time.time() + self.retry_backoff_seconds
                    attempts = int(state["count"])

                    if self.max_file_attempts > 0 and attempts >= self.max_file_attempts:
                        logger.error(
                            f"❌ Failed to process {bucket}/{object_key} after {attempts} attempts; "
                            f"max attempts reached, skipping permanently"
                        )
                        self.processed_files.add(file_id)
                        self.failed_files.pop(file_id, None)
                    else:
                        max_hint = f"/{self.max_file_attempts}" if self.max_file_attempts > 0 else "/unlimited"
                        logger.warning(
                            f"⚠️ Processing failed for {bucket}/{object_key} (attempt {attempts}{max_hint}); "
                            f"will retry in {self.retry_backoff_seconds}s"
                        )
                        
            except Exception as e:
                logger.error(f"❌ Exception processing {bucket}/{object_key}: {e}")
                state = self.failed_files.setdefault(file_id, {"count": 0, "next_retry_at": 0.0})
                state["count"] = int(state.get("count", 0)) + 1
                state["next_retry_at"] = time.time() + self.retry_backoff_seconds
    
    def print_stats(self):
        """Print processing statistics"""
        try:
            stats = self.processor.get_processing_stats()
            logger.info("📊 Processing Statistics:")
            logger.info(f"   Total processed: {stats.get('total_processed', 0)}")
            logger.info(f"   Total size: {stats.get('total_size', 0) / 1024 / 1024:.2f} MB")
            logger.info(f"   By method: {stats.get('by_method', {})}")
        except Exception as e:
            logger.warning(f"⚠️ Could not get stats: {e}")


def main():
    """Start the universal auto-processing pipeline"""
    logger.info("🚀 Starting Universal MinIO Auto-Processing Pipeline")
    logger.info("=" * 60)
    
    # Initialize processor
    try:
        processor = UniversalMinIOProcessor()
    except Exception as e:
        logger.error(f"❌ Failed to initialize processor: {e}")
        return
    
    # Setup watcher with multi-bucket support
    check_interval = int(os.getenv("CHECK_INTERVAL", "10"))
    watch_buckets_env = os.getenv("WATCH_BUCKETS", "")
    watch_buckets = [b.strip() for b in watch_buckets_env.split(",") if b.strip()] if watch_buckets_env else None
    watcher = UniversalMinIOWatcher(processor, check_interval=check_interval, watch_buckets=watch_buckets)
    
    logger.info(f"👀 Watching MinIO bucket(s) for new files")
    logger.info(f"📁 Watched buckets: {', '.join(watcher.watch_buckets)}")
    logger.info(f"📁 Processed bucket: {processor.processed_bucket}")
    logger.info(f"⏱️  Check interval: {check_interval} seconds")
    logger.info(f"🔧 Tika URL: {processor.tika_url}")
    logger.info("=" * 60)
    
    # Print initial stats
    watcher.print_stats()
    
    # Health check counter
    health_check_counter = 0
    
    try:
        while True:
            # Process new files
            watcher.process_new_files()
            
            # Periodic health check and stats (every 60 checks)
            health_check_counter += 1
            if health_check_counter >= 60:
                health_check_counter = 0
                processor._check_tika_health()
                watcher.print_stats()
            
            # Sleep before next check
            time.sleep(check_interval)
            
    except KeyboardInterrupt:
        logger.info("🛑 Stopping Universal MinIO processor...")
        watcher.print_stats()
    except Exception as e:
        logger.error(f"❌ Fatal error in main loop: {e}")
        raise


if __name__ == "__main__":
    main()
