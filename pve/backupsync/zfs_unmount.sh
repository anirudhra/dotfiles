#!/bin/bash
# (c) Anirudh Acharya 2024
# Unmounts ZFS filesystem and exports the pool for safe USB removal.

set -e

ZFSPOOL="${1:-pvebackup}"

if ! zpool list "${ZFSPOOL}" >/dev/null 2>&1; then
  echo "ZFS pool '${ZFSPOOL}' does not exist."
  exit 1
fi

echo "This will unmount and export the ZFS pool '${ZFSPOOL}'."
read -p "Press Enter to continue or Ctrl+C to abort..."

# Unmount all mounted datasets belonging to this pool
echo "Unmounting datasets in '${ZFSPOOL}'..."
while IFS= read -r dataset; do
  if [ -n "$dataset" ]; then
    zfs unmount "$dataset" 2>/dev/null || true
  fi
done < <(zfs list -H -o name -r "${ZFSPOOL}" 2>/dev/null)

# Export the pool
echo "Exporting pool '${ZFSPOOL}'..."
zpool export "${ZFSPOOL}"

echo "Pool '${ZFSPOOL}' unmounted and exported successfully. Safe to disconnect."
