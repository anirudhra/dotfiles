# Enabling and saving logs to USB

This will save the logs to USB drive. Note that this will not survive a reboot as the service is restarted.

* Enable USB support and automount
* Enable logging from : Services > Services > syslogd
* Create the directory on USB: /opt/logs/system or (/tmp/mnt/sda1/logs/system for non-Optware generic USB)
* Goto Administration > Commands and add the following under USB commands and click "Save USB":

```
# Replace /opt/logs/system below with /tmp/mnt/sda1/logs/system for non-Optware generic USB
mkdir -p /opt/logs
killall syslogd
syslogd -Z -L -s 1024 -O /opt/logs/system
ln -sf /opt/logs/system /jffs/messages
```

* Explanation: on USB mount, restarts syslogd service to start logging on to the USB drive automounted on /dev/sda1 and creates a symlink on /jffs/messages so that this log is available via Web UI. "-s <size>" sets the max size of the log in KB
* Optional: The following to crontab to delete the log file regularly, for e.g. every Sunday
```0 0 * * 0 root rm /opt/logs/system # or /tmp/mnt/sda1/logs/system```
