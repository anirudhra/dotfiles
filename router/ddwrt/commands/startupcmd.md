###############################################################################

## IGMP for media bridge to interact with main bridge

# Force Multicast forwarding on the kernel level for all bridges

echo 1 > /proc/sys/net/ipv4/conf/all/mc_forwarding
echo 1 > /proc/sys/net/ipv4/conf/br0/mc_forwarding
echo 1 > /proc/sys/net/ipv4/conf/br2/mc_forwarding
echo 1 > /proc/sys/net/ipv4/conf/br3/mc_forwarding

# Enable IGMP Snooping on the bridges to keep the traffic efficient

echo 1 > /sys/class/net/br0/bridge/multicast_snooping
echo 1 > /sys/class/net/br2/bridge/multicast_snooping
echo 1 > /sys/class/net/br3/bridge/multicast_snooping

### Entware initialization ###

# Wait up to 30 seconds for /opt to be fully mounted

for i in 1 2 3 4 5 6; do
    if [ -d /opt/etc/init.d ]; then
        /opt/etc/init.d/rc.unslung start
        break
    fi
    sleep 5
done

### Login Shell Setup ###

# Recreate the login bootstrap in RAM after every reboot

cat <<'EOF' > /tmp/root/.ashrc
export ROOT_HOME="/opt/root"
export JFFS_HOME="/jffs"
export DOTFILES_HOME="${ROOT_HOME}"

# Load the persistent DD-WRT profile

[ -r "${DOTFILES_HOME}/dotfiles/home/.profile.ddwrt" ] &&
  . "${DOTFILES_HOME}/dotfiles/home/.profile.ddwrt"
EOF

### Service Fixes ###

# Restarting mDNS clears "zombie" states often found on initial boot

service mdns restart

### Failsafe Tailscale Integration ###

# Start Tailscale only if the binary is present (prevents errors after upgrades)

if [ -f "/opt/bin/tailscaled" ]; then
    # Ensure the state directory exists on persistent storage
    [ -d /opt ] && mkdir -p /opt/tailscale
    /opt/bin/tailscaled --state=/opt/tailscale/tailscaled.state --tun=userspace-networking > /dev/null 2>&1 &

    # Allow the daemon to initialize
    sleep 10

    # Background the 'up' command to prevent the script from hanging
    /opt/bin/tailscale up --advertise-exit-node --advertise-routes=10.100.10.0/24 --ssh &
fi
