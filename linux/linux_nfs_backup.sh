#!/bin/bash
# (c) Anirudh Acharya 2024
# Linux NFS Backup Script - backs up local system to NFS server
# Run this script from within client Linux with server mounted as /mnt/server

BACKUP_BASE_DIR="/mnt/nfs/sata-ssd/ssd-data/backup/linux"
BACKUP_HOME_SOURCE_DIR=${HOME}
BACKUP_ETC_SOURCE_DIR="/etc"
BACKUP_DST_HOME_DIR="${BACKUP_BASE_DIR}/home"
BACKUP_DST_ETC_DIR="${BACKUP_BASE_DIR}/etc"
# add all backup exclusion regex to the file below
BACKUP_EXCLUDE_LIST="./exclude_linux_nfs_backup.txt"

# timestamp
NOW=$(date)

#confirm external storage/destination is mounted correctly before proceeding
echo
echo "============================================================================================"
echo "Ensure your backup destination is mounted and accessible before running this script"
echo "Destination (Linux file system assumed): ${BACKUP_BASE_DIR}"
echo "Source Home directory: ${BACKUP_HOME_SOURCE_DIR}"
echo "Source /etc directory: ${BACKUP_ETC_SOURCE_DIR}"
echo "============================================================================================"
echo
echo "Contents of ${BACKUP_BASE_DIR}:"
echo
ls ${BACKUP_BASE_DIR}
echo "============================================================================================"
echo
echo "Disk space usage of ${BACKUP_BASE_DIR}"
df -h ${BACKUP_BASE_DIR}
echo "============================================================================================"
echo
echo "============================================================================================"
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "============================================================================================"
echo

# read into dummy variable to pause
read answer

#failsafe
mkdir -p "${BACKUP_DST_HOME_DIR}"
mkdir -p "${BACKUP_DST_ETC_DIR}"

mkdir -p "${BACKUP_DST_ETC_DIR}/udev"
mkdir -p "${BACKUP_DST_ETC_DIR}/systemd"

# run backup commands
echo
echo Starting /etc backup...
echo
#
# rsync individual and small directories first
#

# /etc directories to backup
ETC_DIRS=(
  'udev'
  'systemd'
  'tlp.d'
)

# /etc files to backup
ETC_FILES=(
  'fstab'
  'auto.pveshare'
  'auto.master'
  'throttled.conf'
  'tlp.conf'
  'environment'
)

# backup /etc/ directories
for i in "${ETC_DIRS[@]}"; do
  #don't forget trailing '/' for destination!
  sudo rsync -avHPA --delete /etc/"${i}" ${BACKUP_DST_ETC_DIR}/
done

# backup /etc/ files
for j in "${ETC_FILES[@]}"; do
  #don't forget trailing '/' for destination!
  sudo rsync -avHPA --delete /etc/"${j}" ${BACKUP_DST_ETC_DIR}/
done

# run home backup commands
echo
echo "Starting ${BACKUP_HOME_SOURCE_DIR} backup..."
echo
# backup home directory
# following command is only for linux/macos file systems and won't work for exfat/fat32 sources
rsync -avHPAX --delete --exclude-from=${BACKUP_EXCLUDE_LIST} "${BACKUP_HOME_SOURCE_DIR}" "${BACKUP_DST_HOME_DIR}"

echo
echo "Backing up GNOME settings..."
echo
dconf dump /org/gnome/ >"${BACKUP_DST_HOME_DIR}/gnome_settings_backup.dconf"

echo
echo "Done! Backup complete: ${NOW}"
echo "Lastbackup: ${NOW}" >"${BACKUP_DST_HOME_DIR}/lastbackup.log"
echo
# end of script
#
