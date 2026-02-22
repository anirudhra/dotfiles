#!/bin/bash
# (c) Anirudh Acharya 2024
# iPod Music and Playlists Sync script
# Run this script from PVE Server (not one of the LXCs or VMs)
# Only one iPod must be connected when the script is invoked
# Script will keep iPod in sync with the music and playlists on the Server/NAS
# This script expects certain paths/names/hostnames etc. to work correctly

# various server directories
SERVER_BASE_SOURCE_DIR="/mnt/sata-ssd/ssd-media/media/music"
SOURCE_MUSIC_DIR="${SERVER_BASE_SOURCE_DIR}/music"
SOURCE_PLAYLISTS_DIR="${SERVER_BASE_SOURCE_DIR}/playlists"

# ipod directories/mounts/devices
#IPOD5G_MOUNT_DIR="/mnt/IPOD5G"
#IPOD7G_MOUNT_DIR="/mnt/IPOD7G"
IPOD_MOUNT_DIR="/mnt/ipod"
#IPOD5G_DEVICE="/dev/sdb2" #FIXME: /dev/sdX2
#IPOD7G_DEVICE="/dev/sdb1" #FIXME: /dev/sdX1
IPOD_MUSIC_DIR="${IPOD_MOUNT_DIR}/music"
IPOD_PLAYLISTS_DIR="${IPOD_MOUNT_DIR}/playlists"

######################################################################3
# Check if iPod is attached
# iPod device IDs for detection
IPOD7G_DEVID="05ac:1261"
IPOD5G_DEVID="05ac:1209" # "05ac:1262"?

# Function to detect iPod type
detect_ipod() {
  local ipod7g_found=false
  local ipod5g_found=false
  local ipod_count=0

  # Check for iPod 7G
  if lsusb | grep -q "$IPOD7G_DEVID"; then
    ipod7g_found=true
    ipod_count=$((ipod_count + 1))
    echo "Found iPod 7G (Device ID: $IPOD7G_DEVID)"
  fi

  # Check for iPod 5G
  if lsusb | grep -q "$IPOD5G_DEVID"; then
    ipod5g_found=true
    ipod_count=$((ipod_count + 1))
    echo "Found iPod 5G (Device ID: $IPOD5G_DEVID)"
  fi

  # Validate detection results
  if [ $ipod_count -eq 0 ]; then
    echo "No iPod found! Please connect an iPod and try again."
    echo "Supported devices:"
    echo "  - iPod 5G (Device ID: $IPOD5G_DEVID)"
    echo "  - iPod 7G (Device ID: $IPOD7G_DEVID)"
    exit 1
  elif [ $ipod_count -gt 1 ]; then
    echo "Multiple iPods detected! Only one iPod can be connected when this script is invoked."
    echo "Please disconnect one iPod and re-run the script."
    exit 1
  fi

  # Return detected type
  if [ "$ipod7g_found" = true ]; then
    echo "IPOD_TYPE=7G"
  elif [ "$ipod5g_found" = true ]; then
    echo "IPOD_TYPE=5G"
  fi
}

# Function to suggest mount command based on iPod type
suggest_mount_command() {
  local ipod_type="$1"

  echo "Suggested mount commands for iPod $ipod_type:"
  echo

  # Find USB storage devices
  echo "Available USB storage devices:"
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "(sd[a-z]|usb)" || echo "No USB storage devices found"
  echo

  if [ "$ipod_type" = "7G" ]; then
    echo "For iPod 7G, typically use: mount /dev/sdX1 ${IPOD_MOUNT_DIR}"
    echo "  (where sdX is your iPod device, partition 1)"
  elif [ "$ipod_type" = "5G" ]; then
    echo "For iPod 5G, typically use: mount /dev/sdX2 ${IPOD_MOUNT_DIR}"
    echo "  (where sdX is your iPod device, partition 2)"
  fi

  echo
  echo "To find the correct device, you can use:"
  echo "  dmesg | tail -20  # Shows recent USB device connections"
  echo "  lsblk             # Shows all block devices"
  echo "  fdisk -l          # Shows detailed partition information"
}

