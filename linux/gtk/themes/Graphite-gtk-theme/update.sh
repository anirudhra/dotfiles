#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Graphite-gtk-theme"
gitdir="Fluent-icon-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -t blue --tweaks nord darker
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"
