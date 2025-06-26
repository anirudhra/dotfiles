#!/bin/bash
# this script installs GTK themes from the dotfiles repository
# It should be run from the dotfiles/linux directory
# Usage: ./gtkthemes.sh
# this script can be run standalone (after installation to update) or as part of the dotfiles setup process

# Ensure the script is run from the dotfiles/linux directory hierarchy
install_dir="$(pwd)"
expected_subdir="/dotfiles/linux"

if [[ "$install_dir" != *"$expected_subdir"* ]]; then
  echo "Script invoked from incorrect directory!"
  echo "The current directory is: $install_dir"
  echo "Please run this script from a directory within $expected_subdir"
  echo
  exit 1
fi

# copy the gtk/themes directory to the packages/install directory
pkg_install_dir="${HOME}/packages/install"
mkdir -p "${pkg_install_dir}"
cp -r "${install_dir}/gtk/themes" "${pkg_install_dir}/"
cd "${pkg_install_dir}/themes" || { echo "Failed to enter themes directory!"; exit 1; }

# run update.sh script from each directory above where supported, if at least one was sync'd
echo "Installing GTK UI themes..."
find . -maxdepth 1 -type d ! -name . | while read -r theme_dir; do
  if [[ -x "$theme_dir/update.sh" ]]; then
    echo "Updating theme in $theme_dir"
    (cd "$theme_dir" && ./update.sh)
  else
    echo "No update.sh found in $theme_dir, skipping."
  fi
done

exit 0

# retaining old code for reference
# Install GTK and Icon themes in the following directory
#pkg_install_dir="${HOME}/packages/install"
#mkdir -p "${pkg_install_dir}"
#cp -r "${install_dir}/gtk/themes" "${pkg_install_dir}/"
#cd "${pkg_install_dir}/themes" || exit
# execute install.sh script from each directory above where supported, if at least one was sync'd
#echo "Installing GTK UI themes"
#find . -maxdepth 1 -type d \( ! -name . \) -exec bash -c "cd '{}' && pwd && ./update.sh" \;
