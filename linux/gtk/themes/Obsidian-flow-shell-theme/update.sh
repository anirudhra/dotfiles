#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/JustDeax/Obsidian-flow-shell-theme"
gitdir="Obsidian-flow-shell-theme"

installupdate() {
  python install.py --blue --gray --filled
  #sudo python install.py --blue --gray --filled
}

##---------------------common part-----------------------------------------#

# Source the git functions (now includes run_git_update_and_install)
source "${HOME}/.gitfuncs"

run_git_update_and_install "$giturl" "$gitdir" installupdate "$@"



