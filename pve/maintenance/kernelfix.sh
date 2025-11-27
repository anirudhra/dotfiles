#!/bin/bash
proxmox-boot-tool status # to check if ESP is detected, if not then run:
lsblk -o +FSTYPE         # look for /dev/xxx boot efi partition with type vfat
umount /boot/efi
proxmox-boot-tool init /dev/nvme0n1p2 # replace 'xxx' with the partition from the lsblk command above
mount -a
proxmox-boot-tool refresh
proxmox-boot-tool status
