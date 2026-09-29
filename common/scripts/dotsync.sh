#!/bin/sh
set -e

SRC_DIR="${HOME}/dotfiles/home"
TARGET_DIR="${HOME}"

if [ ! -d "$SRC_DIR" ]; then
  echo "Error: Source directory '$SRC_DIR' not found." >&2
  exit 1
fi

echo "Syncing dotfiles: $SRC_DIR -> $TARGET_DIR"

# 1. Clean up broken/dead symlinks pointing into ~/dotfiles/home
# (Handles files deleted or moved in your git repo)
find "$TARGET_DIR" -maxdepth 3 -type l | while IFS= read -r link; do
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

  # Skip if the link already points to the correct source file
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src_abs" ]; then
    continue
  fi

  # Remove existing conflicting file or symlink
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
  fi

  # Create the symlink
  ln -s "$src_abs" "$dest"
  echo "Linked: ~/${rel_path} -> ${SRC_DIR}/${rel_path}"
done

echo "Dotfiles sync complete."
