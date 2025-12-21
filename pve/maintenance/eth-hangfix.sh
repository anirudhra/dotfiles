#!/bin/bash

# Reset network interface if system journal shows it has hung
# Refer https://forum.proxmox.com/threads/e1000-driver-hang.58284

# 19/11/2025 v1.0 Created simplified version - Tim.
# 2025-12-21 v1.0a Anirudh Acharya, parameterized ethernet interface and added sample cron command for reference
#   Add entry to root crontab, e.g. run every 10 minutes, starting at 2 minutes past the hour:
#   2,12,22,32,42,52 * * * * <path_to_this_script.sh> >> /var/log/eth-hangfix.log || echo "CRON JOB FAILED"

set -euo pipefail

usage() {
  cat <<EOF
Reset network if hang detected in PVE networking, must be run as root.

Options:
-h this help
-v verbose output, specify multiple times to increase verbosity
EOF
}

log_msg() {
  local loglevel="$1"
  local logmsg="$2"
  local timestamp

  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  if [[ $loglevel -le $VERBOSITY ]]; then
    echo "$timestamp: $logmsg"
  fi
}

#defaults
VERBOSITY=0

# ethernet interface
ETHIF="eno1"

while getopts "hv" OPTION; do
  case $OPTION in
  h)
    usage
    exit 0
    ;;
  v)
    VERBOSITY=$((VERBOSITY + 1))
    ;;
  \?)
    usage
    exit 3
    ;;
  esac
done

shift $((OPTIND - 1))

[[ $VERBOSITY -ge 1 ]] && echo "Verbosity is: $VERBOSITY"

# check system journal for recent hang
if ! hangcount=$(journalctl \
  --since "2 minutes ago" _TRANSPORT=kernel \
  _KERNEL_SUBSYSTEM=pci --priority=3 |
  grep -c "Detected Hardware Unit Hang:"); then
  log_msg 1 "No network hang detected, exiting"
  exit 0
fi

log_msg 0 "Hang detected, count is: $hangcount, restarting network"
# need full path, root cron PATH does not include /usr/sbin
/usr/sbin/ifdown ${ETHIF}
sleep 10
/usr/sbin/ifup ${ETHIF}

log_msg 2 "Sleeping 10 seconds for good luck"
sleep 10

# problem has been detected, so exit non-zero to get notification from cron
exit 1
