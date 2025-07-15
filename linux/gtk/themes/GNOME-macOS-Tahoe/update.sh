#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/kayozxo/GNOME-macOS-Tahoe"
gitdir="GNOME-macOS-Tahoe"

installupdate() {
  #sudo ./install.sh -d /usr/share/themes -a alt -HD --shell -i fedora --darker
  sudo ./install.sh
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"
