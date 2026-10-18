#!/bin/bash
# (c) Anirudh Acharya 2025, 2026
# Update dotfiles repository and synchronize symlinks to user home
set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Error: Dotfiles repository not found at '$DOTFILES_DIR'." >&2
  exit 1
fi

echo "==> Pulling latest changes from git repository..."
cd "$DOTFILES_DIR"
git pull --ff-only || {
  echo "Warning: git pull failed or fast-forward was not possible." >&2
}

if command -v stow >/dev/null 2>&1; then
  echo "==> Stowing dotfiles using GNU Stow..."
  cd "$DOTFILES_DIR/home"
  stow --verbose=1 --stow --target="${HOME}" .
elif [ -x "$DOTFILES_DIR/common/scripts/dotsync.sh" ]; then
  echo "==> GNU Stow not found; synchronizing via dotsync.sh..."
  "$DOTFILES_DIR/common/scripts/dotsync.sh"
else
  echo "Error: Neither GNU Stow nor dotsync.sh is available." >&2
  exit 1
fi

echo "==> Dotfiles synchronization complete!"
