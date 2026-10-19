#!/bin/sh
#
# Script to convert OpenWRT router to access point
set -e

# Default to 10.100.10 if no argument is passed
SUBNET_PREFIX="${1:-10.100.10}"

# Strip any accidental trailing dot (e.g. "10.100.10." -> "10.100.10")
SUBNET_PREFIX="${SUBNET_PREFIX%.}"

ROUTER_IP="${SUBNET_PREFIX}.1"
AP_IP="${SUBNET_PREFIX}.2"

echo "Configuring OpenWrt dumb AP:"
echo "  Subnet:  ${SUBNET_PREFIX}.0/24"
echo "  Router:  ${ROUTER_IP}"
echo "  AP IP:   ${AP_IP}"

# 1. Disable DHCPv4, DHCPv6, and Router Advertisements on LAN
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dhcpv4='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ra='disabled'
uci commit dhcp

# 2. Set static IP, gateway, and DNS pointing to the main router
uci set network.lan.proto='static'
uci set network.lan.ipaddr="${AP_IP}/24"
uci set network.lan.gateway="${ROUTER_IP}"
uci set network.lan.dns="${ROUTER_IP}"

# 3. Detect physical WAN port and LAN bridge device before deletion
WAN_DEV="$(uci -q get network.wan.device || echo 'wan')"
LAN_BRIDGE="$(uci -q get network.lan.device || echo 'br-lan')"

# Remove standalone WAN interfaces so the WAN jack can join the bridge
uci -q delete network.wan
uci -q delete network.wan6

# 4. Bridge the physical WAN port into the LAN bridge
BR_SEC=""
i=0
while :; do
  dev_name="$(uci -q get "network.@device[$i].name")" || break
  if [ "$dev_name" = "$LAN_BRIDGE" ]; then
    BR_SEC="@device[$i]"
    break
  fi
  i=$((i + 1))
done

if [ -n "$BR_SEC" ]; then
  # Modern OpenWrt (DSA device bridge)
  uci -q del_list "network.${BR_SEC}.ports=${WAN_DEV}" 2>/dev/null || true
  uci add_list "network.${BR_SEC}.ports=${WAN_DEV}"
else
  # Fallback for legacy swconfig / interface-level bridge
  uci -q del_list "network.lan.ifname=${WAN_DEV}" 2>/dev/null || true
  uci add_list "network.lan.ifname=${WAN_DEV}"
fi

# 5. Commit network changes
uci commit network

echo "Configuration applied. Stopping and disabling dnsmasq, odhcpd, and firewall services. Run '/etc/init.d/network restart' or reboot to apply."

# 6. Stop and disable local dnsmasq, odhcpd, and firewall daemons
/etc/init.d/dnsmasq stop || true
/etc/init.d/dnsmasq disable || true
/etc/init.d/odhcpd stop || true
/etc/init.d/odhcpd disable || true
/etc/init.d/firewall stop || true
/etc/init.d/firewall disable || true

echo "All done!"
