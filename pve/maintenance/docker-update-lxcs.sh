#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Modified by: Anirudh Acharya
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"

 ____             _             
|  _ \  ___   ___| | _____ _ __ 
| | | |/ _ \ / __| |/ / _ \ '__|
| |_| | (_) | (__|   <  __/ |   
|____/ \___/ \___|_|\_\___|_|   
   __  __          __      __          __   _  ________
  / / / /___  ____/ /___ _/ /____     / /  | |/ / ____/
 / / / / __ \/ __  / __ `/ __/ _ \   / /   |   / /
/ /_/ / /_/ / /_/ / /_/ / /_/  __/  / /___/   / /___
\____/ .___/\__,_/\__,_/\__/\___/  /_____/_/|_\____/
    /_/

EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
header_info
echo "Loading..."
whiptail --backtitle "Additional Proxmox VE Helper Scripts" --title "Proxmox VE LXC Docker Updater" --yesno "This Will Update Docker Containers in LXCs. Proceed?" 10 58 || exit
NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Additional Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to skip docker updates:\n" 16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit

function needs_reboot() {
  local container=$1
  local os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  local reboot_required_file="/var/run/reboot-required.pkgs"
  if [ -f "$reboot_required_file" ]; then
    if [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
      if pct exec "$container" -- [ -s "$reboot_required_file" ]; then
        return 0
      fi
    fi
  fi
  return 1
}

function update_container() {

  container=$1
  header_info
  name=$(pct exec "$container" hostname)
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')

  dockercd="cd /mnt/pve-sata-ssd/ssd-data/dockerapps/${name}" 
  dockerupdate="dockerfind . -maxdepth 1 -type d \( ! -name . \) -not -path '*disabled*' -exec bash -c \"cd '{}' && pwd && docker compose down && docker compose pull && docker compose up -d --remove-orphans\" \;"
  dockerclean="docker image prune -a -f && docker system prune --volumes -f"
  
  if [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "fedora" ]]; then
    disk_info=$(pct exec "$container" df /boot | awk 'NR==2{gsub("%","",$5); printf "%s %.1fG %.1fG %.1fG", $5, $3/1024/1024, $2/1024/1024, $4/1024/1024 }')
    read -ra disk_info_array <<<"$disk_info"
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}Boot Disk: ${disk_info_array[0]}% full [${disk_info_array[1]}/${disk_info_array[2]} used, ${disk_info_array[3]} free]${CL}\n"
  else
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}[No disk info for ${os}]${CL}\n"
  fi
  case "$os" in
  alpine) pct exec "$container" -- ash -c "${dockercd} && ${dockerupdate} && ${dockerclean}" ;;
  archlinux) pct exec "$container" -- bash -c "${dockercd} && ${dockerupdate} && ${dockerclean}" ;;
  fedora | rocky | centos | alma) pct exec "$container" -- bash -c "${dockercd} && ${dockerupdate} && ${dockerclean}" ;;
  ubuntu | debian | devuan) pct exec "$container" -- bash -c "${dockercd} && ${dockerupdate} && ${dockerclean}" ;;
  opensuse) pct exec "$container" -- bash -c "${dockercd} && ${dockerupdate} && ${dockerclean}" ;;
  esac
}

containers_needing_reboot=()
header_info
for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
    sleep 1
  else
    status=$(pct status $container)
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
      pct start $container
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
      sleep 5
      update_container $container
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      update_container $container
    fi
    if pct exec "$container" -- [ -e "/var/run/reboot-required" ]; then
      # Get the container's hostname and add it to the list
      container_hostname=$(pct exec "$container" hostname)
      containers_needing_reboot+=("$container ($container_hostname)")
    fi
  fi
done
wait
header_info
echo -e "${GN}The process is complete, and the containers have been successfully updated.${CL}\n"
if [ "${#containers_needing_reboot[@]}" -gt 0 ]; then
  echo -e "${RD}The following containers require a reboot:${CL}"
  for container_name in "${containers_needing_reboot[@]}"; do
    echo "$container_name"
  done
fi
echo ""
