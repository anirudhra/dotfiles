#!/bin/bash
# Kernel module installation script for SBC (Single Board Computer) systems
# Safely installs kernel modules from build artifacts with proper validation

# original code for backup/reference
#cd /lib/modules
#cp /mnt/nfs/sata-ssd/ssd-data/backup/ifc6410/github/poky/build/qcom-armv7a/artifacts/modules* .
#tar xvf modules*.tgz
#cd ./lib/modules
#mv 6.6* /lib/modules
#cd /lib/modules
#rmdir /lib/modules/lib/modules
#rmdir /lib/modules/lib

source "../../home/.helperfuncs"

set -euo pipefail # Exit on error, undefined vars, pipe failures

# Configuration
MODULES_DIR="/lib/modules"
BACKUP_DIR="/tmp/kernel_modules_backup"
BUILD_ARTIFACTS_DIR="/mnt/nfs/sata-ssd/ssd-data/backup/ifc6410/github/poky/build/qcom-armv7a/artifacts"
MODULES_PATTERN="modules*.tgz"
# leave kernel version empty to copy whatever is available, else put specific number
KERNEL_VER=''

# Help function
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Install kernel modules from build artifacts for SBC systems.

Options:
  -h, --help              Show this help message
  -v, --version           Show version information
  -s, --source DIR        Source directory for modules (default: ${BUILD_ARTIFACTS_DIR})
  -d, --dest DIR          Destination directory (default: ${MODULES_DIR})
  -k, --kernel VERSION    Specific kernel version to install (default ${KERNEL_VER}
  --no-backup             Skip creating backup of existing modules
  --force                 Force installation without confirmation
  --dry-run               Show what would be done without making changes

Examples:
  $0                                    # Install with defaults
  $0 -s /path/to/artifacts             # Use custom source directory
  $0 -k 6.6.0                          # Install specific kernel version
  $0 --dry-run                         # Preview installation
  $0 --no-backup --force               # Install without backup or confirmation

EOF
}

# Version function
show_version() {
  echo "Kernel Module Install Script v2.0"
}

# Check if help or version is requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

if [[ "${1:-}" == "-v" || "${1:-}" == "--version" ]]; then
  show_version
  exit 0
fi

# Parse command line arguments
SOURCE_DIR="${BUILD_ARTIFACTS_DIR}"
DEST_DIR="${MODULES_DIR}"
KERNEL_VERSION="${KERNEL_VER}"
NO_BACKUP=true
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -s | --source)
    SOURCE_DIR="$2"
    shift 2
    ;;
  -d | --dest)
    DEST_DIR="$2"
    shift 2
    ;;
  -k | --kernel)
    KERNEL_VERSION="$2"
    shift 2
    ;;
  --no-backup)
    NO_BACKUP=true
    shift
    ;;
  --force)
    FORCE=true
    shift
    ;;
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  *)
    error "Unknown option: $1"
    ;;
  esac
done

# Validation functions
validate_root() {
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
  fi
}

validate_source() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    error "Source directory does not exist: $SOURCE_DIR"
  fi

  # Check for modules archive
  local modules_file
  modules_file=$(find "$SOURCE_DIR" -name "$MODULES_PATTERN" -print -quit)

  if [[ -z "$modules_file" ]]; then
    error "No modules archive found in $SOURCE_DIR matching pattern: $MODULES_PATTERN"
  fi

  log "Found modules archive: $modules_file"
  MODULES_ARCHIVE="$modules_file"
}

validate_destination() {
  if [[ ! -d "$DEST_DIR" ]]; then
    error "Destination directory does not exist: $DEST_DIR"
  fi

  if [[ ! -w "$DEST_DIR" ]]; then
    error "Destination directory is not writable: $DEST_DIR"
  fi
}

show_config() {
  info "Source directory: ${SOURCE_DIR}"
  info "Destination directory: ${DEST_DIR}"
  info "Kernel version: ${KERNEL_VERSION}"
  info "Backup: ${NO_BACKUP}"
  info "Force: ${FORCE}"
  info "Dry run: ${DRY_RUN}"
}

check_existing_modules() {
  if [[ -n "$KERNEL_VERSION" ]]; then
    if [[ -d "$DEST_DIR/$KERNEL_VERSION" ]]; then
      warn "Kernel modules for version $KERNEL_VERSION already exist"
      if [[ "$FORCE" != "true" ]]; then
        read -p "Overwrite existing modules? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log "Installation cancelled"
          exit 0
        fi
      fi
    fi
  else
    # Check for any existing modules
    local existing_modules
    existing_modules=$(find "$DEST_DIR" -maxdepth 1 -type d -name "[0-9]*" | head -1)
    if [[ -n "$existing_modules" ]]; then
      warn "Existing kernel modules found: $(basename "$existing_modules")"
      if [[ "$FORCE" != "true" ]]; then
        read -p "Continue with installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log "Installation cancelled"
          exit 0
        fi
      fi
    fi
  fi
}

