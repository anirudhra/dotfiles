#!/bin/bash
# Docker installation script for SBC (Single Board Computer) systems
# Supports Debian-based systems with proper iptables configuration

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_GPG_URL="https://download.docker.com/linux/debian/gpg"
DOCKER_REPO_URL="https://download.docker.com/linux/debian"
DOCKER_GPG_KEY="/etc/apt/keyrings/docker.asc"
DOCKER_REPO_FILE="/etc/apt/sources.list.d/docker.list"

# Logging functions
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Install Docker on Debian-based SBC systems with proper configuration.

Options:
  -h, --help          Show this help message
  -v, --version       Show version information
  --skip-iptables     Skip iptables-legacy configuration
  --skip-user         Skip adding current user to docker group

Examples:
  $0                    # Full installation with all configurations
  $0 --skip-iptables   # Skip iptables configuration
  $0 --skip-user       # Skip user group configuration

EOF
}

# Version function
show_version() {
    echo "Docker Install Script v2.0"
    echo "Compatible with Debian-based SBC systems"
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
SKIP_IPTABLES=false
SKIP_USER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-iptables)
            SKIP_IPTABLES=true
            shift
            ;;
        --skip-user)
            SKIP_USER=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validation functions
validate_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
    fi
    
    source /etc/os-release
    if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
        warn "This script is designed for Debian-based systems. Detected: $ID"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log "Detected OS: $PRETTY_NAME"
}

validate_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

check_docker_installed() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        warn "Docker is already installed: $DOCKER_VERSION"
        read -p "Reinstall Docker? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Installation cancelled"
            exit 0
        fi
    fi
}

# Installation functions
install_prerequisites() {
    log "Installing prerequisites..."
    
    apt-get update || error "Failed to update package list"
    
    local packages=(
        "ca-certificates"
        "curl"
        "gnupg"
        "lsb-release"
        "software-properties-common"
        "apt-transport-https"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log "Installing $package..."
            apt-get install -y "$package" || error "Failed to install $package"
        else
            log "Package $package already installed"
        fi
    done
}

setup_docker_repository() {
    log "Setting up Docker repository..."
    
    # Create keyrings directory
    install -m 0755 -d /etc/apt/keyrings || error "Failed to create keyrings directory"
    
    # Download and install Docker's GPG key
    log "Downloading Docker GPG key..."
    if ! curl -fsSL "$DOCKER_GPG_URL" -o "$DOCKER_GPG_KEY"; then
        error "Failed to download Docker GPG key"
    fi
    
    chmod a+r "$DOCKER_GPG_KEY" || error "Failed to set GPG key permissions"
    
    # Add Docker repository
    log "Adding Docker repository..."
    local arch
    arch=$(dpkg --print-architecture)
    
    source /etc/os-release
    local codename="$VERSION_CODENAME"
    
    echo "deb [arch=$arch signed-by=$DOCKER_GPG_KEY] $DOCKER_REPO_URL $codename stable" | \
        tee "$DOCKER_REPO_FILE" > /dev/null || error "Failed to add Docker repository"
    
    # Update package list
    apt-get update || error "Failed to update package list after adding repository"
}

install_docker() {
    log "Installing Docker..."
    
    local docker_packages=(
        "docker-ce"
        "docker-ce-cli"
        "containerd.io"
        "docker-buildx-plugin"
        "docker-compose-plugin"
    )
    
    for package in "${docker_packages[@]}"; do
        log "Installing $package..."
        if ! apt-get install -y "$package"; then
            error "Failed to install $package"
        fi
    done
}

configure_iptables() {
    if [[ "$SKIP_IPTABLES" == "true" ]]; then
        warn "Skipping iptables configuration as requested"
        return
    fi
    
    log "Configuring iptables for Docker compatibility..."
    
    # Check if iptables-legacy alternatives exist
    if ! update-alternatives --list iptables 2>/dev/null | grep -q "iptables-legacy"; then
        warn "iptables-legacy not available, Docker may not work properly on this system"
        return
    fi
    
    # Set iptables to legacy mode for Docker compatibility
    update-alternatives --set iptables /usr/sbin/iptables-legacy || \
        warn "Failed to set iptables to legacy mode"
    
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || \
        warn "Failed to set ip6tables to legacy mode"
    
    log "iptables configured for Docker compatibility"
}

configure_docker_service() {
    log "Configuring Docker service..."
    
    # Enable Docker service
    systemctl enable docker || error "Failed to enable Docker service"
    
    # Start Docker service
    systemctl start docker || error "Failed to start Docker service"
    
    # Verify Docker is running
    if ! systemctl is-active --quiet docker; then
        error "Docker service failed to start"
    fi
    
    log "Docker service is running"
}

configure_user() {
    if [[ "$SKIP_USER" == "true" ]]; then
        warn "Skipping user configuration as requested"
        return
    fi
    
    # Get the user who ran sudo (if applicable)
    local real_user
    if [[ -n "${SUDO_USER:-}" ]]; then
        real_user="$SUDO_USER"
    elif [[ -n "${USER:-}" ]]; then
        real_user="$USER"
    else
        warn "Cannot determine real user, skipping user configuration"
        return
    fi
    
    log "Adding user '$real_user' to docker group..."
    
    # Add user to docker group
    usermod -aG docker "$real_user" || error "Failed to add user to docker group"
    
    info "User '$real_user' added to docker group"
    warn "You may need to log out and back in for group changes to take effect"
}

verify_installation() {
    log "Verifying Docker installation..."
    
    # Check Docker version
    if ! docker --version; then
        error "Docker installation verification failed"
    fi
    
    # Test Docker functionality
    if ! docker run --rm hello-world > /dev/null 2>&1; then
        warn "Docker hello-world test failed, but installation may still be functional"
    else
        log "Docker hello-world test passed"
    fi
    
    # Show Docker info
    log "Docker installation verified successfully"
    info "Docker version: $(docker --version)"
    info "Docker compose version: $(docker compose version --short 2>/dev/null || echo 'Not available')"
}

cleanup() {
    log "Cleaning up..."
    apt-get autoremove -y || true
    apt-get autoclean || true
}

# Main execution
main() {
    log "Starting Docker installation for SBC..."
    
    # Validate environment
    validate_os
    validate_root
    check_docker_installed
    
    # Installation steps
    install_prerequisites
    setup_docker_repository
    install_docker
    configure_iptables
    configure_docker_service
    configure_user
    verify_installation
    cleanup
    
    log "Docker installation completed successfully!"
    info "Next steps:"
    info "1. Log out and back in to apply group changes"
    info "2. Test Docker: docker run hello-world"
    info "3. Consider setting up Docker Compose for container orchestration"
}

# Run main function
main "$@"
