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
  echo "Usage: $0 [gen|--generate]"
  echo "  gen, --generate   Generate new SSH key and copy to servers."
  echo "  -h, --help        Show this help message."
  echo
  echo "By default, only the ssh-agent/ssh-add section runs."
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

SSHKEY_FILE="${HOME}/.ssh/id_rsa"

if [[ "$1" == "gen" || "$1" == "--generate" ]]; then
  # interactive, choose options within
  ssh-keygen -t rsa

  # copy over keys to servers: pve, lxc, vm
  #ssh-copy-id -p "${ROUTERPORT}" -i "${SSHKEY_FILE}.pub" "${ROUTERUSER}@${ROUTER}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${DDWRTROUTER}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVESERVER}"
  #ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVEVENTOY}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVWG}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVEVEGA}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVEBLANKA}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVEHA}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVESAGAT}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVEJF}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVEKUMA}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVELMS}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${PVEIMM}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHNONROOT}@${PVEUBUNTU}"
  ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${SBC}"
  #ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${SBCWIFI}"
  #ssh-copy-id -i "${SSHKEY_FILE}.pub" "${SSHROOT}@${SBCETH}"
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
