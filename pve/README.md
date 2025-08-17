# HP Elitedesk 800 G4/G5 Desktop Mini as Server

## BIOS Updates

1. Extract contents from sp<xxx>.exe file by running it on a Windows machine or by other means
2. Create <USB>:\HP\DEVFW directory on a fat32 formatted USB drive
3. Rename "Qxx_< ver >.bin" as "firmware.bin" in this directory
4. Reboot to BIOS and choose to upgrade BIOS from local storage/media

## Proxmox, fwupdate and udisks2

fwupdate requires udisks2, but proxmox has compatiblity issues with udisks2 and it is not recommended to install udisks2 as it will likely interfere with proxmox kernel updates and /boot/efi (ESP) locations. No known good solution as of now.

## Custom scripts for Proxmox host and LXC setup and maintenance

Installation script:

### Proxmox Host:

1) HP UEFI 2.27 update introduces an issue with displayport pin mapping by not activating pin 6 for audio in Linux and needs explicit patching until kernel includes it by default (not as of 6.8.12): /etc/modprobe.d/hda-jack-retask.conf, /usr/lib/firmware/hda-jack-retask.fw
2) Sets DP/HDMI as default audio: /etc/asound.conf
3) Adds useful set of aliases /home/(user)/.aliases
4) Enables NFS exports: /etc/exports
5) Enables Samba exports to /etc/samba/smb.conf
6) Provides X11 Intel iGPU config files if GUI is needed/installed
7) Adds additional /etc/modules for acpi health monitoring and Intel VT-d virtualization
8) Includes GPU, Keyboard, Audio passthrough in LXC conf for reference: /etc/pve/lxc/lxc-id.conf
9) Includes scritps for PVE host maintenance, backup-restore and other tweaks: /pve_maintenance (needs to be manually installed/pulled from github)
10) Includes Coral TPU drivers, runtimes etc. for newer versions of Linux kernels, Python as standard Google repos no longer support any of those are stuck pre-Linux6.2 and Python 3.9

### LXC:

1) Sets DP/HDMI as default audio: /etc/asound.conf
2) Adds useful set of aliases /home/(user)/.aliases
3) Mounts NFS exports: /etc/auto.master, /etc/auto.mount
4) Provides X11 Intel iGPU config files if GUI is needed/installed

*Note*: In LXC, use PID and GID 65534 in docker compose files for read/write permissions to shared directories so that it maps to nobody:nogroup on PVE.

### Unattended Upgrade for Debian-based distros

Refer to: https://wiki.debian.org/UnattendedUpgrades

## Useful management tools

Proxmenux is a useful suite of scripts in TUI for managing various aspects of PVE server: https://github.com/MacRimi/ProxMenux

## LXC Environment automation

Use this command to run off github:
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/anirudhra/dotfiles/refs/heads/main/pve/setup/install.sh)"
```

Use this command to download locally:
```
wget https://raw.githubusercontent.com/anirudhra/dotfiles/refs/heads/main/pve/setup/install.sh
```
<br><br>

## LXC/VM Dockerup "all update" automation

Recursively updates all docker images and prunes if the directory does not have "disabled" in the name anywhere:

```
godocker
cd `hostname`
find . -maxdepth 1 -type d \( ! -name . \) -not -path '*disabled*' -exec bash -c "cd '{}' && pwd && docker compose down && docker compose pull && docker image prune -f && docker compose up -d --remove-orphans" \;
docker prune -a -f
```

## LXC autologin in PVE Console
Type the following in LXC console to enable auto login:

```
GETTY_OVERRIDE="/etc/systemd/system/container-getty@1.service.d/override.conf"
mkdir -p $(dirname $GETTY_OVERRIDE)
cat <<EOF >$GETTY_OVERRIDE
  [Service]
  ExecStart=
  ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
