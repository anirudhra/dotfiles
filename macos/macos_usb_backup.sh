#!/bin/bash
#
# (c) Anirudh Acharya 2024
# macOS Backup script to external USB HDD
#

# macOS backup to an external USB drive.
#
# Usage:
#   bash macos_usb_backup.sh
#   bash macos_usb_backup.sh --dry-run
#   bash macos_usb_backup.sh -n

set -euo pipefail

source "../home/.helperfuncs"
OS_TYPE=$(detect_os_type)

# only run this script on macOS
if [[ "${OS_TYPE}" != "macos" ]]; then
  error "This script is only supported for macOS"
  error "Please do not run this script from Linux/Windows etc."
  error
  exit 1
fi

DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: macos_usb_backup.sh [OPTIONS]

Options:
  -n, --dry-run    Preview transfers and deletions without changing the backup.
  -h, --help       Show this help.

Excluded files already on the backup remain there.
Normal runs use --delete to remove non-excluded destination files
that are no longer present in the corresponding source directory.
EOF
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            die "Unknown option: $1"
            ;;
    esac
    shift
done

# Only run on macOS.
[[ "$(uname -s)" == "Darwin" ]] ||
    die "This script is only supported on macOS."

RSYNC="/usr/bin/rsync"
[[ -x "$RSYNC" ]] || die "rsync not found at $RSYNC"

# External backup drive.
BACKUP_VOLUME="/Volumes/BackupPlus"
DEST_HOME_BASE_DIR="${BACKUP_VOLUME}/BACKUP/data/Mac"
DEST_MEDIA_BASE_DIR="${BACKUP_VOLUME}/BACKUP/music"

# Local source directories.
SOURCE_HOME_BASE_DIR="${HOME}"
SOURCE_MEDIA_BASE_DIR="${HOME}/Music"

# Paths relative to SOURCE_HOME_BASE_DIR.
SOURCE_HOME_DIR_LIST=(
    'Downloads'
    'Documents'
    'Pictures'
)

# Paths relative to SOURCE_MEDIA_BASE_DIR.
SOURCE_MEDIA_DIR_LIST=(
    'MusicLibrary'
)

# Shared exclusions.
# Review the temporary-file patterns before using them:
# files with these names will not be backed up.
RSYNC_EXCLUDES=(
    '--exclude=.DS_Store'
    '--exclude=._*'
    '--exclude=*.tmp'
    '--exclude=*.temp'
    '--exclude=*.swp'
    '--exclude=*.swo'
    '--exclude=*~'
    '--exclude=.~lock.*#'

    # Directory-only exclusions.
    '--exclude=.Trash/'
    '--exclude=.Trashes/'
    '--exclude=.Spotlight-V100/'
    '--exclude=.fseventsd/'
    '--exclude=.TemporaryItems/'
)

# Retain the original transfer options.
RSYNC_OPTIONS=(
    '-hvrltD'
    '--delete'
    '--modify-window=1'
    '--itemize-changes'
)

if [[ "$DRY_RUN" -eq 1 ]]; then
    RSYNC_OPTIONS+=('--dry-run')
fi

# Verify the volume is actually mounted, not merely a leftover directory.
MOUNT_LIST="$(/sbin/mount)"
if ! printf '%s\n' "$MOUNT_LIST" |
    /usr/bin/grep -Fq " on ${BACKUP_VOLUME} ("; then
    die "Backup volume is not mounted at ${BACKUP_VOLUME}"
fi

# Require existing destinations to avoid accidentally using the wrong path.
for destination in "$DEST_HOME_BASE_DIR" "$DEST_MEDIA_BASE_DIR"; do
    [[ -d "$destination" ]] ||
        die "Destination directory does not exist: $destination"

    if [[ "$DRY_RUN" -eq 0 ]]; then
        [[ -w "$destination" ]] ||
            die "Destination directory is not writable: $destination"
    fi
done

# Validate all sources before starting any transfers.
for directory in "${SOURCE_HOME_DIR_LIST[@]}"; do
    source_path="${SOURCE_HOME_BASE_DIR}/${directory}"
    [[ -d "$source_path" ]] ||
        die "Source directory does not exist: $source_path"
done

for directory in "${SOURCE_MEDIA_DIR_LIST[@]}"; do
    source_path="${SOURCE_MEDIA_BASE_DIR}/${directory}"
    [[ -d "$source_path" ]] ||
        die "Source directory does not exist: $source_path"
done

printf '\n============================================================\n'
if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'DRY RUN: no backup files will be changed.\n'
else
    printf 'LIVE BACKUP: transfers and deletions will be performed.\n'
fi

printf '\nHome destination:  %s\n' "$DEST_HOME_BASE_DIR"
printf 'Media destination: %s\n' "$DEST_MEDIA_BASE_DIR"

printf '\nHome directories:\n'
printf '  %s\n' "${SOURCE_HOME_DIR_LIST[@]}"

printf '\nMedia directories under %s:\n' "$SOURCE_MEDIA_BASE_DIR"
printf '  %s\n' "${SOURCE_MEDIA_DIR_LIST[@]}"

printf '\nDestination disk space:\n'
df -h "$DEST_HOME_BASE_DIR" "$DEST_MEDIA_BASE_DIR"

printf '\nExcluded files already in the backup will be retained.\n'
printf 'Non-excluded files missing from the source may be deleted.\n'
printf '============================================================\n\n'

read -r -p "Press Enter to continue, or Ctrl+C to cancel: " answer

backup_directory() {
    local source_path="$1"
    local destination_path="$2"

    local command=(
        "$RSYNC"
        "${RSYNC_OPTIONS[@]}"
        "${RSYNC_EXCLUDES[@]}"
        "$source_path"
        "${destination_path}/"
    )

    printf '\n------------------------------------------------------------\n'
    printf 'Source:      %s\n' "$source_path"
    printf 'Destination: %s/\n' "$destination_path"

    printf 'Command:'
    printf ' %q' "${command[@]}"
    printf '\n\n'

    # No trailing slash on the source:
    # copy the named directory into the destination.
    if "${command[@]}"; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            printf '\nDry run completed: %s\n' "$source_path"
        else
            printf '\nBackup completed: %s\n' "$source_path"
        fi
    else
        die "rsync failed for: $source_path"
    fi
}

for directory in "${SOURCE_HOME_DIR_LIST[@]}"; do
    backup_directory \
        "${SOURCE_HOME_BASE_DIR}/${directory}" \
        "$DEST_HOME_BASE_DIR"
done

for directory in "${SOURCE_MEDIA_DIR_LIST[@]}"; do
    backup_directory \
        "${SOURCE_MEDIA_BASE_DIR}/${directory}" \
        "$DEST_MEDIA_BASE_DIR"
done

# Write completion logs only after all transfers succeed.
# Dry runs do not write logs.
if [[ "$DRY_RUN" -eq 0 ]]; then
    COMPLETED_AT="$(date '+%Y-%m-%d %H:%M:%S %Z')"

    printf 'Backup successfully completed on %s\n' "$COMPLETED_AT" \
        > "${DEST_HOME_BASE_DIR}/log.txt"

    printf 'Backup successfully completed on %s\n' "$COMPLETED_AT" \
        > "${DEST_MEDIA_BASE_DIR}/log.txt"

    printf '\nAll backups completed successfully.\n'
else
    printf '\nDry run completed. No backup files or logs were changed.\n'
fi