#!/bin/sh
# (c) Anirudh Acharya 2024
# backs up local to server
# run this script from within client linux with server mounted as /mnt/server
# Create folders in destination
#

backup_base_dir="/mnt/server/ssd-data/backup/linux"
backup_home_source_dir=${HOME}
backup_etc_source_dir="/etc"
backup_dst_home_dir="${backup_base_dir}/home"
backup_dst_etc_dir="${backup_base_dir}/etc"
backup_exclude_list="./exclude_linux_nfs_backup.txt"

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
mkdir -p ${backup_dst_home_dir}
mkdir -p ${backup_dst_etc_dir}

mkdir -p ${backup_dst_etc_dir}/udev
mkdir -p ${backup_dst_etc_dir}/systemd
# timestamp
today=`date -I`

# run backup commands
echo
echo Starting /etc backup...
echo
#
# rsync individual and small directories first
#

etc_dirs=(
    'udev'
    'systemd'
    'tlp.d'
)

etc_files=(
    'fstab'
    'auto.pveshare'
    'auto.master'
    'throttled.conf'
    'tlp.conf'
    'environment'
)

# /etc/ directories
for i in "${etc_dirs[@]}"
do
    #don't forget trailing '/' for destination!
    rsync -avHPAX --delete /etc/${i} ${backup_dst_etc_dir}/
done

# /etc/ files
for j in "${etc_files[@]}"
do
    #don't forget trailing '/' for destination!
    rsync -avHPAX --delete /etc/${j} ${backup_dst_etc_dir}/
done

#rsync -avHPAX --delete /etc/udev/ ${backup_base_dir}/etc/udev
#rsync -avHPAX --delete /etc/systemd/ ${backup_base_dir}/etc/systemd
#rsync -avHPAX --delete /etc/profile ${backup_base_dir}/etc/profile
#rsync -avHPAX --delete /etc/auto.pveshare ${backup_base_dir}/etc/auto.pveshare
#rsync -avHPAX --delete /etc/auto.master ${backup_base_dir}/etc/auto.master
#rsync -avHPAX --delete /etc/throttled.conf ${backup_base_dir}/etc/throttled.conf
#rsync -avHPAX --delete /etc/tlp.conf ${backup_base_dir}/etc/tlp.conf
#rsync -avHPAX --delete /etc/environment ${backup_base_dir}/etc/environment

# run backup commands
echo 
echo Starting ${backup_home_source_dir} backup...
echo
# backup home directory
# following command is only for linux/macos file systems and won't work for exfat/fat32 sources
rsync -avHPAX --delete --exclude-from=${backup_exclude_list} ${backup_home_source_dir} ${backup_dst_home_dir}

echo
echo Done!
echo
# end of script
#