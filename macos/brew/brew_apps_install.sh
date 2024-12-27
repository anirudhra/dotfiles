#!/bin/sh

#
# command line apps
#
echo "Installing command line apps..."
brew install romkatv/powerlevel10k/powerlevel10k
echo 'source $(brew --prefix powerlevel10k)/powerlevel10k.zsh-theme' >>! ~/.zshrc
#brew tap homebrew/dupes
brew install wget
#brew install homebrew/dupes/tidy
#brew install node
#brew install imagemagick
brew install ack
brew install fortune
brew install cowsay
brew install colordiff
brew install neofetch
brew install gawk
#brew install gnu-sed --with-default-names
brew install gnu-sed
brew install p7zip
brew install pv
brew install sshfs
brew install htop
brew install calc
brew install dos2unix
brew install ext2fuse
brew install ext4fuse
#brew install python-tk
#brew install tcl-tk
#brew install homebrew/dupes/grep
brew install nmap
brew install ntfs-3g
brew install rename
brew install watch
brew install tree
brew install trash
brew install coreutils
brew install figlet
brew install font-hack-nerd-font
brew install font-meslo-lg-nerd-font
brew install nvim
brew install iterm2
brew install vimr

# gtk integration
#brew install gtk
#brew install gtk+
#brew install gtk+3
#brew install gtk-mac-integration
#brew install gtk-chtheme
#brew install gtk-engines
#brew install gtk-murrine-engine
#brew install gnome-themes-standard
# extract themes in /usr/local/Cellar/gtk+/2.24.31/share/themes

echo "Installing command line apps... done!"

#
# cask gui apps
#
echo "Installing GUI apps..."
#brew install macvim
brew install alfred
brew install gimp
brew install xquartz
brew install macfuse

echo "Installing GUI apps... done!"

#brew linkapps

echo "Cleaning up..."
brew cleanup
#brew cask cleanup
echo "Cleaning up... done!"

