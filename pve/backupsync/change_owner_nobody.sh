#!/bin/sh
# (c) Anirudh Acharya
# Be careful before running this!

set -e

TARGET_DIR="${1:-.}"

echo "====================================================================================="
echo "This script will recursively change ownership of all files and directories in"
echo "'$TARGET_DIR' to nobody:nobody. If that was not the intention, press Ctrl+C"
echo "to quit now, else press Enter to continue."
echo "====================================================================================="
echo
read -r -p "Press Enter to continue..."

if [ "$(id -u)" -ne 0 ]; then
    echo "Warning: You are not running as root. You may be prompted for your password."
fi

sudo chown -R nobody:nobody -- "$TARGET_DIR"
sudo chmod -R 755 --

