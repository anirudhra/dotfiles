#!/bin/bash
# (c) Anirudh Acharya 2024
# macOS post installer script
# Run this script as non-root user

source "../home/.helperfuncs"
OS_TYPE=$(detect_os_type)
SHELL_TYPE=$(detect_shell_type)

# only run this script on macOS
if [[ "${OS_TYPE}" != "macos" ]]; then
  error "This script is only supported for macOS"
  error "Please do not run this script from Linux/Windows etc."
  error
  exit 1
fi

# check if running from the right directory
INSTALL_DIR=$(pwd)
if [[ ${INSTALL_DIR} != *"/dotfiles/macos"* ]]; then
  error "Script invoked from incorrect directory!"
  error "The current directory is: ${INSTALL_DIR}"
  error "Please run this script from .../dotfiles/macos directory"
  error
  exit 1
fi

####################################################################################
# Functions
####################################################################################
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

# This is the post install script and MUST be run after macos_install.sh script
echo
echo "============================================================================================"
echo "Starting automated POST-installer script. This should be run AFTER macos_install.sh script is run and"
read -p "reopening the terminal. If not, Press Ctrl+C now to quit, else Press Enter to continue" -n1 -s
#echo "============================================================================================"
echo

#git login, choose browser based for easy auth
gh auth login
git config --global core.editor "nano"

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
# Install dotfiles with stow under /dotfiles/home directory - should be last in this file
####################################################################################

#backup existing files
LOCAL_PROFILE="$HOME/.profile"
LOCAL_ZSHRC="$HOME/.zshrc"
LOCAL_ALIASES="$HOME/.aliases"
LOCAL_P10K="$HOME/.p10k.zsh"
LOCAL_NVIM_DIR="$HOME/.config/nvim"

# Define arrays for backup
files_to_backup=(
  "$LOCAL_PROFILE"
  "$LOCAL_ZSHRC"
  "$LOCAL_ALIASES"
  "$LOCAL_P10K"
)

dirs_to_backup=(
  "$LOCAL_NVIM_DIR"
)

# Call the generic function for files
backup_local_items "file" files_to_backup[@]

# Call the generic function for directories
backup_local_items "dir" dirs_to_backup[@]

# activate stow
echo "Stowing dotfiles..."
cd "${INSTALL_DIR}/../home" || exit 1
stow --verbose=1 --target="$HOME" --stow --adopt .
# above will overwrite git repo if files already exist in $HOME,
# git restore . will restore with the correct versions, this is a trick to overwrite with repo files
git restore .
cd "${INSTALL_DIR}" || exit 1

echo "==========================================================================================="
echo " All done, logout and log back in for changes to take effect."
echo "==========================================================================================="

####################################################################################
# END of script
####################################################################################
