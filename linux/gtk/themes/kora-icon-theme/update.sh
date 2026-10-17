#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/bikass/kora"
gitdir="kora-icon-theme"

installupdate() {
  ICONDIR="~/.local/share/icons"
  #sudo cp -r kora* /usr/share/icons
  mkdir -p "${ICONDIR}"
  cp -r kora* "${ICONDIR}"
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"
