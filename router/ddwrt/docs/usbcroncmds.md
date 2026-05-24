# Commands

Following details the manual commands for each type. Put them under Administration > Commands

## USB Commands

* Add commands under admin > commands > USB Script

```
### syslogd logs to entware USB drive and creates symlink for webui access ###
mkdir -p /opt/logs
killall syslogd
syslogd -Z -L -s 1024 -O /opt/logs/system
ln -sf /opt/logs/system /jffs/messages
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
