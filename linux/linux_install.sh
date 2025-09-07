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

source "../home/.helperfuncs"
OS_TYPE=$(detect_os_type)
MACHINE_TYPE=$(detect_machine_type)

####################################################################################
# Functions
####################################################################################

# Function to safely backup and install files
install_file() {
  local source_file="$1"
  local dest_file="$2"
  local description="$3"

  # Check if source file exists
  if [[ ! -f "$source_file" ]]; then
    erroror "Warning: Source file $source_file does not exist, skipping $description"
    return 1
  fi

  # Backup existing file if it exists
  if [[ -e "$dest_file" ]]; then
    info "Backing up existing $description: $dest_file"
    sudo cp -f "$dest_file" "${dest_file}.bak" || {
      error "Error: Failed to backup $dest_file"
      return 1
    }
  fi

  info "Installing $description: $source_file -> $dest_file"
  sudo cp -f "$source_file" "$dest_file" || {
    error "Error: Failed to install $description"
    return 1
  }

  info "Successfully installed $description"
  return 0
}

# Function to add entry to file if not present
append_entry_to_file() {
  local entry="$1"
  local file="$2"
  local description="$3"

  if grep -Fq "$entry" "$file" 2>/dev/null; then
    warn "$description already exists in $file"
  else
    info "Adding $description to $file"
    info "# Adding $description" | sudo tee -a "$file"
    info "$entry" | sudo tee -a "$file"
  fi
}

# Generic function to create repository file
create_repo_file() {
  local repo_file="$1"
  local repo_content="$2"
  local os_type="$3"

  if [[ ! -e "$repo_file" ]]; then
    info "Creating repository file: $repo_file"
    if [[ "$os_type" == "debian" ]]; then
      # For Debian/Ubuntu, use add-apt-repository
      info "$repo_content" | sudo add-apt-repository -y
    else
      # For Fedora/RHEL, create repo file
      info -e "$repo_content" | sudo tee "$repo_file" >/dev/null
    fi
  else
    info "Repository file already exists: $repo_file"
  fi
}

# Generic function to backup existing files or directories
backup_system_items() {
  local type="$1"
  local items_array=("${!2}")

  info "Backing up existing $type items..."

  for item in "${items_array[@]}"; do
    if [[ "$type" == "file" && -e "$item" ]]; then
      sudo cp -rf "$item" "${item}.bak"
      info "Backed up file: $item"
    elif [[ "$type" == "dir" && -d "$item" ]]; then
      sudo mv "$item" "${item}.bak"
      info "Backed up directory: $item"
    fi
  done
}

####################################################################################

echo
info "===================================================================================="
info "Starting automated installer..."
info "===================================================================================="
echo

# check if running from the right directory, OS and machine type
INSTALL_DIR=$(pwd)
if [[ ${INSTALL_DIR} != *"/dotfiles/linux"* ]]; then
  error "Script invoked from incorrect directory!"
  error "The current directory is: ${INSTALL_DIR}"
  error "Please run this script from .../dotfiles/linux directory"
  echo
  exit 1
fi

if [[ ! "${MACHINE_TYPE}" == "client" ]]; then
  error "This script is only supported for Linux Client machines"
  error "Please do not run this script from/on PVE Server/Guests/SBCs/Routers"
  echo
  exit 1
fi

if [[ "${OS_TYPE}" == "fedora" ]] || [[ "${OS_TYPE}" == "arch" ]] || [[ "${OS_TYPE}" == "debian" ]]; then
  info "Detected supported OS Type: ${OS_TYPE}"
else
  error "This script is only supported for Fedora, Arch and Debian based Linux Clients"
  error "Detected OS (should be fedora/arch/debian): ${OS_TYPE}"
  error "Please do not run this script from macOS/FreeBSD/Windows etc."
  error "For macOS, run macOS-specific installer script."
  echo
  exit 1
fi

# get desktop environment
desktopEnv=${XDG_CURRENT_DESKTOP} #gnome, cinnamon, kde...
#Xsessiontype=${XDG_SESSION_TYPE}  #X11, wayland

# get OS info
INSTALL_OS=${OS_TYPE}
INSTALLER=""
INSTALL_OPTIONS=""

# get right timezone and locale/language
L_TZ="America/Los_Angeles"
L_LANG="en_US.UTF-8"

