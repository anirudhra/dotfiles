#!/bin/bash
# interactive, choose options within
ssh-keygen -t rsa
# copy over keys to servers: pve, lxc, vm
ssh-copy-id -i ~/.ssh/id_rsa.pub admin@10.100.100.1
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.50
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.51
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.60
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.65
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.70
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.75
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.80
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.95
ssh-copy-id -i ~/.ssh/id_rsa.pub nonroot@10.100.100.85
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.85
ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.64
