#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/mnt/storage/data/backup/omv"
MAX_BACKUPS=5
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="omv_config_backup_${TIMESTAMP}.tar.gz"
TEMP_DIR=$(mktemp -d /tmp/omv_backup_XXXXXX)

# Ensure backup destination directory exists
mkdir -p "${BACKUP_DIR}"

cleanup() {
  rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

echo "Starting OpenMediaVault configuration backup: ${TIMESTAMP}"

# Stage critical OMV & system configuration paths if they exist
mkdir -p "${TEMP_DIR}/omv_configs"

CONFIG_PATHS=(
  "/etc/openmediavault"
  "/var/lib/openmediavault"
  "/etc/samba"
  "/etc/fstab"
  "/etc/network"
  "/etc/netplan"
  "/srv/salt"
)

for path in "${CONFIG_PATHS[@]}"; do
  if [[ -e "${path}" ]]; then
    # Preserve permissions and directory hierarchy
    cp -a --parents "${path}" "${TEMP_DIR}/omv_configs/" 2>/dev/null || true
  fi
done

# Create compressed tar archive directly in the backup directory
tar -czf "${BACKUP_DIR}/${ARCHIVE_NAME}" -C "${TEMP_DIR}/omv_configs" .

echo "Created backup archive: ${BACKUP_DIR}/${ARCHIVE_NAME}"

# Prune older backups: keep only the latest 5 archives
echo "Checking existing backups (retention: ${MAX_BACKUPS})..."
CURRENT_COUNT=$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" | wc -l)

if (( CURRENT_COUNT > MAX_BACKUPS )); then
  # Sort files oldest first and delete excess
  find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" -printf "%T@ %p\n" \
    | sort -n \
    | head -n -"${MAX_BACKUPS}" \
    | cut -d' ' -f2- \
    | while IFS= read -r old_backup; do
        echo "Removing old backup: ${old_backup}"
        rm -f "${old_backup}"
      done
fi

echo "OMV configuration backup completed successfully. Total backups kept: $(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" | wc -l)"