TZSET=""
if [[ -f /etc/timezone ]]; then
  TZSET=$(cat /etc/timezone)
fi
# LANG is env. variable
LANGSET=${LANG}

if [[ "${INSTALL_OS}" == "fedora" ]]; then
  info "Fedora or derivative detected!"
  echo
  INSTALLER="dnf"
  INSTALL_OPTIONS="--skip-unavailable" #skip unavailable goes here

  # add repos and keys
  sudo ${INSTALLER} install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

  #install plugin manager first
  sudo ${INSTALLER} install dnf-plugins-core

  #microsoft repos
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  VSCODE_REPO_FILE="/etc/yum.repos.d/vscode.repo"
  MSEDGE_REPO_FILE="/etc/yum.repos.d/microsoft-edge.repo"

  # Define repository contents
  MSEDGE_REPO_CONTENT="[microsoft-edge]\nname=Microsoft Edge Browser\nbaseurl=https://packages.microsoft.com/yumrepos/edge\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc"
  VSCODE_REPO_CONTENT="[visualstudio-code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc"

  # Call the function for both repositories
  create_repo_file "$MSEDGE_REPO_FILE" "$MSEDGE_REPO_CONTENT"
  create_repo_file "$VSCODE_REPO_FILE" "$VSCODE_REPO_CONTENT"

  sudo ${INSTALLER} group upgrade core -y
  sudo ${INSTALLER} update --refresh

# Debian and derivative distros
elif [[ "${INSTALL_OS}" == "debian" ]]; then
  info "Debian or derivative detected!"
  echo
  info "Before you run this script, enable non-free and non-free-firmware repos"
  info "!!!Press Ctrl-C to quit now to enable and re-run this script!!! If enabled, press Enter"
  echo
  read -p "===================================================================================="

  INSTALL_OS="debian"
  INSTALLER="apt"
  INSTALL_OPTIONS="" #skip unavailable goes here

  # add repos
  sudo add-apt-repository universe -y && sudo add-apt-repository ppa:agornostal/ulauncher -y
  sudo apt-get install wget gpg

  #install/refresh microsoft repo keys
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
  rm -f packages.microsoft.gpg

  #micrsoft vscode and edge
  VSCODE_REPO_FILE="/etc/apt/sources.list.d/vscode.list"
  MSEDGE_REPO_FILE="/etc/apt/sources.list.d/miscrosoft-edge.list"

  # Define repository contents for Debian
  VSCODE_REPO_CONTENT="deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
  MSEDGE_REPO_CONTENT="deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main"

  # Call the function for both repositories (debian type)
  create_repo_file "$VSCODE_REPO_FILE" "$VSCODE_REPO_CONTENT" "$INSTALL_OS"
  create_repo_file "$MSEDGE_REPO_FILE" "$MSEDGE_REPO_CONTENT" "$INSTALL_OS"

  # Configure console font and size, esp. usefull for hidpi displays (select Combined Latin, Terminus, 16x32 for legibility
  # disabled for now, enable this manually if needed
  #echo "Configuring Console..."
  #sudo dpkg-reconfigure console-setup
  # Configure timezone and locale for en/UTF-8
  if [[ ! "${TZSET}" == "${L_TZ}" ]]; then
    info "Configuring Timezone..."
    #sudo dpkg-reconfigure tzdata
    sudo timedatectl set-timezone "${L_TZ}" #set automatically
  fi

  if [[ ! "${LANGSET}" == "${L_LANG}" ]]; then
    info "Configuring Locales..."
    #sudo dpkg-reconfigure locales
    sudo update-locale LANG=${L_LANG} #set automatically
  fi

elif [[ "${INSTALL_OS}" == "arch" ]]; then
  info "Arch or derivative detected!"
  echo

  INSTALLER="yay"        # don't run this as sudo
  INSTALLER_ALT="pacman" # run this as sudo
  INSTALL_OPTIONS="-Sy"  # skip unavailable goes here

  # sync and update repo
  sudo ${INSTALLER_ALT} ${INSTALL_OPTIONS}u
  # now install yay
  sudo ${INSTALLER_ALT} ${INSTALL_OPTIONS} --needed git base-devel
  sudo ${INSTALLER_ALT} ${INSTALL_OPTIONS} ${INSTALLER}

# unknown OS, exit
else
  error "Unknown OS, cannot proceed; exiting"
  exit 1
