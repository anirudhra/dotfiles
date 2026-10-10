#!/usr/bin/env bash
set -euo pipefail

# Storage base path (symlinked to active disk mount)
STORAGE_ROOT="/mnt/storage"
RETENTION_DAYS=30

# Verify storage directory exists and is accessible
if [[ ! -d "${STORAGE_ROOT}" ]]; then
  echo "Error: Base storage path ${STORAGE_ROOT} does not exist or is not mounted." >&2
  exit 1
fi

echo "Starting Samba recycle bin cleanup for files older than ${RETENTION_DAYS} days..."

# Use -L to allow find to dereference the /mnt/storage symlink
# 1. Delete regular files in any .recycle directory older than 30 days
find -L "${STORAGE_ROOT}" -type d -name ".recycle" -exec find -L {} -type f -mtime +"${RETENTION_DAYS}" -delete \;

# 2. Delete empty directories leftover inside .recycle folders
find -L "${STORAGE_ROOT}" -type d -name ".recycle" -exec find -L {} -mindepth 1 -type d -empty -delete \;

echo "Recycle bin cleanup completed successfully."
