#!/bin/bash
cp "${HOME}/.aliases" "${HOME}/.aliases.bak"
#wget -O ~/.aliases https://raw.githubusercontent.com/anirudhra/dotfiles/refs/heads/main/home/.aliases
cp -f ../../home/.aliases "${HOME}/.aliases"
