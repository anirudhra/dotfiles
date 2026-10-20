# Single Board Computer (SBC) Toolkit: IFC6410

Configuration files, bootstrap tools, and maintenance scripts for the **Inforce IFC6410** Single Board Computer (Qualcomm Snapdragon APQ8064 / Krait quad-core ARMv7).

Originally migrated from the [`ifc6410/linux`](https://github.com/anirudhra/ifc6410/tree/main/linux) repository.

---

## Directory Overview

* **[`common/`](common/)**: Hardware-specific configurations shared across all Linux distributions on IFC6410:
  * `etc/modprobe.d/blacklist.conf`: Blacklists the `msm` GPU driver (prevents kernel panics on boot with modern Linux kernels).
  * `etc/udev/rules.d/60-disable-ncq.rules`: Disables SATA NCQ (hardware NCQ on IFC6410 controller causes severe disk timeouts and data corruption).
  * `etc/modules`: Essential hardware modules to auto-load.
  * `etc/resolv.conf`: High-performance public DNS resolvers (Cloudflare `1.1.1.1` and Quad9 `9.9.9.9`).
  * `ifc6410.CoolTermSettings`: Serial console connection settings for CoolTerm (115200 8N1).
* **[`debian/`](debian/)**: Debian-specific APT configurations (`apt/sources.list`, preferences) and manual `debootstrap` notes.
* **[`arch/`](arch/)**: Arch Linux ARM bootstrap instructions and pre-built package dependencies:
  * `ifc6410-arch-pkg-files/gnutls/`: `PKGBUILD` definition for building GnuTLS 3.7.8 on armhf (`armv7h`) to resolve 64-bit time_t issues during Arch Linux ARM bootstrapping.
* **[`scripts/`](scripts/)**: Automation scripts for provisioning and maintenance:
  * [`bootstrap_rootfs.sh`](scripts/bootstrap_rootfs.sh): Bootstraps and stages a fresh Linux rootfs to a target disk, automatically applying IFC6410 hardware rules and distro configs.
  * [`installkmod.sh`](scripts/installkmod.sh): Installs kernel modules from Yocto/Poky build artifacts into `/lib/modules`.
  * [`dockerinstall.sh`](scripts/dockerinstall.sh): Installs Docker CE on Debian ARM with `iptables-legacy` compatibility.

---

## Usage Guide

### 1. Bootstrapping a Root Filesystem
Use [`bootstrap_rootfs.sh`](scripts/bootstrap_rootfs.sh) to clone and configure a rootfs onto a newly formatted drive mounted at `/mnt/rootfs`:

```bash
# Sync from localhost into /mnt/rootfs and apply hardware/Debian configs
sudo ./scripts/bootstrap_rootfs.sh localhost /mnt/rootfs

# Sync from a remote build/staging host over SSH
sudo ./scripts/bootstrap_rootfs.sh ifc6410-builder /mnt/rootfs
```

The script:
1. Performs an incremental rsync with system directory exclusions.
2. Mounts `/proc`, `/sys`, `/dev`, and `/run` recursively with `rslave` propagation.
3. Automatically copies IFC6410 hardware workarounds (`common/etc`) and distro configs (`debian/etc`) into the target `/etc`.

### 2. Installing Kernel Modules
Use [`installkmod.sh`](scripts/installkmod.sh) to unpack and register kernel modules built from Yocto/Poky:

```bash
# Preview what would be installed (dry run)
sudo ./scripts/installkmod.sh --dry-run

# Install modules directly (module backup disabled by default)
sudo ./scripts/installkmod.sh

# Install specific kernel version with module backup enabled
sudo ./scripts/installkmod.sh -k 6.6.0 --backup
```

### 3. Installing Docker on Debian
Docker requires `iptables-legacy` on Debian systems running on IFC6410:

```bash
sudo ./scripts/dockerinstall.sh
```

---

## System Upgrades & Dotfiles Management

* **System & Docker Updates**: Upgrades for IFC6410 are centrally handled by [`common/ansible/clientscripts/upgrade.sh`](../common/ansible/clientscripts/upgrade.sh) (which targets `/opt/dockerapps` on host `ifc6410`) and orchestrated via Ansible in [`common/ansible/playbooks/upgradesbc.yaml`](../common/ansible/playbooks/upgradesbc.yaml).
* **Dotfiles Synchronization**: Managed via GNU Stow (`stow --target="$HOME" .`) or [`common/scripts/dotsync.sh`](../common/scripts/dotsync.sh).
