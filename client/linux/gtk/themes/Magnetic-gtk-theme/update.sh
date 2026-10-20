#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Magnetic-gtk-theme"
gitdir="Magnetic-gtk-theme"

installupdate() {
  #sudo ./install.sh -d /usr/share/themes
  ./install.sh
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
