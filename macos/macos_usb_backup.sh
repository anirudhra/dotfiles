#!/bin/bash
#
# (c) Anirudh Acharya 2024
# macOS Backup script to external USB HDD
#

# on external USB drive, one for home and one for media
dest_home_base_dir="/Volumes/BackupPlus/BACKUP/data/Mac"
dest_media_base_dir="/Volumes/BackupPlus/BACKUP/music"

# on local macOS
source_home_base_dir="${HOME}"
source_media_base_dir="${HOME}/Music"

#confirm external storage/destination is mounted correctly before proceeding
echo
echo "==============================================================================="
echo "Ensure your External USB is mounted correctly before running this script!"
echo "Home will be backed up to: ${dest_home_base_dir}"
echo "Media will be backed up to: ${dest_media_base_dir}"
echo "==============================================================================="
echo
echo "Contents of destination Home: ${dest_home_base_dir}:"
echo
ls ${dest_home_base_dir}
echo
echo "========================"
echo
echo "Contents of destination Media: ${dest_media_base_dir}:"
echo
ls ${dest_media_base_dir}
echo
echo "==============================================================================="
echo "Disk space usage of ${dest_home_base_dir} and ${dest_media_base_dir}"
echo
df -h ${dest_home_base_dir}
echo
df -h ${dest_media_base_dir}
echo
echo "============================================================================================"
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "============================================================================================"
echo
read ans #dummy variable to pause script

# only these folders from user's home
source_home_dir_list=(
  'Downloads'
  'Documents'
  'Pictures'
)

# media directories to be backed up
# path is relative to user's home
source_media_dir_list=(
  'MusicLibrary'
)

echo "================================================================================"
echo " Backing up following directories from user's home directory: $HOME"
echo " Source Directories: ${source_home_dir_list[@]}"
echo " Destination: ${dest_home_base_dir}"
echo "================================================================================"
echo

answer="y"
# timestamp
today=$(date -I)

for i in "${source_home_dir_list[@]}"; do

  # reset flag
  answer="y"

  echo "Now backing up: ${i}..."
  source_path="${source_home_base_dir}/${i}"
  # don't forget the leading "/" for destination!
  dest_path="${dest_home_base_dir}/"

  # /usr/bin/rsync uses Apple's version that understands APFS better and avoid recopyiong
  # -hvrltD --modify-window=1 works for exfat or fat32 destinations, -a will recopy everytime
  echo "Command: rsync -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}"

  #FIXME: following does not work
  #/usr/bin/rsync --dry-run -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  #echo "If dry run is unexpected, enter 'n' to exit now. Any other input will continue. Continue?"
  #read -r answer
  #if [ "$answer" = "n" ]; then
  #   echo "Exiting..."
  #   exit 1
  #fi
  #echo "Continuing..."

  /usr/bin/rsync -hvrltD --delete --modify-window=1 "${source_path}" "${dest_path}"
  echo "Done backing up: ${i}"
  echo "Backed up on ${today}" >"${dest_path}/log.txt"
done

echo "================================================================================"
echo " Backing up media directories: ${source_media__base_dir}/${source_media_dir_list[@]}"
echo " Destination: ${dest_media_base_dir}"
echo "================================================================================"
echo

# reset for next section
answer=y

for j in "${source_media_dir_list[@]}"; do
  # reset flag
  answer="y"

  echo "Now backing up: ${j}..."
  source_path="${source_media_base_dir}/${j}"
  # don't forget the leading "/" for destination!
  dest_path="${dest_media_base_dir}/"

  # /usr/bin/rsync uses Apple's version that understands APFS better and avoid recopyiong
  # -hvrltD --modify-window=1 works for exfat or fat32 destinations, -a will recopy everytime
  echo "Command: rsync -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}"

  #FIXME: Following does not work
  #/usr/bin/rsync --dry-run -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  #echo "If dry run is unexpected, enter 'n' to exit now. Any other input will continue. Continue?"
  #read -r answer
  #if [ "$answer" = "n" ]; then
  #   echo "Exiting..."
  #   exit 1
  #echo "Continuing..."

  /usr/bin/rsync -hvrltD --delete --modify-window=1 "${source_path}" "${dest_path}"
  echo "Backed up on ${today}" >"${dest_path}/log.txt"
  echo "Done backing up: ${j}"
done

echo
echo "All done!"
echo
#
# End of script
#
