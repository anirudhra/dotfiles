#!/bin/bash
## (c) Anirudh Acharya 2024, 2025, 2026
## generate, copy, and clean up ssh keys on servers

# Guard variable to ensure sourcing only once
if [ -n "${SOURCED_SSHKEYGEN}" ]; then
  return 0 # Exit the script if already sourced
fi

# Set the guard variable
SOURCED_SSHKEYGEN=1

# source helpers and hosts
source "${ALIASES_HOME}/.helperfuncs"
source "${HOME}/.aliases_hosts"

show_help() {
  echo "Usage: $0 [gen|--generate] [-f|--force] [--local|--remote] [--purge-old]"
  echo "  -gen, --generate  Generate new SSH key and copy to servers."
  echo "  -f, --force       Force overwrite keys on the server."
  echo "  --local           Copy keys to local servers only."
  echo "  --remote          Copy keys to remote servers only."
  echo "  --purge-old       Safely strip stale 'ssh-rsa' lines from servers during copy."
  echo "  -h, --help        Show this help message."
  echo
  echo "By default, keys are copied to local servers if key generation option is chosen."
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

# Default fallback key file
SSHKEY_FILE="${HOME}/.ssh/id_rsa"
FORCE_FLAG=""
LOCAL_FLAG=false
REMOTE_FLAG=false
PURGE_OLD=false

# Parse arguments for force flag, server types, and cleanup preferences
for arg in "$@"; do
  if [[ "$arg" == "-f" || "$arg" == "--force" ]]; then
    FORCE_FLAG="-f"
  elif [[ "$arg" == "--local" ]]; then
    LOCAL_FLAG=true
  elif [[ "$arg" == "--remote" ]]; then
    REMOTE_FLAG=true
  elif [[ "$arg" == "--purge-old" ]]; then
    PURGE_OLD=true
  fi
  # Catch custom type inputs if passed as loose arguments
  if [[ "$arg" == "rsa" ]]; then ALGO_CHOICE="rsa"; fi
  if [[ "$arg" == "ecdsa" ]]; then ALGO_CHOICE="ecdsa"; fi
done

if [[ "$1" == "-gen" || "$1" == "--generate" ]]; then
  # Flush any old key active states held in running terminal memory
  echo "Flushing local ssh-agent active memory cache..."
  ssh-add -D 2>/dev/null

  # Interactive prompt to choose algorithm if not predetermined
  if [ -z "$ALGO_CHOICE" ]; then
    echo "Select SSH Key Algorithm to generate:"
    echo "1) RSA (Legacy, high compatibility)"
    echo "2) ECDSA (Modern, secure, native DD-WRT support)"
    read -p "Enter choice [1 or 2]: " choice
    case $choice in
    1) ALGO_CHOICE="rsa" ;;
    2) ALGO_CHOICE="ecdsa" ;;
    *)
      echo "Invalid choice. Defaulting to RSA."
      ALGO_CHOICE="rsa"
      ;;
    esac
  fi

  if [[ "$ALGO_CHOICE" == "rsa" ]]; then
    SSHKEY_FILE="${HOME}/.ssh/id_rsa"
    echo "Generating RSA key pair..."
    ssh-keygen -t rsa -f "$SSHKEY_FILE"
  else
    SSHKEY_FILE="${HOME}/.ssh/id_ecdsa"
    echo "Generating ECDSA (nistp521) key pair..."
    ssh-keygen -t ecdsa -b 521 -f "$SSHKEY_FILE"
  fi
else
  # Auto-detect which key file we should prioritize using if both exist
  if [ -f "${HOME}/.ssh/id_ecdsa" ]; then
    SSHKEY_FILE="${HOME}/.ssh/id_ecdsa"
  fi
fi

# Array of local servers to copy keys to
servers=(
  #"-p ${ROUTERSSHPORT} ${SSHROOT}@${DDWRTROUTER}"
  "${SSHROOT}@${PVESERVER}"
  "${SSHROOT}@${PVEVENTOY}"
  "${SSHROOT}@${PVWG}"
  "${SSHROOT}@${PVEVEGA}"
  "${SSHROOT}@${PVEBLANKA}"
  "${SSHROOT}@${PVEHA}"
  "${SSHROOT}@${PVESAGAT}"
  "${SSHROOT}@${PVEJF}"
  "${SSHROOT}@${PVEKUMA}"
  "${SSHROOT}@${PVELMS}"
  "${SSHROOT}@${PVEIMM}"
  "${SSHNONROOT}@${PVEUBUNTU}"
  "${SSHROOT}@${PVEUBUNTU}"
  "${SSHROOT}@${PVETS}"
)

# Array of remote servers to copy keys to
remote_servers=(
  "-p ${ROUTERSSHPORT} ${SSHADMIN}@${R_ASUSROUTER}"
  "${SSHROOT}@${R_PVE}"
  "${SSHROOT}@${R_PVEDOCKER}"
  "${SSHROOT}@${R_PVEDOCKERLXC}"
  "${SSHROOT}@${R_PVENAVI}"
  "${SSHROOT}@${R_PVELMS}"
  "${SSHROOT}@${R_PVEJF}"
  "${SSHROOT}@${R_PVEST}"
  "${SSHROOT}@${R_PVEMEMOS}"
  "${SSHROOT}@${R_PVEOT}"
)

# Helper function to clear old keys and inject new keys cleanly
deploy_and_clean() {
  local target_server="$1"

  # Check if the target is your problematic DD-WRT environment
  if [[ "$target_server" == *"${DDWRTROUTER}"* ]]; then
    echo "--> [DD-WRT Alert]: Skipping automation for ${DDWRTROUTER}."
    echo "    Please manually copy the following key string into its Web GUI Authorized Keys textbox:"
    echo "    $(cat ${SSHKEY_FILE}.pub)"
    echo "--------------------------------------------------------"
    return 0
  fi

  # Safely clear old deprecated configurations if the user asked for it
  if [[ "$PURGE_OLD" == true ]]; then
    echo "Removing old 'ssh-rsa' rows from: $target_server"
    # Runs an in-place stream edit on the target machine's file matching the pattern
    ssh -o ConnectTimeout=5 "$target_server" "sed -i '/ssh-rsa/d' ~/.ssh/authorized_keys" 2>/dev/null
  fi

  # Deploy the newly generated/selected key standardly
  ssh-copy-id $FORCE_FLAG -i "${SSHKEY_FILE}.pub" "$target_server"
}

# Process Local Infrastructure
if [[ "$LOCAL_FLAG" == true ]]; then
  echo "Targeting Local Nodes via: ${SSHKEY_FILE}.pub"
  for server in "${servers[@]}"; do
    deploy_and_clean "$server"
  done
fi

# Process Remote Infrastructure
if [[ "$REMOTE_FLAG" == true ]]; then
  echo "Targeting Remote Nodes via: ${SSHKEY_FILE}.pub"
  for server in "${remote_servers[@]}"; do
    deploy_and_clean "$server"
  done
fi

# run ssh-agent and add keys
if [ -f "$SSHKEY_FILE" ]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    eval "$(ssh-agent -s)"
    ssh-add --apple-use-keychain "${SSHKEY_FILE}"
  else
    eval "$(ssh-agent -s)"
    ssh-add "${SSHKEY_FILE}"
  fi
fi
