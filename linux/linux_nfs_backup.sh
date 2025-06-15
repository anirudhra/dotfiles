#!/bin/bash
# (c) Anirudh Acharya 2024
# backs up local to server
# run this script from within client linux with server mounted as /mnt/server
# Create folders in destination
#

backup_base_dir="/mnt/nfs/sata-ssd/ssd-data/backup/linux"
backup_home_source_dir=${HOME}
backup_etc_source_dir="/etc"
backup_dst_home_dir="${backup_base_dir}/home"
backup_dst_etc_dir="${backup_base_dir}/etc"
# add all backup exclusion regex to the file below
backup_exclude_list="./exclude_linux_nfs_backup.txt"

# timestamp
now=$(date)

#confirm external storage/destination is mounted correctly before proceeding
echo
echo "============================================================================================"
echo "Ensure your backup destination is mounted and accessible before running this script"
echo "Destination (Linux file system assumed): ${backup_base_dir}"
echo "Source Home directory: ${backup_home_source_dir}"
echo "Source /etc directory: ${backup_etc_source_dir}"
echo "============================================================================================"
echo
echo "Contents of ${backup_base_dir}:"
echo
ls ${backup_base_dir}
echo "============================================================================================"
echo
echo "Disk space usage of ${backup_base_dir}"
df -h ${backup_base_dir}
echo "============================================================================================"
echo
echo "============================================================================================"
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "============================================================================================"
echo

# read into dummy variable to pause
read answer

#failsafe
mkdir -p "${backup_dst_home_dir}"
mkdir -p "${backup_dst_etc_dir}"

mkdir -p "${backup_dst_etc_dir}/udev"
mkdir -p "${backup_dst_etc_dir}/systemd"

# run backup commands
echo
echo Starting /etc backup...
echo
#
# rsync individual and small directories first
#

# /etc directories to backup
etc_dirs=(
  'udev'
  'systemd'
  'tlp.d'
)

# /etc files to backup
etc_files=(
  'fstab'
  'auto.pveshare'
  'auto.master'
  'throttled.conf'
  'tlp.conf'
  'environment'
)

# backup /etc/ directories
for i in "${etc_dirs[@]}"; do
  #don't forget trailing '/' for destination!
  sudo rsync -avHPAX --delete /etc/"${i}" ${backup_dst_etc_dir}/
done

# backup /etc/ files
for j in "${etc_files[@]}"; do
  #don't forget trailing '/' for destination!
  sudo rsync -avHPAX --delete /etc/"${j}" ${backup_dst_etc_dir}/
done

# run home backup commands
echo
echo "Starting ${backup_home_source_dir} backup..."
echo
# backup home directory
# following command is only for linux/macos file systems and won't work for exfat/fat32 sources
rsync -avHPAX --delete --exclude-from=${backup_exclude_list} "${backup_home_source_dir}" "${backup_dst_home_dir}"

echo
echo "Backing up GNOME settings..."
echo
dconf dump /org/gnome/ >"${backup_dst_home_dir}/gnome_settings_backup.dconf"

echo
echo "Done! Backup complete: ${now}"
echo "Lastbackup: ${now}" >"${backup_dst_home_dir}/lastbackup.log"
echo
# end of script
#
