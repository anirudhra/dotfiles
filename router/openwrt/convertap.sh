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

# 3. Remove standalone WAN interfaces so the WAN jack can join the bridge
uci -q delete network.wan
uci -q delete network.wan6

# 4. Bridge the physical WAN port into the br-lan device
uci add_list network.@device[0].ports='wan'

# 5. Commit network changes
uci commit network

echo "Configuration applied. Stopping dnsmasq and odhcpd services. Run '/etc/init.d/network restart' or reboot to apply."

# 6. Stop and disable local dnsmasq and odhcpd daemons
/etc/init.d/dnsmasq stop
/etc/init.d/dnsmasq disable
/etc/init.d/odhcpd stop
/etc/init.d/odhcpd disable

echo "All done!"
