#!/bin/sh
# (c) Anirudh Acharya
# Dotfiles symlink synchronizer with dead-link cleanup and data safety backups
set -e

# Resolve base dotfiles root: supports DOTFILES_HOME override (e.g. /opt/root on routers)
DOTFILES_BASE="${DOTFILES_HOME:-$HOME}"
SRC_DIR="${DOTFILES_BASE}/dotfiles/home"
TARGET_DIR="${WRT_LINK_HOME:-$HOME}"

if [ ! -d "$SRC_DIR" ]; then
  echo "Error: Source directory '$SRC_DIR' not found." >&2
  exit 1
fi

# Detect router platforms (OpenWrt, DD-WRT, Asuswrt)
is_router=0
if [ -f /etc/openwrt_release ] || [ -f /etc/openwrt_version ] || \
   [ -f /etc/defaults.bin ] || [ -d /etc/l7-protocols ] || \
   [ -f /etc/asus_build_info ] || [ -f /rom/etc/asus_build_info ] || \
   [ -f /etc/merlin.version ]; then
  is_router=1
fi

echo "Syncing dotfiles: $SRC_DIR -> $TARGET_DIR (Router mode: $is_router)"

if [ "$is_router" -eq 1 ]; then
  # ----------------------------------------------------------------------------
  # Router mode (OpenWrt, DD-WRT, Asuswrt)
  # Only link required directories and configurations.
  # NEVER overwrite the firmware login bootloader (~/.profile or ~/.ashrc).
  # ----------------------------------------------------------------------------

  link_router_target() {
    src="$1"
    dst="$2"
    if [ -e "$src" ] || [ -L "$src" ]; then
      if [ -L "$dst" ] && [ "$(readlink "$dst" 2>/dev/null)" = "$src" ]; then
        return 0
      fi
      [ -L "$dst" ] && rm -f "$dst"
      ln -sfn "$src" "$dst"
      echo "Linked: $dst -> $src"
    fi
  }

  # 1. Core symlinks into router home (resolving directly to DOTFILES_BASE)
  link_router_target "${DOTFILES_BASE}/dotfiles" "${TARGET_DIR}/dotfiles"
  link_router_target "${SRC_DIR}/.vimrc.entware" "${TARGET_DIR}/.vimrc"
  link_router_target "${SRC_DIR}/.vim" "${TARGET_DIR}/.vim"
  link_router_target "${SRC_DIR}/.config" "${TARGET_DIR}/.config"

  # 2. Fastfetch utility link in /opt/bin (if Entware /opt/bin exists)
  if [ -d "/opt/bin" ]; then
    link_router_target "${DOTFILES_BASE}/dotfiles/common/scripts/routerfastfetch" "/opt/bin/fastfetch"
  fi

  # 3. Clean up any unintended desktop-only symlinks left behind in TARGET_DIR
  (
    cd "${TARGET_DIR}" 2>/dev/null || exit 0
    for stale in .aliases_* .bash* .zsh* .p10k.zsh .gtkrc* .profile.* .helperfuncs .filefuncs .gitfuncs; do
      [ -e "$stale" ] || [ -L "$stale" ] || continue
      echo "Removing desktop-only symlink from router: ${TARGET_DIR}/${stale}"
      rm -f "${stale}"
    done
  )

  # 4. Safety check: ensure ~/.profile is not pointing into dotfiles/home/.profile
  if [ -L "${TARGET_DIR}/.profile" ]; then
    target="$(readlink "${TARGET_DIR}/.profile" 2>/dev/null || true)"
    case "$target" in
      *"dotfiles/home"*)
        echo "Warning: ${TARGET_DIR}/.profile was pointing to desktop .profile!"
        latest_bak="$(ls -t "${TARGET_DIR}"/.profile.bak.* 2>/dev/null | head -n 1 || true)"
        if [ -n "$latest_bak" ] && [ -f "$latest_bak" ]; then
          echo "Restoring original router bootloader from $latest_bak -> ${TARGET_DIR}/.profile"
          rm -f "${TARGET_DIR}/.profile"
          cp -p "$latest_bak" "${TARGET_DIR}/.profile"
        fi
        ;;
    esac
  fi

  echo "Router dotfiles sync complete."
  exit 0
fi

# ----------------------------------------------------------------------------
# General Linux / macOS / Server mode (Full Stow-like file walk)
# ----------------------------------------------------------------------------

# 1. Clean up broken/dead symlinks pointing into dotfiles/home
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

# 2. Walk all files in dotfiles/home (including hidden dotfiles)
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
