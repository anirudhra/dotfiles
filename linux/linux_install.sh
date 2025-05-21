#!/bin/bash
# (c) Anirudh Acharya 2024, 2025
#
# Last Update: April 27, 2025
#
# Fedora setup and Fedora/Debian dotfiles repo for thinkpad
# Run this script as non-root user
# If this script is not run with an interpreter (bash, zsh and only some sh) that supports arrays this will fail

# git commands for reference
# git config --global user.name "name"
# git config --global user.email "email"
# gh auth login: for browser based git login instead of token

####################################################################################
# Detect Linux Distribution and update repos
####################################################################################
# . acts as source and is POSIX compliant
. /etc/os-release
#echo $PRETTY_NAME $ID #debug

echo
echo "===================================================================================="
echo "Starting automated installer..."
echo "===================================================================================="
echo

# check if running from the right directory
install_dir=$(pwd)
if [[ ${install_dir} != *"/dotfiles/linux"* ]]; then
  echo "Script invoked from incorrect directory!"
  echo "The current directory is: ${install_dir}"
  echo "Please run this script from .../dotfiles/linux directory"
  echo
  exit
fi

# get desktop environment
desktopEnv=${XDG_CURRENT_DESKTOP} #gnome, cinnamon, kde...
Xsessiontype=${XDG_SESSION_TYPE} #X11, wayland

#default OS
install_os="fedora"
installer="dnf"

# get right timezone and locale/language
L_TZ="America/Los_Angeles"
L_LANG="en_US.UTF-8"

TZSET=""
if [ -f /etc/timezone ]; then
  TZSET=$(cat /etc/timezone)
fi
# LANG is env. variable
LANGSET=${LANG}

if [ "${ID}" == "fedora" ]; then
  echo "Fedora detected!"
  echo
  # don't change installer variable, use default, but keep this block for future use

  # add repos and keys
  sudo ${installer} install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

  #microsoft repos
  vscode_repo_file="/etc/yum.repos.d/vscode.repo"
  msedge_repo_file="/etc/yum.repos.d/microsoft-edge.repo"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

  if [ ! -e "${msedge_repo_file}" ]; then
    echo -e "[ms-edge]\nname=Microsoft Edge Browser\nbaseurl=https://packages.microsoft.com/yumrepos/edge\nenabled=0\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee "${msedge_repo_file}" >/dev/null
  fi

  if [ ! -e "${vscode_repo_file}" ]; then
    echo -e "[vscode]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee "${vscode_repo_file}" >/dev/null
  fi

  sudo ${installer} group upgrade core -y

# Debian and derivative distros
elif [ "${ID}" == "debian" ] || [ "${ID}" == "ubuntu" ] || [ "${ID}" == "linuxmint" ] || [ "${ID}" == "zorin" ]; then
  echo "Debian or derivative detected!"
  echo
  echo "Before you run this script, enable non-free and non-free-firmware repos"
  echo "!!!Press Ctrl-C to quit now to enable and re-run this script!!! If enabled, press Enter"
  echo
  read -p "===================================================================================="

  install_os="debian"
  installer="apt"

  # add repos
  sudo add-apt-repository universe -y && sudo add-apt-repository ppa:agornostal/ulauncher -y

  #micrsoft vscode and edge
  vscode_repo_file="/etc/apt/sources.list.d/vscode.list"
  msedge_repo_file="/etc/apt/sources.list.d/miscrosoft-edge.list"

  if [ ! -e "${vscode_repo_file}" ]; then
  # vscode repos
    sudo apt-get install wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee "${vscode_repo_file}" >/dev/null
    rm -f packages.microsoft.gpg
  fi

  if [ ! -e "${msedge_repo_file}" ]; then
  # microsoft edge
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" -y
  fi

  # Configure console font and size, esp. usefull for hidpi displays (select Combined Latin, Terminus, 16x32 for legibility
  # disabled for now, enable this manually if needed
  #echo "Configuring Console..."
  #sudo dpkg-reconfigure console-setup
  # Configure timezone and locale for en/UTF-8
  if [ ! ${TZSET} == ${L_TZ} ]; then
    echo "Configuring Timezone..."
    #sudo dpkg-reconfigure tzdata
    sudo timedatectl set-timezone "${L_TZ}"
  fi

  if [ ! ${LANGSET} == ${L_LANG} ]; then
    echo "Configuring Locales..."
    #sudo dpkg-reconfigure locales
    sudo update-locale LANG=${L_LANG}
  fi

