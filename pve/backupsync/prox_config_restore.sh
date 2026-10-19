#!/bin/bash
# Version	      0.2.4
# Date		      08.04.2024
# Author 	      razem-io 
# Contributors

# Very basic restore script based on https://github.com/DerDanilo/proxmox-stuff/issues/5

# Restores backup from prox_config_backup.sh
#   example: prox_config_restore.sh pve_proxmoxhostname_2023-12-02.15.48.10.tar.gz

set -e

if [[ $# -eq 0 ]] ; then
    echo 'Argument missing -> prox_config_restore.sh <path_to_pve_proxmoxhostname_2023-12-02.15.48.10.tar.gz>'
    exit 0
fi

echo "Select restore mode:"
echo "1) Default restore"
echo "2) Restore with /etc/fstab commented out and saved as /etc/fstab_RESTORED"
read -p "Enter choice (1 or 2): " CHOICE

case "$CHOICE" in
    1)
        COMMENT_FSTAB=false
        ;;
    2)
        COMMENT_FSTAB=true
        echo "WARNING: Option 2 is experimental and may be suitable for new Proxmox systems."
        echo "A copy of the /etc/fstab file from your backup will be made, all lines will be commented out, and the copy and saved as /etc/fstab_RESTORED and moved to /etc."
        echo "It is your responsibility to make any necessary configuration updates to /etc/fstab based on /etc/fstab_RESTORED."
        read -p "Are you sure you want to proceed with this option? (y/n): " CONFIRMATION
        if [[ "$CONFIRMATION" != "y" && "$CONFIRMATION" != "Y" ]]; then
            echo "Option aborted. Exiting."
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

BACKUP_ARCHIVE="$1"
if [ ! -f "$BACKUP_ARCHIVE" ]; then
    echo "Error: Backup file '$BACKUP_ARCHIVE' not found." >&2
    exit 1
fi

TEMP_DIR=$(mktemp -d "/tmp/prox_restore.XXXXXX")
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

FOLDER_1="$TEMP_DIR/stage1"
FOLDER_2="$TEMP_DIR/stage2"

mkdir -p "$FOLDER_1" "$FOLDER_2"

tar -zxvf "$BACKUP_ARCHIVE" -C "$FOLDER_1"
find "$FOLDER_1" -name "*.tar" -exec tar xvf '{}' -C "$FOLDER_2" \;

if [ "$COMMENT_FSTAB" = true ]; then
    echo "Processing /etc/fstab"
    if [[ -f "$FOLDER_2/etc/fstab" ]]; then
        # Create commented copy in the extracted tree so it gets installed to /etc/fstab_RESTORED
        sed 's/^/# /' "$FOLDER_2/etc/fstab" > "$FOLDER_2/etc/fstab_RESTORED"
        # Remove /etc/fstab from the extracted tree so the live /etc/fstab is preserved!
        rm -f "$FOLDER_2/etc/fstab"
        echo "Created /etc/fstab_RESTORED. Existing /etc/fstab will NOT be overwritten."
    fi
fi

echo "Stopping PVE services..."
for i in pve-cluster pvedaemon vz qemu-server; do systemctl stop $i ; done || true

echo "Restoring configuration files..."
cp -avr "$FOLDER_2/." /

read -p "Restore complete. Hit 'Enter' to reboot or CTRL+C to cancel."
reboot
