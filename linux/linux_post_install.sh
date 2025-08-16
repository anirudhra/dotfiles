#!/bin/bash
# (c) Anirudh Acharya 2024, 2025
#
# Last Update: April 27, 2025
#
# Fedora setup and Fedora/Debian dotfiles repo for thinkpad
# Run this script as non-root user AFTER the linux_install.sh script
# git config --global user.name "name"
# git config --global user.email "email"
# gh auth login: for browser based git login instead of token

# get desktop environment
desktopEnv=${XDG_CURRENT_DESKTOP} #gnome, cinnamon, kde...
#Xsessiontype=${XDG_SESSION_TYPE} #X11, wayland

source "../home/.helperfuncs"
OS_TYPE=$(detect_os_type)
MACHINE_TYPE=$(detect_machine_type)

####################################################################################
# Functions
####################################################################################

# Function to install git repository
install_git_repo() {
  local repo_url="$1"
  local dest_dir="$2"
  local description="$3"
  local git_options="${4:-}"

  if [[ -d "$dest_dir" ]]; then
    echo "$description already exists: $dest_dir"
    return 0
  fi

  echo "Installing $description..."
  if git clone "$git_options" "$repo_url" "$dest_dir"; then
    echo "Successfully installed $description"
  else
    error "Error: Failed to install $description"
    return 1
  fi
}

# Generic function to backup existing files or directories
backup_local_items() {
  local type="$1"
  local items_array=("${!2}")

  echo "Backing up existing $type items..."

  for item in "${items_array[@]}"; do
    if [[ "$type" == "file" && -e "$item" ]]; then
      cp -rf "$item" "${item}.bak"
      echo "Backed up file: $item"
    elif [[ "$type" == "dir" && -d "$item" ]]; then
      mv "$item" "${item}.bak"
      echo "Backed up directory: $item"
    fi
  done
}

####################################################################################

echo
echo "==============================================================================================================="
echo "Starting automated POST-installer script. This should be run AFTER linux_install.sh script is run and "
echo "logging out and log back in. Make sure oh-my-zsh is installed first (after creating empty .zshrc file)"
echo
echo "If not, Press Ctrl+C now to quit, else Press Enter to continue"
read -p "================================================================================================================"
echo

# check if running from the right directory, OS and machine type
INSTALL_DIR=$(pwd)
if [[ ${INSTALL_DIR} != *"/dotfiles/linux"* ]]; then
  error "Script invoked from incorrect directory!"
  error "The current directory is: ${INSTALL_DIR}"
  error "Please run this script from .../dotfiles/linux directory"
  error
  exit 1
fi

if [[ ! "${MACHINE_TYPE}" == "client" ]]; then
  error "This script is only supported for Linux Client machines"
  error "Please do not run this script from PVE Server/Guest/SBCs"
  error
  exit 1
fi

if [[ ! "${OS_TYPE}" == "fedora" ]] || [[ ! "${OS_TYPE}" == "debian" ]]; then
  error "This script is only supported for Fedora and Debian based Linux machines"
  error "Please do not run this script from macOS/FreeBSD/Windows etc."
  error
  exit 1
fi

# check if oh-my-zsh is installed first
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  error "oh-my-zsh installation not detected!"
  error "Install oh-my-zsh from : https://ohmyz.sh/ before running this script!"
  error
  exit 1
fi

# git login, if not yet
GIT_LOGIN=$(gh auth status 2>&1 | grep -i "not logged into")
NOLOGINTEXT="You are not logged into any GitHub hosts. To log in, run: gh auth login"

if [ "${GIT_LOGIN}" == "${NOLOGINTEXT}" ]; then
  #debug
  warn "Not logged into git, logging in..."
  #git login
  gh auth login #for browser based git login instead of token
  git config --global core.editor "nano"
fi

####################################################################################
# Zsh/oh-my-zsh plugins, all these are enabled in "stowed zshrc" already
####################################################################################
if [[ "${SHELL_TYPE}" == "zsh" ]]; then
  # install powerlevel10k
  echo "Installing powerlevel10k and oh-my-zsh plugins..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  #install oh-my-zsh plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
  git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete"
fi

####################################################################################
# EasyEffects pipewire audio enhancer plugins
####################################################################################
# easyeffects presets are now part of github repo and will be stowed

####################################################################################
# Install dotfiles with stow under /dotfiles/home directory - should be last in this file
####################################################################################

# Define arrays for backup
files_to_backup=(
  "${HOME}/.profile"
  "${HOME}/.zshrc"
  "${HOME}/.aliases"
  "${HOME}/.p10k.zsh"
)

dirs_to_backup=(
  "${HOME}/.config/nvim"
)

# Call the generic function for files
backup_local_items "file" files_to_backup[@]

# Call the generic function for directories
backup_local_items "dir" dirs_to_backup[@]

echo "Backup pre-stow completed"

# activate stow
echo "Stowing dotfiles..."
cd "${INSTALL_DIR}/../home" || exit 1
stow --verbose=1 --target="${HOME}" --stow --adopt .
# above will overwrite git repo if files already exist in $HOME,
# git restore . will restore with the correct versions, this is a trick to overwrite with repo files
git restore .
cd "${INSTALL_DIR}" || exit 1

####################################################################################
# Restore GNOME shell extension sessings via config
####################################################################################

if [ "${desktopEnv}" == "GNOME" ]; then
  echo "Restoring GNOME shell extension settings..."
  dconf load /org/gnome/shell/extensions/ <"${INSTALL_DIR}/config/extensions/gnome_extensions_backup.dconf"
fi

echo
echo "==========================================================================================="
echo "All done, logout and log back in for changes to take effect."
if [[ "${OS_TYPE}" == "debian" ]]; then
  if [ ! -e "/usr/bin/fastfetch" ]; then
    echo
    echo "Install fastfetch from https://github.com/fastfetch-cli/fastfetch"
  fi
fi
echo "==========================================================================================="

####################################################################################
# END of script
####################################################################################
