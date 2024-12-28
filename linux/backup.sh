#!/bin/sh
#
# backs up local to server
# run this script from within client linux with server mounted as /mnt/server
# Create folders in destination
mkdir -p /mnt/server/ssd-data/backup/linux/home/dot_local/share
mkdir -p /mnt/server/ssd-data/backup/linux/home/dot_config
mkdir -p /mnt/server/ssd-data/backup/linux/etc/udev
mkdir -p /mnt/server/ssd-data/backup/linux/etc/systemd
mkdir -p /mnt/server/ssd-data/backup/linux/etc/X11/xorg.conf.d
#
# rsync individual and small directories first
#
rsync -av /etc/udev/ /mnt/server/ssd-data/backup/linux/etc/udev
rsync -av /etc/systemd/ /mnt/server/ssd-data/backup/linux/etc/systemd
rsync -av /etc/profile /mnt/server/ssd-data/backup/linux/etc/profile
rsync -av /etc/auto.pveshare /mnt/server/ssd-data/backup/linux/etc/auto.pveshare
rsync -av /etc/auto.master /mnt/server/ssd-data/backup/linux/etc/auto.master
rsync -av /etc/throttled.conf /mnt/server/ssd-data/backup/linux/etc/throttled.conf
rsync -av /etc/tlp.conf /mnt/server/ssd-data/backup/linux/etc/tlp.conf
rsync -av /etc/environment /mnt/server/ssd-data/backup/linux/etc/environment
rsync -av $HOME/.zshrc /mnt/server/ssd-data/backup/linux/home/dot_zshrc
rsync -av $HOME/.profile /mnt/server/ssd-data/backup/linux/home/dot_profile
rsync -av $HOME/.aliases /mnt/server/ssd-data/backup/linux/home/dot_aliases
rsync -av $HOME/.zshrc /mnt/server/ssd-data/backup/linux/home/dot_zshrc
rsync -av $HOME/.Xmodmap /mnt/server/ssd-data/backup/linux/home/dot_Xmodmap
rsync -av $HOME/.Xresources /mnt/server/ssd-data/backup/linux/home/dot_Xresources
#rsync -av /etc/X11/xorg.conf.d/ /mnt/server/ssd-data/backup/linux/etc/X11/xorg.conf.d
#
# rsync larger directories
rsync -av --stats --progress --exclude 'Trash' --exclude 'gvfs*' --exclude 'nvim*' --exclude '*/cache*/' $HOME/.local/share/ /mnt/server/ssd-data/backup/linux/home/dot_local/share
rsync -av --stats --progress --exclude 'microsoft-edge' --exclude 'gvfs*' --exclude '*/cache*/' $HOME/.config/ /mnt/server/ssd-data/backup/linux/home/dot_config
