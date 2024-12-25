#!/bin/sh
# (c) Anirudh Acharya 2024
# Sets up PVE host and/or LXC container for basic usage
# More updates planned to make it parameterizable
# For Fedora
# Configure console font and size, esp. usefull for hidpi displays (select Combined Latin, Terminus, 16x32 for legibility
echo
#echo Configuring Console...
# dpkg-reconfigure console-setup
# Configure timezone and locale for en/UTF-8
echo
#echo Configuring Timezone...
#dpkg-reconfigure tzdata
echo
#echo Configuring Locales...
echo
#dpkg-reconfigure locales
echo
# Perform OS update and upgrade
echo Updating package list and packages...
echo
sudo dnf update
sudo dnf upgrade
echo
echo Installing packages...
echo
# following section is for PVE host
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

sudo dnf copr enable abn/throttled

sudo dnf group update core -y

sudo dnf remove thermald

sudo dnf install s-tui stress throttled nfs-utils zsh gnome-tweaks gnome-extensions-app btop duf avahi-daemon avahi-utils cpufrequtils lm_sensors powertop vainfo usbutils pciutils autofs neovim tlp tlp-rdw wavemon smartmontools
#
# following section is for PVE LXC
# apt install vim btop htop duf avahi-daemon avahi-utils autofs nfs-common wavemon
#
# following section is for PVE host or if you have audio passthrough in LXC
# apt install alsa-utils
#
# for issues with Intel iGPU, read through https://wiki.archlinux.org/title/Intel_graphics for potential issues/solutions
#
# following section is if you have iGPU passthrough in LXC
# foss intel driver - install one of below (only decode)
# apt install intel-media-va-driver vainfo intel-gpu-tools
#
# non-free intel driver (both decode and encode), need "non-free-firmware and non-free" repos in /etc/apt/sources.list else will fail
sudo dnf install intel-media-va-driver vainfo intel-gpu-tools
#
# the following will setup DP-HDMI audio as default in ALSA; works for both PVE host and LXC
# wget -O /etc/asound.conf https://raw.githubusercontent.com/anirudhra/hpe800g4dm_server/main/pve_lxc_scripts/setup/etc/lxc/etc/asound.conf
#
# on kodi hosts, install the following
# apt install kodi-inputstream-adaptive
echo
echo Cleaning up...
echo
#sudo dnf clean
#sudo dnf autoclean
sudo dnf autoremove
#
echo
echo Configuring shell aliases for current user...
echo
# add useful aliases to profile, works for bash and zsh
#wget -O ~/.aliases https://raw.githubusercontent.com/anirudhra/hpe800g4dm_server/main/pve_lxc_scripts/setup/home/dot_pve_aliases
# source aliases in .profile after creating backup
#cp ~/.profile ~/.profile.bak
#echo "source ~/.aliases" >> ~/.profile
echo
# NFS shares and mounts
#
# Following is for PVE hosts only to export NFS shares
#
# echo "#share sata-ssd over nfs" >> /etc/exports
# echo "/mnt/sata-ssd 10.100.100.0/24(rw,sync,no_subtree_check,no_root_squash,no_all_squash)" >> /etc/exports
#
# Following is for LXC clients only (need to be privileged, else will fail
#
echo Automounting NFS share mounts in /mnt/nfs-ssd
echo
sudo cp /etc/auto.master /etc/auto.master.bak
sudo cp /etc/auto.mount /etc/auto.mount.bak
sudo mkdir -p /mnt/server
sudo chmod 777 /mnt/server
sudo echo "# manually added for server" >> /etc/auto.master
sudo echo "/- /etc/auto.pveshare" >> /etc/auto.master
sudo echo "# nfs server mount" >> /etc/auto.pveshare
sudo echo "/mnt/server -rw,fstype=nfs4 10.100.100.50:/mnt/sata-ssd" >> /etc/auto.pveshare
sudo systemctl daemon-reload
sudo systemctl restart autofs
echo
echo "Done! Logout and log back in for changes"
echo

