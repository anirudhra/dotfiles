#!/bin/sh
# (c) Anirudh Acharya 2024
# Unmounts ZFS filesystem and exports the pool for safe USB removal.

set -e

zfspool="${1:-pvebackup}"

if ! zpool list "$zfspool" >/dev/null 2>&1; then
    echo "ZFS pool '$zfspool' does not exist."
    exit 1
fi

echo "This will unmount and export the ZFS pool '$zfspool'."
read -r -p "Press Enter to continue or Ctrl+C to abort..."

zfs umount "/$zfspool"
zpool export "$zfspool"

zpool status
