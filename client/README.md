# Client Workstation Configurations & Provisioning

Centralized setup scripts, application manifests, desktop customizations, and platform-specific utilities for developer workstations and laptops (Linux and macOS).

---

## Directory Overview

* **[`linux/`](linux/README.md)**: Desktop provisioning, hardware optimizations (undervolt, TLP), GTK/shell themes, GNOME extension backups, and NFS sync for Fedora, Debian, and Arch workstations.
* **[`macos/`](macos/README.md)**: Apple Silicon & Intel bootstrapping, Homebrew manifests, Karabiner keyboard remaps, iTerm2 color schemes, and GPU telemetry.

---

## Quick Navigation

| Platform | Quickstart Command | Key Guide |
| :--- | :--- | :--- |
| **Linux Client** (Fedora / Debian / Arch) | `cd "$HOME/dotfiles/client/linux" && ./linux_install.sh` | **[Linux Workstation Guide](linux/README.md)** |
| **macOS Client** (Apple Silicon / Intel) | `cd "$HOME/dotfiles/client/macos" && ./macos_install.sh` | **[macOS Workstation Guide](macos/README.md)** |

---

## Shared Dotfiles Architecture

Both Linux and macOS clients utilize universal shell and editor configurations managed from the [`home/`](../home) directory via GNU Stow:
* **Shells**: Zsh (`.zshrc`) and Bash (`.bashrc`) with unified helpers, aliases, and functions.
* **Navigation Aliases**:
  * `goclient`: Jump to `~/dotfiles/client`
  * `golinux`: Jump to `~/dotfiles/client/linux`
  * `gomacos`: Jump to `~/dotfiles/client/macos`
  * `godot`: Jump to root `~/dotfiles`
