#!/bin/bash
# (c) Anirudh Acharya 2024
# Sets up PVE host and/or LXC container for basic usage
# This script must be run as root on PVE Server and LXC/VMs
# Not running as bash or zsh will cause this script to fail as "sh" does not support arrays!

mode="none"

# validate inputs
if [ $# -ne 1 ]; then
  echo "Usage: $0 pve or $0 guest"
  exit 1
else
  if [ "$1" = "pve" ]; then
    echo "Script invoked in PVE server mode"
  elif [ "$1" = "guest" ]; then
    echo "Script invoked in Guest mode"
  else
    echo "Usage: $0 pve or $0 guest"
    exit 1
  fi
  mode=$1
fi

# must be root
if [ "$(id -u)" -ne 0 ]; then
  echo "Script must be run as root!" >&2
  exit 1
fi

# Configure console font and size, esp. usefull for hidpi displays (select Combined Latin, Terminus, 16x32 for legibility
echo
# echo Configuring Console...
dpkg-reconfigure console-setup
# Configure timezone and locale for en/UTF-8
echo
echo Configuring Timezone...
dpkg-reconfigure tzdata
echo
echo Configuring Locales...
echo
dpkg-reconfigure locales
echo

# Perform OS update and upgrade
echo Updating package list and packages...
echo
apt update
apt upgrade

echo
echo "Installing packages in \"${mode}\" mode..."
echo

common_packages=(
  'neovim'
  'btop'
  'avahi-daemon'
  'avahi-utils'
  'duf'
  'nfs-common'
  'tmux'
  'screen'
  'reptyr'
  'ncdu'
  'autofs'
  'unattended-upgrades'
  'apt-listchanges'
)

pve_packages=(
  #'inxi'
  'iotop'
  'atop'
  'iftop'
  'git'
  'gh'
  'alsa-utils'
  'cpufrequtils'
  'nfs-kernel-server'
  'lm-sensors'
  'powertop'
  'usbutils'
  'pciutils'
  'iperf3'
  'intel-media-va-driver-non-free'
  'vainfo'
  'intel-gpu-tools'
)

guest_packages=(
  'cifs-utils'
  ## all below disabled by default
  #'alsa-utils'
  #'intel-media-va-driver-non-free'
  #'vainfo'
  #'intel-gpu-tools'
  ## for kodi hosts only
  #'kodi-inputstream-adaptive'
)

# for issues with Intel iGPU, read through https://wiki.archlinux.org/title/Intel_graphics for potential issues/solutions
# the following will setup DP-HDMI audio as default in ALSA; works for both PVE host and LXC
#wget -O /etc/asound.conf https://raw.githubusercontent.com/anirudhra/pve_server/main/pve_lxc_scripts/setup/etc/lxc/etc/asound.conf

# install common packages
installer="apt"
$installer install "${common_packages[@]}"

# configure autoupdates/unattended-upgrades
echo "Unattended-Upgrade::Mail \"root\";" >/etc/apt/apt.conf.d/52unattended-upgrades-local
dpkg-reconfigure unattended-upgrades

#server side ops and packages
#nfs mount/exports, must be inside /mnt on the pve server
server_mounts=(
  'sata-ssd'
  'nvme-ssd'
)
server_subnet="10.100.100.0/24"
server_ip="10.100.100.50"

#files
serve_nfs_exports="/etc/exports"
client_auto_master="/etc/auto.master"
client_auto_pveshare="/etc/auto.pveshare"

# PVE server-only ops and packages
if [ "${mode}" = "pve" ]; then
  echo "Installing Server specific packages..."
  ${installer} install "${pve_packages[@]}"

  # check and export each mount
  echo "Exporting server NFS automounts"
  for mount in "${server_mounts[@]}"; do
    # must be inside /mnt directory, for e.g., /mnt/sata-ssd
    mount_nfs="/mnt/${mount}"
    if grep -wq "${mount_nfs} ${server_subnet}" ${serve_nfs_exports}; then
      echo "NFS share mount ${server_subnet}:${mount_nfs} already exists in ${serve_nfs_exports}!"
      echo
    else
      echo "Exporting NFS share mounts as ${server_subnet}:${mount_nfs}"
      echo
      echo "#share ${mount_nfs} over nfs" >>${serve_nfs_exports}
      # there should be NO space between the subnet and (nfs_options) below
      echo "${mount_nfs} ${server_subnet}(rw,sync,no_subtree_check,no_root_squash,no_all_squash)" >>${serve_nfs_exports}
    fi
  done

  # Copy all files in /dotfiles/pve/setup/config/pve to host machine's relevant paths
  echo "Copying PVE config files to host..."
  CONFIG_SRC="$(dirname "$0")/config/pve"
  # etc files
  if [ -d "$CONFIG_SRC/etc" ]; then
    find "$CONFIG_SRC/etc" -type f | while read -r srcfile; do
      relpath="${srcfile#$CONFIG_SRC/}" # strip leading config path
      destfile="/${relpath}"
      destdir="$(dirname "$destfile")"
      echo "Copying $srcfile to $destfile"
      mkdir -p "$destdir"
      cp -a "$srcfile" "$destfile"
    done
  fi
  # usr/lib files
  if [ -d "$CONFIG_SRC/usr/lib" ]; then
    find "$CONFIG_SRC/usr/lib" -type f | while read -r srcfile; do
      relpath="${srcfile#$CONFIG_SRC/}" # strip leading config path
      destfile="/${relpath}"
      destdir="$(dirname "$destfile")"
      echo "Copying $srcfile to $destfile"
      mkdir -p "$destdir"
      cp -a "$srcfile" "$destfile"
    done
  fi

# GuestOS-only ops and packages - LXC or VMs
else
  echo "Installing Guest specific packages..."
  ${installer} install "${guest_packages[@]}"

  # NFS shares and mounts, LXC clients need to be privileged, else this will fail!
  for mount in "${server_mounts[@]}"; do

    base_nfs="/mnt/nfs"
    mount_nfs="${base_nfs}/${mount}"
    # create base directory, all server exportes will be mounted in /mnt/nfs directory, foe g.e., /mnt/nfs/sata-ssd
    mkdir -p "${base_nfs}"
    if grep -wq "${mount_nfs} -fstype=nfs" ${client_auto_pveshare}; then
      echo "NFS share mount ${mount_nfs} already exists in ${client_auto_pveshare}! Check ${client_auto_master} if it does not work!"
      echo
    else
      echo "Automounting NFS share mounts to ${mount_nfs}"
      echo
      cp "${client_auto_master}" "${client_auto_master}.bak"
      cp "${client_auto_pveshare}" "${client_auto_pveshare}.bak"
      # following not needed, autofs should dynamically create necessary directories on mount
      #mkdir -p ${mount_nfs}``
      #chmod 777 ${mount_nfs}

      if grep -wq "/- ${client_auto_pveshare}" ${client_auto_master}; then
        echo "Autofs server already exists!"
      else
        echo "# manually added for server" >>${client_auto_master}
        echo "/- ${client_auto_pveshare}" >>${client_auto_master}
      fi
      echo "# nfs server mount ${mount_nfs}" >>${client_auto_pveshare}
      echo "${mount_nfs} -fstype=nfs,rw ${server_ip}:${mount}" >>${client_auto_pveshare}
    fi
  done

  # Copy all files in /dotfiles/pve/setup/config/lxc to host machine's relevant paths
  echo "Copying LXC config files to guest..."
  CONFIG_SRC="$(dirname "$0")/config/lxc"
  if [ -d "$CONFIG_SRC/etc" ]; then
    find "$CONFIG_SRC/etc" -type f | while read -r srcfile; do
      relpath="${srcfile#$CONFIG_SRC/}" # strip leading config path
      destfile="/${relpath}"
      destdir="$(dirname "$destfile")"
      echo "Copying $srcfile to $destfile"
      mkdir -p "$destdir"
      cp -a "$srcfile" "$destfile"
    done
  fi
fi

#restart autofs
systemctl daemon-reload
systemctl restart autofs

echo
echo Cleaning up...
echo
apt clean
apt autoclean
apt autoremove

echo
echo Configuring shell aliases...
echo

# add useful aliases to profile, works for bash and zsh
source_aliases="source ${HOME}/.aliases"
shell_profile="${HOME}/.profile"

if grep -wq "${source_aliases}" "${shell_profile}"; then
  echo "Aliases file already sourced"
else
  # source aliases in shell profile after creating backup
  cp "${shell_profile}" "${shell_profile}.bak"
  echo "${source_aliases}" >>"${shell_profile}"
  cp ../../home/.aliases "${HOME}/.aliases"
fi

echo
echo "Done! Logout and log back in for changes"
echo

# end of script
#