# Detect iPod and set type
echo "Detecting connected iPod..."
IPOD_INFO=$(detect_ipod)
IPOD_TYPE=$(echo "$IPOD_INFO" | grep "IPOD_TYPE=" | cut -d'=' -f2)

if [ -z "$IPOD_TYPE" ]; then
  echo "Failed to determine iPod type. Exiting."
  exit 1
fi

######################################################################3
# unmount, create mount point (failsafe) and mount ipod
#umount $ipod_device
#mkdir -p "${IPOD_MOUNT_DIR}"
#mount ${IPOD_DEVICE} ${IPOD_MOUNT_DIR}
#ls ${IPOD_MOUNT_DIR}

# manually mount instead of auto, too many corne cases for now
# ipod7g has /dev/sdX1 as the partition while ipod5g has /dev/sdX2 as the partition
echo
echo "==============================================================================="
echo "Detected iPod $IPOD_TYPE - Ensure your iPod is mounted at ${IPOD_MOUNT_DIR}"
echo

# Show mount suggestions based on detected iPod type
suggest_mount_command "$IPOD_TYPE"

echo "==============================================================================="
echo
echo "Contents of ${IPOD_MOUNT_DIR}:"
echo
ls "${IPOD_MOUNT_DIR}"
echo
echo "==============================================================================="
echo "Disk space usage of ${IPOD_MOUNT_DIR}"
df -h "${IPOD_MOUNT_DIR}"
echo
echo "==============================================================================="
echo
echo "Source music dir: ${SOURCE_MUSIC_DIR}"
echo "Source playlist dir: ${SOURCE_PLAYLISTS_DIR}"
echo "Destination music dir:${IPOD_MUSIC_DIR}"
echo "Destination playlist dir:${IPOD_PLAYLISTS_DIR}"
echo
echo "==========================================================================================="
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "==========================================================================================="

# read into dummy variable to pause
read answer

# create destination ipod directories, in case they don't exist
mkdir -p "${IPOD_PLAYLISTS_DIR}"
mkdir -p "${IPOD_MUSIC_DIR}"

######################################################################3
# sync playlists and music with progress shown
echo "Syncing playlists..."
echo

# --size-only is for quick check, -c can be added for complete checksum instead (slower)
RSYNC_OPTS=(
  -hvr
  --size-only
  --modify-window=2
  --delete
)

# enhanced list of options, should work for fat32 systems, but untested at this time
RSYNC_OPTS_EXTRA=(
  -rltv
  #  --hvr
  #  --size-only
  --info=progress2
  --delete
  --inplace
  --no-owner
  --no-group
  --no-perms
  --no-acls
  --no-xattrs
  --chmod=ugo=rwX
  #  --modify-window=1
  --modify-window=2
)

# Don't forget the leading "/" in front of source directories to specify copying the
# contents of that dir and not the dir itself!
#rsync -hvr --size-only --modify-window=2 --delete "${SOURCE_PLAYLISTS_DIR}/" "${IPOD_PLAYLISTS_DIR}"
rsync -"${RSYNC_OPTS[@]}" "${SOURCE_PLAYLISTS_DIR}/" "${IPOD_PLAYLISTS_DIR}"

echo
echo "Syncing music..."
echo
# sync music files
#rsync -hvr --size-only --modify-window=2 --delete "${SOURCE_MUSIC_DIR}/" "${IPOD_MUSIC_DIR}"
rsync "${RSYNC_OPTS[@]}" "${SOURCE_MUSIC_DIR}/" "${IPOD_MUSIC_DIR}"

######################################################################3
# done
echo
echo "==============================================================================="
echo " All done. Manually unmount iPod after verifying with the command: "
echo " umount ${IPOD_MOUNT_DIR}"
echo "==============================================================================="
echo

# end of script
