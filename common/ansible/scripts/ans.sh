#!/bin/bash
# quick ansible playbook command

if [ $# -ne 1 ]; then
  echo
  echo "Usage: $0 <playbook>"
  echo
  echo "Available playbooks:"
  echo
  ls ../playbooks -1 | sed -e 's/\.yaml$//'
  echo
  exit
fi

playbook="$1"
ansible-playbook -i "../inventory.yaml" "../playbooks/${playbook}.yaml"
