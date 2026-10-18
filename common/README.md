# Common Scripts & Configurations

This directory contains cross-platform scripts, system utilities, and Ansible infrastructure automation common across local machines, Proxmox VE (PVE) hypervisors, LXC containers, SBCs, and routers.

---

## Directory Structure

- **`common/scripts/`**: System utilities and tools:
  - [`sshkeygen.sh`](file:///home/anirudh/dotfiles/common/scripts/sshkeygen.sh): Generates modern SSH key pairs (Ed25519 / ECDSA / RSA), deploys public keys to local and remote nodes, purges legacy keys, and manages `ssh-agent`.
  - [`dotsync.sh`](file:///home/anirudh/dotfiles/common/scripts/dotsync.sh): Standalone symlink synchronizer for `~/dotfiles/home` with dead-link cleanup and data safety backups.
  - [`routerfastfetch`](file:///home/anirudh/dotfiles/common/scripts/routerfastfetch): Lightweight, high-performance system summary tool designed specifically for BusyBox / ash on embedded routers (DD-WRT / OpenWrt).
  - [`btrfsrsyncbackup.sh`](file:///home/anirudh/dotfiles/common/scripts/btrfsrsyncbackup.sh): Snapshot, incremental send/receive, and rsync backup tool with retention management for Btrfs volumes.
  - [`nerdfonts_install.sh`](file:///home/anirudh/dotfiles/common/scripts/nerdfonts_install.sh): Interactive installer for Nerd Fonts with automatic cleanup and XDG directory compliance.
  - [`sync_itunes_playlists.py`](file:///home/anirudh/dotfiles/common/scripts/sync_itunes_playlists.py): iTunes smart playlist parser and UTF-8 relative M3U8 generator with atomic rollback protection.

- **`common/ansible/`**: Infrastructure automation:
  - `inventory.yaml`: Central inventory of local/remote PVE hosts, LXCs, VMs, SBCs, and routers with consolidated defaults.
  - `scripts/ans.sh`: Convenient runner for Ansible playbooks with path resolution and argument forwarding.
  - `scripts/pingpass.sh`: Connectivity check with password prompt.
  - `playbooks/`: Ansible playbooks for system updates, dotfiles synchronization, native package management, and service fixes.
  - `clientscripts/`: Host-side scripts executed by Ansible (`upgrade.sh`, `updatedotfiles.sh`).

---

## SSH Key Management

To generate or deploy SSH keys across infrastructure:

```bash
# Generate a new Ed25519 key (recommended) and deploy to local nodes:
./common/scripts/sshkeygen.sh -gen

# Deploy existing key to remote nodes:
./common/scripts/sshkeygen.sh --remote

# Force copy and purge stale ssh-rsa keys:
./common/scripts/sshkeygen.sh -f --purge-old
```

To manually register keys with `ssh-agent`:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

---

## Ansible Automation

Run playbooks conveniently from anywhere using `ans.sh`:

```bash
# Run against default group
./common/ansible/scripts/ans.sh upgrade

# Target a specific host or group using -l / --limit
./common/ansible/scripts/ans.sh upgrade -l pve
./common/ansible/scripts/ans.sh upgrade -l remotelxc

# Sync dotfiles across all nodes
./common/ansible/scripts/ans.sh dotfiles

# Ping active hosts
./common/ansible/scripts/ans.sh ping
```
