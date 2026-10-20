# Server Infrastructure & Maintenance

Centralized configurations, disaster recovery routines, and automation scripts for homelab server environments (Proxmox VE, OpenMediaVault, and scalable server platforms).

---

## Directory Overview

* **[`pve/`](pve/README.md)**: Proxmox VE host automation, container/VM maintenance, hardware passthrough (Intel iGPU / Coral TPU), ZFS backup scripts, and LXC provisioning templates.
* **[`omv/`](omv/README.md)**: OpenMediaVault (OMV) automated configuration backup, disaster recovery tool with safety rollback, and Samba recycle bin sanitation.

---

## Architecture & Server Roles

| Server Platform | Role / Use Case | Key Automation Tools |
| :--- | :--- | :--- |
| **Proxmox VE (`server/pve/`)** | Virtualization Hypervisor (KVM & LXC) | Host kernel cleaner, automated LXC/guest update & cache clean, GUI sensor monitoring mod, ZFS & config backups. |
| **OpenMediaVault (`server/omv/`)** | Network Attached Storage (Samba / NFS) | Daily configuration archiver (`backup-omv-config.sh`), selective state restore (`restore-omv-config.sh`), automated Samba recycle pruner (`clean-recycle-bins.sh`). |

---

## Quick Navigation

* To configure or maintain a Proxmox VE host or LXC guest, see **[Proxmox VE Guide](pve/README.md)**.
* To manage OpenMediaVault backups, rollback snapshots, or storage cleanup, see **[OpenMediaVault Guide](omv/README.md)**.