# unknown OS, exit
else
  echo "Unknown OS, cannot proceed; exiting"
  exit
fi

# refresh again to be sure
sudo ${installer} update && sudo ${installer} upgrade

####################################################################################
# Install packages
####################################################################################

# list of core packages
corepackages=(
  'tmux'
  'duf'
  'code'
  'btop'
  'stress'
  'zsh'
  'avahi-daemon'
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
  'vlc'
  #'golang'
  #'cmake'
  #'gcc'
  'inxi'
  #'gem'
  #'luarocks'
  'fzf'
  'fd-find'
  'python3-pip'
  'rdfind'
  'lolcat'
  'p7zip'
  'unzip'
  'unrar'
  'microsoft-edge-stable'
  'nmap'
  'expect'
  'mencoder'
  'jhead'
  'iperf3'
  'ncdu'
  's-tui'
  'solaar' #logitech config utility
  'papirus-icon-theme'
)

# seperate out core gnome packages
# need not install on distros w/ xfce/cinnamon
coregnomepkgs=(
  'gparted'
  'gimp'
  'menulibre'
  'geary'
  'gnome-tweaks'
  'dconf-editor'
)

# Nerd fonts list to be installed
# Update to lastest version from: https://github.com/ryanoasis/nerd-fonts
nerd_font_ver='3.4.0'

# enable the nerd fonts to be installed
fonts=(
  #'BitstreamVeraSansMono'
  #'CodeNewRoman'
  #'DroidSansMono'
  'FiraCode'
  'FiraMono'
  #'Go-Mono'
  #'Hack'
  #'Hermi't
  #'JetBrainsMono'
  'Meslo'
  #'Noto'
  #'Overpass'
  #'ProggyClean'
  'RobotoMono'
  'SourceCodePro'
  #'SpaceMono'
  #'Ubuntu'
  #'UbuntuMono'
)

# OS specific packages are listed in this block
if [ "${ID}" == "fedora" ]; then
  # Fedora specific packages
  ospackages=(
    'throttled'
    'fastfetch'
    'lm_sensors'
    'p7zip-plugins'
    'nfs-utils'
    'intel-media-driver'
    'epapirus-icon-theme'
    'papirus-icon-theme-dark'
    'papirus-icon-theme-light'
    'ulauncher'
    #'btrfs-assistant'
    'heif-pixbuf-loader'
    'libheif-freeworld'
    'libheif'
    'easyeffects'
    'fuse'
    'fuse-libs'
  )

  osgnomepkgs=(
    'gtk-murrine-engine'
    'gnome-extensions-app'
    'gtk2-engines'
  )

  echo "Fedora installer..."

  # following conflicts with throttled
  sudo ${installer} remove thermald -y
  sudo ${installer} copr enable abn/throttled -y
else
  # Debian/Ubuntu specific packages
  ospackages=(
    'apt-transport-https'
    'lm-sensors'
    'neofetch'
    'avahi-utils'
    'nfs-common'
    'systemd-resolved'
    'cifs-utils'
    'alsa-utils'
    'intel-media-va-driver-non-free'
    'ulauncher'
    # the following are for 'throttled' build and install
    'build-essential'
    'python3-dev'
    'libdbus-glib-1-dev'
    'libgirepository1.0-dev'
    'libcairo2-dev'
    'python3-cairo-dev'
    'python3-venv'
    'python3-wheel'
  )

  osgnomepkgs=(
    'gtk2-engines-murrine'
    'gtk2-engines-pixbuf'
    'chrome-gnome-shell'
    'gnome-shell-extension-prefs'
  )

  echo "Debian installer..."
  sudo ${installer} remove thermald -y

fi

# install all non-gnome packages
sudo ${installer} install "${corepackages[@]}"
sudo ${installer} install "${ospackages[@]}"

# on gnome, install gnome-only packages
if [ "${desktopEnv}" == "GNOME" ]; then
  sudo ${installer} install "${coregnomepkgs[@]}"
  sudo ${installer} install "${osgnomepkgs[@]}"
fi

#debug: phase1
#read -p "Phase1: Press any key to continue"

