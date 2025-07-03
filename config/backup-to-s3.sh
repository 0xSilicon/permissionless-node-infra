#!/bin/bash
set -e

TODAY=$(date +"%Y%m%d")

# Paths
DATA_DIR="/home/ubuntu/data"
TMP_BACKUP_DIR="/home/ubuntu/tmp/data-backup-$TODAY"
TMP_ARCHIVE="$TMP_BACKUP_DIR/$TODAY.tar.gz"
S3_BUCKET="{{S3_BUCKET}}" 
S3_PREFIX="backups"  
S3_PATH="s3://$S3_BUCKET/$S3_PREFIX/$TODAY.tar.gz"

echo "[$TODAY] Starting backup..."

# 1. Copy data to temporary directory
sudo mkdir -p "$TMP_BACKUP_DIR"
sudo rsync -a --delete "$DATA_DIR/" "$TMP_BACKUP_DIR/"

# 2. Compress
sudo tar -czf "$TMP_ARCHIVE" -C "$TMP_BACKUP_DIR" .

# 3. Set ownership for upload
sudo chown ubuntu:ubuntu "$TMP_ARCHIVE"

# 4. Upload to S3
aws s3api head-object --bucket "$S3_BUCKET" --key "$S3_PREFIX/" || \
aws s3api put-object --bucket "$S3_BUCKET" --key "$S3_PREFIX/" --body /dev/null

aws s3 cp "$TMP_ARCHIVE" "$S3_PATH"

# 5. Cleanup
sudo rm -rf "$TMP_BACKUP_DIR" "$TMP_ARCHIVE"

echo "[$TODAY] Backup completed → $S3_PATH"