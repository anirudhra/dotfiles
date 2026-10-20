#!/bin/bash
# (c) Anirudh Acharya 2025, 2026
# Update dotfiles repository and synchronize symlinks to user home
set -euo pipefail

DOTFILES_DIR="${DOTFILES_HOME:-$HOME}/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Error: Dotfiles repository not found at '$DOTFILES_DIR'." >&2
  exit 1
fi

echo "==> Updating dotfiles repository..."
cd "$DOTFILES_DIR"

current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"
if [ "$current_branch" = "HEAD" ] || [ -z "$current_branch" ]; then
  current_branch="main"
fi

git fetch --depth=1 origin "$current_branch" 2>/dev/null || git fetch origin "$current_branch"

if ! git pull --ff-only 2>/dev/null; then
  echo "Notice: Fast-forward pull not possible on '$current_branch'. Resetting to origin/$current_branch..."
  git reset --hard "origin/$current_branch"
fi

echo "==> Optimizing git repository storage..."
git reflog expire --expire=now --all 2>/dev/null || true
git prune --expire=now 2>/dev/null || true
git repack -a -d -f --depth=250 --window=250 2>/dev/null || git gc --prune=now 2>/dev/null || true

if command -v stow >/dev/null 2>&1; then
  echo "==> Stowing dotfiles using GNU Stow..."
  cd "$DOTFILES_DIR/home"
  stow --verbose=1 --target="${HOME}" --stow --adopt . && git restore . && stow --verbose=1 --target="${HOME}" --restow .
elif [ -x "$DOTFILES_DIR/common/scripts/dotsync.sh" ]; then
  echo "==> GNU Stow not found; synchronizing via dotsync.sh..."
  "$DOTFILES_DIR/common/scripts/dotsync.sh"
else
  echo "Error: Neither GNU Stow nor dotsync.sh is available." >&2
  exit 1
fi

echo "==> Dotfiles synchronization complete!"
