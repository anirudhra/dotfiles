#!/bin/bash

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

if [[ "$1" == "gen" || "$1" == "--generate" ]]; then
    # interactive, choose options within
    ssh-keygen -t rsa

    # copy over keys to servers: pve, lxc, vm
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.50
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.51
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.55
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.60
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.65
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.70
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.75
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.80
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.95
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.85
    ssh-copy-id -i ~/.ssh/id_rsa.pub nonroot@10.100.100.85
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@10.100.100.64
    ssh-copy-id -i ~/.ssh/id_rsa.pub admin@10.100.100.64
    ssh-copy-id -p 12372 -i ~/.ssh/id_rsa.pub admin@10.100.100.1
fi

# run ssh-agent and add keys
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: add key to Apple keychain and also to ssh-agent for CLI
    eval "$(ssh-agent -s)"
    ssh-add --apple-use-keychain ~/.ssh/id_rsa
else
    # Linux and other systems: start agent and add key
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
fi

