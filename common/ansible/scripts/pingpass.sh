#!/bin/bash
# (c) Anirudh Acharya 2025, 2026
# Ping all active hosts in inventory and prompt for SSH password
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INVENTORY="$ANSIBLE_DIR/inventory.yaml"
PLAYBOOK="$ANSIBLE_DIR/playbooks/ping.yaml"

ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --ask-pass "$@"
