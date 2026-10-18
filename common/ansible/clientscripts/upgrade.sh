#!/bin/bash
# (c) Anirudh Acharya 2025, 2026
# Upgrades Debian/Ubuntu systems and active Docker compose stacks safely
# Intended to be run on PVE server and guests
set -euo pipefail

fullclean() {
  export DEBIAN_FRONTEND=noninteractive
  echo "==> Cleaning package cache and unused packages..."
  sudo apt-get clean
  sudo apt-get autoclean
  sudo apt-get autoremove -y --purge
}

fullupdate() {
  export DEBIAN_FRONTEND=noninteractive
  echo "==> Updating package repositories and upgrading distribution packages..."
  sudo apt-get update
  sudo apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

  # PVE server only: firmware updates
  if command -v pveversion >/dev/null 2>&1 && command -v fwupdmgr >/dev/null 2>&1; then
    echo "==> Checking hardware firmware updates via fwupdmgr..."
    sudo fwupdmgr refresh --force && sudo fwupdmgr get-updates && sudo fwupdmgr update -y || true
  fi
}

# Intended to be run on PVE guests / SBCs only
dockerupdateall() {
  # Ensure it is not the PVE hypervisor host, and docker is installed
  if command -v pveversion >/dev/null 2>&1 || ! command -v docker >/dev/null 2>&1; then
    return 0
  fi

  local host_name
  host_name="$(hostname -s | tr '[:upper:]' '[:lower:]')"
  local app_dir="/mnt/pve-sata-ssd/ssd-data/dockerapps/${host_name}"

  if [ "$host_name" = "ifc6410" ]; then
    app_dir="/opt/dockerapps"
  fi

  if [ ! -d "$app_dir" ]; then
    echo "==> No docker apps directory found at '$app_dir', skipping docker update."
    return 0
  fi

  echo "==> Updating Docker Compose stacks in '$app_dir'..."
  while IFS= read -r -d '' compose_dir; do
    echo "--> Updating stack: $(basename "$compose_dir")"
    (
      cd "$compose_dir" || exit 1
      # Update containers in-place: pulls new images and recreates only changed containers.
      # Does NOT run 'docker compose down' to avoid downtime and prevent volume wipe hazards.
      docker compose pull
      docker compose up -d --remove-orphans
    )
  done < <(find "$app_dir" -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -path '*disabled*' -print0)

  # Prune dangling/unused images only.
  # NEVER run 'docker system prune --volumes' here to protect persistent databases and named volumes!
  echo "==> Pruning obsolete Docker images..."
  docker image prune -f
}

# Main execution
fullupdate
fullclean
dockerupdateall
echo "==> Upgrade complete!"
