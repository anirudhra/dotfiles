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
source "../home/.filefuncs"
source "../home/.gitfuncs"

OS_TYPE=$(detect_os_type)
MACHINE_TYPE=$(detect_machine_type)

####################################################################################
# Functions
####################################################################################

# functions used in this file can be found in ~/dotfiles/home/.filefuncs file

# Function to install zsh/oh-my-zsh plugins
install_zsh_plugins() {
  info "Installing powerlevel10k and oh-my-zsh plugins..."
  echo
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  #install oh-my-zsh plugins
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
  git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete"
}

####################################################################################

echo
info "==============================================================================================================="
info "Starting automated POST-installer script. This should be run AFTER linux_install.sh script is run and "
info "logging out and log back in. Make sure oh-my-zsh is installed first (after creating empty .zshrc file)"
echo
info "If not, Press Ctrl+C now to quit, else Press Enter to continue"
read -p "================================================================================================================"
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

# check if oh-my-zsh is installed first
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  error "oh-my-zsh installation not detected!"
  error "Install oh-my-zsh from : https://ohmyz.sh/ before running this script!"
  echo
  exit 1
fi

if [[ ! "${MACHINE_TYPE}" == "client" ]]; then
  warn "WARNING: This script is intended to be run only on 'client' Linux machines"
  warn "Detected machine type: ${MACHINE_TYPE}"
  warn "This script is NOT recommended for PVE Server/Guest/SBCs/others"
  warn "Running this script on non-client machines may cause issues or unexpected behavior"
  echo
  read -p "Do you really want to continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Script execution cancelled by user."
    exit 0
  fi
  warn "Proceeding with script execution on ${MACHINE_TYPE} machine..."
  echo
fi

# git login, if not yet
echo
info "Do you want to configure git-cli (GitHub authentication and basic settings)?"
read -p "This will run 'gh auth login' and set git editor to nano. Continue? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  GIT_LOGIN=$(gh auth status 2>&1 | grep -i "not logged into")
  NOLOGINTEXT="You are not logged into any GitHub hosts. To log in, run: gh auth login"

  if [ "${GIT_LOGIN}" == "${NOLOGINTEXT}" ]; then
    #debug
    warn "Not logged into git, logging in..."
    #git login
    gh auth login #for browser based git login instead of token
    git config --global core.editor "nano"
  else
    info "Already logged into GitHub, skipping authentication."
    git config --global core.editor "nano"
  fi
else
  info "Skipping git-cli configuration."
fi

####################################################################################
# Zsh/oh-my-zsh plugins, all these are enabled in "stowed zshrc" already
####################################################################################
if [[ "${SHELL_TYPE}" == "zsh" ]]; then
  install_zsh_plugins
else
  warn "Detected shell type: ${SHELL_TYPE} (not zsh)"
  warn "The following commands are designed for zsh/oh-my-zsh setup."
  echo
  read -p "Do you want to install zsh/oh-my-zsh plugins anyway? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_zsh_plugins
  else
    info "Skipping zsh/oh-my-zsh plugin installation."
  fi
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

info "Backup pre-stow completed"

# activate stow
info "Stowing dotfiles..."
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
  info "Restoring GNOME shell extension settings..."
  dconf load /org/gnome/shell/extensions/ <"${INSTALL_DIR}/config/extensions/gnome_extensions_backup.dconf"
fi

echo
info "==========================================================================================="
info "All done, logout and log back in for changes to take effect."

if command -v fastfetch >/dev/null 2>&1; then
  echo
  info "Fastfetch not detected. Install fastfetch from package manager"
  info "or https://github.com/fastfetch-cli/fastfetch"
fi

info "==========================================================================================="

####################################################################################
# END of script
####################################################################################
