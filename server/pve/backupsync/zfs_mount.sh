#!/bin/sh
#
# (c) Anirudh Acharya 2024
# Script to mount USB ZFS pool

set -e

ZFSPOOL="${1:-pvebackup}"
MOUNTPOINT="${2:-zfsdata}"

if zpool list "${ZFSPOOL}" >/dev/null 2>&1; then
  echo "ZFS pool '${ZFSPOOL}' is already imported."
else
  echo "Importing ZFS pool '${ZFSPOOL}'..."
  # Uncomment the -f version if pool fails to import normally
  # zpool import -f "$zfspool"
  zpool import "${ZFSPOOL}"
fi

mkdir -p "/${MOUNTPOINT}"

# Set mountpoint (may not be needed every time, but included for safety)
zfs set mountpoint="/${MOUNTPOINT}" "${ZFSPOOL}/${MOUNTPOINT}"

zpool status
