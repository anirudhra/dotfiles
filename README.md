# dotfiles

Repository for cross-platform dotfiles, system configurations, and automation scripts (macOS, Linux client, Proxmox VE server & guests, OpenMediaVault, SBC, and custom router firmwares).

---

## Directory Overview

* **[`home/`](home/)**: Universal dotfiles for both Linux and macOS managed via GNU Stow or [`dotsync.sh`](common/scripts/dotsync.sh) (`.zshrc`, `.bashrc`, `.profile`, `.aliases`, `.vimrc`, `.config/`).
* **[`linux/`](linux/)**: Provisioning, post-install tweaks, and theme configurations for Linux desktop clients (Debian, Fedora, Arch).
* **[`macos/`](macos/README.md)**: Bootstrapping scripts, Homebrew manifests, Karabiner keybindings, iTerm2 themes, and GPU telemetry for macOS.
* **[`pve/`](pve/README.md)**: Automated maintenance, container/VM backups, and configuration templates for Proxmox VE hosts and LXC guests.
* **[`omv/`](omv/README.md)**: Configuration backup, selective state restore, and recycle bin sanitation for OpenMediaVault.
* **[`sbc/`](sbc/README.md)**: Bootstrapping tools, kernel module installer, and hardware configurations for the Inforce IFC6410 Single Board Computer.
* **[`router/`](router/README.md)**: Configurations, Entware installers, and automation runbooks for Asuswrt-Merlin, OpenWrt, and DD-WRT.
* **[`common/`](common/README.md)**: Cross-system Ansible playbooks, inventory, and shared utility scripts (`btrfsrsyncbackup.sh`, `sshkeygen.sh`, `nerdfonts_install.sh`).

---

## Quickstart

### 1. Client Linux (Debian / Fedora / Arch)

```bash
cd "$HOME"
git clone https://github.com/anirudhra/dotfiles
cd "$HOME/dotfiles/linux"
./linux_install.sh
./linux_post_install.sh
```

> [!NOTE]
> In order to apply undervolt settings via `throttled`, secure boot must be disabled in UEFI.

---

### 2. macOS (Apple Silicon & Intel)

```bash
cd "$HOME"
git clone https://github.com/anirudhra/dotfiles
cd "$HOME/dotfiles/macos"
./macos_install.sh
./macos_post_install.sh
```

---

### 3. PVE Server and Guests

```bash
cd "$HOME"
git clone https://github.com/anirudhra/dotfiles
cd "$HOME/dotfiles/pve/setup"
./install.sh
```

---

### 4. Remote Tmux Configuration

Install the Catppuccin theme:
```bash
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
```

Add the following to `~/.config/tmux/tmux.conf` to enable mouse scrolling and the Catppuccin theme:
```tmux
set -g mouse on
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
set -g default-terminal "xterm-256color"
set-option -ga terminal-overrides ",xterm-256color:Tc"
```
Re-login or run `tmux source ~/.config/tmux/tmux.conf` to reload settings.
