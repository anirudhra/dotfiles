#!/usr/bin/env bash
# (c) Anirudh Acharya
# OpenMediaVault Samba Recycle Bin Cleanup Script
# Prunes deleted files older than 30 days and removes empty directories from Samba .recycle folders.
# Designed for automated execution via monthly cron job.

set -euo pipefail

STORAGE_ROOT="/mnt/storage"
RETENTION_DAYS=30
DRY_RUN=0

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Prunes Samba recycle bin files older than ${RETENTION_DAYS} days from ${STORAGE_ROOT}.

OPTIONS:
  -n, --dry-run      Preview files and directories that would be deleted without removing them.
  -s, --storage DIR  Override base storage root (default: /mnt/storage).
  -h, --help         Show this help message and exit.

EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -s|--storage)
      [[ $# -ge 2 ]] || { echo "Error: Option $1 requires a path argument" >&2; exit 1; }
      STORAGE_ROOT="$2"
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

# Verify base storage directory exists and is accessible
if [[ ! -d "${STORAGE_ROOT}" ]]; then
  echo "Error: Base storage path ${STORAGE_ROOT} does not exist or is not mounted." >&2
  exit 1
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "=========================================================================="
echo "Samba Recycle Bin Cleanup: ${TIMESTAMP}"
echo "Storage Root:   ${STORAGE_ROOT}"
echo "Retention:      Files older than ${RETENTION_DAYS} days"
if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "Mode:           DRY RUN (no files will be deleted)"
else
  echo "Mode:           LIVE PRUNE"
fi
echo "=========================================================================="

# Track statistics
TOTAL_BINS=0
FILES_PROCESSED=0

# Use -prune on outer find to locate .recycle folders in a SINGLE pass without
# recursing deeper into the recycle folder tree itself, cutting disk I/O in half.
while IFS= read -r recycle_dir; do
  [[ -z "${recycle_dir}" ]] && continue
  TOTAL_BINS=$((TOTAL_BINS + 1))
  echo "Processing recycle bin: ${recycle_dir}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    # Preview old files
    OLD_FILES=$(find -L "${recycle_dir}" -type f -mtime +"${RETENTION_DAYS}")
    if [[ -n "${OLD_FILES}" ]]; then
      echo "${OLD_FILES}" | while IFS= read -r f; do
        echo "  [Would delete] ${f}"
      done
      COUNT=$(echo "${OLD_FILES}" | wc -l | tr -d ' ')
      FILES_PROCESSED=$((FILES_PROCESSED + COUNT))
    else
      echo "  No files older than ${RETENTION_DAYS} days."
    fi

    # Preview empty dirs
    find -L "${recycle_dir}" -mindepth 1 -type d -empty | while IFS= read -r d; do
      echo "  [Would delete empty dir] ${d}"
    done
  else
    # 1. Delete regular files older than retention limit
    DELETED_COUNT=$(find -L "${recycle_dir}" -type f -mtime +"${RETENTION_DAYS}" -print -delete | wc -l | tr -d ' ')
    FILES_PROCESSED=$((FILES_PROCESSED + DELETED_COUNT))

    # 2. Delete empty directories leftover inside this .recycle folder
    find -L "${recycle_dir}" -mindepth 1 -type d -empty -delete 2>/dev/null || true

    echo "  Cleaned: ${DELETED_COUNT} file(s) deleted."
  fi
done < <(find -L "${STORAGE_ROOT}" -type d -iname ".recycle" -prune 2>/dev/null)

echo "=========================================================================="
if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "Dry run complete. Found ${TOTAL_BINS} recycle bin(s), ${FILES_PROCESSED} eligible file(s)."
else
  echo "Recycle bin cleanup completed. Processed ${TOTAL_BINS} recycle bin(s), removed ${FILES_PROCESSED} file(s)."
fi
echo "=========================================================================="
