#!/bin/bash
## (c) Anirudh Acharya 2024, 2025
## generate and copy ssh keys to servers

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
  echo "Usage: $0 [gen|--generate] [-f|--force] [--local|--remote]"
  echo "  -gen, --generate  Generate new SSH key and copy to servers."
  echo "  -f, --force       Force overwrite keys on the server."
  echo "  --local           Copy keys to local servers only."
  echo "  --remote          Copy keys to remote servers only."
  echo "  -h, --help        Show this help message."
  echo
  echo "By default, keys are copied to local servers if key generation option is chosen."
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

SSHKEY_FILE="${HOME}/.ssh/id_rsa"
FORCE_FLAG=""
LOCAL_FLAG=true
REMOTE_FLAG=false

# Parse arguments for force flag and server type flags
for arg in "$@"; do
  if [[ "$arg" == "-f" || "$arg" == "--force" ]]; then
    FORCE_FLAG="-f"
  elif [[ "$arg" == "--local" ]]; then
    LOCAL_FLAG=true
  elif [[ "$arg" == "--remote" ]]; then
    REMOTE_FLAG=true
  fi
done

if [[ "$1" == "-gen" || "$1" == "--generate" ]]; then
  # interactive, choose options within
  ssh-keygen -t rsa

  # Array of local servers to copy keys to
  servers=(
    "-p ${ROUTERSSHPORT} ${SSHROOT}@${DDWRTROUTER}"
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
    # "${SSHROOT}@${SBC}"
    # "${SSHROOT}@${SBCWIFI}"
    # "${SSHROOT}@${SBCETH}"
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

  # copy over keys to local servers: pve, lxc, vm
  if [[ "$LOCAL_FLAG" == true ]]; then
    for server in "${servers[@]}"; do
      ssh-copy-id $FORCE_FLAG -i "${SSHKEY_FILE}.pub" "$server"
    done
  fi

  # copy over keys to remote servers
  if [[ "$REMOTE_FLAG" == true ]]; then
    for server in "${remote_servers[@]}"; do
      ssh-copy-id $FORCE_FLAG -i "${SSHKEY_FILE}.pub" "$server"
    done
  fi
  # ssh-copy-id -p "${ROUTERPORT}" -i "${SSHKEY_FILE}.pub" "${ROUTERUSER}@${ROUTER}"
fi

# run ssh-agent and add keys
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS: add key to Apple keychain and also to ssh-agent for CLI
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain "${SSHKEY_FILE}"
else
  # Linux and other systems: start agent and add key
  eval "$(ssh-agent -s)"
  ssh-add "${SSHKEY_FILE}"
fi
