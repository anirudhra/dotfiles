#!/usr/bin/env bash
# (c) Anirudh Acharya
# OpenMediaVault Configuration Restore Script
# Restores core OMV databases, Samba settings, and Salt configurations from backup.

set -euo pipefail

BACKUP_DIR="/mnt/storage/data/backup/omv"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ROLLBACK_DIR="/root/omv_rollback_${TIMESTAMP}"
TARGET_ARCHIVE=""
FORCE=0

# Selective restoration options
RESTORE_NETWORK=0
RESTORE_FSTAB=0
RESTORE_SALT=0

usage() {
  cat << 'EOF'
Usage: restore-omv-config.sh [OPTIONS] [ARCHIVE_PATH]

Safely restores OpenMediaVault configuration databases, Samba settings,
and daemon configs from a backup tarball, then runs omv-salt synchronization.

OPTIONS:
  -l, --list             List available configuration backups in the backup directory.
  -n, --latest           Target the newest available backup in the backup directory.
  -d, --dest DIR         Directory to search for backups (default: /mnt/storage/data/backup/omv).
      --restore-network  Restore /etc/network and /etc/netplan (disabled by default to avoid lockout).
      --restore-fstab    Restore /etc/fstab (disabled by default to prevent mount conflicts).
      --restore-salt     Restore /srv/salt (disabled by default; Salt states are managed by OMV packages).
      --restore-all      Restore all files in archive including network, fstab, and salt.
  -y, --yes              Skip interactive confirmation prompt (non-interactive).
  -h, --help             Show this help menu and exit.

ARGUMENTS:
  ARCHIVE_PATH           Path to a specific .tar.gz backup archive.

EXAMPLES:
  # View all backups currently stored on disk:
  sudo restore-omv-config.sh --list

  # Interactively select and restore the newest backup (core OMV & Samba):
  sudo restore-omv-config.sh --latest

  # Restore a specific backup with network configuration:
  sudo restore-omv-config.sh --restore-network /mnt/storage/data/backup/omv/omv_config_backup_20261009.tar.gz

EOF
}

list_backups() {
  echo "Available OMV configuration backups in ${BACKUP_DIR}:"
  echo "--------------------------------------------------------------------------------"
  if [[ ! -d "${BACKUP_DIR}" ]]; then
    echo "Directory ${BACKUP_DIR} not found."
    return 1
  fi

  local count=0
  while IFS= read -r file; do
    if [[ -n "${file}" ]]; then
      count=$((count + 1))
      local fsize fdate
      fsize=$(du -h "${file}" | cut -f1)
      fdate=$(date -r "${file}" "+%Y-%m-%d %H:%M:%S")
      printf "[%2d]  %-19s  %-7s  %s\n" "${count}" "${fdate}" "${fsize}" "${file}"
    fi
  done < <(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -nr | cut -d' ' -f2-)

  if [[ ${count} -eq 0 ]]; then
    echo "No configuration backup archives found."
  fi
  echo "--------------------------------------------------------------------------------"
}

# Parse CLI flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -l|--list)
      list_backups
      exit 0
      ;;
    -d|--dest)
      [[ $# -ge 2 ]] || { echo "Error: Option $1 requires an argument" >&2; exit 1; }
      BACKUP_DIR="$2"
      shift 2
      ;;
    -n|--latest)
      if [[ ! -d "${BACKUP_DIR}" ]]; then
        echo "Error: Directory ${BACKUP_DIR} does not exist." >&2
        exit 1
      fi
      TARGET_ARCHIVE=$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "omv_config_backup_*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)
      shift
      ;;
    --restore-network)
      RESTORE_NETWORK=1
      shift
      ;;
    --restore-fstab)
      RESTORE_FSTAB=1
      shift
      ;;
    --restore-salt)
      RESTORE_SALT=1
      shift
      ;;
    --restore-all)
      RESTORE_NETWORK=1
      RESTORE_FSTAB=1
      RESTORE_SALT=1
      shift
      ;;
    -y|--yes)
      FORCE=1
      shift
      ;;
    -*)
      echo "Error: Unknown option '$1'" >&2
      echo "Run 'restore-omv-config.sh --help' for usage." >&2
      exit 1
      ;;
    *)
      TARGET_ARCHIVE="$1"
      shift
      ;;
  esac
done

# Require root
if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: This script must be run as root or with sudo." >&2
  exit 1
fi

# If no archive specified, show list and help
if [[ -z "${TARGET_ARCHIVE}" ]]; then
  echo "Error: No backup archive specified." >&2
  echo ""
  list_backups
  echo ""
  echo "Specify a file path or pass '--latest' to target the most recent backup."
  echo "See 'restore-omv-config.sh --help' for options."
  exit 1
fi

# Verify archive exists
if [[ ! -f "${TARGET_ARCHIVE}" ]]; then
  echo "Error: Archive file '${TARGET_ARCHIVE}' not found." >&2
  exit 1
fi

# Inspect contents before asking
echo "Validating backup archive..."
if ! tar -tzf "${TARGET_ARCHIVE}" >/dev/null 2>&1; then
  echo "Error: '${TARGET_ARCHIVE}' is corrupt or not a valid gzip tar archive." >&2
  exit 1
fi

