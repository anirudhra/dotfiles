#!/bin/bash
# (c) Anirudh Acharya 2024
# macOS installer script
# Run this script as non-root user

source "../home/.helperfuncs"
OS_TYPE=$(detect_os_type)

# only run this script on macOS
if [[ "${OS_TYPE}" != "macos" ]]; then
  err "This script is only supported for macOS"
  err "Please do not run this script from Linux/Windows etc."
  err
  exit 1
fi

# check if running from the right directory
INSTALL_DIR=$(pwd)
if [[ ${INSTALL_DIR} != *"/dotfiles/macos"* ]]; then
  err "Script invoked from incorrect directory!"
  err "The current directory is: ${INSTALL_DIR}"
  err "Please run this script from .../dotfiles/macos directory"
  err
  exit 1
fi

# installs homebrew, oh-my-zsh, powerlevel10k
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install homebrew/cask/brew-cask

# command line apps
corepackages=(
  'wget'
  'imagemagick'
  'ack'
  'fortune'
  'cowsay'
  'colordiff'
  'expect'
  'fastfetch'
  'gawk'
  'gnu-sed'
  'p7zip'
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
  'iterm2'
  'vimr'
  'duf'
  'stow'
  'usbutils'
  'git'
  'gh'
  'fzf'
  'rdfind'
  'lolcat'
  'luarocks'
  'unzip'
  'ncdu'
  'iperf3'
)

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

gtkpackages=(
  # gtk integration - none for now
  #'gtk'
  #'gtk+'
  #'gtk+3'
  #'gtk-mac-integration'
  #'gtk-chtheme'
  #'gtk-engines'
  #'gtk-murrine-engine'
  #'gnome-themes-standard'
  # extract themes in /usr/local/Cellar/gtk+/2.24.31/share/themes
)

guipackages=(
  # cask gui apps
  #'macvim'
  'alfred'
  'gimp'
  'xquartz'
  'macfuse'
)

echo "Installing command line apps..."
brew install "${corepackages[@]}"
#install itemr2 shell integration
curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
echo "Installing command line apps... done!"

echo "Installing nerd fonts..."
brew install --cask "${nerdfonts[@]}"
echo "Installing command line apps... done!"

echo "Installing GUI apps..."
brew install "${gtkpackages[@]}" "${guipackages[@]}"
echo "Installing GUI apps... done!"

echo "Cleaning up..."
brew cleanup
#brew cask cleanup
echo "Cleaning up... done!"

echo "==============================================================================================="
echo "Installing oh-my-zsh. The script will exit automatically after this."
echo "Once oh-my-zsh is installed, quit and reopen terminal and run the macos_post_install.sh script"
echo "==============================================================================================="

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "Done!"
