# dotfiles
Repo for dotfiles and other configs and installation scripts (macOS and Linux)

* home directory contains universal dotfiles for both Linux and macOS that stow installer will use
* linux and macos directories contain other specific OS files and scripts


## How to
Clone this repo and change directory to .../dotfiles/linux and run linux_install.sh and linux_post_install.sh for Linux (Fedora/Debian/Ubuntu) or .../dotfiles/mac/macos_install.sh and macos_post_install.sh for macOS in that order

### Linux

Installation script:

```
cd $HOME
git clone https://github.com/anirudhra/dotfiles
cd $HOME/dotfiles/linux
./linux_install.sh
```

Post installation script:

```
cd $HOME/dotfiles/linux
./linux_post_install.sh
```

### macOS

Installation script:

```
cd $HOME
git clone https://github.com/anirudhra/dotfiles
cd $HOME/dotfiles/macos
./macos_install.sh
```

Post installation script:

```
cd $HOME/dotfiles/macos
./macos_post_install.sh
```

### tmux config (on remote machines)

Install Catppuccin theme:
```
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
```

Add the following to ~/.config/tmux/tmux.conf to enable mouse scrolling/up and invoke theme
```
set -g mouse on
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
```

Relogin to enable/reload settings.
