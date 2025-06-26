#!/bin/sh
# (c) Anirudh Acharya 2024
# unmounts hdpool filesystem - first step (does not remove the pool)
#

zfspool="pvebackup"

zfs umount /${zfspool}
# exports the zpool to make it safe to USB disconnect after unmount
zpool export ${zfspool}

#zpool status -v
#zfs list -v
zpool status
zfs list
