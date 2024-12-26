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

echo
echo ====================================================================================
echo Starting automated installer...
echo ====================================================================================
echo

# check if running from the right directory
current_dir=$(pwd)
if [[ $current_dir != *"/dotfiles/install"* ]]; then
  echo "Script invoked from incorrect directory!"
  echo "The current directory is: $current_dir"
  echo "Please run this script from .../dotfiles/install directory"
  echo
  exit -1
fi

installer="dnf" #default
if [ $ID == "fedora" ];
then
    echo "Fedora detected!"
    echo
    # don't change installer variable, use default, but keep this block for future use
    #FIXME: temporary disable
    #sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
    
    #FIXME: temporary disable
    #sudo dnf group upgrade core -y
elif [ $ID == "debian" ] || [ $ID == "ubuntu" ];
then
    echo "Debian or derivative detected!"
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

#FIXME: temporary disable
# refresh again to be sure
#sudo $installer update && sudo $installer upgrade

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
    'fastfetch'
)

# OS specific packages are listed in this block
if [ $ID == "fedora" ]; then
    # Fedora specific packages
    ospackages=(
        's-tui'
        'throttled'
        'nfs-utils'
        'intel-media-driver'
    )

    #FIXME: temporary disable
    echo "Fedora installer..."
    #sudo dnf remove thermald -y
    #sudo dnf copr enable abn/throttled -y
else
    # Debian/Ubuntu specific packages
    echo "Debian installer..."
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
#FIXME: temporary disable
###sudo $installer install "${corepackages[@]}" "${ospackages[@]}"

####################################################################################
# Install useful aliases
####################################################################################
local_aliases="$HOME/.aliases"
local_profile="$HOME/.profile"
local_zshrc="$HOME/.zshrc"
local_bashrc="$HOME/.bashrc"
aliases_source_file="./"$ID"/"$ID"_dot_aliases"

if [ -e "$local_aliases" ]; then
  echo "local_aliases file exists, nothing to do!"
else
  echo "Installing useful aliases"
  if [ $ID == "fedora" ]; then
      echo "Fedora aliases: $aliases_source_file"
      #cp ./install/fedora/fedora_dot_aliases $local_aliases
  else
      echo "Debian aliases: $aliases_source_file"
      #cp ./install/debian/debian_dot_aliases $local_aliases
  fi
  cp $aliases_source_file $local_aliases
fi

if grep -wq "source ~/.aliases" $local_profile; then 
  echo "$local_aliases already sourced in $local_profile, nothing to do!" 
else 
  echo "Updating $local_profile to source $local_aliases"
  echo "source ~/.aliases" >> $local_profile
fi

####################################################################################
# Install UI/Customizations
####################################################################################

####################################################################################
# Install /etc config files
####################################################################################
source_autofs_share_file="./etc/auto.pveshare"
sys_autofs_share_file="/etc/auto.pveshare"
source_tlp_file="./etc/tlp.conf"
sys_tlp_file="/etc/tlp.conf"
source_throttled_file="./etc/throttled.conf"
sys_throttled_file="/etc/throttled.conf"

# comment out checking files for now, force install the new files to overwrite default ones

#if [ -e "$sys_autofs_share_file" ]; then
#    echo "$sys_autofs_share_file /etc config file exists, nothing to do!"
#else
    echo "Installing /etc config file: $source_autofs_share_file to $sys_autofs_share_file"
    sudo cp $source_autofs_share_file $sys_autofs_share_file
#fi

#if [ -e "$sys_tlp_file" ]; then
#    echo "$sys_tlp_file /etc config file exists, nothing to do!"
#else
    echo "Installing /etc config file: $source_tlp_file to $sys_tlp_file"
    sudo cp $source_tlp_file $sys_tlp_file
#fi

#if [ -e "$sys_throttled_file" ]; then
#    echo "$sys_throttled_file /etc config file exists, nothing to do!"
#else
    echo "Installing /etc config file: $source_throttled_file to $sys_throttled_file"
    sudo cp $source_throttled_file $sys_throttled_file
#fi

####################################################################################
# Enable various services
####################################################################################

#FIXME: Section disabled for testing
#sudo systemctl enable tlp
#sudo systemctl start tlp
#sudo tlp start

#sudo systemctl enable autofs
#sudo systemctl start autofs

#sudo systemctl enable throttled
#sudo systemctl start throttled

# Disable services: thermald conflicts with throttled
#sudo systemctl disable thermald
#sudo systemctl mask thermald

####################################################################################
# End
####################################################################################

echo
echo "Done! Logout and log back in for changes"
echo

