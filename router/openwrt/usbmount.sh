#!/bin/sh
set -e
# Install mount utilities if not already present
apk add block-mount e2fsprogs

# Create mount target
mkdir -p /opt

# Configure persistent auto-mount by label (idempotent named section)
uci set fstab.opt=mount
uci set fstab.opt.label='opt'
uci set fstab.opt.target='/opt'
uci set fstab.opt.enabled='1'
uci commit fstab

# Start fstab and verify mount
/etc/init.d/fstab enable
/etc/init.d/fstab start
df -h /opt
