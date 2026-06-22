#!/bin/bash
##
## following are the new fixes for kernel add/remove errors
##
echo 'grub-efi-amd64 grub2/force_efi_extra_removable boolean true' | debconf-set-selections -v -u
apt install --reinstall grub-efi-amd64
proxmox-boot-tool refresh
proxmox-boot-tool status
##
## Following are the older suggestions for fixes, which are not very consistent, disabling
##
#proxmox-boot-tool status # to check if ESP is detected, if not then run:
#lsblk -o +FSTYPE         # look for /dev/xxx boot efi partition with type vfat
#umount /boot/efi
#proxmox-boot-tool init /dev/nvme0n1p2 # replace 'xxx' with the partition from the lsblk command above
#mount -a
#proxmox-boot-tool refresh
#proxmox-boot-tool status
