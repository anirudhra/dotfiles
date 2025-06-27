#!/bin/sh
#
# (c) Anirudh Acharya 2024
# Script to mount USB ZFS pool

set -e

zfspool="${1:-pvebackup}"
mountpoint="${2:-zfsdata}"

if zpool list "$zfspool" >/dev/null 2>&1; then
    echo "ZFS pool '$zfspool' is already imported."
else
    echo "Importing ZFS pool '$zfspool'..."
    # Uncomment the -f version if pool fails to import normally
    # zpool import -f "$zfspool"
    zpool import "$zfspool"
fi

mkdir -p "/$mountpoint"

# Set mountpoint (may not be needed every time, but included for safety)
zfs set mountpoint="/$mountpoint" "$zfspool/$mountpoint"

zpool
