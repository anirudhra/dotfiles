#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Jasper-gtk-theme"
gitdir="Jasper-gtk-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -t blue
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"


