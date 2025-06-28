#!/bin/sh
# (c) Anirudh Acharya 2024
# Force clears ZFS pool if I/O is suspended.

set -e

ZFSPOOL="${1:-pvebackup}"

if ! zpool list "${ZFSPOOL}" >/dev/null 2>&1; then
    echo "ZFS pool '${ZFSPOOL}' does not exist."
    exit 1
fi

echo "This will force clear the ZFS pool '${ZFSPOOL}' (I/O suspended)."
read -r -p "Press Enter to continue or Ctrl+C to abort..."

zpool clear -nFX "${ZFSPOOL}"

zpool status
zfs list
