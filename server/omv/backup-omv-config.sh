#!/usr/bin/env bash
# (c) Anirudh Acharya
# OpenMediaVault Configuration Backup Script
# Archives core OMV databases, Samba configs, Salt states, and system network settings.

set -euo pipefail

BACKUP_DIR="/mnt/storage/data/backup/omv"
STORAGE_ROOT="/mnt/storage"
MAX_BACKUPS=5

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Archives critical OpenMediaVault databases, Salt states, Samba settings,
and system configuration files.

OPTIONS:
  -d, --dest DIR     Target backup directory (default: /mnt/storage/data/backup/omv)
  -k, --keep COUNT   Number of backup archives to retain (default: 5)
  -h, --help         Display this help message and exit

EXAMPLES:
  sudo $(basename "$0")
  sudo $(basename "$0") --keep 10
  sudo $(basename "$0") --dest /mnt/backup/omv
EOF
}

# Parse CLI options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dest)
      [[ $# -ge 2 ]] || { echo "Error: Option $1 requires a directory argument" >&2; exit 1; }
      BACKUP_DIR="$2"
      shift 2
      ;;
    -k|--keep)
      [[ $# -ge 2 ]] || { echo "Error: Option $1 requires a numeric argument" >&2; exit 1; }
      MAX_BACKUPS="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      show_help
      exit 1
      ;;
  esac
done

# 1. Require root privileges
if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: This script must be run as root or with sudo." >&2
  echo "Root access is required to read /etc/openmediavault/config.xml and Samba secrets." >&2
  exit 1
fi

# 2. Verify that storage mount exists before creating backup directories
# Prevents creating directories and writing archives to the root partition if storage is unmounted.
if [[ "${BACKUP_DIR}" == "${STORAGE_ROOT}"* ]] && [[ ! -d "${STORAGE_ROOT}" ]]; then
  echo "Error: Base storage mount '${STORAGE_ROOT}' does not exist or is unmounted." >&2
  echo "Aborting backup to prevent writing to the root OS partition." >&2
  exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="omv_config_backup_${TIMESTAMP}.tar.gz"
TEMP_DIR=$(mktemp -d /tmp/omv_backup_XXXXXX)

cleanup() {
  rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# Ensure backup destination directory exists
mkdir -p "${BACKUP_DIR}"

echo "Starting OpenMediaVault configuration backup: ${TIMESTAMP}"
echo "Destination: ${BACKUP_DIR}/${ARCHIVE_NAME}"

# Stage critical OMV & system configuration paths if they exist
mkdir -p "${TEMP_DIR}/omv_configs"

CONFIG_PATHS=(
  "/etc/openmediavault"
  "/var/lib/openmediavault"
  "/etc/samba"
  "/etc/fstab"
  "/etc/network"
  "/etc/netplan"
  "/etc/default/openmediavault"
  "/etc/monit"
  "/srv/salt"
)

for path in "${CONFIG_PATHS[@]}"; do
  if [[ -e "${path}" ]]; then
    cp -a --parents "${path}" "${TEMP_DIR}/omv_configs/" 2>/dev/null || true
  fi
done

# Create compressed tar archive
tar -czf "${BACKUP_DIR}/${ARCHIVE_NAME}" -C "${TEMP_DIR}/omv_configs" .

ARCHIVE_SIZE=$(du -h "${BACKUP_DIR}/${ARCHIVE_NAME}" | cut -f1)
echo "Created backup archive: ${BACKUP_DIR}/${ARCHIVE_NAME} (${ARCHIVE_SIZE})"

# Prune older backups
echo "Checking existing backups (retention: ${MAX_BACKUPS})..."
CURRENT_COUNT=$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" | wc -l | tr -d ' ')

if (( CURRENT_COUNT > MAX_BACKUPS )); then
  find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" -printf "%T@ %p\n" \
    | sort -n \
    | head -n -"${MAX_BACKUPS}" \
    | cut -d' ' -f2- \
    | while IFS= read -r old_backup; do
        echo "Removing old backup: ${old_backup}"
        rm -f "${old_backup}"
      done
fi

TOTAL_KEPT=$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" | wc -l | tr -d ' ')
echo "OMV configuration backup completed successfully. Total backups kept: ${TOTAL_KEPT}"
