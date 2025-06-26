#!/bin/sh
# (c) Anirudh Acharya
# Be careful before running this!

echo "====================================================================================="
echo "This script will recursively change ownership of all files and directories in"
echo "the current hierarchy to nobody:nobody. If that was not the intention, press Ctrl+C"
echo "to quit now, else press any other key to continue."
echo "====================================================================================="
echo
read ans #dummy variable

sudo chown -R nobody:nobody *
sudo chmod -R 755 *

