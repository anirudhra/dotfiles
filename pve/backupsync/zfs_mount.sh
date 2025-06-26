#!/bin/sh
#
# (c) Anirudh Acharya 2024
# script to mount usb zfs pool
#

zfspool="pvebackup"
mountpoint="zfsdata"
# uncomment -f version if pool fails to mount, else use non-f version
# zpool import ${zfspool} -f
zpool import ${zfspool}

mkdir -p /${mountpoint}

# following command may not be needed all the time, but just in case
zfs set mountpoint=/${mountpoint} ${zfspool}/${mountpoint}

#zpool status -v
zpool status
#zfs list -v
zfs list
