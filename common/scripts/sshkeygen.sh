#!/bin/bash
## (c) Anirudh Acharya 2024, 2025, 2026
## Generate, copy, and clean up SSH keys on local and remote servers

# Determine if the script is being sourced or executed directly
if (return 0 2>/dev/null); then
  IS_SOURCED=1
else
  IS_SOURCED=0
fi

if [ "$IS_SOURCED" -eq 1 ] && [ -n "${SOURCED_SSHKEYGEN:-}" ]; then
  return 0
fi
SOURCED_SSHKEYGEN=1

# Source helpers and hosts if available
ALIASES_DIR="${ALIASES_HOME:-$HOME}"
if [ -f "${ALIASES_DIR}/.helperfuncs" ]; then
  # shellcheck source=/dev/null
  source "${ALIASES_DIR}/.helperfuncs"
fi
if [ -f "${HOME}/.aliases_hosts" ]; then
  # shellcheck source=/dev/null
  source "${HOME}/.aliases_hosts"
fi

show_help() {
  echo "Usage: $0 [gen|--generate] [-f|--force] [--local|--remote] [--purge-old] [ed25519|ecdsa|rsa]"
  echo "  -gen, --generate  Generate new SSH key and copy to servers."
  echo "  -f, --force       Force overwrite keys on the server."
  echo "  --local           Copy keys to local servers only (default)."
  echo "  --remote          Copy keys to remote servers only."
  echo "  --purge-old       Safely strip stale 'ssh-rsa' lines from servers during copy."
  echo "  -h, --help        Show this help message."
  echo
  echo "By default, keys are copied to local servers if key generation or copy is chosen."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  if [ "$IS_SOURCED" -eq 1 ]; then return 0; else exit 0; fi
fi

# Defaults
SSHKEY_FILE="${HOME}/.ssh/id_ed25519"
FORCE_FLAG=""
LOCAL_FLAG=false
REMOTE_FLAG=false
PURGE_OLD=false
ALGO_CHOICE=""
GENERATE_KEY=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
  -gen | --generate | gen)
    GENERATE_KEY=true
    ;;
  -f | --force)
    FORCE_FLAG="-f"
    ;;
  --local)
    LOCAL_FLAG=true
    ;;
  --remote)
    REMOTE_FLAG=true
    ;;
  --purge-old)
    PURGE_OLD=true
    ;;
  ed25519 | ecdsa | rsa)
    ALGO_CHOICE="$arg"
    ;;
  esac
done

# If neither --local nor --remote was explicitly set, default to local servers
if [ "$LOCAL_FLAG" = false ] && [ "$REMOTE_FLAG" = false ]; then
  LOCAL_FLAG=true
fi

if [ "$GENERATE_KEY" = true ]; then
  # Flush existing active keys from ssh-agent
  echo "==> Flushing local ssh-agent active memory cache..."
  ssh-add -D 2>/dev/null || true

  # Interactive prompt to choose algorithm if not specified
  if [ -z "$ALGO_CHOICE" ]; then
    echo "Select SSH Key Algorithm to generate:"
    echo "1) Ed25519 (Recommended: modern, secure, fast, native OpenWrt/DD-WRT/Linux support)"
    echo "2) ECDSA (nistp521)"
    echo "3) RSA (4096-bit legacy compatibility)"
    read -r -p "Enter choice [1, 2, or 3] (default 1): " choice
    case "$choice" in
    2) ALGO_CHOICE="ecdsa" ;;
    3) ALGO_CHOICE="rsa" ;;
    *) ALGO_CHOICE="ed25519" ;;
    esac
  fi

  case "$ALGO_CHOICE" in
  ed25519)
    SSHKEY_FILE="${HOME}/.ssh/id_ed25519"
    echo "==> Generating Ed25519 key pair..."
    ssh-keygen -t ed25519 -a 100 -f "$SSHKEY_FILE"
    ;;
  ecdsa)
    SSHKEY_FILE="${HOME}/.ssh/id_ecdsa"
    echo "==> Generating ECDSA (nistp521) key pair..."
    ssh-keygen -t ecdsa -b 521 -f "$SSHKEY_FILE"
    ;;
  rsa)
    SSHKEY_FILE="${HOME}/.ssh/id_rsa"
    echo "==> Generating RSA (4096-bit) key pair..."
    ssh-keygen -t rsa -b 4096 -f "$SSHKEY_FILE"
    ;;
  esac
else
  # Auto-detect existing key file by priority: Ed25519 > ECDSA > RSA
  if [ -f "${HOME}/.ssh/id_ed25519" ]; then
    SSHKEY_FILE="${HOME}/.ssh/id_ed25519"
  elif [ -f "${HOME}/.ssh/id_ecdsa" ]; then
    SSHKEY_FILE="${HOME}/.ssh/id_ecdsa"
  elif [ -f "${HOME}/.ssh/id_rsa" ]; then
    SSHKEY_FILE="${HOME}/.ssh/id_rsa"
  fi
fi

if [ ! -f "${SSHKEY_FILE}.pub" ]; then
  echo "Error: Public key '${SSHKEY_FILE}.pub' not found. Run with -gen to create one." >&2
  if [ "$IS_SOURCED" -eq 1 ]; then return 1; else exit 1; fi
fi

