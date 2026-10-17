# dotfiles
Repo for dotfiles and other configs and installation scripts (macOS and Linux - client, pve server and pve guests)

* home directory contains universal dotfiles for both Linux and macOS that stow installer will use
* linux and macos directories contain other specific OS files and scripts
* pve directory contains installation and maintenance scripts for PVE server and guest OS, migrated from: https://github.com/anirudhra/pve_server
* sbc directory scripts for single board computer, installation for debian and arch distros
* common directory contains ansible and other general scripts

## How to
Clone this repo and:

* For Linux (Debian/Fedora and derivatives)
** change directory to .../dotfiles/linux and run linux_install.sh and linux_post_install.sh in order
* For macOS
** change directory to .../dotfiles/mac and run macos_install.sh and macos_post_install.sh in order

## Client Linux

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

A note about "throttled": In order to apply undervolt settings, secure boot must be disabled.

## macOS

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

## PVE Server and Guests

```
cd $HOME
git clone https://github.com/anirudhra/dotfiles
cd $HOME/dotfiles/pve/setup
./install.sh
```

## tmux config (on remote machines)

Install Catppuccin theme:
```
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
```

Add the following to ~/.config/tmux/tmux.conf to enable mouse scrolling/up and invoke theme
```
set -g mouse on
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
set -g default-terminal "xterm-256color"
set-option -ga terminal-overrides ",xterm-256color:Tc"
```

Relogin to enable/reload settings.
