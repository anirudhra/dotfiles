#!/bin/sh
#
# backs up local to server
# run this script from within client linux with server mounted as /mnt/server and user "anirudh"
# Create folders in destination
mkdir -p /mnt/server/ssd-data/anirudh/linux/home/dot_local/share
mkdir -p /mnt/server/ssd-data/anirudh/linux/home/dot_config
mkdir -p /mnt/server/ssd-data/anirudh/linux/etc/udev
mkdir -p /mnt/server/ssd-data/anirudh/linux/etc/systemd
mkdir -p /mnt/server/ssd-data/anirudh/linux/etc/X11/xorg.conf.d
#
# rsync individual and small directories first
#
rsync -av /etc/udev/ /mnt/server/ssd-data/anirudh/linux/etc/udev
rsync -av /etc/systemd/ /mnt/server/ssd-data/anirudh/linux/etc/systemd
rsync -av /etc/profile /mnt/server/ssd-data/anirudh/linux/etc/profile
rsync -av /etc/auto.pveshare /mnt/server/ssd-data/anirudh/linux/etc/auto.pveshare
rsync -av /etc/auto.master /mnt/server/ssd-data/anirudh/linux/etc/auto.master
rsync -av /etc/throttled.conf /mnt/server/ssd-data/anirudh/linux/etc/throttled.conf
rsync -av /etc/tlp.conf /mnt/server/ssd-data/anirudh/linux/etc/tlp.conf
rsync -av /etc/environment /mnt/server/ssd-data/anirudh/linux/etc/environment
rsync -av /home/anirudh/.zshrc /mnt/server/ssd-data/anirudh/linux/home/dot_zshrc
rsync -av /home/anirudh/.profile /mnt/server/ssd-data/anirudh/linux/home/dot_profile
rsync -av /home/anirudh/.aliases /mnt/server/ssd-data/anirudh/linux/home/dot_aliases
rsync -av /home/anirudh/.zshrc /mnt/server/ssd-data/anirudh/linux/home/dot_zshrc
rsync -av /home/anirudh/.Xmodmap /mnt/server/ssd-data/anirudh/linux/home/dot_Xmodmap
rsync -av /home/anirudh/.Xresources /mnt/server/ssd-data/anirudh/linux/home/dot_Xresources
#rsync -av /etc/X11/xorg.conf.d/ /mnt/server/ssd-data/anirudh/linux/etc/X11/xorg.conf.d
#
# rsync larger directories
rsync -av --stats --progress --exclude 'Trash' --exclude 'gvfs*' --exclude 'nvim*' --exclude '*/cache*/' /home/anirudh/.local/share/ /mnt/server/ssd-data/anirudh/linux/home/dot_local/share
rsync -av --stats --progress --exclude 'microsoft-edge' --exclude 'gvfs*' --exclude '*/cache*/' /home/anirudh/.config/ /mnt/server/ssd-data/anirudh/linux/home/dot_config
