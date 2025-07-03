#!/bin/bash

# ex) ./restore-from-s3.sh 20250603
set -e

RESTORE_DATE=$1

if [ -z "$RESTORE_DATE" ]; then
  echo "Usage: $0 YYYYMMDD"
  exit 1
fi

DATA_DIR="/home/ubuntu/data"
TMP_RESTORE_DIR="/home/ubuntu/tmp/data-restore-$RESTORE_DATE"
ARCHIVE_PATH="/home/ubuntu/tmp/$RESTORE_DATE.tar.gz"
S3_BUCKET="{{S3_BUCKET}}" 
S3_PATH="s3://$S3_BUCKET/backups/$RESTORE_DATE.tar.gz"

echo "[*] Restoring backup from $RESTORE_DATE..."

# 1. Download from S3
aws s3 cp "$S3_PATH" "$ARCHIVE_PATH"

# 2. Extract to temp directory
mkdir -p "$TMP_RESTORE_DIR"
sudo tar -xzf "$ARCHIVE_PATH" -C "$TMP_RESTORE_DIR"

# 3. Replace existing data
echo "[*] Stopping docker services..."
sudo docker compose -f /home/ubuntu/docker-compose.yml down

echo "[*] Restoring data to $DATA_DIR..."
sudo rsync -a --info=progress2 --delete "$TMP_RESTORE_DIR/" "$DATA_DIR/"

# 4. Cleanup
sudo rm -rf "$TMP_RESTORE_DIR" "$ARCHIVE_PATH"

# 5. Restart
echo "[*] Restarting docker services..."
sudo docker compose -f /home/ubuntu/docker-compose.yml up -d

echo "[✓] Restore complete from $RESTORE_DATE"
