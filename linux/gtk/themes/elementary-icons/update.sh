#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/elementary/icons"
gitdir="elementary-icons"

# provide custom installupdate() function per theme
installupdate() {
  # update/install per dir commands
  meson build --prefix=/usr
  cd build || exit
  ninja
  sudo ninja install
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"
