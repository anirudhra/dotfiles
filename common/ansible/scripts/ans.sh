#!/bin/bash
# (c) Anirudh Acharya 2025, 2026
# Ansible playbook runner with dynamic path resolution and argument forwarding
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INVENTORY="$ANSIBLE_DIR/inventory.yaml"
PLAYBOOKS_DIR="$ANSIBLE_DIR/playbooks"

if [ $# -lt 1 ]; then
  echo
  echo "Usage: $0 <playbook> [ansible-playbook options...]"
  echo
  echo "Examples:"
  echo "  $0 upgradeall"
  echo "  $0 upgrade -l pve"
  echo "  $0 ping --check"
  echo
  echo "Available playbooks:"
  find "$PLAYBOOKS_DIR" -maxdepth 1 -name '*.yaml' -exec basename {} .yaml \; | sort | sed 's/^/  - /'
  echo
  exit 1
fi

PLAYBOOK_NAME="${1%.yaml}"
shift

PLAYBOOK_FILE="$PLAYBOOKS_DIR/${PLAYBOOK_NAME}.yaml"

if [ ! -f "$PLAYBOOK_FILE" ]; then
  echo "Error: Playbook '$PLAYBOOK_FILE' not found." >&2
  exit 1
fi

ansible-playbook -i "$INVENTORY" "$PLAYBOOK_FILE" "$@"
