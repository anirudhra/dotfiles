#!/bin/bash
ansible-playbook -i ../repo/inventory.yaml ../repo/playbook.yaml --ask-pass
