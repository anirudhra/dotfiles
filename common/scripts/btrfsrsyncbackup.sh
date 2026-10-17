#!/bin/bash
# This is a generic rsync- and btrfs-based backup script
# with retention config support

# Set variables
DATA_DIR="/mnt/data"                         # backup source, btrfs volume needs to be mounted
BACKUP_DIR="/mnt/backup"                     # backup destination
SNAPSHOT_DIR="$DATA_DIR/.snapshots"          # btrfs snapshot volume, needs to be created and mounted
BACKUP_SNAPSHOT_DIR="$BACKUP_DIR/.snapshots" # btrfs snapshot backup
DATE=$(date +%Y-%m-%d)
SNAPSHOT_NAME="snapshot_$DATE"
RETENTION_DAYS=10 # configurable

# Ensure snapshot directories exist
sudo mkdir -p "$SNAPSHOT_DIR"
sudo mkdir -p "$BACKUP_SNAPSHOT_DIR"

# Create a new snapshot on /mnt/data
sudo btrfs subvolume snapshot "$DATA_DIR" "$SNAPSHOT_DIR/$SNAPSHOT_NAME"

# Copy the snapshot to /mnt/backup using btrfs send/receive
sudo btrfs send "$SNAPSHOT_DIR/$SNAPSHOT_NAME" | sudo btrfs receive "$BACKUP_SNAPSHOT_DIR"

# Sync live data to /mnt/backup
sudo rsync -av --delete "$DATA_DIR/" "$BACKUP_DIR/"

# Clean up snapshots older than $RETENTION_DAYS (e.g., 10 days)
find "$SNAPSHOT_DIR" -maxdepth 1 -type d -name 'snapshot_*' -mtime +"$RETENTION_DAYS" -exec sudo btrfs subvolume delete {} \;
find "$BACKUP_SNAPSHOT_DIR" -maxdepth 1 -type d -name 'snapshot_*' -mtime +"$RETENTION_DAYS" -exec sudo btrfs subvolume delete {} \;

# Done
echo "Backup and snapshot cleanup complete!"
