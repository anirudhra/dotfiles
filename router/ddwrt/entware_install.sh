#!/bin/sh
# This script installs entware on DDWRT/OpenWRT
# (c) 2025 Anirudh Acharya

# Locate script directory and source helper functions
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if [ -f "${SCRIPT_DIR}/../../home/.helperfuncs" ]; then
  . "${SCRIPT_DIR}/../../home/.helperfuncs"
elif [ -f "${HOME}/dotfiles/home/.helperfuncs" ]; then
  . "${HOME}/dotfiles/home/.helperfuncs"
elif [ -f "/opt/root/dotfiles/home/.helperfuncs" ]; then
  . "/opt/root/dotfiles/home/.helperfuncs"
else
  echo "Error: .helperfuncs not found" >&2
  exit 1
fi

# Function definitions
# Download entware installer based on detected architecture and install
install_entware() {
  #run installer
  OPTWARE_DIR="/opt" # change if optware/entware/USB mount is different
  INSTALLER_FILE="entware_installer.sh"

  if [ -z "${ENTWARE_URL}" ]; then
    error "Entware URL is empty. Check for errors and fix them."
    exit 1
  fi

  # download and run installer
  cd "${OPTWARE_DIR}" || { error "Failed to change to ${OPTWARE_DIR}"; exit 1; }
  rm -f "${INSTALLER_FILE}" || { error "Failed to remove existing installer"; exit 1; }
  info "Downloading installer..."
  curl -L -o "${INSTALLER_FILE}" "${ENTWARE_URL}" || { error "Failed to download installer"; exit 1; }

  # run installer
  info "Running installer..."
  sh "${INSTALLER_FILE}" || { error "Failed to run installer"; exit 1; }

  # remove installer
  rm -f "${INSTALLER_FILE}"
}

# Post-installation menu for package management
post_install_menu() {
  echo
  echo "Package install options:"
  echo "  1) Install packages from ${SCRIPT_DIR}/entware_packages.txt"
  echo "  2) Install packages from ~/local_entware_packages.txt (create a temporary list locally)"
  echo "  3) Quit"
  echo
  read -p "Enter your choice (1, 2 or 3): " choice

  case "$choice" in
  1)
    info "Installing packages from entware_packages.txt..."
    if [ -f "${SCRIPT_DIR}/entware_packages.txt" ]; then
      while IFS= read -r package; do
        opkg install "$package" || error "Failed to install $package"
      done <"${SCRIPT_DIR}/entware_packages.txt" || error "Failed to install packages"
      info "Package installation complete."
    else
      error "entware_packages.txt not found in ${SCRIPT_DIR}"
    fi
    ;;
  2)
    info "Installing packages from ~/local_entware_packages.txt..."
    if [ -f "${HOME}/local_entware_packages.txt" ]; then
      while IFS= read -r package; do
        opkg install "$package" || error "Failed to install $package"
      done <"${HOME}/local_entware_packages.txt" || error "Failed to install packages"
      info "Package installation complete."
    else
      error "local_entware_packages.txt not found in ${HOME}"
    fi
    ;;
  3)
    info "Quitting as requested."
    exit 0
    ;;
  *)
    error "Invalid choice. Please run the script again and select 1, 2, or 3."
    ;;
  esac
}

# Main script logic
echo
echo "###########################################################"
info "Entware installer script"
echo "###########################################################"

# check if entware is already installed
if command -v opkg >/dev/null 2>&1 && opkg list-installed 2>/dev/null | grep -q "entware"; then
  info "entware is already installed."
  post_install_menu
  exit 0
fi

# debugLog / error etc. functions can only be used after sourcing helperfuncs
# Detect CPU architecture using the merged function
CPU_ARCH="$(detect_arch_type)"
ENTWARE_URL=""

# Build per-arch Entware installer URL or exit if unsupported
case "$CPU_ARCH" in
mips) # mips is big endian
  ENTWARE_URL="http://bin.entware.net/mipssf-k3.4/installer/generic.sh"
  debuglog "mips: ${ENTWARE_URL}"
  ;;
mipsel) # mipsel is little endian
  ENTWARE_URL="http://bin.entware.net/mipselsf-k3.4/installer/generic.sh"
  debuglog "mipsel: ${ENTWARE_URL}"
  ;;
armv5) # armv5 family
  ENTWARE_URL="http://bin.entware.net/armv5sf-k3.2/installer/generic.sh"
  debuglog "armv5 family (${CPU_ARCH}): ${ENTWARE_URL}"
  ;;
armv7 | armv7l | armv7h) # armv7 family
  ENTWARE_URL="http://bin.entware.net/armv7sf-k3.2/installer/generic.sh"
  debuglog "armv7 family (${CPU_ARCH}): ${ENTWARE_URL}"
  ;;
aarch64) # arm64
  ENTWARE_URL="http://bin.entware.net/aarch64-k3.10/installer/generic.sh"
  debuglog "arm64: ${ENTWARE_URL}"
  ;;
unsupported | unknown | *)
  error "entware is unsupported for this platform ($CPU_ARCH)."
  exit 1
  ;;
esac

# Install entware
install_entware

# update database
info "Updating database..."
opkg update
opkg upgrade

info "Entware installation complete."
echo
info "Add the following lines to router's startup script section: Administration > Commands > Startup section:"
echo
echo "##### Entware initialization #####"
echo "sleep 10"
echo "/opt/etc/init.d/rc.unslung start"
echo "##################################"
echo
read -p "Press any key to continue..."

# Show post-installation menu
post_install_menu

exit 0
