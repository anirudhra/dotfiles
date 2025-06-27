#!/bin/sh
# (c) Anirudh Acharya 2024
# Force clears ZFS pool if I/O is suspended.

set -e

zfspool="${1:-pvebackup}"

if ! zpool list "$zfspool" >/dev/null 2>&1; then
    echo "ZFS pool '$zfspool' does not exist."
    exit 1
fi

echo "This will force clear the ZFS pool '$zfspool' (I/O suspended)."
read -r -p "Press Enter to continue or Ctrl+C to abort..."

zpool clear -nFX "$zfspool"

zpool status
zfs list
