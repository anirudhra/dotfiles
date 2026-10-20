# OpenMediaVault (OMV) Maintenance & Disaster Recovery

Production-grade utilities for automated configuration backups, selective disaster recovery, and Samba storage maintenance on OpenMediaVault NAS servers.

---

## Directory Overview

```
server/omv/
├── backup-omv-config.sh     # Daily/weekly configuration archiver with automated retention
├── restore-omv-config.sh    # Disaster recovery tool with safety rollback and selective restoration
├── clean-recycle-bins.sh    # Samba .recycle pruner for files older than 30 days
└── README.md                # Documentation & cron scheduling guide
```

---

## 1. Configuration Backup (`backup-omv-config.sh`)

Archives the core OpenMediaVault database, daemon configurations, and system network settings into a compressed tarball (`.tar.gz`).

### Usage

```bash
# Run backup with default settings (root required)
sudo ./backup-omv-config.sh

# Keep 10 backup archives instead of the default 5
sudo ./backup-omv-config.sh --keep 10

# Store backups on an alternative path
sudo ./backup-omv-config.sh --dest /mnt/backup/omv
```

### What is Backed Up

* `/etc/openmediavault` — Core database (`config.xml`), environment settings, and sample templates.
* `/var/lib/openmediavault` — Internal state and database modules.
* `/etc/samba` — Samba shares, permissions, and daemon configurations (`smb.conf`).
* `/etc/fstab` — Filesystem mount declarations.
* `/etc/network` & `/etc/netplan` — Interface and routing configurations.
* `/etc/default/openmediavault` & `/etc/monit` — Daemon defaults and service monitors.
* `/srv/salt` — SaltStack states (for reference).

### Safety Features

* **Root Requirement**: Strictly enforces `EUID == 0` to prevent partial/silent omissions of restricted files like `/etc/openmediavault/config.xml` (mode `0600`).
* **Mount Verification**: Validates that `/mnt/storage` exists before creating directories to prevent accidentally filling the OS root partition when storage drives are unmounted or offline.
* **Automated Retention**: Automatically sorts and prunes archives, retaining only the `MAX_BACKUPS` most recent archives (default: 5).

---

## 2. Disaster Recovery & Restoration (`restore-omv-config.sh`)

Restores OpenMediaVault settings from a backup tarball, creates an automatic rollback safety snapshot, sets proper permissions, and redeploys system states via `omv-salt`.

### Usage

```bash
# 1. List available backup archives on disk
sudo ./restore-omv-config.sh --list

# 2. Restore from the most recent backup
sudo ./restore-omv-config.sh --latest

# 3. Restore from a specific backup file
sudo ./restore-omv-config.sh /mnt/storage/data/backup/omv/omv_config_backup_20261018.tar.gz
```

### Selective Restoration Options

By default, the script restores core OMV settings and Samba shares without touching low-level network or disk mount configurations (preventing administrative lockouts if hardware has changed).

| Option | Description |
| :--- | :--- |
| *(Default)* | Restores `/etc/openmediavault`, `/var/lib/openmediavault`, and `/etc/samba`. |
| `--restore-network` | Restores `/etc/network` and `/etc/netplan` interface configurations. |
| `--restore-fstab` | Restores `/etc/fstab` drive mount definitions. |
| `--restore-salt` | Restores `/srv/salt` custom Salt formulas. *(See note below)* |
| `--restore-all` | Restores all configuration files included in the archive. |
| `-y, --yes` | Skips the interactive `RESTORE` confirmation prompt (for automation). |

> [!NOTE]
> **Why `/srv/salt` is not restored by default:**  
> In OpenMediaVault, `/srv/salt/omv/` contains orchestration code supplied directly by Debian package updates (`openmediavault`). The user's actual configuration lives in `/etc/openmediavault/config.xml`. Restoring an older `/srv/salt` can overwrite newer package-managed state files and cause `omv-salt` deployment syntax failures.

### Safety Rollback

Before any file is overwritten, the script creates a full snapshot of the existing live configuration in:
`/root/omv_rollback_<TIMESTAMP>/`

---

## 3. Samba Recycle Bin Cleanup (`clean-recycle-bins.sh`)

Samba shares configured with the `vfs_recycle` module accumulate deleted files in hidden `.recycle` directories. This script prunes files older than 30 days and removes leftover empty folders.

### Usage

```bash
# Preview files that would be pruned (safe dry-run)
sudo ./clean-recycle-bins.sh --dry-run

# Execute live cleanup
sudo ./clean-recycle-bins.sh

# Target an alternative storage mount
sudo ./clean-recycle-bins.sh --storage /srv/dev-disk-by-uuid-...
```

### Performance & Safety Optimizations

* **Single-Pass `-prune` Traversal**: The outer `find` command stops recursing once `.recycle` is identified, eliminating duplicate traversals across multi-terabyte arrays and reducing disk I/O by 50%.
* **Combined Deletion**: Cleans up old files and immediately prunes empty directories in a single pass.
* **Execution Summary**: Reports the number of recycle bins processed and total files removed.

---

## 4. Automated Cron Scheduling

To automate maintenance on OpenMediaVault, add the following cron configuration to `/etc/cron.d/omv-maintenance` on the OMV server:

```cron
# /etc/cron.d/omv-maintenance
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Daily configuration backup at 3:00 AM (retains last 5 backups)
0 3 * * * root /root/dotfiles/server/omv/backup-omv-config.sh >/var/log/omv_backup.log 2>&1

# Monthly Samba recycle bin cleanup (files >30 days old) on the 1st of every month at 4:00 AM
0 4 1 * * root /root/dotfiles/server/omv/clean-recycle-bins.sh >/var/log/omv_recycle_clean.log 2>&1
```
