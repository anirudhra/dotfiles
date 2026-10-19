#!/bin/bash
# (c) Anirudh Acharya 2024, 2026
# macOS installer script
# Run this script as non-root user

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export DOTFILES_DIR
export ALIASES_HOME="${DOTFILES_DIR}/home"

source "${ALIASES_HOME}/.helperfuncs"
OS_TYPE=$(detect_os_type)

# only run this script on macOS
if [[ "${OS_TYPE}" != "macos" ]]; then
  error "This script is only supported for macOS"
  error "Please do not run this script from Linux/Windows etc."
  exit 1
fi

INSTALL_DIR="${SCRIPT_DIR}"
ARCH_TYPE="$(uname -m)"

info "Detected macOS (${ARCH_TYPE})"

# Homebrew setup:
# If Apple Silicon and brew is missing -> auto install.
# If Intel and brew is missing -> skip installation entirely (optional on Intel).
if command -v brew &>/dev/null; then
  info "Homebrew is already installed and available."
  if [[ "${ARCH_TYPE}" == "arm64" && -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  if [[ "${ARCH_TYPE}" == "arm64" ]]; then
    info "Apple Silicon detected (arm64): launching Homebrew installation..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -f "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    warn "Intel CPU detected (${ARCH_TYPE}): skipping automated Homebrew installation as configured."
    warn "If you wish to use Homebrew on this Intel Mac, install it manually from https://brew.sh/"
  fi
fi

# Command line applications
corepackages=(
  'wget'
  'imagemagick'
  'ack'
  'fortune'
  'cowsay'
  'colordiff'
  'expect'
  'most'
  'fastfetch'
  'gawk'
  'gnu-sed'
  'p7zip'
  'bat'
  'bat-extras'
  'zoxide'
  'eza'
  'pv'
  'btop'
  'calc'
  'dos2unix'
  'nmap'
  'rename'
  'watch'
  'tree'
  'trash'
  'coreutils'
  'figlet'
  'neovim'
  'duf'
  'stow'
  'usbutils'
  'git'
  'gh'
  'fzf'
  'rdfind'
  'lolcat'
  'luarocks'
  'ncdu'
  'iperf3'
  'rsync'
)

# Nerd fonts (available via Homebrew Cask)
nerdfonts=(
  'font-fira-code-nerd-font'
  'font-fira-mono-nerd-font'
  'font-hack-nerd-font'
  'font-meslo-lg-nerd-font'
  'font-roboto-mono-nerd-font'
  'font-ubuntu-nerd-font'
  'font-sauce-code-pro-nerd-font'
  'font-ubuntu-mono-nerd-font'
  'font-jetbrains-mono-nerd-font'
  'font-dejavu-sans-mono-nerd-font'
  'font-droid-sans-mono-nerd-font'
)

# GUI cask applications
guipackages=(
  'alfred'
  'gimp'
  'xquartz'
  'macfuse'
  'vimr'
  'iterm2'
)

if command -v brew &>/dev/null; then
  echo
  info "Installing command line apps via Homebrew..."
  brew install "${corepackages[@]}"
  info "Installing command line apps: done!"

  # Install iTerm2 shell integration script
  curl -fsSL https://iterm2.com/shell_integration/zsh -o "${HOME}/.iterm2_shell_integration.zsh" || true

  echo
  info "Installing GUI cask apps..."
  brew install --cask "${guipackages[@]}"
  info "Installing GUI apps: done!"

  echo
  info "Installing nerd fonts..."
  brew install --cask "${nerdfonts[@]}"
  info "Installing nerd fonts: done!"

  echo
  info "Cleaning up Homebrew cache..."
  brew cleanup
  info "Cleaning up: done!"
else
  warn "Homebrew is not installed; skipping Homebrew package installation."
fi

# Oh-My-Zsh setup
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  echo
  info "==============================================================================================="
  info "Installing oh-my-zsh non-interactively..."
  info "==============================================================================================="
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" || true
else
  info "oh-my-zsh is already installed at ${HOME}/.oh-my-zsh, skipping."
fi

echo
info "==============================================================================================="
info "macOS install complete! Please run macos_post_install.sh to finalize dotfiles and configs."
info "==============================================================================================="
echo
