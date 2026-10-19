#!/bin/bash
set -euo pipefail

echo "=== Current Proxmox Boot Tool Status ==="
proxmox-boot-tool status || true
echo

PARTITION="${1:-}"

if [ -z "$PARTITION" ]; then
    echo "Available EFI/VFAT partitions:"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -i vfat || true
    echo
    echo "Usage: $0 /dev/<efi_partition> (e.g. $0 /dev/nvme0n1p2)"
    echo "Please provide the target EFI partition explicitly as an argument."
    exit 1
fi

if [ ! -b "$PARTITION" ]; then
    echo "Error: Block device '$PARTITION' does not exist." >&2
    exit 2
fi

echo "WARNING: This will reinitialize Proxmox EFI boot on '$PARTITION'!"
read -r -p "Are you sure you want to proceed? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation aborted."
    exit 0
fi

if mountpoint -q /boot/efi; then
    echo "Unmounting /boot/efi..."
    umount /boot/efi || true
fi

echo "Initializing $PARTITION with proxmox-boot-tool..."
proxmox-boot-tool init "$PARTITION"
mount -a || true
proxmox-boot-tool refresh
proxmox-boot-tool status
echo "Boot configuration refreshed successfully!"
