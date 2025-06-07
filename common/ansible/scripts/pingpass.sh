#!/bin/bash
ansible-playbook -i ../inventory.yaml ../playbooks/ping.yaml --ask-pass
