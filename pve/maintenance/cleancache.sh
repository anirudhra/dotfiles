#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
   ________                    __   _  ________
  / ____/ /__  ____ _____     / /  | |/ / ____/
 / /   / / _ \/ __ `/ __ \   / /   |   / /
/ /___/ /  __/ /_/ / / / /  / /___/   / /___
\____/_/\___/\__,_/_/ /_/  /_____/_/|_\____/

EOF
}
BL=$(echo "\033[36m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
name=$(hostname)
header_info
echo -e "${BL}[Info]${GN} Cleaning $name${CL} \n"

# Remove package and application caches
if [ -d /var/cache ]; then
  find /var/cache -type f -delete 2>/dev/null || true
  echo "Successfully Removed Cache"
fi

header_info
echo -e "${BL}[Info]${GN} Cleaning logs on $name${CL} \n"

# Vacuum systemd journal to 1 day
if command -v journalctl >/dev/null 2>&1; then
  journalctl --vacuum-time=1d >/dev/null 2>&1 || true
fi

# Remove rotated and archived logs without breaking open file descriptors
if [ -d /var/log ]; then
  find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.old" -o -name "*.bak" \) -delete 2>/dev/null || true
  # Truncate active .log files rather than deleting them
  find /var/log -type f -name "*.log" -exec truncate -s 0 {} + 2>/dev/null || true
  echo "Successfully Cleaned Logs"
fi

header_info
echo -e "${BL}[Info]${GN} Populating apt lists on $name${CL} \n"
apt-get update >/dev/null 2>&1 || true
echo -e "${GN}Done!${CL} \n"