fi

####################################################################################
# Install packages
####################################################################################

# list of core packages
CORE_PACKAGES=(
  'tmux'
  'most'
  'duf'
  'code'
  'btop'
  'stress'
  'zsh'
  #'powertop'
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
  'stow'
  'vlc'
  'iotop'
  'iftop'
  'atop'
  #'gem'
  #'luarocks'
  'fzf'
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
  'bat'
  'yazi'
  's-tui'
  'solaar' #logitech config utility
  'papirus-icon-theme'
)

# seperate out core gnome packages
# need not install on distros w/ xfce/cinnamon
CORE_GNOME_PKGS=(
  'gparted'
  #'gimp'
  #'menulibre'
  #'geary'
  'gnome-tweaks'
  'dconf-editor'
)

# Nerd fonts list to be installed
# Update to lastest version from: https://github.com/ryanoasis/nerd-fonts
NERD_FONT_VER='3.4.0'

# enable the nerd fonts to be installed
NERD_FONTS=(
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

info "Starting ${INSTALL_OS} installer..."

# OS specific packages are listed in this block
if [ "${INSTALL_OS}" == "fedora" ]; then
  # Fedora specific packages
  OS_PACKAGES=(
    'throttled'
    'dnf-plugins-core'
    'fastfetch'
    'fd-find'
    'lm_sensors'
    'p7zip-plugins'
    'nfs-utils'
    'python3-pip'
    'intel-media-driver'
    'epapirus-icon-theme'
    'papirus-icon-theme-dark'
    'papirus-icon-theme-light'
    'ulauncher'
    #'btrfs-assistant' #this needs QT libraries
    'heif-pixbuf-loader'
    'libheif-freeworld'
    'libheif'
    'vainfo'
    'avahi-daemon'
    'easyeffects'
    'zoxide'
    'gh'
    'fuse'
    'fuse-libs'
    'meson'
    'ninja'
  )

  OS_GNOME_PKGS=(
    'gtk-murrine-engine'
    'gnome-extensions-app'
    'gtk2-engines'
  )

  # following conflicts with throttled
  sudo ${INSTALLER} remove thermald -y
  sudo ${INSTALLER} copr enable abn/throttled -y

# Debian/Ubuntu specific packages
elif [ "${INSTALL_OS}" == "debian" ]; then
  OS_PACKAGES=(
    'apt-transport-https'
    'avahi-daemon'
    'lm-sensors'
    'fd-find'
    'neofetch'
    'avahi-utils'
    'nfs-common'
    'systemd-resolved'
    'cifs-utils'
    'gh'
    'alsa-utils'
    'intel-media-va-driver-non-free'
    'ulauncher'
    # the following are for 'throttled' build and install
    'build-essential'
    'python3-dev'
    'libdbus-glib-1-dev'
    'vainfo'
    'libgirepository1.0-dev'
    'libcairo2-dev'
    'python3-cairo-dev'
    'python3-venv'
    'python3-wheel'
    'python3-pip'
    #'unattended-upgrades'
    #'apt-listchanges'
  )

  OS_GNOME_PKGS=(
    'gtk2-engines-murrine'
    'gtk2-engines-pixbuf'
    'chrome-gnome-shell'
    'gnome-shell-extension-prefs'
  )

  # conflicts with throttled, remove
  sudo ${INSTALLER} remove thermald -y

# Arch specific packages
elif [ "${INSTALL_OS}" == "arch" ]; then
  OS_PACKAGES=(
    'throttled'
    'github-cli'
    'fastfetch'
    'fd'
    'lm_sensors'
    'avahi'
    'nfs-utils'
    'intel-media-driver'
    'linux-firmware'
    'vulkan-intel'
    'libva-utils'
    'python-pip'
    'ulauncher'
    #'btrfs-assistant' #this needs QT libraries
    'libheif'
    'easyeffects'
    'zoxide'
    'fuse'
    'meson'
    'ninja'
  )

  OS_GNOME_PKGS=(
    'gtk-engine-murrine'
    'extension-manager'
    'gtk-engines'
  )
fi

if [[ "${OS_TYPE}" == "fedora" ]] || [[ "${OS_TYPE}" == "debian" ]]; then
  # refresh again to be sure
  sudo ${INSTALLER} update && sudo ${INSTALLER} upgrade

  # install all non-gnome packages
  sudo ${INSTALLER} install "${CORE_PACKAGES[@]}" "${INSTALL_OPTIONS}"
  sudo ${INSTALLER} install "${OS_PACKAGES[@]}" "${INSTALL_OPTIONS}"

  # on gnome, install gnome-only packages
  if [ "${desktopEnv}" == "GNOME" ]; then
    sudo ${INSTALLER} install "${CORE_GNOME_PKGS[@]}" "${INSTALL_OPTIONS}"
    sudo ${INSTALLER} install "${OS_GNOME_PKGS[@]}" "${INSTALL_OPTIONS}"
  fi
elif [[ "${OS_TYPE}" == "arch" ]]; then

  ${INSTALLER} "${INSTALL_OPTIONS}" "${CORE_PACKAGES[@]}"
  ${INSTALLER} "${INSTALL_OPTIONS}" "${OS_PACKAGES[@]}"

  if [[ "${desktopEnv}" == "GNOME" ]]; then
    ${INSTALLER} "${INSTALL_OPTIONS}" "${CORE_GNOME_PKGS[@]}"
    ${INSTALLER} "${INSTALL_OPTIONS}" "${OS_GNOME_PKGS[@]}"
  fi
fi

####################################################################################
# Install dotfiles with stow under /dotfiles/home directory
####################################################################################
# dotfiles installation with stow is now done in the post installer script

####################################################################################
# Install /etc config files
####################################################################################
# Configuration file paths
SOURCE_AUTOFS_SHARE_FILE="./config/etc/auto.pveshare"
SYS_AUTOFS_SHARE_FILE="/etc/auto.pveshare"
SOURCE_TLP_FILE="./config/etc/tlp.conf"
SYS_TLP_FILE="/etc/tlp.conf"
SOURCE_THROTTLED_FILE="./config/etc/throttled.conf"
SYS_THROTTLED_FILE="/etc/throttled.conf"
NFS_MOUNT_POINT="/mnt/nfs"
AUTOFS_MASTER="/etc/auto.master"

# Define arrays for backup
system_files_to_backup=(
  "$SYS_AUTOFS_SHARE_FILE"
  "$SYS_TLP_FILE"
  "$SYS_THROTTLED_FILE"
)

# Backup existing system configuration files
backup_system_items "file" system_files_to_backup[@]

# Create NFS mount point with proper permissions
echo "Creating NFS mount point: $NFS_MOUNT_POINT"
sudo mkdir -p "$NFS_MOUNT_POINT" || {
  error "Error: Failed to create NFS mount point"
  exit 1
}
sudo chmod 755 "$NFS_MOUNT_POINT" || {
  error "Error: Failed to set NFS mount point permissions"
  exit 1
}

# Add auto mount PVE to auto.master file
append_entry_to_file "/- $SYS_AUTOFS_SHARE_FILE" "$AUTOFS_MASTER" "PVE server NFS entry mount"

# Install autofs PVE share file
install_file "$SOURCE_AUTOFS_SHARE_FILE" "$SYS_AUTOFS_SHARE_FILE" "AutoFS share configuration"

# Install TLP config file
install_file "$SOURCE_TLP_FILE" "$SYS_TLP_FILE" "TLP configuration"

# Install throttled config file
install_file "$SOURCE_THROTTLED_FILE" "$SYS_THROTTLED_FILE" "Throttled configuration"

####################################################################################
# Install UI/Customizations
####################################################################################

debuglog "Current directory: ${INSTALL_DIR}"

# Replace audio alert file
AUDIO_ALERT_FILE="/usr/share/sounds/gnome/default/alerts/hum.ogg"
AUDIO_ALERT_SOURCE_FILE="./gtk/sounds/hum.ogg"

# Install audio alert file replacement
install_file "$AUDIO_ALERT_SOURCE_FILE" "$AUDIO_ALERT_FILE" "Installing audio alert replacement"

# Install GTK and Icon themes in the following directory
PKG_INSTALL_DIR="${HOME}/packages/install"
mkdir -p "${PKG_INSTALL_DIR}"
cd "${PKG_INSTALL_DIR}" || exit 1

# for debian and derivatives, also sync throttled repo for manual install
if [[ ! -d "${PKG_INSTALL_DIR}/throttled" ]] && [[ "${INSTALL_OS}" == "debian" ]]; then
  git clone https://github.com/erpalma/throttled.git
  sudo /bin/bash "${PKG_INSTALL_DIR}/throttled/install.sh"
fi

# Install Nerd fonts, cleanup and update font cache
SOURCE_NERD_FONT_DIR="./nerd_font_install"
mkdir -p "${SOURCE_NERD_FONT_DIR}"
cd "${SOURCE_NERD_FONT_DIR}" || exit 1

FONTS_DIR="${HOME}/.local/share/fonts"
mkdir -p "${FONTS_DIR}"

info "Installing Nerf Fonts..."

#array defined at the top of the file, change list and version there
for font in "${NERD_FONTS[@]}"; do
  ZIP_FILE="${font}.zip"
  DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VER}/${ZIP_FILE}"
  info "Downloading ${DOWNLOAD_URL}"
  wget "${DOWNLOAD_URL}"
  unzip -o "${ZIP_FILE}" -d "${FONTS_DIR}"
  rm "${ZIP_FILE}"
