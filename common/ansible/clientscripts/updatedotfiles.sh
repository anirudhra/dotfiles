#!/bin/bash

cd "${HOME}"/dotfiles || exit
echo "Syncing to repo head..."
git pull
cd home || exit
echo "Stowing new files..."
stow --verbose=1 --stow --target="${HOME}" .
