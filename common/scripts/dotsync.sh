#!/bin/sh
# (c) Anirudh Acharya
# Dotfiles symlink synchronizer with dead-link cleanup and data safety backups
set -e

SRC_DIR="${HOME}/dotfiles/home"
TARGET_DIR="${HOME}"

if [ ! -d "$SRC_DIR" ]; then
  echo "Error: Source directory '$SRC_DIR' not found." >&2
  exit 1
fi

echo "Syncing dotfiles: $SRC_DIR -> $TARGET_DIR"

# 1. Clean up broken/dead symlinks pointing into ~/dotfiles/home
# Prune heavy non-dotfile directories to keep the check fast
find "$TARGET_DIR" -maxdepth 3 \
  \( -name ".cache" -o -name "node_modules" -o -name ".cargo" -o -name ".rustup" -o -name ".git" -o -name ".mozilla" -o -name "Downloads" \) -prune \
  -o -type l -print | while IFS= read -r link; do
  target=$(readlink "$link" 2>/dev/null || true)
  case "$target" in
  "${SRC_DIR}"*)
    if [ ! -e "$link" ]; then
      echo "Removing dead symlink: $link"
      rm -f "$link"
    fi
    ;;
  esac
done

# 2. Walk all files in ~/dotfiles/home (including hidden dotfiles)
(cd "$SRC_DIR" && find . -type f ! -path "./.git/*" ! -name ".git" ! -name "README*") | while IFS= read -r file; do
  rel_path="${file#./}"
  dest="${TARGET_DIR}/${rel_path}"
  dest_dir=$(dirname "$dest")
  src_abs="${SRC_DIR}/${rel_path}"

  # Create destination subdirectory if needed (e.g. ~/.config/...)
  [ ! -d "$dest_dir" ] && mkdir -p "$dest_dir"

  # Skip if destination already resolves to the exact same file (via direct symlink or symlinked parent directory)
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    dest_real=$(realpath "$dest" 2>/dev/null || true)
    src_real=$(realpath "$src_abs" 2>/dev/null || true)
    if [ -n "$dest_real" ] && [ "$dest_real" = "$src_real" ]; then
      continue
    fi
  fi

  # Safely handle existing destination if it does not resolve to the source file
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    # Destination is a regular unversioned file/directory - back it up to prevent data loss
    backup_path="${dest}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "Warning: Existing non-symlink file found. Backing up: $dest -> $backup_path"
    mv "$dest" "$backup_path"
  elif [ -L "$dest" ]; then
    # Destination is an outdated symlink - remove it
    rm -f "$dest"
  fi

  # Create the atomic symlink
  ln -sfn "$src_abs" "$dest"
  echo "Linked: ~/${rel_path} -> ${SRC_DIR}/${rel_path}"
done

echo "Dotfiles sync complete."
