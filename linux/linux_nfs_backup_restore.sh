#!/bin/bash
# (c) Anirudh Acharya 2024
# Linux NFS Backup and Restore Script - backs up and restores local system to/from NFS server
# Run this script from within client Linux with server mounted as /mnt/server

BACKUP_BASE_DIR="/mnt/nfs/sata-ssd/ssd-data/backup/linux"
BACKUP_HOME_SOURCE_DIR=${HOME}
BACKUP_ETC_SOURCE_DIR="/etc"
BACKUP_DST_HOME_DIR="${BACKUP_BASE_DIR}/home"
BACKUP_DST_ETC_DIR="${BACKUP_BASE_DIR}/etc"
# add all backup exclusion regex to the file below
BACKUP_EXCLUDE_LIST="./exclude_linux_nfs_backup.txt"

# /etc directories to backup/restore
ETC_DIRS=(
  'udev'
  'systemd'
  'tlp.d'
)

# /etc files to backup/restore
ETC_FILES=(
  'fstab'
  'auto.pveshare'
  'auto.master'
  'throttled.conf'
  'tlp.conf'
  'environment'
)

# Function to check if mount point is accessible
check_mount() {
  local operation=$1
  echo
  echo "============================================================================================"
  echo "Ensure your backup destination is mounted and accessible before running this script"
  echo "Destination (Linux file system assumed): ${BACKUP_BASE_DIR}"
  if [ "$operation" = "backup" ]; then
    echo "Source Home directory: ${BACKUP_HOME_SOURCE_DIR}"
    echo "Source /etc directory: ${BACKUP_ETC_SOURCE_DIR}"
  else
    echo "Restore Home directory: ${BACKUP_HOME_SOURCE_DIR}"
    echo "Restore /etc directory: ${BACKUP_ETC_SOURCE_DIR}"
  fi
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
  read answer
}

# Function to create necessary directories
create_directories() {
  mkdir -p "${BACKUP_DST_HOME_DIR}"
  mkdir -p "${BACKUP_DST_ETC_DIR}"
  mkdir -p "${BACKUP_DST_ETC_DIR}/udev"
  mkdir -p "${BACKUP_DST_ETC_DIR}/systemd"
}

# Function to backup /etc directories
backup_etc_dirs() {
  echo
  echo "Starting /etc directories backup..."
  echo
  for i in "${ETC_DIRS[@]}"; do
    #don't forget trailing '/' for destination!
    sudo rsync -avHPA --delete /etc/"${i}" ${BACKUP_DST_ETC_DIR}/
  done
}

# Function to backup /etc files
backup_etc_files() {
  echo
  echo "Starting /etc files backup..."
  echo
  for j in "${ETC_FILES[@]}"; do
    #don't forget trailing '/' for destination!
    sudo rsync -avHPA --delete /etc/"${j}" ${BACKUP_DST_ETC_DIR}/
  done
}

# Function to backup home directory
backup_home() {
  echo
  echo "Starting ${BACKUP_HOME_SOURCE_DIR} backup..."
  echo
  # backup home directory
  # following command is only for linux/macos file systems and won't work for exfat/fat32 sources
  rsync -avHPAX --delete --exclude-from=${BACKUP_EXCLUDE_LIST} "${BACKUP_HOME_SOURCE_DIR}" "${BACKUP_DST_HOME_DIR}"
}

# Function to backup GNOME settings
backup_gnome() {
  echo
  echo "Backing up GNOME settings..."
  echo
  dconf dump /org/gnome/ >"${BACKUP_DST_HOME_DIR}/gnome_settings_backup.dconf"
}

# Function to restore /etc directories
restore_etc_dirs() {
  echo
  echo "Starting /etc directories restore..."
  echo
  for i in "${ETC_DIRS[@]}"; do
    if [ -d "${BACKUP_DST_ETC_DIR}/${i}" ]; then
      sudo rsync -avHPA --delete "${BACKUP_DST_ETC_DIR}/${i}" /etc/
    else
      echo "Warning: ${BACKUP_DST_ETC_DIR}/${i} not found, skipping..."
    fi
  done
}

