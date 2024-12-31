#!/bin/sh
#
# (c) Anirudh Acharya 2024
# macOS Backup script to external USB HDD
#

# on external USB drive, one for home and one for media
dest_home_base_dir="/Volumes/BackupPlus/BACKUP/data/Mac"
dest_media_base_dir="/Volumes/BackupPlus/BACKUP/music"

# on local macOS
source_home_base_dir=${HOME}
source_media_base_dir=${HOME}/Music

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

today=`date -I`

echo "================================================================================"
echo " Backing up following directories from user's home directory: $HOME"
echo " Source Directories: ${source_home_dir_list[@]}"
echo " Destination: ${dest_home_base_dir}"
echo "================================================================================"
echo

answer="y"

for i in "${source_home_dir_list[@]}"
do
    
  # reset flag
  answer="y"
   
  echo "Now backing up: ${i}..."
  source_path="${source_home_base_dir}/${i}"
  # don't forget the leading "/" for destination!
  dest_path="${dest_home_base_dir}/"
   
  # /usr/bin/rsync uses Apple's version that understands APFS better and avoid recopyiong
  # -hvrltD --modify-window=1 works for exfat or fat32 destinations, -a will recopy everytime
  echo "Command (dry run first): rsync -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}"
   
  #FIXME: following does not work
  #/usr/bin/rsync --dry-run -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  #echo "If dry run is unexpected, enter 'n' to exit now. Any other input will continue. Continue?"
  #read -r answer
  #if [ "$answer" = "n" ]; then 
  #   echo "Exiting..."
  #   exit
  #fi
  #echo "Continuing..."
   
  /usr/bin/rsync -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  echo "Done backing up: ${i}"
  echo "Backed up on ${today}" > "${dest_path}/log.txt"
done

echo "================================================================================"
echo " Backing up media directories: ${source_media__base_dir}/${source_media_dir_list[@]}"
echo " Destination: ${dest_media_base_dir}"
echo "================================================================================"
echo

# reset for next section
answer=y

for j in "${source_media_dir_list[@]}"
do
  # reset flag
  answer="y"
  
  echo "Now backing up: ${j}..."
  source_path="${source_media_base_dir}/${j}"
  # don't forget the leading "/" for destination!
  dest_path="${dest_media_base_dir}/"
  
  # /usr/bin/rsync uses Apple's version that understands APFS better and avoid recopyiong
  # -hvrltD --modify-window=1 works for exfat or fat32 destinations, -a will recopy everytime
  echo "Command (dry run first): rsync -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}"
 
  #FIXME: Following does not work
  #/usr/bin/rsync --dry-run -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  #echo "If dry run is unexpected, enter 'n' to exit now. Any other input will continue. Continue?"
  #read -r answer
  #if [ "$answer" = "n" ]; then 
  #   echo "Exiting..."
  #   exit
  #fi
  #echo "Continuing..."
  
  /usr/bin/rsync -hvrltD --delete --modify-window=1 ${source_path} ${dest_path}
  echo "Backed up on ${today}" > "${dest_path}/log.txt"
  echo "Done backing up: ${j}"
done

echo
echo "All done!"
echo
#
# End of script
#
