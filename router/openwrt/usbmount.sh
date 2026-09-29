#!/bin/sh
set -e
# Install mount utilities if not already present
apk add block-mount e2fsprogs

# Create mount target
mkdir -p /opt

# Configure persistent auto-mount by label
uci add fstab mount
uci set fstab.@mount[-1].label='opt'
uci set fstab.@mount[-1].target='/opt'
uci set fstab.@mount[-1].enabled='1'
uci commit fstab

# Start fstab and verify mount
/etc/init.d/fstab enable
/etc/init.d/fstab start
df -h /opt