systemctl daemon-reload
systemctl restart $(basename $(dirname $GETTY_OVERRIDE) | sed 's/\.d//')
```
<br><br>

## PCIe Power Management on PVE host: ASPM

Check which devices support ASPM but not enabled
```
lspci -vv | awk '/ASPM/{print $0}' RS= | grep --color -P '(^[a-z0-9:.]+|ASPM )'
```

If necessary append the following to grub CMDLINE: 
```
pcie_aspm=force
```
<br><br>

## Power/Temperature monitoring on PVE host

Install and add powertune to autotune on startup through "crontab -e":

```
@reboot sleep 60 && /usr/sbin/powertop --auto-tune
```

Also add the following modules to /etc/modules:
```
coretemp
drivetemp
```

Run the following script to add detected CPU/HDD/NVMe sensors to PVE web page (may need after proxmox updates):
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/anirudhra/dotfiles/refs/heads/main/pve/maintenance/pve-mod-gui-sensors.sh)"
```
These scripts come from Meliox's excellent PVE mods repo: https://github.com/Meliox/PVE-mods
<br><br>

## GPU passthrough to LXC for HW acceleration (Jellyfin etc.)

Add following line on PVE host at the end of /etc/pve/lxc/< lxcid >.conf. This will create a new host:lxc shared group to which devices can be added to for read-write permission from within LXC. This is because sometimes the default groups (render and video) have wrong GID inside LXC and result in permission issues. Replace /dev/dri/card1 with card0 as appropriate (must match what's in /etc/pve/lxc/<lxc-id>.conf file on PVE host:
```
lxc.hook.pre-start: sh -c "chown 100000:111000 /dev/dri/renderD128 && chown 100000:111000 /dev/dri/card1"
```

Run following commands on LXC (assumes username is jellyfin and the shared pve-lxc group name is lxc_gpu_shares that maps to the gid above):
```
groupadd -g 111000 lxc_gpu_shares
gpasswd -a jellyfin lxc_gpu_shares
usermod -aG render jellyfin
usermod -aG video jellyfin
systemctl restart jellyfin
sudo -u jellyfin ls -l /dev/dri
```

References (more explanation): <br>
* https://github.com/jellyfin/jellyfin/issues/9390 <br>
* https://github.com/TheHellSite/proxmox_collection/tree/main/lxc/device_passthrough
<br><br>

## Enabling IOMMU/VT-d Virtualization on PVE host

Referenced from https://pve.proxmox.com/wiki/PCI(e)_Passthrough:

1) Add the following to /etc/default/grub "GRUB_CMDLINE_LINUX_DEFAULT" to modify kernel command line (remove i915.enable_gvt=1 if there are stability issues):
```
i915.enable_gvt=1 i915.enable_guc=2 intel_iommu=on iommu=pt
```
2) Run to pick changes:
```
update-grub
```
4) Add following modules to /etc/modules:
```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd #not needed if on kernel 6.2 or newer
```
6) Run to update initram:
```
update-initramfs -u -k all
```
8) Reboot the machine
9) Run following commands to veryify (should see lines along Directed I/O for IOMMMU):
```
dmesg | grep -i -e DMAR -e IOMMU
lsmod | grep -i vfio
cat /proc/cmdline
```

### Full Kernel Command line on PVE host for reference
Kernel command line from /etc/default/grub (remove i915.enable_gvt=1 if there are stability issues and add pcie_aspm=force if ASPM is not getting enabled automatically):
```
BOOT_IMAGE=/boot/vmlinuz-6.8.12-1-pve root=/dev/mapper/pve-root ro quiet i915.enable_gvt=1 i915.enable_guc=2 intel_iommu=on iommu=pt
```
<br><br>

## Switching PVE host/LXC between default console and GUI boot modes (if GUI is installed)

To set console/cli as default:
```
systemctl set-default multi-user.target
```

To set X11 login on boot as default:
```
systemctl set-default graphical.target
```
<br><br>

## Intel iGPU issues and solutions
Note: More information here (may need to create explicit xorg conf): https://wiki.archlinux.org/title/Intel_graphics
Wiki says enable_gvt=1 conflicts with any non-zero enable_guc option in kernal command line.

<br>Also check this page for missing Intel iGPU firmware for certain models like Celeron etc.: https://wiki.debian.org/Firmware#Firmware_missing_from_Debian
<br><br>

## PVE Helper Scripts archives
Repo also contains archives of the excellent and much popular PVE and LXC scripts from ttek and mrrudy (for kodi):

### mrrudy Kodi scripts

Copy of Kodi installation PVE LXC from mrrudy available in this repo, modified for local use: https://github.com/mrrudy/proxmoxHelper (modified here to additionally install kodi-inputstream-adaptive)
