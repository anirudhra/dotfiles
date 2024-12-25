#!/bin/sh
# (c) Anirudh Acharya 2024
# Fedora setup and Fedora/Debian dotfiles repo for thinkpad
# Run this script as non-root user
# git config --global user.name "name"
# git config --global user.email "email"
# gh auth login: for browser based git login instead of token

####################################################################################
# Detect Linux Distribution and update repos
####################################################################################
source /etc/os-release
#echo $PRETTY_NAME $ID
# ID will have fedora or debian
#ID="debian" #override for testing

installer="dnf" #default
if [ $ID == "fedora" ];
then
    echo "Fedora detected"
    # don't change installer variable, use default, but keep this block for future use
    sudo $installer update && sudo $installer upgrade

    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
    
    sudo dnf group upgrade core -y
elif [ $ID == "debian" ] || [ $ID == "ubuntu" ];
then
    echo "Debian or derivative detected"
    echo
    echo "Before you run this script, enable non-free and non-free-firmware repos"
    read -p "!!!Press Ctrl-C to quit now to enable and re-run this script!!! If enabled, press Enter" -n1 -s
    echo
    pause
    installer="apt"
    # Configure console font and size, esp. usefull for hidpi displays (select Combined Latin, Terminus, 16x32 for legibility
    echo Configuring Console...
    sudo dpkg-reconfigure console-setup
    # Configure timezone and locale for en/UTF-8
    echo Configuring Timezone...
    sudo dpkg-reconfigure tzdata
    echo Configuring Locales...
    sudo dpkg-reconfigure locales
else
    echo "Unknown OS, cannot proceed; exiting"
    exit -1
fi

# refresh again to be sure
sudo $installer update && sudo $installer upgrade

####################################################################################
# Install packages
####################################################################################

# list of core packages
corepackages=(
    'duf'
    'btop'
    'stress'
    'zsh' 
    'gnome-tweaks'
    'gnome-extensions-app'
    'avahi-daemon'
    'lm_sensors'
    'powertop'
    'vainfo'
    'usbutils'
    'pciutils'
    'autofs'
    'neovim'
    'tlp'
    'tlp-rdw'
    'wavemon'
    'smartmontools'
    'intel-gpu-tools'
    'git'
    'gh'
    'stow'
)

# OS specific packages are listed in this block
if [ $installer == "dnf" ]; then
    # Fedora specific packages
    ospackages=(
        's-tui'
        'throttled'
        'nfs-utils'
        'intel-media-driver'
    )

    sudo dnf remove thermald
    sudo dnf copr enable abn/throttled -y
else
    # Debian/Ubuntu specific packages
    ospackages=(
        's-tui'
        'avahi-utils'
        'nfs-common'
        'systemd-resolved'
        'cifs-utils'
        'alsa-utils'
        'intel-media-va-driver-non-free'
    )
fi

# install all packages
sudo $installer install "${corepackages[@]}" "${ospackages[@]}"

####################################################################################
# Install useful aliases
####################################################################################
local_aliases="~/.aliases"
local_profile="~/.profile"
local_zshrc="~/.zshrc"
local_bashrc="~/.bashrc"

if [ -f "$local_aliases" ]; then
  echo "Aliases file exists, nothing to do!"
else
  echo "Installing useful aliases"
fi

####################################################################################
# Install UI/Customizations
####################################################################################

echo
echo "Done! Logout and log back in for changes"
echo

