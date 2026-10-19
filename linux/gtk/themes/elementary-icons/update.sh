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
if [ -f "${HOME}/.gitfuncs" ]; then
  source "${HOME}/.gitfuncs"
elif [ -n "${ALIASES_HOME:-}" ] && [ -f "${ALIASES_HOME}/.gitfuncs" ]; then
  source "${ALIASES_HOME}/.gitfuncs"
elif [ -n "${DOTFILES_DIR:-}" ] && [ -f "${DOTFILES_DIR}/home/.gitfuncs" ]; then
  source "${DOTFILES_DIR}/home/.gitfuncs"
fi

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"