done
find "${FONTS_DIR}" -name '*Windows Compatible*' -delete
fc-cache -fv

## install gtk themes
info "Installing GTK themes..."
# change back to original installation directory
cd "${INSTALL_DIR}" || exit 1
/bin/bash ./gtk/gtkthemes.sh

if [[ "${desktopEnv}" == "GNOME" ]]; then
  # set GTK and icon themes
  info "Setting GTK and Icon themes..."
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
cd "${INSTALL_DIR}" || exit 1

####################################################################################
# Enable various services
####################################################################################

sudo systemctl daemon-reload

sudo systemctl enable tlp
sudo systemctl start tlp
sudo tlp start

sudo systemctl enable rpcbind
sudo systemctl start rpcbind

sudo systemctl enable autofs
sudo systemctl start autofs

# only on fedora. on debian and derivatives, this happens
# as part of manual installation/script
if [[ "${INSTALL_OS}" == "fedora" ]] || [[ "${INSTALL_OS}" == "arch" ]]; then
  sudo systemctl enable throttled
  sudo systemctl start throttled
  sudo systemctl mask systemd-rfkill.socket
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
info "==========================================================================================="
echo
if [[ "${desktopEnv}" == "GNOME" ]]; then
  info "Install the following GNOME Extensions manually from: https://extensions.gnome.org/"
  info "AppIndiator and KStatusNotifierItem Support, ArcMenu, Caffine, Dash to Dock, Forge Tiling, Linux Update Notifier, Just Perfection,"
  info "Removable Drive Menu, OpenBar, Transparent Window Moving, User Themes, Vitals, Weather O Clock, Easy Effects Preset Selector"
  echo
  info "Manually set GNOME Shell theme and Hum alert sound in settings"
  echo
