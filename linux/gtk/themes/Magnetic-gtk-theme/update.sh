#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Magnetic-gtk-theme"
gitdir="Magnetic-gtk-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"
