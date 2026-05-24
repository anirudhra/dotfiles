# Commands

## Startup Commands  

* Add commands under admin > commands > startup

* mount --bind should be skipped typically as it is not a good idea to have /jffs on external USB (mounted at /opt)
* Below assumes dotfiles is on /jffs (persistent emmc internal storage)

```

# =====================================================================
# CONFIGURATION HEADER (Modify here to scale, rename, or adapt)
# =====================================================================
# 1. IP Subnets & Key Hosts
MAIN_SUBNET="<MAIN.0/24>"
ADGUARD_IP="<ADGUARD_IP>"
HA_IP="<HASS_IP>"

# 2. Hardware Interface Definitions (Bridges)
NET_MAIN="br0"    # Zion
NET_IOT="br1"     # IoT
NET_GUEST="br2"   # Guest
NET_MEDIA="br3"   # Media

# 3. Interface Group Loops
ISOLATED_BRIDGES="$NET_IOT $NET_GUEST $NET_MEDIA"
ALL_BRIDGES="$NET_MAIN $NET_IOT $NET_GUEST $NET_MEDIA"

# 4. Port Definitions
PORTS_DNS="53"
PORTS_SSDP="1900"
PORTS_MDNS="5353"
PORTS_AIRPLAY_TCP="5000,7000"
PORTS_AIRPLAY_UDP_SYNC="6001,6002"
PORTS_AIRPLAY_STREAM="32768:65535"
PORTS_MGMT_BLOCK="22,23,80,443,6666"

# Combined Port Groups for Cleaner Rules
PORTS_ROUTER_DISC="53,67,1900,5353" # DNS, DHCP, SSDP, mDNS for Router Input

# =====================================================================
# 0. CLEAN SLATE
# =====================================================================
iptables -F INPUT
iptables -F FORWARD
iptables -t nat -F PREROUTING
iptables -t mangle -F PREROUTING

# =====================================================================
# 1. THE ADGUARD REDIRECT (Strict)
# =====================================================================
for br in $ISOLATED_BRIDGES; do
    iptables -t nat -A PREROUTING -i "$br" -p udp --dport "$PORTS_DNS" ! -d "$ADGUARD_IP" -j DNAT --to "$ADGUARD_IP"
done

# =====================================================================
# 2. MULTICAST, IGMP & AIRPLAY STREAMING (The Secret Sauce)
# =====================================================================
# Allow IGMP (Protocol 2) globally
iptables -A FORWARD -p igmp -j ACCEPT
iptables -A INPUT -p igmp -j ACCEPT

# TTL BUMP for mDNS/SSDP (Ensures discovery crosses bridge boundaries)
iptables -t mangle -A PREROUTING -p udp --dport "$PORTS_MDNS" -j TTL --ttl-set 2
iptables -t mangle -A PREROUTING -p udp --dport "$PORTS_SSDP" -j TTL --ttl-set 2

# Accept discovery groups (mDNS and SSDP Multicast addresses)
iptables -A FORWARD -d 224.0.0.251 -j ACCEPT
iptables -A FORWARD -d 239.255.255.250 -j ACCEPT

# Allow AirPlay Ports
iptables -A FORWARD -p tcp -m multiport --dports "$PORTS_AIRPLAY_TCP" -j ACCEPT
iptables -A FORWARD -p udp -m multiport --dports "$PORTS_AIRPLAY_UDP_SYNC" -j ACCEPT
iptables -A FORWARD -p udp --dport "$PORTS_AIRPLAY_STREAM" -j ACCEPT

# =====================================================================
# 3. GLOBAL STATE ENGINE
# =====================================================================
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# =====================================================================
# 4. THE STATEFUL "OPEN PIPE" (Lean & Accelerated)
# =====================================================================
iptables -A FORWARD -i "$NET_MAIN" -o "$NET_MEDIA" -m state --state NEW -j ACCEPT
iptables -A FORWARD -i "$NET_GUEST" -o "$NET_MEDIA" -m state --state NEW -j ACCEPT

# =====================================================================
# 5. SERVER SPECIAL RULES
# =====================================================================
# Stateful access rule for Home Assistant to control IoT devices securely
iptables -A FORWARD -i "$NET_MAIN" -s "$HA_IP" -o "$NET_IOT" -m state --state NEW -j ACCEPT

# =====================================================================
# 6. THE IRON CURTAIN
# =====================================================================
# Allow return DNS traffic from AdGuard back to the subnets, then drop unauthorized access
for br in $ISOLATED_BRIDGES; do
    iptables -A FORWARD -i "$br" -d "$ADGUARD_IP" -p udp --dport "$PORTS_DNS" -j ACCEPT
    iptables -A FORWARD -o "$br" -s "$ADGUARD_IP" -p udp --sport "$PORTS_DNS" -j ACCEPT
    iptables -A FORWARD -i "$br" -d "$MAIN_SUBNET" -j REJECT --reject-with icmp-port-unreachable
done

# Lateral Isolation Between Guest, IoT, and Media Bridges
iptables -A FORWARD -i "$NET_IOT" -o "$NET_GUEST" -j REJECT
iptables -A FORWARD -i "$NET_IOT" -o "$NET_MEDIA" -j REJECT
iptables -A FORWARD -i "$NET_GUEST" -o "$NET_IOT" -j REJECT
iptables -A FORWARD -i "$NET_MEDIA" -o "$NET_IOT" -j REJECT
iptables -A FORWARD -i "$NET_MEDIA" -o "$NET_GUEST" -j REJECT

# =====================================================================
# 7. INPUT CHAIN (Router Discovery Services)
# =====================================================================
for br in $ALL_BRIDGES; do
    iptables -I INPUT -i "$br" -p udp -m multiport --dports "$PORTS_ROUTER_DISC" -j ACCEPT
done

# =====================================================================
# 8. MANAGEMENT LOCKDOWN
# =====================================================================
for br in $ISOLATED_BRIDGES; do
    iptables -I INPUT -i "$br" -p tcp -m multiport --dports "$PORTS_MGMT_BLOCK" -j REJECT --reject-with tcp-reset
done

```
```

```
