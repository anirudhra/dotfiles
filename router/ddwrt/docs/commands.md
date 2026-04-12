# Commands

Following details the manual commands for each type. Put them under Administration > Commands

## Startup Commands  

* Add commands under admin > commands > startup

* mount --bind should be skipped typically as it is not a good idea to have /jffs on external USB (mounted at /opt)
* Below assumes dotfiles is on /jffs (persistent emmc internal storage)

```
### Entware initialization ###
sleep 10
/opt/etc/init.d/rc.unslung start
### export dir variables for use ###
export ROOT_HOME="/opt/root"
export JFFS_HOME="/jffs"
### smartdns adblock script https://github.com/egc112/ddwrt/tree/main/adblock/smartdns ###
##cp ${ROOT_HOME}/dotfiles/router/ddwrt/ddwrt-adblock-s.sh ${JFFS_HOME}/ddwrt-adblock-s.sh
##${JFFS_HOME}/ddwrt-adblock-s.sh &
### create login shell init script, sync dotfiles repo first ###
cat <<'EOF' >"/tmp/root/.ashrc"
export ROOT_HOME="/opt/root"
export JFFS_HOME="/jffs"
export DOTFILES_HOME="${ROOT_HOME}"
source ${DOTFILES_HOME}/dotfiles/home/.profile.ddwrt
EOF
### Trigger Avahi/mDNS to restart, due to a bug ###
service mdns start
```

## USB Commands

* Add commands under admin > commands > USB Script

```
### syslogd logs to entware USB drive and creates symlink for webui access ###
mkdir -p /opt/logs
killall syslogd
syslogd -Z -L -s 1024 -O /opt/logs/system
ln -sf /opt/logs/system /jffs/messages
```

## Firewall command

* Add commands under admin > commands > firewall
* Enables only HomeAssistant/UptimeKuma hosts, on main network br0, one-way access to Guest network bridge br1
* Disables router config access from guest network
* Enables guest devices to access DNS on router
* Replace <*_IP> with the correct host IPs

```
# 1. Allow the specific HA/Kuma hosts to initiate connections to the Guest Network (br0)
iptables -I FORWARD -i br0 -s <HASS_IP> -o br1 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -i br0 -s <KUMA_IP> -o br1 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# 2. Allow Guest devices (br1) to respond to established/related connections from HA/Kuma hosts
iptables -I FORWARD -i br1 -o br0 -d <HASS_IP> -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -i br1 -o br0 -d <KUMA_IP> -m state --state ESTABLISHED,RELATED -j ACCEPT

# 3. Drop all other traffic initiated by the Guest Network (br1) toward the Main Network (br0)
iptables -I FORWARD -i br1 -o br0 -m state --state NEW -j DROP

# 3a. For Debugging, allow br0 and br1 to talk, disable after debug
#iptables -I FORWARD -i br1 -o br0 -m state --state NEW -j ACCEPT
#iptables -I FORWARD -i br0 -o br1 -m state --state NEW -j ACCEPT

# 4. Restrict Guests on br1 from accessing the Router's Web UI/SSH (ssh/http/https ports)
iptables -I INPUT -i br1 -d <DDWRT_IP> -p tcp --dport <SSH_PORT> -j REJECT
iptables -I INPUT -i br1 -d <DDWRT_IP> -p tcp --dport 80 -j REJECT
iptables -I INPUT -i br1 -d <DDWRT_IP> -p tcp --dport 443 -j REJECT

# 5. Allow Guest Network (br1) to send DNS queries (UDP/TCP 53) to the router IP
iptables -I INPUT -i br1 -d <DDWRT_IP> -p udp --dport 53 -j ACCEPT
iptables -I INPUT -i br1 -d <DDWRT_IP> -p tcp --dport 53 -j ACCEPT

# 6. Ensure the router can respond to those DNS queries back to the Guest Network
iptables -I OUTPUT -o br1 -p udp -s <DDWRT_IP> --sport 53 -j ACCEPT
iptables -I OUTPUT -o br1 -p tcp -s <DDWRT_IP> --sport 53 -j ACCEPT
```

## Cron commands

* Add commands under admin > Management
* Cleans syslog on every reboot
* Runs adblock script on every 4 hours
* Reboots router every 1st and 16th of every month

```
0 0 * * 0 root rm /opt/logs/system
# enable below for smartDNS
# 0 4 * * * root /jffs/ddwrt-adblock-s.sh
0 3 1,16 * * root reboot
```
