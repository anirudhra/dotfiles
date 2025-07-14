#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Qogir-theme"
gitdir="Qogir-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -i fedora --tweaks round
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"