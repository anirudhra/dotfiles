#!/bin/bash
# Home Assistant device config backup/restore script
# Primary usage is to restore device config after a router reboot that messes up iot network IPs
# Usage:
# 1) Put this somewhere accessible by Homeassistant, and call it once everyday ~1am to take backup':
#       /media/media/ssd-data/backup/hass/hadevicebackuprestore.sh /homeassistant/.storage/core.config_entries /media/media/ssd-data/backup/hass backup
# 2) Create an automation in HA to run restore ~15mins either after scheduled router reboot and/or after getting a trigger from router for unscheduled reboots
#       /media/media/ssd-data/backup/hass/hadevicebackuprestore.sh /homeassistant/.storage/core.config_entries /media/media/ssd-data/backup/hass restore
#
# This script copies a file to a backup location or restores it from backup.
# It requires exactly three arguments: the source file, backup directory and either "backup" or "restore".

# Function to backup a file if it exists
backup_file_if_exists() {
  local file_path="$1"
  
  if [ -f "${file_path}" ]; then
    echo "Destination file exists! Making a backup copy."
    mv "${file_path}" "${file_path}.bak"
  fi
}

# Function to display usage instructions
usage() {
  echo "Usage: $0 <source_file> <backup_dir> [backup|restore]"
  echo "  <source_file>: The file to backup or restore"
  echo "  <backup_dir>:  The directory to backup to or restore from (creates one, if needed)"
  echo "  backup:        Copies the file to a backup directory"
  echo "  restore:       Copies the file back from the backup directory"
  exit 1 # Exit with a non-zero code to indicate an error
}

# Check if the number of arguments is exactly 2
if [ "$#" -ne 3 ]; then
  echo "Error: Incorrect number of arguments." >&2 # Output error to standard error
  usage
fi

# Assign arguments to variables for better readability
SOURCE_FILE="$1"
OPERATION="$3"
BACKUP_DIR="$2"

# Check if the source file exists
if [ ! -f "${SOURCE_FILE}" ]; then
  echo "Error: Source file '${SOURCE_FILE}' not found." >&2 # Output error to standard error
  exit 1
fi

# Perform the requested operation
case "${OPERATION}" in
backup)
  # Create backup directory if it doesn't exist
  mkdir -p "${BACKUP_DIR}" || {
    echo "Error: Failed to create backup directory '${BACKUP_DIR}'." >&2
    exit 1
  }

  # if the backup already exists, make a copy to keep most recent 2 copies
  BACKUP_FILE="${BACKUP_DIR}/$(basename "${SOURCE_FILE}")" # Get the backup file path
  backup_file_if_exists "${BACKUP_FILE}"

  # Copy the file to the backup directory
  cp -f "${SOURCE_FILE}" "${BACKUP_DIR}/" || {
    echo "Error: Failed to copy '${SOURCE_FILE}' to '${BACKUP_DIR}'." >&2
    exit 1
  }
  echo "Successfully backed up '${SOURCE_FILE}' to '${BACKUP_DIR}'."
  ;;
restore)
  BACKUP_FILE="${BACKUP_DIR}/$(basename "${SOURCE_FILE}")" # Get the backup file path

  # Check if the backup file exists
  if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: Backup file '${BACKUP_FILE}' not found." >&2 # Output error to standard error
    exit 1
  fi

  # Backup the current source file before restoring
  backup_file_if_exists "${SOURCE_FILE}"

  # Copy the backup file back to the source location
  cp -f "${BACKUP_FILE}" "${SOURCE_FILE}" || {
    echo "Error: Failed to restore '${BACKUP_FILE}' to '${SOURCE_FILE}'." >&2
    exit 1
  }
  echo "Successfully restored '${SOURCE_FILE}' from '${BACKUP_DIR}'."
  ;;
*)
  echo "Error: Invalid operation '${OPERATION}'." >&2 # Output error to standard error
  usage
  ;;
esac

exit 0 # Exit with 0 to indicate success