echo ""
echo "================================ [ WARNING ] ================================"
echo "You are about to restore OpenMediaVault configurations from:"
echo "  Archive: ${TARGET_ARCHIVE}"
echo "  Created: $(date -r "${TARGET_ARCHIVE}" "+%Y-%m-%d %H:%M:%S")"
echo "  Size:    $(du -h "${TARGET_ARCHIVE}" | cut -f1)"
echo ""
echo "Components to restore:"
echo "  [x] Core OMV database (/etc/openmediavault, /var/lib/openmediavault)"
echo "  [x] Samba configuration (/etc/samba)"
if [[ "${RESTORE_NETWORK}" -eq 1 ]]; then
  echo "  [x] Network configuration (/etc/network, /etc/netplan)"
else
  echo "  [ ] Network configuration (omitted; pass --restore-network to include)"
fi
if [[ "${RESTORE_FSTAB}" -eq 1 ]]; then
  echo "  [x] Filesystem mounts (/etc/fstab)"
else
  echo "  [ ] Filesystem mounts (omitted; pass --restore-fstab to include)"
fi
if [[ "${RESTORE_SALT}" -eq 1 ]]; then
  echo "  [x] Salt states (/srv/salt)"
else
  echo "  [ ] Salt states (omitted; package-managed state recipes preserved)"
fi
echo ""
echo "A safety pre-restore backup will be created in:"
echo "  ${ROLLBACK_DIR}"
echo "============================================================================="
echo ""

if [[ "${FORCE}" -ne 1 ]]; then
  read -rp "Type 'RESTORE' to confirm and proceed: " CONFIRM
  if [[ "${CONFIRM}" != "RESTORE" ]]; then
    echo "Confirmation mismatch ('${CONFIRM}' != 'RESTORE'). Operation canceled."
    exit 0
  fi
fi

TEMP_RESTORE=$(mktemp -d /tmp/omv_restore_XXXXXX)
cleanup() {
  rm -rf "${TEMP_RESTORE}"
}
trap cleanup EXIT

echo "Stopping OpenMediaVault engines and Samba daemons..."
systemctl stop openmediavault-engined smbd nmbd 2>/dev/null || true

# Prepare rollback list based on what is being restored
ROLLBACK_TARGETS=(
  "/etc/openmediavault"
  "/var/lib/openmediavault"
  "/etc/samba"
)
if [[ "${RESTORE_NETWORK}" -eq 1 ]]; then
  ROLLBACK_TARGETS+=("/etc/network" "/etc/netplan")
fi
if [[ "${RESTORE_FSTAB}" -eq 1 ]]; then
  ROLLBACK_TARGETS+=("/etc/fstab")
fi
if [[ "${RESTORE_SALT}" -eq 1 ]]; then
  ROLLBACK_TARGETS+=("/srv/salt")
fi

echo "Creating safety snapshot of current configuration in ${ROLLBACK_DIR}..."
mkdir -p "${ROLLBACK_DIR}"
for path in "${ROLLBACK_TARGETS[@]}"; do
  if [[ -e "${path}" ]]; then
    cp -a --parents "${path}" "${ROLLBACK_DIR}/" 2>/dev/null || true
  fi
done

echo "Extracting backup archive..."
tar -xzf "${TARGET_ARCHIVE}" -C "${TEMP_RESTORE}"

echo "Restoring core configuration files..."
if [[ -d "${TEMP_RESTORE}/etc/openmediavault" ]]; then
  cp -a "${TEMP_RESTORE}/etc/openmediavault/." /etc/openmediavault/
fi

if [[ -d "${TEMP_RESTORE}/var/lib/openmediavault" ]]; then
  cp -a "${TEMP_RESTORE}/var/lib/openmediavault/." /var/lib/openmediavault/
fi

if [[ -d "${TEMP_RESTORE}/etc/samba" ]]; then
  cp -a "${TEMP_RESTORE}/etc/samba/." /etc/samba/
fi

if [[ "${RESTORE_SALT}" -eq 1 && -d "${TEMP_RESTORE}/srv/salt" ]]; then
  echo "Restoring /srv/salt..."
  cp -a "${TEMP_RESTORE}/srv/salt/." /srv/salt/
fi

if [[ "${RESTORE_NETWORK}" -eq 1 ]]; then
  if [[ -d "${TEMP_RESTORE}/etc/network" ]]; then
    echo "Restoring /etc/network..."
    cp -a "${TEMP_RESTORE}/etc/network/." /etc/network/
  fi
  if [[ -d "${TEMP_RESTORE}/etc/netplan" ]]; then
    echo "Restoring /etc/netplan..."
    cp -a "${TEMP_RESTORE}/etc/netplan/." /etc/netplan/
  fi
fi

if [[ "${RESTORE_FSTAB}" -eq 1 && -f "${TEMP_RESTORE}/etc/fstab" ]]; then
  echo "Restoring /etc/fstab..."
  cp -a "${TEMP_RESTORE}/etc/fstab" /etc/fstab
fi

echo "Setting permissions and file ownership..."
chown -R openmediavault:openmediavault /var/lib/openmediavault 2>/dev/null || true
chown -R root:openmediavault /etc/openmediavault 2>/dev/null || true
chmod 600 /etc/openmediavault/config.xml 2>/dev/null || true

echo "Synchronizing system states via omv-salt (this takes ~30-60 seconds)..."
omv-salt deploy run all

echo "Restarting services..."
systemctl restart openmediavault-engined
systemctl restart nginx
systemctl restart smbd nmbd 2>/dev/null || true

# Dynamically discover active server IP for WebGUI
PRIMARY_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "10.100.10.10")

echo "--------------------------------------------------------"
echo "Restore completed successfully."
echo "Safety rollback copy preserved at: ${ROLLBACK_DIR}"
echo "WebGUI accessible at: http://${PRIMARY_IP}"
echo "--------------------------------------------------------"
