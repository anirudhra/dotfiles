# Linux Client Workstation Setup & Dotfiles

Automated provisioning, desktop optimization, theme integration, and maintenance scripts for Linux desktop and laptop clients (Fedora, Debian, and Arch).

---

## Directory Overview

```text
client/linux/
├── linux_install.sh           # Initial package installation (DNF/APT/Pacman, Flatpak, Nerd Fonts)
├── linux_post_install.sh      # Post-install: Dotfiles stow, zsh plugins, GNOME extension restore
├── linux_nfs_backup_restore.sh# NFS-based system & home directory backup/restore
├── exclude_linux_nfs_backup.txt
├── gtk/
│   ├── gtkthemes.sh           # GTK, shell, and icon theme downloader & installer
│   ├── flatpak/update.sh      # Flatpak GTK theme filesystem overrides
│   └── themes/                # Theme submodules & update hooks
└── config/                    # Hardware tweaks & desktop configurations
    ├── etc/                   # System configs (throttled.conf, tlp.conf, udev rules)
    └── extensions/            # GNOME shell extension dconf dumps
```

---

## Getting Started

### 1. Initial Installation (`linux_install.sh`)

Run as a standard non-root user (prompts for `sudo` when required):

```bash
cd "$HOME/dotfiles/client/linux"
./linux_install.sh
```

**What it does:**
* Detects your Linux distribution (`fedora`, `debian`, `arch`).
* Installs core command line utilities (`zoxide`, `fastfetch`, `bat`, `btop`, `eza`, `neovim`, `stow`, etc.).
* Configures Flatpak and desktop applications (VS Code, Microsoft Edge, VLC, etc.).
* Installs curated Nerd Fonts.
* Configures hardware power optimizations:
  * **ThinkPad / Intel Undervolt**: Provisions `throttled` (requires Secure Boot disabled in UEFI).
  * **Power Management**: Deploys `tlp` configuration for battery optimization.

### 2. Post-Installation (`linux_post_install.sh`)

```bash
./linux_post_install.sh
```

**What it does:**
* Backs up existing configuration files that would conflict with GNU Stow.
* Deploys universal dotfiles to `$HOME` using GNU Stow.
* Installs Oh-My-Zsh plugins and Powerlevel10k theme.
* Restores GNOME shell extension configurations via `dconf`.

---

## Desktop Customization

### GTK & Shell Themes (`gtk/gtkthemes.sh`)

Installs or updates curated desktop themes (Orchis, Fluent, Graphite, Tela, elementary icons):

```bash
# Update default theme selection
./gtk/gtkthemes.sh

# Or use the convenience alias
gtkupdate
```

---

## Maintenance & Backups

### NFS Backup & Disaster Recovery (`linux_nfs_backup_restore.sh`)

Backs up user data, desktop settings, and `/etc` configs to an NFS share:

```bash
# Preview backup (dry-run)
./linux_nfs_backup_restore.sh -b -d

# Perform backup
./linux_nfs_backup_restore.sh -b

# Restore from NFS backup
./linux_nfs_backup_restore.sh -r
```
