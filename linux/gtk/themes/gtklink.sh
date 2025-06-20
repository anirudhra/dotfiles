#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <target_theme_directory>"
  exit 1
fi

# Define the target file and symlink directory
TARGET_THEME_DIR="$1"
CONFIG_DIR="${HOME}/.config"

DEST_DIRS=(
  "gtk-3.0"
  "gtk-4.0"
)

SUBLINKS=(
  "assets"
  "gtk.css"
  "gtk-dark.css"
)

# Extract the base name of the target file
#LINK_NAME=$(basename "${TARGET_FILE}")

# backup existing dirs/links
for dir in "${DEST_DIRS[@]}"; do
  echo "Processing: $dir"
  dest_dir="${CONFIG_DIR}/${dir}"
  if [ -d "${dest_dir}" ]; then
    cp -r "${dest_dir}" "${dest_dir}-bak"
  fi

  # create symlinks for each of the folders
  for item in "${SUBLINKS[@]}"; do
    # Create the symbolic link
    rm ${dest_dir}/${item}
    ln -s "$(realpath "${TARGET_THEME_DIR}")/${dir}/${item}" "${dest_dir}/${item}"
  done
done

echo Done!
