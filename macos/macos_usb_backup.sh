#!/bin/bash
#
# (c) Anirudh Acharya 2024
# macOS Backup script to external USB HDD
#
source "../home/.helperfuncs"
OS_TYPE=$(detect_os_type)

# only run this script on macOS
if [[ "${OS_TYPE}" != "macos" ]]; then
  err "This script is only supported for macOS"
  err "Please do not run this script from Linux/Windows etc."
  err
  exit 1
fi

# on external USB drive, one for home and one for media
DEST_HOME_BASE_DIR="/Volumes/BackupPlus/BACKUP/data/Mac"
DEST_MEDIA_BASE_DIR="/Volumes/BackupPlus/BACKUP/music"

# on local macOS
SOURCE_HOME_BASE_DIR="${HOME}"
SOURCE_MEDIA_BASE_DIR="${HOME}/Music"

#confirm external storage/destination is mounted correctly before proceeding
echo
echo "==============================================================================="
echo "Ensure your External USB is mounted correctly before running this script!"
echo "Home will be backed up to: ${DEST_HOME_BASE_DIR}"
echo "Media will be backed up to: ${DEST_MEDIA_BASE_DIR}"
echo "==============================================================================="
echo
echo "Contents of destination Home: ${DEST_HOME_BASE_DIR}:"
echo
ls ${DEST_HOME_BASE_DIR}
echo
echo "========================"
echo
echo "Contents of destination Media: ${DEST_MEDIA_BASE_DIR}:"
echo
ls ${DEST_MEDIA_BASE_DIR}
echo
echo "==============================================================================="
echo "Disk space usage of ${DEST_HOME_BASE_DIR} and ${DEST_MEDIA_BASE_DIR}"
echo
df -h ${DEST_HOME_BASE_DIR}
echo
df -h ${DEST_MEDIA_BASE_DIR}
echo
echo "============================================================================================"
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "============================================================================================"
echo
read ans #dummy variable to pause script

# only these folders from user's home
SOURCE_HOME_DIR_LIST=(
  'Downloads'
  'Documents'
  'Pictures'
)

# media directories to be backed up
# path is relative to user's home
SOURCE_MEDIA_DIR_LIST=(
  'MusicLibrary'
)

echo "================================================================================"
echo " Backing up following directories from user's home directory: $HOME"
echo " Source Directories: ${SOURCE_HOME_DIR_LIST[@]}"
echo " Destination: ${DEST_HOME_BASE_DIR}"
echo "================================================================================"
echo

ANSWER="y" # default answer
# timestamp
TODAY=$(date -I)

for i in "${SOURCE_HOME_DIR_LIST[@]}"; do

  # reset flag
  ANSWER="y"

  echo "Now backing up: ${i}..."
  SOURCE_PATH="${SOURCE_HOME_BASE_DIR}/${i}"
  # don't forget the leading "/" for destination!
  DEST_PATH="${DEST_HOME_BASE_DIR}/"

  # /usr/bin/rsync uses Apple's version that understands APFS better and avoid recopyiong
  # -hvrltD --modify-window=1 works for exfat or fat32 destinations, -a will recopy everytime
  echo "Command: rsync -hvrltD --delete --modify-window=1 ${SOURCE_PATH} ${DEST_PATH}"

  #FIXME: following does not work
  #/usr/bin/rsync --dry-run -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  #echo "If dry run is unexpected, enter 'n' to exit now. Any other input will continue. Continue?"
  #read -r answer
  #if [ "$answer" = "n" ]; then
  #   echo "Exiting..."
  #   exit 1
  #fi
  #echo "Continuing..."

  /usr/bin/rsync -hvrltD --delete --modify-window=1 "${SOURCE_PATH}" "${DEST_PATH}"
  echo "Done backing up: ${i}"
  echo "Backed up on ${TODAY}" >"${DEST_PATH}/log.txt"
done

echo "================================================================================"
echo " Backing up media directories: ${SOURCE_MEDIA_BASE_DIR}/${SOURCE_MEDIA_DIR_LIST[@]}"
echo " Destination: ${DEST_MEDIA_BASE_DIR}"
echo "================================================================================"
echo

# reset for next section
ANSWER=y

for j in "${SOURCE_MEDIA_DIR_LIST[@]}"; do
  # reset flag
  #  ANSWER="y"

  echo "Now backing up: ${j}..."
  SOURCE_PATH="${SOURCE_MEDIA_BASE_DIR}/${j}"
  # don't forget the leading "/" for destination!
  DEST_PATH="${DEST_MEDIA_BASE_DIR}/"

  # /usr/bin/rsync uses Apple's version that understands APFS better and avoid recopyiong
  # -hvrltD --modify-window=1 works for exfat or fat32 destinations, -a will recopy everytime
  echo "Command: rsync -hvrltD --delete --modify-window=1 ${SOURCE_PATH} ${DEST_PATH}"

  #FIXME: Following does not work
  #/usr/bin/rsync --dry-run -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  #echo "If dry run is unexpected, enter 'n' to exit now. Any other input will continue. Continue?"
  #read -r answer
  #if [ "$answer" = "n" ]; then
  #   echo "Exiting..."
  #   exit 1
  #echo "Continuing..."

  /usr/bin/rsync -hvrltD --delete --modify-window=1 "${SOURCE_PATH}" "${DEST_PATH}"
  echo "Backed up on ${TODAY}" >"${DEST_PATH}/log.txt"
  echo "Done backing up: ${j}"
done

echo
echo "All done!"
echo
#
# End of script
#
