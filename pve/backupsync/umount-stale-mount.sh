#!/bin/bash
# Umount stale CIFS/SMB or NFS mounts after 300 seconds
# PVE will remount automatically if storage is activated

set -euo pipefail

check_and_umount() {
    local type="$1"
    # Use mapfile/readarray to handle spaces in mount points
    mapfile -t mounts < <(mount | sed -n "s/^.* on \(.*\) type $type .*/\1/p")
    for mnt in "${mounts[@]}"; do
        if ! timeout 300 ls "$mnt" &>/dev/null; then
            echo "Stale $type mount: $mnt"
            echo "Umounting this stale mount..."
            umount -f -l "$mnt"
        fi
    done
}

check_and_umount cifs
check_and_umount nfs
