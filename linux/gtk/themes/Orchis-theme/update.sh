#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Orchis-theme"
gitdir="Orchis-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -s standard -f --tweaks dock primary
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"
