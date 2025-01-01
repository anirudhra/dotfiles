#!/bin/sh
# (c) Anirudh Acharya 2024
# backs up local to server
# run this script from within client linux with server mounted as /mnt/server
# Create folders in destination
#

backup_base_dir="/mnt/server/ssd-data/backup/linux"

#confirm external storage/destination is mounted correctly before proceeding
echo
echo "============================================================================================"
echo "Ensure your backup destination is mounted and accessible before running this script"
echo "Destination (Linux file system assumed): ${backup_base_dir}"
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

mkidr -p ${backup_base_dir}

mkdir -p ${backup_base_dir}/home/dot_local/share
mkdir -p ${backup_base_dir}/home/dot_config
mkdir -p ${backup_base_dir}/etc/udev
mkdir -p ${backup_base_dir}/etc/systemd
mkdir -p ${backup_base_dir}/etc/X11/xorg.conf.d
#
# rsync individual and small directories first
#
rsync -av /etc/udev/ ${backup_base_dir}/etc/udev
rsync -av /etc/systemd/ ${backup_base_dir}/etc/systemd
rsync -av /etc/profile ${backup_base_dir}/etc/profile
rsync -av /etc/auto.pveshare ${backup_base_dir}/etc/auto.pveshare
rsync -av /etc/auto.master ${backup_base_dir}/etc/auto.master
rsync -av /etc/throttled.conf ${backup_base_dir}/etc/throttled.conf
rsync -av /etc/tlp.conf ${backup_base_dir}/etc/tlp.conf
rsync -av /etc/environment ${backup_base_dir}/etc/environment
rsync -av $HOME/.zshrc ${backup_base_dir}/home/dot_zshrc
rsync -av $HOME/.profile ${backup_base_dir}/home/dot_profile
rsync -av $HOME/.aliases ${backup_base_dir}/home/dot_aliases
rsync -av $HOME/.zshrc ${backup_base_dir}/home/dot_zshrc
rsync -av $HOME/.Xmodmap ${backup_base_dir}/home/dot_Xmodmap
rsync -av $HOME/.Xresources ${backup_base_dir}/home/dot_Xresources
#rsync -av /etc/X11/xorg.conf.d/ ${backup_base_dir}/etc/X11/xorg.conf.d
#
# rsync larger directories
# run backup commands
echo Starting backup...
echo
rsync -av --stats --progress --exclude 'Trash' --exclude 'gvfs*' --exclude 'nvim*' --exclude '*/cache*/' $HOME/.local/share/ ${backup_base_dir}/home/dot_local/share
rsync -av --stats --progress --exclude 'microsoft-edge' --exclude 'icons' --exclude 'gvfs*' --exclude '*/cache*/' $HOME/.config/ ${backup_base_dir}/home/dot_config
echo
echo Done!
echo
# end of script
#
