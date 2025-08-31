#!/bin/sh
# (c) Anirudh Acharya 2024
# Unmounts ZFS filesystem and exports the pool for safe USB removal.

set -e

ZFSPOOL="${1:-pvebackup}"

if ! zpool list "${ZFSPOOL}" >/dev/null 2>&1; then
  echo "ZFS pool '${ZFSPOOL}' does not exist."
  exit 1
fi

echo "This will unmount and export the ZFS pool '${ZFSPOOL}'."
read -p "Press Enter to continue or Ctrl+C to abort..."

zfs umount "/${ZFSPOOL}"
zpool export "${ZFSPOOL}"

zpool status