# Function to restore /etc files
restore_etc_files() {
  echo
  echo "Starting /etc files restore..."
  echo
  for j in "${ETC_FILES[@]}"; do
    if [ -f "${BACKUP_DST_ETC_DIR}/${j}" ]; then
      sudo rsync -avHPA --delete "${BACKUP_DST_ETC_DIR}/${j}" /etc/
    else
      echo "Warning: ${BACKUP_DST_ETC_DIR}/${j} not found, skipping..."
    fi
  done
}

# Function to restore home directory
restore_home() {
  echo
  echo "Starting ${BACKUP_HOME_SOURCE_DIR} restore..."
  echo
  # restore home directory
  # following command is only for linux/macos file systems and won't work for exfat/fat32 sources
  if [ -d "${BACKUP_DST_HOME_DIR}/$(basename ${BACKUP_HOME_SOURCE_DIR})" ]; then
    rsync -avHPAX --delete --exclude-from=${BACKUP_EXCLUDE_LIST} "${BACKUP_DST_HOME_DIR}/$(basename ${BACKUP_HOME_SOURCE_DIR})/" "${BACKUP_HOME_SOURCE_DIR}/"
  else
    echo "Warning: ${BACKUP_DST_HOME_DIR}/$(basename ${BACKUP_HOME_SOURCE_DIR}) not found, skipping..."
  fi
}

# Function to restore GNOME settings
restore_gnome() {
  echo
  echo "Restoring GNOME settings..."
  echo
  if [ -f "${BACKUP_DST_HOME_DIR}/gnome_settings_backup.dconf" ]; then
    dconf load /org/gnome/ <"${BACKUP_DST_HOME_DIR}/gnome_settings_backup.dconf"
  else
    echo "Warning: ${BACKUP_DST_HOME_DIR}/gnome_settings_backup.dconf not found, skipping..."
  fi
}

# Function to perform backup operation
do_backup() {
  local NOW=$(date)
  check_mount "backup"
  create_directories
  backup_etc_dirs
  backup_etc_files
  backup_home
  backup_gnome
  echo
  echo "Done! Backup complete: ${NOW}"
  echo "Lastbackup: ${NOW}" >"${BACKUP_DST_HOME_DIR}/lastbackup.log"
  echo
}

# Function to perform restore operation with warning
do_restore() {
  local NOW=$(date)
  echo
  echo "============================================================================================"
  echo "WARNING: RESTORE OPERATION"
  echo "============================================================================================"
  echo
  echo "This operation will OVERWRITE your current system files with backup data."
  echo "This includes:"
  echo "  - /etc configuration files and directories"
  echo "  - Home directory files: ${BACKUP_HOME_SOURCE_DIR}"
  echo "  - GNOME desktop settings"
  echo
  echo "This action CANNOT be easily undone!"
  echo
  echo "Source backup location: ${BACKUP_BASE_DIR}"
  echo
  echo "============================================================================================"
  echo "Type 'RESTORE' (all caps) to confirm and proceed with restore, or anything else to cancel:"
  echo "============================================================================================"
  echo
  read confirmation
  if [ "$confirmation" != "RESTORE" ]; then
    echo
    echo "Restore operation cancelled."
    echo
    exit 0
  fi
  echo
  echo "Restore confirmed. Proceeding..."
  echo
  check_mount "restore"
  restore_etc_dirs
  restore_etc_files
  restore_home
  restore_gnome
  echo
  echo "Done! Restore complete: ${NOW}"
  echo
}

# Main script logic
echo
echo "============================================================================================"
echo "Linux NFS Backup and Restore Script"
echo "============================================================================================"
echo
echo "Select operation:"
echo "  1) Backup"
echo "  2) Restore"
echo
echo "Enter choice (1 or 2): "
read operation

case $operation in
  1)
    do_backup
    ;;
  2)
    do_restore
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