####################################################################################
# Install dotfiles with stow under /dotfiles/home directory
####################################################################################
# dotfiles installation with stow is now done in the post installer script

####################################################################################
# Install /etc config files
####################################################################################
source_autofs_share_file="./etc/auto.pveshare"
sys_autofs_share_file="/etc/auto.pveshare"
source_tlp_file="./etc/tlp.conf"
sys_tlp_file="/etc/tlp.conf"
source_throttled_file="./etc/throttled.conf"
sys_throttled_file="/etc/throttled.conf"
nfs_mount_point="/mnt/nfs"
autofs_master="/etc/auto.master"

# unalias cp, if it has an alias
[[ $(type -t cp) == "alias" ]] && unalias cp

# install autofs pve share file
if [ -e "${sys_autofs_share_file}" ]; then
  echo "${sys_autofs_share_file} /etc config file exists, creating backup!"
  # command \\cp should use the unaliased version of cp (command is \cp, with \ for escape),
  # else cp is usually aliases to cp -i and below will fail
  # else force run "unalias cp" command as above
  #sudo \\cp -rf ${sys_autofs_share_file} "${sys_autofs_share_file}.bak"
  sudo cp -rf ${sys_autofs_share_file} "${sys_autofs_share_file}.bak"
fi

echo "Installing /etc config file: ${source_autofs_share_file} to ${sys_autofs_share_file}"
#sudo \\cp -rf ${source_autofs_share_file} ${sys_autofs_share_file}
sudo cp -rf ${source_autofs_share_file} ${sys_autofs_share_file}
sudo mkdir -p ${nfs_mount_point}
sudo chmod 777 ${nfs_mount_point}

# add auto mount pve to auto.master file
if grep -wq "/- ${sys_autofs_share_file}" "${autofs_master}"; then
  echo "${autofs_master} already has PVE share NFS entry, restart autofs service if server isn't mounted"
else
  echo "Appending PVE entry to ${autofs_master} file"
  echo "# Adding PVE server NFS entry mount" | sudo tee -a ${autofs_master}
  echo "/- ${sys_autofs_share_file}" | sudo tee -a ${autofs_master}
fi

# install tlp config file
if [ -e "${sys_tlp_file}" ]; then
  echo "${sys_tlp_file} /etc config file exists, creating backup"
  #sudo \\cp -rf ${sys_tlp_file} "${sys_tlp_file}.bak"
  sudo cp -rf ${sys_tlp_file} "${sys_tlp_file}.bak"
fi
echo "Installing /etc config file: ${source_tlp_file} to ${sys_tlp_file}"
#sudo \\cp -rf ${source_tlp_file} ${sys_tlp_file}
sudo cp -rf ${source_tlp_file} ${sys_tlp_file}

# install throttled and UV config file
if [ -e "${sys_throttled_file}" ]; then
  echo "${sys_throttled_file} /etc config file exists, creating backup"
  #sudo \\cp -rf ${sys_tlp_file} "${sys_tlp_file}.bak"
  sudo cp -rf ${sys_tlp_file} "${sys_tlp_file}.bak"
fi
echo "Installing /etc config file: ${source_throttled_file} to ${sys_throttled_file}"
#sudo \\cp -rf ${source_throttled_file} ${sys_throttled_file}
sudo cp -rf ${source_throttled_file} ${sys_throttled_file}

####################################################################################
# Install UI/Customizations
####################################################################################

echo "Current directory: ${install_dir}"

# Replace audio alert file
audio_alert_file="/usr/share/sounds/gnome/default/alerts/hum.ogg"
audio_alert_bak_file="/usr/share/sounds/gnome/default/alerts/hum_og.ogg"
audio_alert_source_file="./sounds/hum.ogg"

if [ ! -e ${audio_alert_bak_file} ]; then
  echo "Installing audio alert file replacement"
  echo
  sudo cp ${audio_alert_file} ${audio_alert_bak_file}
  sudo cp ${audio_alert_source_file} ${audio_alert_file}
fi

# Install GTK and Icon themes in the following directory
pkg_install_dir="${HOME}/packages/install"
mkdir -p "${pkg_install_dir}"
cd "${pkg_install_dir}" || exit
install_ui=0 #default flag, if at least one is pulled, set this below

