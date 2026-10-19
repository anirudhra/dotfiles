#!/bin/bash
# (c) Anirudh Acharya 2024, 2026
# macOS post installer script
# Run this script as non-root user AFTER macos_install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export DOTFILES_DIR
export ALIASES_HOME="${DOTFILES_DIR}/home"

source "${ALIASES_HOME}/.helperfuncs"
source "${ALIASES_HOME}/.filefuncs"
source "${ALIASES_HOME}/.gitfuncs"

OS_TYPE=$(detect_os_type)
SHELL_TYPE=$(detect_shell_type)

# only run this script on macOS
if [[ "${OS_TYPE}" != "macos" ]]; then
  error "This script is only supported for macOS"
  error "Please do not run this script from Linux/Windows etc."
  exit 1
fi

INSTALL_DIR="${SCRIPT_DIR}"

####################################################################################
# Functions
####################################################################################
backup_local_items() {
  local type="$1"
  local items_array=("${!2}")

  info "Backing up existing $type items..."

  for item in "${items_array[@]}"; do
    if [[ "$type" == "file" && -e "$item" ]]; then
      cp -rf "$item" "${item}.bak"
      info "Backed up file: $item"
    elif [[ "$type" == "dir" && -d "$item" ]]; then
      mv "$item" "${item}.bak"
      info "Backed up directory: $item"
    fi
  done
}

####################################################################################

echo
info "============================================================================================"
info "Starting automated macOS POST-installer script."
echo
read -r -p "Press Enter to continue, or Ctrl+C to quit: "
echo

# GitHub CLI authentication check
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    warn "Not authenticated with GitHub CLI. Launching login..."
    gh auth login
  else
    info "Already authenticated with GitHub CLI."
  fi
fi

####################################################################################
# Zsh/oh-my-zsh plugins
####################################################################################
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "${HOME}/.oh-my-zsh" ]; then
  info "Configuring powerlevel10k and oh-my-zsh plugins..."

  mkdir -p "${ZSH_CUSTOM_DIR}/themes" "${ZSH_CUSTOM_DIR}/plugins"

  # powerlevel10k theme
  P10K_DIR="${ZSH_CUSTOM_DIR}/themes/powerlevel10k"
  if [ ! -d "${P10K_DIR}" ]; then
    info "Cloning powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${P10K_DIR}"
  else
    info "powerlevel10k already present at ${P10K_DIR}"
  fi

  # oh-my-zsh plugins (shallow clone, idempotent)
  declare -A PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
    ["zsh-autocomplete"]="https://github.com/marlonrichert/zsh-autocomplete.git"
  )

  for plugin in "${!PLUGINS[@]}"; do
    plugin_dest="${ZSH_CUSTOM_DIR}/plugins/${plugin}"
    if [ ! -d "${plugin_dest}" ]; then
      info "Cloning plugin: ${plugin}..."
      git clone --depth=1 "${PLUGINS[$plugin]}" "${plugin_dest}"
    else
      info "Plugin ${plugin} already exists, skipping clone."
    fi
  done
else
  warn "oh-my-zsh directory not detected at ${HOME}/.oh-my-zsh; skipping plugin cloning."
fi

####################################################################################
# Karabiner-Elements configuration
####################################################################################
KARABINER_SRC="${SCRIPT_DIR}/karabiner/karabiner.json"
KARABINER_DST_DIR="${HOME}/.config/karabiner"
KARABINER_DST="${KARABINER_DST_DIR}/karabiner.json"

if [ -f "${KARABINER_SRC}" ]; then
  info "Configuring Karabiner-Elements..."
  mkdir -p "${KARABINER_DST_DIR}"
  if [ -e "${KARABINER_DST}" ] && [ ! -L "${KARABINER_DST}" ]; then
    cp -f "${KARABINER_DST}" "${KARABINER_DST}.bak"
    info "Backed up existing non-symlink karabiner.json"
  fi
  ln -sf "${KARABINER_SRC}" "${KARABINER_DST}"
  info "Linked Karabiner configuration -> ${KARABINER_DST}"
fi

####################################################################################
# iTerm2 Color Themes Import
####################################################################################
if [ -d "/Applications/iTerm.app" ] || [ -d "${HOME}/Applications/iTerm.app" ]; then
  info "Importing iTerm2 color schemes..."
  for color_file in "${SCRIPT_DIR}/iterm2-colors"/*.itermcolors; do
    if [ -f "$color_file" ]; then
      open -g "$color_file" 2>/dev/null || true
    fi
  done
  info "iTerm2 color schemes imported successfully."
fi

####################################################################################
# Install dotfiles with GNU Stow under /dotfiles/home directory
####################################################################################
files_to_backup=(
  "${HOME}/.profile"
  "${HOME}/.zshrc"
  "${HOME}/.aliases"
  "${HOME}/.p10k.zsh"
)

dirs_to_backup=(
  "${HOME}/.config/nvim"
)

backup_local_items "file" files_to_backup[@]
backup_local_items "dir" dirs_to_backup[@]

if command -v stow >/dev/null 2>&1; then
  info "Stowing dotfiles from ${DOTFILES_DIR}/home to ${HOME}..."
  cd "${DOTFILES_DIR}/home" || exit 1
  stow --verbose=1 --target="${HOME}" --stow --adopt .
  git restore .
  stow --verbose=1 --target="${HOME}" --stow .
  cd "${INSTALL_DIR}" || exit 1
  info "Dotfiles stowed successfully."
else
  warn "stow is not installed; skipping dotfiles linking. Install stow with 'brew install stow'."
fi

echo
info "==========================================================================================="
info "All done! Restart your terminal or logout and log back in for changes to take effect."
info "==========================================================================================="
echo
