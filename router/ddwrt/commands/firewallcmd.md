# =====================================================================
# USER VARIABLE BLOCK (Modify here if your network topology changes)
# =====================================================================
MAIN_SUBNET="<<< ADD MAIN SUBNET HERE>>>.0/24"      # Your main LAN address space (Zion)
ADGUARD_IP="<<< ADGUARDARD_IP_WITHOUTPORT >>>"         # The central AdGuard Home DNS instance
HASS_IP="<<< HOMEASSISTANT IP HERE >>>"            # Your Home Assistant / Music Assistant server IP

# =====================================================================
# !!! SYSTEM CONSTANTS BARRIER - DO NOT MODIFY ANYTHING BELOW THIS !!!
# =====================================================================

# 1. Hardware Interface Definitions (Bridges)
NET_MAIN="br0"    # Zion
NET_IOT="br1"     # IoT
NET_GUEST="br2"   # Guest
NET_MEDIA="br3"   # Media

# 2. Interface Group Loops
ISOLATED_BRIDGES="$NET_IOT $NET_GUEST $NET_MEDIA"
ALL_BRIDGES="$NET_MAIN $NET_IOT $NET_GUEST $NET_MEDIA"

# 3. Protocol & Service Port Definitions
PORTS_DNS="53"
PORTS_DHCP="67"
PORTS_SSDP="1900"
PORTS_MDNS="5353"
PORTS_AIRPLAY_TCP="5000,7000"
PORTS_AIRPLAY_UDP_SYNC="6001,6002"
PORTS_AIRPLAY_STREAM="32768:65535"
PORTS_MGMT_BLOCK="22,23,80,443,6666"

# Music Assistant Streaming Core Engine Ports
PORTS_MUSIC_ASSISTANT_WEB="8095"    
PORTS_MUSIC_ASSISTANT_STREAM="8097" 

# 4. Dynamic String Concatenation for Router input
PORTS_ROUTER_DISC="$PORTS_DNS,$PORTS_DHCP,$PORTS_SSDP,$PORTS_MDNS"

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
iptables -A FORWARD -p igmp -j ACCEPT
iptables -A INPUT -p igmp -j ACCEPT

iptables -t mangle -A PREROUTING -p udp --dport "$PORTS_MDNS" -j TTL --ttl-set 2
iptables -t mangle -A PREROUTING -p udp --dport "$PORTS_SSDP" -j TTL --ttl-set 2

iptables -A FORWARD -d 224.0.0.251 -j ACCEPT
iptables -A FORWARD -d 239.255.255.250 -j ACCEPT

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
iptables -A FORWARD -i "$NET_MAIN" -s "$HASS_IP" -o "$NET_IOT" -m state --state NEW -j ACCEPT
iptables -A FORWARD -i "$NET_MEDIA" -o "$NET_MAIN" -d "$HASS_IP" -p tcp -m multiport --dports "$PORTS_MUSIC_ASSISTANT_WEB,$PORTS_MUSIC_ASSISTANT_STREAM" -m state --state NEW -j ACCEPT

# =====================================================================
# 6. THE IRON CURTAIN
# =====================================================================
for br in $ISOLATED_BRIDGES; do
    iptables -A FORWARD -i "$br" -d "$ADGUARD_IP" -p udp --dport "$PORTS_DNS" -j ACCEPT
    iptables -A FORWARD -o "$br" -s "$ADGUARD_IP" -p udp --sport "$PORTS_DNS" -j ACCEPT
    iptables -A FORWARD -i "$br" -d "$MAIN_SUBNET" -j REJECT --reject-with icmp-port-unreachable
done

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

