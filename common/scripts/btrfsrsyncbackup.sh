#!/bin/bash
# (c) Anirudh Acharya
# Generic rsync- and Btrfs-based backup script with incremental send/receive and retention support
set -euo pipefail

# Configuration
DATA_DIR="/mnt/data"                         # backup source, btrfs volume must be mounted
BACKUP_DIR="/mnt/backup"                     # backup destination
SNAPSHOT_DIR="$DATA_DIR/.snapshots"          # btrfs snapshot volume
BACKUP_SNAPSHOT_DIR="$BACKUP_DIR/.snapshots" # btrfs snapshot backup destination
DATE=$(date +%Y-%m-%d_%H%M%S)
SNAPSHOT_NAME="snapshot_$DATE"
RETENTION_DAYS=10                            # retention window in days

# Ensure snapshot directories exist
sudo mkdir -p "$SNAPSHOT_DIR"
sudo mkdir -p "$BACKUP_SNAPSHOT_DIR"

# Identify the most recent existing read-only snapshot on the source for incremental delta
PREV_SNAPSHOT=$(find "$SNAPSHOT_DIR" -maxdepth 1 -mindepth 1 -type d -name 'snapshot_*' 2>/dev/null | sort | tail -n 1 || true)
PREV_SNAPSHOT_NAME=""
if [ -n "$PREV_SNAPSHOT" ]; then
  PREV_SNAPSHOT_NAME=$(basename "$PREV_SNAPSHOT")
fi

# 1. Create a new READ-ONLY snapshot on /mnt/data
# Note: The -r flag is mandatory because 'btrfs send' only operates on read-only subvolumes.
echo "==> Creating read-only Btrfs snapshot: $SNAPSHOT_NAME"
sudo btrfs subvolume snapshot -r "$DATA_DIR" "$SNAPSHOT_DIR/$SNAPSHOT_NAME"

# 2. Copy the snapshot to /mnt/backup using Btrfs send/receive
# If a matching parent snapshot exists on both source and destination, perform an incremental send.
if [ -n "$PREV_SNAPSHOT_NAME" ] && [ -d "$BACKUP_SNAPSHOT_DIR/$PREV_SNAPSHOT_NAME" ]; then
  echo "==> Performing incremental btrfs send from parent '$PREV_SNAPSHOT_NAME'..."
  sudo btrfs send -p "$SNAPSHOT_DIR/$PREV_SNAPSHOT_NAME" "$SNAPSHOT_DIR/$SNAPSHOT_NAME" | sudo btrfs receive "$BACKUP_SNAPSHOT_DIR"
else
  echo "==> Performing initial full btrfs send..."
  sudo btrfs send "$SNAPSHOT_DIR/$SNAPSHOT_NAME" | sudo btrfs receive "$BACKUP_SNAPSHOT_DIR"
fi

# 3. Sync live data to /mnt/backup
# Explicitly exclude the .snapshots directory to prevent overwriting or colliding with Btrfs subvolumes on destination
echo "==> Syncing live data to $BACKUP_DIR (excluding .snapshots)..."
sudo rsync -av --delete --exclude='.snapshots' --exclude='.snapshots/**' "$DATA_DIR/" "$BACKUP_DIR/"

# 4. Clean up snapshots older than $RETENTION_DAYS
echo "==> Cleaning up snapshots older than $RETENTION_DAYS days..."
find "$SNAPSHOT_DIR" -maxdepth 1 -mindepth 1 -type d -name 'snapshot_*' -mtime +"$RETENTION_DAYS" -exec sudo btrfs subvolume delete {} \;
find "$BACKUP_SNAPSHOT_DIR" -maxdepth 1 -mindepth 1 -type d -name 'snapshot_*' -mtime +"$RETENTION_DAYS" -exec sudo btrfs subvolume delete {} \;

# Done
echo "==> Backup and snapshot cleanup complete!"
