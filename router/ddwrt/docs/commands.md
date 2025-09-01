# Commands

Following details the manual commands for each type. Put them under Administration > Commands

## Startup Commands  

* Add commands under admin > commands > startup

* mount --bind should be skipped typically as it is not a good idea to have /jffs on external USB (mounted at /opt). Any failure will take down the router with it
* Below assumes dotfiles is on /jffs (persistent emmc internal storage)

```
# entware initialization
sleep 10
/opt/etc/init.d/rc.unslung start
#
# smartdns adblock script: https://github.com/egc112/ddwrt/tree/main/adblock/smartdns
/jffs/ddwrt-adblock-s.sh &
# create login shell init script, sync dotfiles repo first
cat <<'EOF' >"/tmp/root/.ashrc"
source /jffs/dotfiles/home/.profile.ddwrt
EOF
# Trigger Avahi/mDNS restart, due to a dbus dependency issue
service mdns start 
```

## USB Commands

* Add commands under admin > commands > USB Script

```
# syslogd logs to entware USB drive and creates symlink for webui access
mkdir -p /opt/logs
killall syslogd
syslogd -Z -L -s 1024 -O /opt/logs/system
ln -sf /opt/logs/system /jffs/messages
```

## Firewall command

* Add commands under admin > commands > firewall
* Enables only HomeAssistant/UptimeKuma hosts, on main network br0, one-way access to Guest network bridge br1

```
# allow HASS and UptimeKuma one-way access to guest network
iptables -I FORWARD -i br0 -s <HASSIP> -o br1 -m state --state NEW -j ACCEPT
iptables -I FORWARD -i br0 -s <KIMAIP> -o br1 -m state --state NEW -j ACCEPT
```

## Cron commands

* Add commands under admin > Management
* Cleans syslog on every reboot
* Runs adblock script on every 4 hours
* Reboots router every 1st and 16th of every month

```
0 0 * * 0 root rm /opt/logs/system
0 4 * * * root /jffs/ddwrt-adblock-s.sh
0 3 1,16 * * root reboot
```
