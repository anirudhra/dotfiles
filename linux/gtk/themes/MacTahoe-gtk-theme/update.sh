#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/MacTahoe-gtk-theme"
gitdir="MacTahoe-gtk-theme"

installupdate() {
  #sudo ./install.sh -d /usr/share/themes -a alt -HD --shell -i fedora --darker
  sudo ./install.sh -d /usr/share/themes -a alt --shell -i fedora --darker
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"