# Array of local servers to copy keys to
servers=(
  "${SSHROOT:-root}@${PVESERVER:-10.100.10.50}"
  "${SSHROOT:-root}@${PVEVENTOY:-10.100.10.71}"
  "${SSHROOT:-root}@${PVEWG:-10.100.10.63}"
  "${SSHROOT:-root}@${PVEVEGA:-10.100.10.61}"
  "${SSHROOT:-root}@${PVEBLANKA:-10.100.10.62}"
  "${SSHROOT:-root}@${PVEHA:-10.100.10.64}"
  "${SSHROOT:-root}@${PVESAGAT:-10.100.10.66}"
  "${SSHROOT:-root}@${PVEJF:-10.100.10.60}"
  "${SSHROOT:-root}@${PVEKUMA:-10.100.10.67}"
  "${SSHROOT:-root}@${PVELMS:-10.100.10.68}"
  "${SSHROOT:-root}@${PVEIMM:-10.100.10.69}"
  "${SSHNONROOT:-anirudh}@${PVEUBUNTU:-10.100.10.65}"
  "${SSHROOT:-root}@${PVEUBUNTU:-10.100.10.65}"
  "${SSHROOT:-root}@${PVETS:-10.100.10.70}"
)

# Array of remote servers to copy keys to (supports optional leading -p <port>)
remote_servers=(
  "-p ${ROUTERSSHPORT:-6666} ${SSHADMIN:-admin}@${R_ASUSROUTER:-10.100.100.1}"
  "${SSHROOT:-root}@${R_PVE:-10.100.100.10}"
  "${SSHROOT:-root}@${R_PVEDOCKER:-10.100.100.20}"
  "${SSHROOT:-root}@${R_PVEDOCKERLXC:-10.100.100.24}"
  "${SSHROOT:-root}@${R_PVENAVI:-10.100.100.21}"
  "${SSHROOT:-root}@${R_PVELMS:-10.100.100.22}"
  "${SSHROOT:-root}@${R_PVEJF:-10.100.100.23}"
  "${SSHROOT:-root}@${R_PVEST:-10.100.100.25}"
  "${SSHROOT:-root}@${R_PVEMEMOS:-10.100.100.26}"
  "${SSHROOT:-root}@${R_PVEOT:-10.100.100.27}"
)

# Helper function to clear old keys and inject new keys cleanly
deploy_and_clean() {
  local entry="$1"
  local target_server=""
  local ssh_port_args=()

  # Parse out leading -p <port> options if present
  if [[ "$entry" =~ ^-p[[:space:]]+([0-9]+)[[:space:]]+(.*)$ ]]; then
    ssh_port_args=(-p "${BASH_REMATCH[1]}")
    target_server="${BASH_REMATCH[2]}"
  else
    target_server="$entry"
  fi

  # DD-WRT manual key configuration alert
  if [ -n "${DDWRTROUTER:-}" ] && [[ "$target_server" == *"${DDWRTROUTER}"* ]]; then
    echo "--> [DD-WRT Alert]: Skipping automated injection for ${DDWRTROUTER}."
    echo "    Please manually copy this key string into its Web GUI Authorized Keys:"
    echo "    $(cat "${SSHKEY_FILE}.pub")"
    echo "--------------------------------------------------------"
    return 0
  fi

  # Safely clear old deprecated ssh-rsa keys if requested
  if [ "$PURGE_OLD" = true ]; then
    echo "--> Removing old 'ssh-rsa' lines from: $target_server"
    ssh -o ConnectTimeout=5 "${ssh_port_args[@]}" "$target_server" "sed -i '/ssh-rsa/d' ~/.ssh/authorized_keys" 2>/dev/null || true
  fi

  # Deploy the public key
  echo "--> Copying key to: $target_server"
  # shellcheck disable=SC2086
  ssh-copy-id $FORCE_FLAG "${ssh_port_args[@]}" -i "${SSHKEY_FILE}.pub" "$target_server" || {
    echo "Warning: Could not copy key to $target_server" >&2
  }
}

# Process Local Infrastructure
if [ "$LOCAL_FLAG" = true ]; then
  echo "==> Targeting Local Nodes via: ${SSHKEY_FILE}.pub"
  for server in "${servers[@]}"; do
    deploy_and_clean "$server"
  done
fi

# Process Remote Infrastructure
if [ "$REMOTE_FLAG" = true ]; then
  echo "==> Targeting Remote Nodes via: ${SSHKEY_FILE}.pub"
  for server in "${remote_servers[@]}"; do
    deploy_and_clean "$server"
  done
fi

# Run ssh-agent and register key if not already managed
if [ -f "$SSHKEY_FILE" ]; then
  agent_running=0
  if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    ssh-add -l >/dev/null 2>&1
    exit_code=$?
    # Exit code 0 means keys present, 1 means no keys, 2 means agent unreachable
    if [ "$exit_code" -ne 2 ]; then
      agent_running=1
    fi
  fi

  if [ "$agent_running" -eq 0 ]; then
    eval "$(ssh-agent -s)"
  fi

  if [ "$(uname)" = "Darwin" ]; then
    ssh-add --apple-use-keychain "${SSHKEY_FILE}" 2>/dev/null || ssh-add "${SSHKEY_FILE}"
  else
    ssh-add "${SSHKEY_FILE}"
  fi
fi

echo "==> SSH key operation complete!"
