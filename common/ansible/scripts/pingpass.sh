#!/bin/bash
# (c) Anirudh Acharya 2025
# ping all hosts in inventory, ask for password

ansible-playbook -i ../inventory.yaml ../playbooks/ping.yaml --ask-pass
