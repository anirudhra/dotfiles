#!/usr/bin/env bash
# (c) Anirudh Acharya
# OMV Docker Bridge Isolation & IoT Routing Setup Script
# Hardens OMV Docker bridged containers (br-+) from accessing:
# 1. IoT Guest Subnet (192.168.101.0/24)
# 2. Asus Router Admin UI & SSH (10.100.100.1 ports 80, 443, 6666)
# 3. OMV Host SSH, Web UI, RPC, and Samba mounts (ports 22, 80, 111, 139, 222, 445)
# Note: Host-network containers (homeassistant, govee2mqtt) use OUTPUT/lo and are unaffected.

set -euo pipefail

IOT_SUBNET="192.168.101.0/24"
ROUTER_IP="10.100.100.1"
SCRIPT_PATH="$(readlink -f "$0")"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Applies OMV Docker bridge isolation rules (DOCKER-USER & INPUT).
With --install, also sets up persistent systemd service, IoT subnet route,
and Docker default-address-pools.

OPTIONS:
  --install    Install systemd unit, persistent route (192.168.101.0/24), and apply rules
  -h, --help   Display this help message and exit
EOF
}

apply_firewall_rules() {
  iptables -N DOCKER-USER 2>/dev/null || true

  # Clean up existing rules to ensure idempotency
  iptables -D DOCKER-USER -i br-+ -d "${IOT_SUBNET}" -j DROP 2>/dev/null || true
  iptables -D DOCKER-USER -i br-+ -d "${ROUTER_IP}" -p tcp -m multiport --dports 80,443,6666 -j DROP 2>/dev/null || true
  iptables -D INPUT -i br-+ -p tcp -m multiport --dports 22,80,111,139,222,445 -j DROP 2>/dev/null || true

  # Insert DOCKER-USER rules
  iptables -I DOCKER-USER 1 -i br-+ -d "${IOT_SUBNET}" -j DROP
  iptables -I DOCKER-USER 2 -i br-+ -d "${ROUTER_IP}" -p tcp -m multiport --dports 80,443,6666 -j DROP

  # Insert INPUT rule protecting OMV host services from bridged containers
  iptables -I INPUT 1 -i br-+ -p tcp -m multiport --dports 22,80,111,139,222,445 -j DROP
}

install_all() {
  # 1. Persistent route for IoT subnet via 10.100.100.1
  mkdir -p /etc/systemd/network/10-netplan-enp1s0.network.d
  cat <<EOF >/etc/systemd/network/10-netplan-enp1s0.network.d/iot-route.conf
[Route]
Destination=${IOT_SUBNET}
Gateway=${ROUTER_IP}
EOF
  networkctl reload

  # 2. Symlink script to /usr/local/sbin/omv-docker-firewall.sh
  ln -sf "${SCRIPT_PATH}" /usr/local/sbin/omv-docker-firewall.sh

  # 3. Create & enable systemd service
  cat <<'EOF' >/etc/systemd/system/omv-docker-firewall.service
[Unit]
Description=OMV Docker Bridge Isolation Firewall Rules (DOCKER-USER & INPUT)
After=network-online.target docker.service
Requires=docker.service
PartOf=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/omv-docker-firewall.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target docker.service
EOF

  systemctl daemon-reload
  systemctl enable --now omv-docker-firewall.service
  echo "Installed and enabled omv-docker-firewall.service and persistent IoT route."
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: This script must be run as root." >&2
  exit 1
fi

case "${1:-}" in
  --install)
    install_all
    ;;
  -h|--help)
    show_help
    exit 0
    ;;
  "")
    apply_firewall_rules
    ;;
  *)
    echo "Error: Unknown option '$1'" >&2
    show_help
    exit 1
    ;;
esac
