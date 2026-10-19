#!/bin/bash
# (c) Anirudh Acharya
# Installs GTK, icon, and shell themes from the dotfiles repository.
# Usage: ./gtkthemes.sh [--all | theme1 theme2 ...]
# Default installs: Orchis-theme, elementary-icons, Tela-icon-theme

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
THEMES_SRC_DIR="${SCRIPT_DIR}/themes"

export DOTFILES_DIR
export ALIASES_HOME="${DOTFILES_DIR}/home"

PKG_INSTALL_DIR="${HOME}/packages/install"
PKG_THEMES_DIR="${PKG_INSTALL_DIR}/themes"

# Default theme selection
DEFAULT_THEMES=(
  "Orchis-theme"
  "elementary-icons"
  "Tela-icon-theme"
)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [THEME_NAME...]

Options:
  --all       Install or update ALL available GTK, shell, and icon themes.
  -l, --list  List all available themes in this repository.
  -h, --help  Display this help message.

Default themes installed when no arguments are provided:
  ${DEFAULT_THEMES[*]}

Examples:
  $(basename "$0")                      # Install default themes
  $(basename "$0") --all                # Install all themes
  $(basename "$0") Orchis-theme         # Install only Orchis
EOF
}

list_available_themes() {
  echo "Available themes:"
  for dir in "${THEMES_SRC_DIR}"/*/; do
    if [ -f "${dir}update.sh" ]; then
      basename "${dir}"
    fi
  done
}

# Parse options
INSTALL_ALL=false
SELECTED_THEMES=()

if [ $# -eq 0 ]; then
  SELECTED_THEMES=("${DEFAULT_THEMES[@]}")
else
  while [ $# -gt 0 ]; do
    case "$1" in
      --all)
        INSTALL_ALL=true
        shift
        ;;
      -l|--list)
        list_available_themes
        exit 0
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -*)
        echo "Unknown option: $1" >&2
        show_help
        exit 1
        ;;
      *)
        SELECTED_THEMES+=("$1")
        shift
        ;;
    esac
  done
fi

if [ "${INSTALL_ALL}" = true ]; then
  SELECTED_THEMES=()
  for dir in "${THEMES_SRC_DIR}"/*/; do
    if [ -f "${dir}update.sh" ]; then
      SELECTED_THEMES+=("$(basename "${dir}")")
    fi
  done
fi

mkdir -p "${PKG_THEMES_DIR}"

echo ""
echo "######################################################################"
echo "Installing/Updating GTK & Icon themes"
echo "Target directory: ${PKG_THEMES_DIR}"
echo "Selected themes: ${SELECTED_THEMES[*]}"
echo "######################################################################"
echo ""

for theme in "${SELECTED_THEMES[@]}"; do
  theme_src="${THEMES_SRC_DIR}/${theme}"
  theme_dst="${PKG_THEMES_DIR}/${theme}"

  if [ ! -d "${theme_src}" ] || [ ! -f "${theme_src}/update.sh" ]; then
    echo "Warning: Theme '${theme}' not found in ${THEMES_SRC_DIR}, skipping."
    continue
  fi

  echo "----------------------------------------------------------------------"
  echo "Processing theme: ${theme}"
  echo "----------------------------------------------------------------------"

  # Sync theme directory to packages/install/themes
  mkdir -p "${theme_dst}"
  cp -rf "${theme_src}/"* "${theme_dst}/"

  if [ -x "${theme_dst}/update.sh" ]; then
    (
      cd "${theme_dst}"
      ./update.sh
    ) || echo "Warning: Update failed for ${theme}"
  else
    echo "Notice: ${theme}/update.sh is not executable or not found."
  fi
  echo ""
done

echo "Theme installation / update process complete."
exit 0
