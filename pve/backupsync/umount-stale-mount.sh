#!/bin/bash
# Umount stale CIFS/SMB or NFS mounts after 300 seconds
# PVE will remount automatically if storage is activated

set -euo pipefail

check_and_umount() {
    local TYPE="$1"
    # Use mapfile/readarray to handle spaces in mount points
    mapfile -t mounts < <(mount | sed -n "s/^.* on \(.*\) type $TYPE .*/\1/p")
    for MNT in "${mounts[@]}"; do # mounts needs to be lowercase
        if ! timeout 300 ls "$MNT" &>/dev/null; then
            echo "Stale $TYPE mount: $MNT"
            echo "Umounting this stale mount..."
            umount -f -l "$MNT"
        fi
    done
}

check_and_umount cifs
check_and_umount nfs
