#!/bin/bash
# Home Assistant device config backup/restore script
# Primary usage is to restore device config after a router reboot that messes up iot network IPs
# Usage:
# 1) Put this on homeassistant VM's /root directory and call it once every day with 'crontab -e':
#      @daily  ./devicebackuprestore.sh /homeassistant/.storage/core.config_entries backup
# 2) Put another instance in crontab -e for the restore to run a few minutes after the router reboots
#      <frequency> ./devicebackuprestore.sh /homeassistant/.storage/core.config_entries restore
#
# crontab -e contents for reference:
## backup device config everyday
# @daily /bin/bash /root/devicebackup/devicebackuprestore.sh /homeassistant/.storage/core.config_entries backup
## restore device config 30mins after every monthly router reboot: on 15th of every month at 3.30am and restart homeassistant
# 30 3 15 * * /bin/bash /root/devicebackup/devicebackuprestore.sh /homeassistant/.storage/core.config_entries restore && ha core restart
#
# This script copies a file to a backup location or restores it from backup.
# It requires exactly two arguments: the source file and either "backup" or "restore".

# Function to display usage instructions
usage() {
  echo "Usage: $0 <source_file> [backup|restore]"
  echo "  <source_file>: The file to backup or restore."
  echo "  backup:  Copies the file to a backup location (creates one if needed)."
  echo "  restore: Copies the file back from the backup location."
  exit 1 # Exit with a non-zero code to indicate an error
}

# Check if the number of arguments is exactly 2
if [ "$#" -ne 2 ]; then
  echo "Error: Incorrect number of arguments." >&2 # Output error to standard error
  usage
fi

# Assign arguments to variables for better readability
SOURCE_FILE="$1"
OPERATION="$2"
BACKUP_DIR="/root/devicebackup" # Define your backup directory here

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
  if [ -f "${BACKUP_FILE}" ]; then
    echo "Backup file exists! Making a copy."
    mv "${BACKUP_FILE}" "${BACKUP_FILE}.bak"
  fi

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
