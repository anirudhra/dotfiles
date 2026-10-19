# Router Configurations & Automation

Configuration files, deployment scripts, and reference documentation for custom router firmwares: **Asuswrt-Merlin**, **OpenWrt** (modern `apk`-based), and **DD-WRT**.

---

## Directory Structure

```
router/
├── merlin/               # Asuswrt-Merlin configurations and aliases
│   └── profile.add       # Shell aliases and environment sourced from /jffs/configs/profile.add
├── openwrt/              # OpenWrt (24.x+ / apk-based) scripts and docs
│   ├── convertap.sh      # Script to convert OpenWrt router into a dumb Access Point
│   ├── restore-packages.sh # Restores packages via apk from installed_packages.txt
│   ├── usbmount.sh       # Installs block-mount and configures persistent USB /opt mount
│   ├── dot_profile       # Shell environment and aliases for OpenWrt
│   └── recovery.md       # Recovery and TFTP flash guide (e.g. Linksys LN1301 / MX4300)
└── ddwrt/                # DD-WRT automation scripts, Entware, and command docs
    ├── entware_install.sh # Architecture-aware Entware installer (MIPS, ARMv7, AArch64)
    ├── entware_packages.txt # Curated list of Entware packages
    ├── ddwrt-adblock-s.sh # SmartDNS adblock script with blacklist fetching and deduplication
    └── commands/         # Reference documentation for DD-WRT Administration > Commands
        ├── adguard.md        # AdGuard Home setup on USB /opt
        ├── ddns.md           # Dynamic DNS update script
        ├── entware.md        # Entware drive preparation and mount instructions
        ├── firewallcmd.md    # Custom iptables firewall rules
        ├── logging.md        # Persistent syslogd logging to USB and rotation
        ├── smartdnsadblock.md # SmartDNS adblocking configuration
        ├── smartdnsmasq.md   # Dnsmasq + SmartDNS forwarding setup
        ├── startupcmd.md     # WebUI Startup commands
        ├── usbcroncmds.md    # USB-mounted run commands and crontab recipes
        └── wireguard.md      # WireGuard VPN setup on DD-WRT
```

---

## Firmware Guides

### 1. Asuswrt-Merlin (`router/merlin/`)

Asuswrt-Merlin stores user configurations and persistent scripts on the `/jffs` flash partition.

* **[`profile.add`](merlin/profile.add)**:
  * Copy or link to `/jffs/configs/profile.add` to load custom aliases and utilities on every SSH login.
  * Includes shortcuts for Skynet (`firewall`), `backupmon`, JFFS backups (`jffsbackup`), network socket monitoring (`ports`), and POSIX path inspection (`path`).
  * Creates `/root/.exrc` to prevent BusyBox vi / defaults.vim warnings.

```bash
# Backup JFFS partition to mounted USB drive
jffsbackup
```

---

### 2. OpenWrt (`router/openwrt/`)

Optimized for modern OpenWrt releases (24.x+ / snapshots) using the `apk` package manager.

* **Convert Router to Dumb AP ([`convertap.sh`](openwrt/convertap.sh))**:
  Converts an OpenWrt router into an access point on a target subnet:
  ```bash
  # Convert to AP on 10.100.10.0/24 (AP IP: 10.100.10.2, Gateway: 10.100.10.1)
  sh /root/convertap.sh 10.100.10

  # Or specify custom subnet prefix
  sh /root/convertap.sh 192.168.1
  ```
  The script disables local DHCP/RA (`odhcpd`), deletes standalone WAN interfaces, dynamically bridges the physical WAN port into the LAN bridge (`br-lan`), assigns static IP/DNS/gateway, and disables local resolver and firewall daemons (`dnsmasq`, `odhcpd`, `firewall`).

* **Package Restoration ([`restore-packages.sh`](openwrt/restore-packages.sh))**:
  Batch installs packages from `installed_packages.txt` via `apk add`.

* **USB `/opt` Automount ([`usbmount.sh`](openwrt/usbmount.sh))**:
  Installs `block-mount` and `e2fsprogs`, and registers the USB drive with filesystem label `opt` in `/etc/config/fstab` mounted to `/opt`.

* **Hardware Recovery ([`recovery.md`](openwrt/recovery.md))**:
  Contains bootloader recovery, TFTP flashing, and serial pinout documentation for Qualcomm IPQ807x devices (Linksys LN1301 / MX4300).

---

### 3. DD-WRT (`router/ddwrt/`)

Scripts and operational runbooks for DD-WRT builds with Entware:

* **Entware Multi-Architecture Installer ([`entware_install.sh`](ddwrt/entware_install.sh))**:
  Detects the router's CPU architecture (`mips`, `mipsel`, `armv5`, `armv7`, `aarch64`), downloads the appropriate Entware installer, initializes `/opt`, updates repositories, and offers an interactive menu to install packages from `entware_packages.txt`.
  ```bash
  # Run from router terminal
  sh entware_install.sh
  ```

* **SmartDNS Adblocking ([`ddwrt-adblock-s.sh`](ddwrt/ddwrt-adblock-s.sh))**:
  Downloads ad-blocking blacklists, cleans and deduplicates domains, applies custom whitelists, and compiles a SmartDNS configuration file into `/tmp/smartdns.conf`.

* **WebUI Command Recipes ([`commands/`](ddwrt/commands/))**:
  DD-WRT NVRAM scripts configured via **Administration > Commands**:
  * `startupcmd.md`: Startup hooks to mount drives and start Entware (`rc.unslung`).
  * `logging.md` & `usbcroncmds.md`: Redirects `syslogd` to USB storage (`/opt/logs/system`) with symlink to `/jffs/messages`.
    > [!IMPORTANT]
    > When scheduling periodic log rotation in cron, truncate the file in-place (`: > /opt/logs/system`) rather than `rm`, so active file descriptors and symlinks remain intact without restarting `syslogd`.
  * `firewallcmd.md`: Custom iptables filtering and NAT rules.
  * `wireguard.md`: WireGuard tunnel startup scripts.