# check if exists, else pull
if [ ! -d "Tela-icon-theme" ]; then
  git clone https://github.com/vinceliuice/Tela-icon-theme
  install_ui=1
fi
if [ ! -d "Orchis-theme" ] && [ "${desktopEnv}" == "GNOME" ]; then
  git clone https://github.com/vinceliuice/Orchis-theme
  install_ui=1
fi
if [ ! -d "Magnetic-gtk-theme" ] && [ "${desktopEnv}" == "GNOME" ]; then
  git clone https://github.com/vinceliuice/Magnetic-gtk-theme
  install_ui=1
fi
if [ ! -d "Qogir-theme" ] && [ "${desktopEnv}" == "GNOME" ]; then
  git clone https://github.com/vinceliuice/Qogir-theme
  install_ui=1
fi
if [ ! -d "Qogir-icon-theme" ]; then
  git clone https://github.com/vinceliuice/Qogir-icon-theme
  install_ui=1
fi
if [ ! -d "Jasper-gtk-theme" ] && [ "${desktopEnv}" == "GNOME" ]; then
  git clone https://github.com/vinceliuice/Jasper-gtk-theme
  install_ui=1
fi
if [ ! -d "Fluent-gtk-theme" ] && [ "${desktopEnv}" == "GNOME" ]; then
  git clone https://github.com/vinceliuice/Fluent-gtk-theme
  install_ui=1
fi
if [ ! -d "Fluent-icon-theme" ]; then
  git clone https://github.com/vinceliuice/Fluent-icon-theme
  install_ui=1
fi

# -------------------
# kora, marble, elementary OS and Zorin OS assets
# no installation scripts for them, need to manually install each

if [ ! -d "kora-icon-theme" ]; then
  git clone https://github.com/bikass/kora kora-icon-theme
  # no install script for now
  #install_ui=1
fi

if [ ! -d "Marble-shell-theme" ] && [ "${desktopEnv}" == "GNOME" ]; then
  git clone https://github.com/Fausto-Korpsvart/Marble-shell-theme
  # no install script for now
  #install_ui=1
fi

# elementary OS assets icons theme: no standard install; pull the repos for manual install
if [ ! -d "elementary-icon-theme" ]; then
  git clone https://github.com/elementary/icons elementary-icon-theme
  # no install script for now
  #install_ui=1
fi

# elementary OS assets: no standard install; pull the repos for manual install
if [ ! -d "elementary-sound-theme" ]; then
  git clone https://github.com/elementary/sound-theme elementary-sound-theme
  # no install script for now
  #install_ui=1
fi

# zorin OS assets - icons
if [ ! -d "zorin-icon-themes" ]; then
  git clone https://github.com/ZorinOS/zorin-icon-themes
  # no install script for now
  #install_ui=1
fi

# zorin OS assets - gtk
if [ ! -d "zorin-desktop-themes" ] && [ "${desktopEnv}" == "GNOME" ]; then
  git clone https://github.com/ZorinOS/zorin-desktop-themes
  # no install script for now
  #install_ui=1
fi
# -------------------

# for debian and derivatives, also sync throttled repo for manual install
if [ ! -d "throttled" ]; then
  git clone https://github.com/erpalma/throttled.git
  #sudo ./throttled/install.sh
fi

# execute install.sh script from each directory above where supported, if at least one was sync'd
if [ ${install_ui} -eq 1 ]; then
  echo "Executing UI installation scripts"
  find . -maxdepth 1 -type d \( ! -name . \) -exec bash -c "cd '{}' && pwd && ./install.sh" \;
fi

# Install Nerd fonts, cleanup and update font cache
source_nerd_font_dir="./nerd_font_install"
cd "${pkg_install_dir}" || exit
mkdir -p "${source_nerd_font_dir}"
cd "${source_nerd_font_dir}" || exit

fonts_dir="${HOME}/.local/share/fonts"
if [[ ! -d "${fonts_dir}" ]]; then
  mkdir -p "${fonts_dir}"
fi

#array defined at the top of the file, change list and version there
for font in "${fonts[@]}"; do
  zip_file="${font}.zip"
  download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${nerd_font_ver}/${zip_file}"
  echo "Downloading ${download_url}"
  wget "${download_url}"
  unzip -o "${zip_file}" -d "${fonts_dir}"
  rm "${zip_file}"
