#!/bin/bash
# Script to bootstrap linux installation to a fresh storage device, mounted to /mnt/rootfs
# Usage: ./bootstrap_rootfs.sh [SOURCE_HOST] [ROOTFS_PATH]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Default values
SOURCE_HOST="${1:-localhost}"
ROOTFS="${2:-/mnt/rootfs}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [SOURCE_HOST] [ROOTFS_PATH]

Bootstrap a Linux installation to a fresh storage device.

Arguments:
  SOURCE_HOST    Source host to sync from (default: localhost)
  ROOTFS_PATH    Path where rootfs is mounted (default: /mnt/rootfs)

Examples:
  $0                      # Use defaults
  $0 ifc6410              # Sync from ifc6410 host
  $0 ifc6410 /mnt/rootfs  # Sync from ifc6410 to /mnt/rootfs

EOF
}

# Check if help is requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

# Validation functions
validate_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

validate_mount() {
    if [[ ! -d "$ROOTFS" ]]; then
        error "Rootfs directory $ROOTFS does not exist"
    fi
    
    if ! mountpoint -q "$ROOTFS"; then
        error "Rootfs directory $ROOTFS is not mounted"
    fi
}

validate_source() {
    if [[ "$SOURCE_HOST" != "localhost" ]]; then
        if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$SOURCE_HOST" exit 2>/dev/null; then
            error "Cannot connect to source host $SOURCE_HOST"
        fi
    fi
}

# Cleanup function
cleanup() {
    log "Cleaning up bind mounts..."
    umount -l "${ROOTFS}/proc" 2>/dev/null || true
    umount -l "${ROOTFS}/sys" 2>/dev/null || true
    umount -l "${ROOTFS}/dev" 2>/dev/null || true
    umount -l "${ROOTFS}/run" 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    log "Starting bootstrap process..."
    log "Source: $SOURCE_HOST"
    log "Target: $ROOTFS"
    
    # Validate prerequisites
    validate_root
    validate_mount
    validate_source
    
    ###################
    log "Stage 1: Initial file sync..."
    ###################
    
    # Build rsync source path
    if [[ "$SOURCE_HOST" == "localhost" ]]; then
        SOURCE_PATH="/"
    else
        SOURCE_PATH="$SOURCE_HOST:/"
    fi
    
    # Enhanced rsync with better exclusions and error handling
    rsync -avP --numeric-ids \
        --exclude='/dev' \
        --exclude='/proc' \
        --exclude='/sys' \
        --exclude='/tmp' \
        --exclude='/var/tmp' \
        --exclude='/var/log' \
        --exclude='/var/cache' \
        --exclude='/var/lib/apt/lists' \
        --exclude='/run' \
        --exclude='/mnt' \
        --exclude='/media' \
        --exclude='/lost+found' \
        --exclude='.cache' \
        --exclude='.Trash*' \
        "$SOURCE_PATH" "$ROOTFS/" || error "rsync failed"
    
    ###################
    log "Stage 2: Setting up system directories..."
    ###################
    
    # Create and mount system directories
    mount --make-rslave --rbind /proc "${ROOTFS}/proc" || error "Failed to mount /proc"
    mount --make-rslave --rbind /sys "${ROOTFS}/sys" || error "Failed to mount /sys"
    mount --make-rslave --rbind /dev "${ROOTFS}/dev" || error "Failed to mount /dev"
    mount --make-rslave --rbind /run "${ROOTFS}/run" || error "Failed to mount /run"
    
    ###################
    log "Stage 3: Copying configuration files..."
    ###################
    
    # Copy essential configuration files
    local config_files=(
        "/etc/fstab"
        "/etc/ssh/sshd_config"
        "/etc/ssh/ssh_config"
        "/etc/NetworkManager"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -e "$file" ]]; then
            cp -a "$file" "${ROOTFS}${file}" || warn "Failed to copy $file"
        else
            warn "Source file $file does not exist"
        fi
    done
    
    ###################
    log "Stage 4: Copying kernel modules and firmware..."
    ###################
    
    # Copy kernel modules and firmware
    mkdir -p "${ROOTFS}/lib/modules"
    mkdir -p "${ROOTFS}/lib/firmware"
    
    if [[ -d "/lib/modules" ]]; then
        cp -a /lib/modules/* "${ROOTFS}/lib/modules/" || warn "Failed to copy kernel modules"
    fi
    
    if [[ -d "/lib/firmware" ]]; then
        cp -a /lib/firmware/* "${ROOTFS}/lib/firmware/" || warn "Failed to copy firmware"
    fi
    
    ###################
    log "Stage 5: Copying custom configuration..."
    ###################
    
    # Copy custom etc files if they exist
    if [[ -d "./etc" ]]; then
        cp -a ./etc/* "${ROOTFS}/etc/" || warn "Failed to copy custom etc files"
    else
        warn "Custom etc directory not found"
    fi
    
    ###################
    log "Bootstrap completed successfully!"
    log "Next steps:"
    log "1. chroot ${ROOTFS}"
    log "2. Install essential packages:"
    log "   apt update && apt install -y btop ssh ca-certificates tmux duf nano sudo"
    log "   apt install -y console-setup console-setup-linux network-manager wget curl"
    log "   apt install -y lsb-release locales iw net-tools systemd-timesyncd"
    log "3. Configure system:"
    log "   dpkg-reconfigure tzdata"
    log "   dpkg-reconfigure locales"
    ###################
}

# Run main function
main "$@"
