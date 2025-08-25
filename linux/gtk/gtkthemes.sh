#!/bin/bash
# this script installs GTK themes from the dotfiles repository
# It should be run from the dotfiles/linux directory
# Usage: ./gtkthemes.sh
# this script can be run standalone (after installation to update) or as part of the dotfiles setup process

# Ensure the script is run from the dotfiles/linux directory hierarchy
INSTALL_DIR="$(pwd)"
EXPECTED_SUBDIR="/dotfiles/linux"

if [[ "$INSTALL_DIR" != *"$EXPECTED_SUBDIR"* ]]; then
  echo "Script invoked from incorrect directory!"
  echo "The current directory is: $INSTALL_DIR"
  echo "Please run this script from a directory within $EXPECTED_SUBDIR"
  echo
  exit 1
fi

# copy the gtk/themes directory to the packages/install directory
PKG_INSTALL_DIR="${HOME}/packages/install"
mkdir -p "${PKG_INSTALL_DIR}"
cp -r "${INSTALL_DIR}/gtk/themes" "${PKG_INSTALL_DIR}/"
cd "${PKG_INSTALL_DIR}/themes" || {
  echo "Failed to enter themes directory!"
  exit 1
}

# run update.sh script from each directory above where supported, if at least one was sync'd
echo ""
echo "######################################"
echo "Installing/Updating GTK UI themes..."
echo "######################################"
echo ""

find . -maxdepth 1 -type d ! -name . | while read -r THEME_DIR; do
  if [[ -x "$THEME_DIR/update.sh" ]]; then
    echo "Running install/update script from: $THEME_DIR"
    (cd "$THEME_DIR" && ./update.sh)
  else
    echo "No update.sh script found in $THEME_DIR, skipping."
  fi
  echo " "
done

exit 0