fi
# no need to install easyeffects presets, now part of repo and stowed
#echo "EasyEffects presets: bash -c \"$(curl -fsSL https://raw.githubusercontent.com/JackHack96/PulseEffects-Presets/master/install.sh)\""
#echo "and https://github.com/shuhaowu/linux-thinkpad-speaker-improvements"
#echo
info "Manually set Nerd Font in: Terminal, Gnome Tweaks (if GNOME DE) and VSCode etc."
echo
info "UI customizations have been cloned in ${PKG_INSTALL_DIR}, for future git pulls and "
info "updates or can be manually removed to save space."
echo
info "==========================================================================================="
echo

####################################################################################
# ZSH and customizations
####################################################################################

info "==========================================================================================="
info "Done! Logout and log back in for changes then login to github and run linux_post_installer.sh script."
info "Before running the post-installer script, install oh-my-zsh manually from: https://ohmyz.sh/"
if [[ "${INSTALL_OS}" == "debian" ]]; then
  # install latest version of zoxide as debian repos have an old buggy version
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  echo
  info "Install 'throttled' manually (https://github.com/erpalma/throttled) for Debian and derivatives"
  info "Repo has been sync'd in ${PKG_INSTALL_DIR}. Run \"sudo ./throttled/install.sh\" from this directory"
  echo
fi
info "==========================================================================================="

# installing oh-my-zsh will exit this script, needs to debugged
#ohmyzshinstallurl="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#sh -c "$(curl -fsSL ${ohmyzshinstallurl})"

####################################################################################
# END of script
####################################################################################