# Installation functions
create_backup() {
  if [[ "$NO_BACKUP" == "true" ]]; then
    warn "Skipping backup as requested"
    return
  fi

  log "Creating backup of existing modules..."

  if [[ "$DRY_RUN" == "true" ]]; then
    info "DRY RUN: Would create backup in $BACKUP_DIR"
    return
  fi

  # Create backup directory
  mkdir -p "$BACKUP_DIR" || error "Failed to create backup directory"

  # Backup existing modules
  if [[ -n "$KERNEL_VERSION" ]]; then
    if [[ -d "$DEST_DIR/$KERNEL_VERSION" ]]; then
      cp -a "$DEST_DIR/$KERNEL_VERSION" "$BACKUP_DIR/" ||
        warn "Failed to backup kernel modules for $KERNEL_VERSION"
    fi
  else
    # Backup all kernel modules
    find "$DEST_DIR" -maxdepth 1 -type d -name "[0-9]*" -exec cp -a {} "$BACKUP_DIR/" \; ||
      warn "Failed to backup existing kernel modules"
  fi

  log "Backup created in: $BACKUP_DIR"
}

extract_modules() {
  log "Extracting kernel modules..."

  if [[ "$DRY_RUN" == "true" ]]; then
    info "DRY RUN: Would extract $MODULES_ARCHIVE to $DEST_DIR"
    return
  fi

  # Create temporary extraction directory
  local temp_dir
  temp_dir=$(mktemp -d) || error "Failed to create temporary directory"

  # Extract modules archive
  if ! tar -xzf "$MODULES_ARCHIVE" -C "$temp_dir"; then
    rm -rf "$temp_dir"
    error "Failed to extract modules archive"
  fi

  # Find extracted modules directory
  local extracted_modules
  extracted_modules=$(find "$temp_dir" -name "lib" -type d | head -1)

  if [[ -z "$extracted_modules" ]]; then
    rm -rf "$temp_dir"
    error "Could not find extracted modules directory"
  fi

  # Move modules to destination
  local kernel_version_dir
  kernel_version_dir=$(find "$extracted_modules/modules" -maxdepth 1 -type d -name "[0-9]*" | head -1)

  if [[ -z "$kernel_version_dir" ]]; then
    rm -rf "$temp_dir"
    error "Could not find kernel version directory in extracted modules"
  fi

  local kernel_version
  kernel_version=$(basename "$kernel_version_dir")

  # If specific kernel version requested, verify it matches
  if [[ -n "$KERNEL_VERSION" && "$kernel_version" != "$KERNEL_VERSION" ]]; then
    rm -rf "$temp_dir"
    error "Extracted kernel version ($kernel_version) does not match requested version ($KERNEL_VERSION)"
  fi

  # Remove existing modules for this version if they exist
  if [[ -d "$DEST_DIR/$kernel_version" ]]; then
    rm -rf "$DEST_DIR/$kernel_version" || error "Failed to remove existing modules"
  fi

  # Move modules to destination
  mv "$kernel_version_dir" "$DEST_DIR/" || error "Failed to move modules to destination"

  # Clean up temporary directory
  rm -rf "$temp_dir"

  log "Modules extracted successfully for kernel version: $kernel_version"
  INSTALLED_KERNEL_VERSION="$kernel_version"
}

update_module_dependencies() {
  log "Updating module dependencies..."

  if [[ "$DRY_RUN" == "true" ]]; then
    info "DRY RUN: Would run depmod for $INSTALLED_KERNEL_VERSION"
    return
  fi

  if ! depmod "$INSTALLED_KERNEL_VERSION"; then
    warn "Failed to update module dependencies for $INSTALLED_KERNEL_VERSION"
  else
    log "Module dependencies updated successfully"
  fi
}

verify_installation() {
  log "Verifying module installation..."

  if [[ "$DRY_RUN" == "true" ]]; then
    info "DRY RUN: Would verify installation"
    return
  fi

  # Check if modules directory exists
  if [[ ! -d "$DEST_DIR/$INSTALLED_KERNEL_VERSION" ]]; then
    error "Module installation verification failed: directory not found"
  fi

  # Check for kernel modules
  local module_count
  module_count=$(find "$DEST_DIR/$INSTALLED_KERNEL_VERSION" -name "*.ko" | wc -l)

  if [[ $module_count -eq 0 ]]; then
    warn "No kernel modules found in installation"
  else
    log "Found $module_count kernel modules"
  fi

  # Check modules.dep file
  if [[ -f "$DEST_DIR/$INSTALLED_KERNEL_VERSION/modules.dep" ]]; then
    log "Module dependencies file created successfully"
  else
    warn "Module dependencies file not found"
  fi

  log "Module installation verified successfully"
}

cleanup_backup() {
  if [[ "$NO_BACKUP" == "true" ]]; then
    return
  fi

  read -p "Remove backup files? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing backup files..."
    rm -rf "$BACKUP_DIR" || warn "Failed to remove backup directory"
  else
    info "Backup files preserved in: $BACKUP_DIR"
  fi
}

# Main execution
main() {
  log "Starting kernel module installation..."

  # Validate environment
  validate_root
  validate_source
  validate_destination
  check_existing_modules

  if [[ "$DRY_RUN" == "true" ]]; then
    info "DRY RUN MODE: No changes will be made"
  fi

  # Installation steps
  create_backup
  extract_modules
  update_module_dependencies
  verify_installation

  if [[ "$DRY_RUN" != "true" ]]; then
    cleanup_backup
  fi

  log "Kernel module installation completed successfully!"
  info "Installed kernel version: $INSTALLED_KERNEL_VERSION"
  info "Modules location: $DEST_DIR/$INSTALLED_KERNEL_VERSION"
  info "Next steps:"
  info "1. Reboot system to load new modules"
  info "2. Check module loading: lsmod"
  info "  2a. If error, goto kernel modules directory and run: depmod -a"
  info "3. Load specific modules: modprobe <module_name>"
}

# Run main function
main "$@"
