#!/bin/sh
#
# (c) Anirudh Acharya 2024
# Script to backup PVE server
# Used in conjunction with exclude_pve_zfs_backup.txt to specify exclusions
# Before backing up mount external USB ZFS with zfs_mount.sh script and after
# backup, unmount the ZFS fs and export the pool cleanly with zfs_umount.sh script before
# disconnecting to avoid data loss
#
# mv /hdpool/fs/log/server_backup.log /hdpool/fs/log/server_backup_prev.log
#
# add all exclusion directories to the _exclude external file below, all output logged to file
# verbose version of above
#

#zfspool="pvebackup"
mountpoint="zfsdata"
#backup_dest="/${pvebackup}/${mountpoint}"
# zfs fs mountpoint does not include zpool anymore
backup_dest="/${mountpoint}"
backup_dest_dir="${backup_dest}/pve_backup"
backup_source_dir="/mnt/sata-ssd"
backup_exclude_list="./exclude_pve_zfs_backup.txt"

#confirm backup destination is available and correct
echo
echo "==============================================================================="
echo "Ensure your backup destination is mounted correctly before running this script"
echo
echo "Backup desitnation: ${backup_dest}"
echo "Backup destination directory: ${backup_dest_dir}"
echo "Backup source diretory: ${backup_source_dir}"
echo "Backup exclude list: ${backup_exclude_list}"
echo "==============================================================================="
echo
echo "Contents of backup destination - ${backup_dest}:"
echo
ls ${backup_dest}
echo
echo "==============================================================================="
echo "Disk space usage of destination: ${backup_dest}"
echo
df -h ${backup_dest}
echo
echo "==============================================================================="
echo
echo "Command: rsync -avHPAX --delete --exclude-from=${backup_exclude_list} ${backup_source_dir} ${backup_dest_dir}"
echo
echo
echo "==========================================================================================="
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "==========================================================================================="

# read into dummy variable to pause
read answer
echo
echo "Starting backup..."
echo

mkdir -p ${backup_dest_dir}
# -avHPAX should handle linux/macos volumes fine, not intended for fat32/vfat destinations
rsync -avHPAX --delete --exclude-from=${backup_exclude_list} ${backup_source_dir} ${backup_dest_dir}

today=$(date '+%Y-%m-%d')

echo "Backup complete: ${today}"
echo "Backed up on ${today}" >"${backup_dest}/log.txt"
echo
