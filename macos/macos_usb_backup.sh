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
source_media__base_dir=${HOME}/Music

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

for i in "${source_home_dir_list[@]}"
do
    echo "Now backing up: ${i}..."
    source_path="${source_home_base_dir}/${i}"
    dest_path="${dest_home_base_dir}"
    # don't forget the leading "/" for destination!
    echo "Command: rsync -avP --delete ${source_path} ${dest_path}/"
    rsync -avP --delete ${source_path} ${dest_path}/
    echo "Backed up on ${today}" > "${dest_path}/log.txt"
done

echo "================================================================================"
echo " Backing up media directories: ${source_media__base_dir}/${source_media_dir_list[@]}"
echo " Destination: ${dest_media_base_dir}"
echo "================================================================================"
echo

for j in "${source_media_dir_list[@]}"
do
    echo "Now backing up: ${j}..."
    source_path="${source_media_base_dir}/${j}"
    dest_path="${dest_media_base_dir}"
    # don't forget the leading "/" for destination!
    echo "Command: rsync -avP --delete ${source_path} ${dest_path}/"
    rsync -avP --delete ${source_path} ${dest_path}/
    echo "Backed up on ${today}" > "${dest_path}/log.txt"
done
