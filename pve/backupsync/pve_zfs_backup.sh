#!/bin/sh
#
# (c) Anirudh Acharya 2024
# Script to backup PVE server
# Used in conjunction with exclude_pve_zfs_backup.txt to specify exclusions
# Before backing up mount external USB ZFS with zfs_mount.sh script and after
# backup, unmount the ZFS fs and export the pool cleanly with zfs_umount.sh script before
# disconnecting to avoid data loss
#
# mv /hdpool/fs/log/server_backup.log /hdpool/fs/log/server_backup_prev.log
#
# add all exclusion directories to the _exclude external file below, all output logged to file
# verbose version of above
#

#zfspool="pvebackup"
MOUNTPOINT="zfsdata"
#backup_dest="/${pvebackup}/${mountpoint}"
# zfs fs mountpoint does not include zpool anymore
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DEST="/${MOUNTPOINT}"
BACKUP_DEST_DIR="${BACKUP_DEST}/pve_backup"
BACKUP_SOURCE_DIR="/mnt/sata-ssd"
BACKUP_EXCLUDE_LIST="${SCRIPT_DIR}/exclude_pve_zfs_backup.txt"

# Verify backup destination is an active mountpoint to prevent writing to rootfs
if ! mountpoint -q "${BACKUP_DEST}"; then
  echo "ERROR: Backup destination '${BACKUP_DEST}' is NOT a mounted filesystem!" >&2
  echo "Aborting backup to prevent filling the PVE host root filesystem." >&2
  exit 1
fi

if [ ! -f "${BACKUP_EXCLUDE_LIST}" ]; then
  echo "ERROR: Exclude list '${BACKUP_EXCLUDE_LIST}' not found!" >&2
  exit 1
fi

#confirm backup destination is available and correct
echo
echo "==============================================================================="
echo "Ensure your backup destination is mounted correctly before running this script"
echo
echo "Backup destination: ${BACKUP_DEST}"
echo "Backup destination directory: ${BACKUP_DEST_DIR}"
echo "Backup source directory: ${BACKUP_SOURCE_DIR}"
echo "Backup exclude list: ${BACKUP_EXCLUDE_LIST}"
echo "==============================================================================="
echo
echo "Contents of backup destination - ${BACKUP_DEST}:"
echo
ls -la "${BACKUP_DEST}"
echo
echo "==============================================================================="
echo "Disk space usage of destination: ${BACKUP_DEST}"
echo
df -h ${BACKUP_DEST}
echo
echo "==============================================================================="
echo
echo "Command: rsync -avHPAX --delete --exclude-from=${BACKUP_EXCLUDE_LIST} ${BACKUP_SOURCE_DIR} ${BACKUP_DEST_DIR}"
echo
echo
echo "==========================================================================================="
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "==========================================================================================="

# read into dummy variable to pause
read answer
echo
echo "Starting backup..."
echo

mkdir -p ${BACKUP_DEST_DIR}
# -avHPAX should handle linux/macos volumes fine, not intended for fat32/vfat destinations
rsync -avHPAX --delete --exclude-from=${BACKUP_EXCLUDE_LIST} ${BACKUP_SOURCE_DIR} ${BACKUP_DEST_DIR}

TODAY=$(date '+%Y-%m-%d')

echo "Backup complete: ${TODAY}"
echo "Backed up on ${TODAY}" >"${BACKUP_DEST}/log.txt"
echo
