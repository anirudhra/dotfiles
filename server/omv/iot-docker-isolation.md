# OMV & Asuswrt-Merlin IoT Network Isolation Runbook

Complete restore guide for isolating the IoT Guest Network (`192.168.101.0/24` on `br1`/`wl0.1`) and OMV bridged Docker containers while allowing `homeassistant` and `govee2mqtt` on OMV (`10.100.100.10`) to communicate with IoT devices.

---

## Network Architecture

* **Main LAN (`br0` on Router / `enp1s0` on OMV):** `10.100.100.0/24`
  * **Asus RT-AX82U Router:** `10.100.100.1`
  * **OMV Server:** `10.100.100.10`
* **IoT 2.4 GHz Guest Network 1 (`br1` / `wl0.1` on Router):** `192.168.101.0/24` (`Access Intranet: Disable` enabled in Asus GUI)

---

## Part 1: OMV Server Configuration (`10.100.100.10`)

### 1. Persistent Route to IoT Subnet (`192.168.101.0/24`)
Prevents Docker bridge networks from hijacking `192.168.101.0/24` and routes traffic via `10.100.100.1`.

**File:** `/etc/systemd/network/10-netplan-enp1s0.network.d/iot-route.conf`
```ini
[Route]
Destination=192.168.101.0/24
Gateway=10.100.100.1
```

**Apply:**
```bash
sudo mkdir -p /etc/systemd/network/10-netplan-enp1s0.network.d
sudo tee /etc/systemd/network/10-netplan-enp1s0.network.d/iot-route.conf >/dev/null <<'EOF'
[Route]
Destination=192.168.101.0/24
Gateway=10.100.100.1
EOF
sudo networkctl reload
```

---

### 2. Docker Default Address Pools (`172.16.0.0/12`)
Prevents Docker from allocating `192.168.x.x/20` subnets to Compose bridge networks.

**File:** `/etc/docker/daemon.json`
```json
{
  "data-root": "/var/lib/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-file": "3",
    "max-size": "50m"
  },
  "storage-driver": "overlay2",
  "default-address-pools": [
    {
      "base": "172.16.0.0/12",
      "size": 24
    }
  ]
}
```
> **Important OMV GUI Note:** In **OMV GUI → Services → Compose → Settings → Docker → Docker Storage**, leave the **Docker Storage** field **blank** so OMV never overwrites `/etc/docker/daemon.json`.

---

### 3. OMV Docker Bridge Firewall (`DOCKER-USER` & `INPUT`)
Blocks all bridged Docker containers (`br-+`, e.g., `transmission`, `pyload-ng`, `jellyfin`, `immich`) from reaching:
1. The IoT subnet (`192.168.101.0/24`)
2. The Asus Router Web UI & SSH (`10.100.100.1` ports `80, 443, 6666`)
3. OMV's own SSH, Web UI, RPC, and Samba shares (`ports 22, 80, 111, 139, 222, 445`)

*(Host-mode containers `homeassistant` and `govee2mqtt` use the host `OUTPUT` / `lo` interface and are unaffected).*

**Script:** `/usr/local/sbin/omv-docker-firewall.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

iptables -N DOCKER-USER 2>/dev/null || true

iptables -D DOCKER-USER -i br-+ -d 192.168.101.0/24 -j DROP 2>/dev/null || true
iptables -D DOCKER-USER -i br-+ -d 10.100.100.1 -p tcp -m multiport --dports 80,443,6666 -j DROP 2>/dev/null || true
iptables -D INPUT -i br-+ -p tcp -m multiport --dports 22,80,111,139,222,445 -j DROP 2>/dev/null || true

iptables -I DOCKER-USER 1 -i br-+ -d 192.168.101.0/24 -j DROP
iptables -I DOCKER-USER 2 -i br-+ -d 10.100.100.1 -p tcp -m multiport --dports 80,443,6666 -j DROP
iptables -I INPUT 1 -i br-+ -p tcp -m multiport --dports 22,80,111,139,222,445 -j DROP
```

**Systemd Service:** `/etc/systemd/system/omv-docker-firewall.service`
```ini
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
```

**Enable & Start:**
```bash
sudo chmod +x /usr/local/sbin/omv-docker-firewall.sh
sudo systemctl daemon-reload
sudo systemctl enable --now omv-docker-firewall.service
```

---

## Part 2: Asuswrt-Merlin Router Configuration (`10.100.100.1`)

Reference copy stored at: `/root/dotfiles/router/merlin/firewall-start`

**File on Router:** `/jffs/scripts/firewall-start` (`chmod a+rx /jffs/scripts/firewall-start`)
```sh
#!/bin/sh

sh /jffs/scripts/firewall start skynetloc=/tmp/mnt/USB/skynet # Skynet

HA_IP="10.100.100.10"
GOVEE_IP="192.168.101.82"

# 1. Layer-2 (ebtables): Allow traffic from Guest Wi-Fi (wl0.1) addressed to OMV (10.100.100.10)
#    to pass up to Layer-3 so stateful iptables FORWARD rules can inspect it.
ebtables -t broute -D BROUTING -p IPv4 -i wl0.1 --ip-dst "$HA_IP" -j ACCEPT 2>/dev/null
ebtables -t broute -I BROUTING 1 -p IPv4 -i wl0.1 --ip-dst "$HA_IP" -j ACCEPT

# 2. Layer-3 (iptables): Clean up old rules to prevent duplicates
iptables -D FORWARD -i br0 -o br1 -s "$HA_IP" -m state --state NEW -j ACCEPT 2>/dev/null
iptables -D FORWARD -i br0 -o br1 -s "$HA_IP" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
iptables -D FORWARD -i br1 -o br0 -d "$HA_IP" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
iptables -D FORWARD -i br1 -o br0 -s "$GOVEE_IP" -d "$HA_IP" -p udp --dport 4002 -j ACCEPT 2>/dev/null
iptables -D FORWARD -i br0 -o br1 -j DROP 2>/dev/null
iptables -D FORWARD -i br1 -o br0 -j DROP 2>/dev/null

# Insert FORWARD rules in reverse order so they land at positions 1..5:
iptables -I FORWARD 1 -i br1 -o br0 -j DROP
iptables -I FORWARD 1 -i br0 -o br1 -j DROP
iptables -I FORWARD 1 -i br1 -o br0 -s "$GOVEE_IP" -d "$HA_IP" -p udp --dport 4002 -j ACCEPT
iptables -I FORWARD 1 -i br1 -o br0 -d "$HA_IP" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD 1 -i br0 -o br1 -s "$HA_IP" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

[ -x /jffs/addons/AdGuardHome.d/AdGuardHome.sh ] && /jffs/addons/AdGuardHome.d/AdGuardHome.sh firewall "$1"
```

---

## Part 3: Verification Commands

Run on OMV (`10.100.100.10`) after restoring:
```bash
# 1. Verify route goes via 10.100.100.1 (enp1s0), NOT a Docker br-* interface
ip route get 192.168.101.101

# 2. Verify Home Assistant (host network) CAN reach IoT device
docker exec homeassistant ping -c 1 -W 1 192.168.101.101

# 3. Verify bridged container (e.g. transmission) is BLOCKED from IoT, OMV SMB, and Router UI
docker exec transmission ping -c 1 -W 1 192.168.101.101
docker exec transmission nc -zv -w 1 10.100.100.10 445
docker exec transmission nc -zv -w 1 10.100.100.1 80
```