done
find "${fonts_dir}" -name '*Windows Compatible*' -delete
fc-cache -fv

if [ "${desktopEnv}" == "GNOME" ]; then
  # set GTK and icon themes
  echo "Setting GTK and Icon themes..."
  gsettings set org.gnome.desktop.interface gtk-theme "'Orchis-Dark-Compact'"
  # following fails and needs to be manually enabled in GNOME Tweaks
  gsettings set org.gnome.shell.extensions user-theme "'Orchis-Dark-Compact'"
  gsettings set org.gnome.desktop.interface icon-theme "'Tela-dark'"
  gsettings set org.gnome.desktop.interface color-scheme "'prefer-dark'"

  # enable minimize and maximize buttons and center windows
  gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
  gsettings set org.gnome.mutter center-new-windows true

  #customize clock on top bar
  gsettings set org.gnome.desktop.interface clock-format "'12h'"
  gsettings set org.gnome.desktop.interface clock-show-date true
  gsettings set org.gnome.desktop.interface clock-show-seconds false
  gsettings set org.gnome.desktop.interface clock-show-weekday true

  #set fonts
  gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 11'
  gsettings set org.gnome.desktop.interface font-name 'Cantarell 10'
  gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 10'
  gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Cantarell 10'
fi

# change back to original installation directory
cd "${install_dir}" || exit

####################################################################################
# Enable various services
####################################################################################

sudo systemctl daemon-reload

sudo systemctl enable tlp
sudo systemctl start tlp
sudo tlp start

sudo systemctl enable autofs
sudo systemctl start autofs

# only on fedora. on debian and derivatives, this happens 
# as part of manual installation/script
if [ "${ID}" == "fedora" ]; then
  sudo systemctl enable throttled
  sudo systemctl start throttled
fi

# Disable services: thermald conflicts with throttled
sudo systemctl disable thermald.service
sudo systemctl mask thermald.service

# change shell to zsh, need to logout and back in to take effect
# if zsh wasn't installed, this will automatically fail, not altering current shell
touch ~/.zshrc
chsh -s "$(which zsh)"

####################################################################################
# Manual install notice
####################################################################################

echo
echo "==========================================================================================="
echo
if [ "${desktopEnv}" == "GNOME" ]; then
  echo "Install the following GNOME Extensions manually from: https://extensions.gnome.org/"
  echo "AppIndiator and KStatusNotifierItem Support, ArcMenu, Caffine, Dash to Dock, Forge Tiling, Linux Update Notifier, Just Perfection,"
  echo "Removable Drive Menu, Transparent Window Moving, User Themes, Vitals, Weather O Clock, Easy Effects Preset Selector"
  echo
  echo "Manually set GNOME Shell theme and Hum alert sound in settings"
  echo
fi
# no need to install easyeffects presets, now part of repo and stowed
#echo "EasyEffects presets: bash -c \"$(curl -fsSL https://raw.githubusercontent.com/JackHack96/PulseEffects-Presets/master/install.sh)\""
#echo "and https://github.com/shuhaowu/linux-thinkpad-speaker-improvements"
#echo
echo "Manually set Nerd Font in: Terminal, Gnome Tweaks (if GNOME DE) and VSCode etc."
echo
echo "UI customizations have been cloned in ${pkg_install_dir}, for future git pulls and "
echo "updates or can be manually removed to save space."
echo
echo "==========================================================================================="
echo

####################################################################################
# ZSH and customizations
####################################################################################
ohmyzshinstallurl="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "==========================================================================================="
echo "Done! Logout and log back in for changes then login to github and run linux_post_installer.sh script."
echo "Before running the post-installer script, install oh-my-zsh manually from: https://ohmyz.sh/"
if [ "${install_os}" == "debian" ]; then
  echo
  echo "Install 'throttled' manually (https://github.com/erpalma/throttled) for Debian and derivatives"
  echo "Repo has been sync'd in ${pkg_install_dir}. Run \"sudo ./throttled/install.sh\" from this directory"
  echo
fi
echo "==========================================================================================="
#sh -c "$(curl -fsSL ${ohmyzshinstallurl})"

# installing oh-my-zsh will exit this script, so keep it as the last item to be installed
####################################################################################
# END of script
####################################################################################
