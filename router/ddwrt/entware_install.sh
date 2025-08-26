#!/bin/sh
# This script installs entware on DDWRT/OpenWRT
# (c) 2025 Anirudh Acharya

# Ensure we are running from dotfiles/router/ddwrt
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
if [ "$PWD" != "$SCRIPT_DIR" ]; then
  echo "Error: Please run this script from: $SCRIPT_DIR" >&2
  exit 1
fi
if [ "$(basename "$SCRIPT_DIR")" != "ddwrt" ] || \
   [ "$(basename "$(dirname "$SCRIPT_DIR")")" != "router" ] || \
   [ "$(basename "$(dirname "$(dirname "$SCRIPT_DIR")")")" != "dotfiles" ]; then
  echo "Error: Script must be run and reside under .../dotfiles/router/ddwrt" >&2
  exit 1
fi

# Source helper functions via relative path
if [ -f "../../home/.helperfuncs" ]; then
  . "../../home/.helperfuncs"
else
  echo "Error: ../../home/.helperfuncs not found" >&2
  exit 1
fi

# debugLog / error etc. functions can only be used after sourcing helperfuncs
# Detect CPU architecture using the merged function
CPU_ARCH="$(detect_arch_type)"

# Build per-arch Entware installer URL or exit if unsupported
case "$CPU_ARCH" in
  mips)  # mips is big endian
    ENTWARE_URL="http://bin.entware.net/mipssf-k3.4/installer/generic.sh" ;
    debuglog "mips: ${ENTWARE_URL}" ;;
  mipsel)   # mipsel is little endian
    ENTWARE_URL="http://bin.entware.net/mipselsf-k3.4/installer/generic.sh" ;
    debuglog "mipsel: ${ENTWARE_URL}" ;;
  armv5)  # armv5 family
    ENTWARE_URL="http://bin.entware.net/armv5sf-k3.2/installer/generic.sh" ;
    debuglog "armv5 family (${CPU_ARCH}): ${ENTWARE_URL}" ;;
  armv7|armv7l|armv7h)  # armv7 family
    ENTWARE_URL="http://bin.entware.net/armv7sf-k3.2/installer/generic.sh" ;
    debuglog "armv7 family (${CPU_ARCH}): ${ENTWARE_URL}" ;;
  aarch64)  # arm64
    ENTWARE_URL="http://bin.entware.net/aarch64-k3.10/installer/generic.sh" ;
    debuglog "arm64: ${ENTWARE_URL}" ;;
  unsupported|unknown|*)
    error "entware is unsupported for this platform ($CPU_ARCH)." ;;
 esac
