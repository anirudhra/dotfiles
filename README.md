# dotfiles

Repository for cross-platform dotfiles, system configurations, and automation scripts (macOS, Linux client, Proxmox VE server & guests, OpenMediaVault, SBC, and custom router firmwares).

---

## Directory Overview

* **[`home/`](home/)**: Universal dotfiles for both Linux and macOS managed via GNU Stow or [`dotsync.sh`](common/scripts/dotsync.sh) (`.zshrc`, `.bashrc`, `.profile`, `.aliases`, `.vimrc`, `.config/`).
* **[`client/`](client/README.md)**: Workstation setup, package provisioning, desktop themes, and utilities:
  * **[`client/linux/`](client/linux/README.md)**: Linux desktop clients (Debian, Fedora, Arch) and GNOME customizations.
  * **[`client/macos/`](client/macos/README.md)**: macOS workstations (Apple Silicon & Intel), Homebrew, Karabiner, and GPU telemetry.
* **[`server/`](server/README.md)**: Maintenance, disaster recovery, and configuration templates for homelab servers:
  * **[`server/pve/`](server/pve/README.md)**: Proxmox VE host maintenance, container/VM backups, and LXC templates.
  * **[`server/omv/`](server/omv/README.md)**: OpenMediaVault configuration archiver, selective state restore, and recycle bin sanitation.
* **[`sbc/`](sbc/README.md)**: Bootstrapping tools, kernel module installer, and hardware configurations for the Inforce IFC6410 Single Board Computer.
* **[`router/`](router/README.md)**: Configurations, Entware installers, and automation runbooks for Asuswrt-Merlin, OpenWrt, and DD-WRT.
* **[`common/`](common/README.md)**: Cross-system Ansible playbooks, inventory, and shared utility scripts (`btrfsrsyncbackup.sh`, `sshkeygen.sh`, `nerdfonts_install.sh`).

---

## Quickstart

### 1. Client Linux (Debian / Fedora / Arch)

```bash
cd "$HOME"
git clone https://github.com/anirudhra/dotfiles
cd "$HOME/dotfiles/client/linux"
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
cd "$HOME/dotfiles/client/macos"
./macos_install.sh
./macos_post_install.sh
```

---

### 3. PVE Server and Guests

```bash
cd "$HOME"
git clone https://github.com/anirudhra/dotfiles
cd "$HOME/dotfiles/server/pve/setup"
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
