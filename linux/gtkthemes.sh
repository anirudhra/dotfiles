#!/bin/bash
# this script installs GTK themes from the dotfiles repository
# It should be run from the dotfiles/linux directory
# Usage: ./gtkthemes.sh
# this script can be run standalone (after installation to update) or as part of the dotfiles setup process

install_dir=$(pwd)
if [[ ${install_dir} != *"/dotfiles/linux"* ]]; then
  echo "Script invoked from incorrect directory!"
  echo "The current directory is: ${install_dir}"
  echo "Please run this script from .../dotfiles/linux directory"
  echo
  exit
fi

# Install GTK and Icon themes in the following directory
pkg_install_dir="${HOME}/packages/install"
mkdir -p "${pkg_install_dir}"

cp -r "${install_dir}/gtk/themes" "${pkg_install_dir}/"
cd "${pkg_install_dir}/themes" || exit

# execute install.sh script from each directory above where supported, if at least one was sync'd
echo "Installing GTK UI themes"
find . -maxdepth 1 -type d \( ! -name . \) -exec bash -c "cd '{}' && pwd && ./update.sh" \;
