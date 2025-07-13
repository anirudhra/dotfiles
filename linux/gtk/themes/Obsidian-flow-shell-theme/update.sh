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

force_update="false"
if [ $# -gt 0 ]; then
  case "$1" in
    --force)
      force_update="true"
      ;;
    --help)
      print_git_theme_update_help
      ;;
    *)
      print_git_theme_update_help
      ;;
  esac
fi

# Run the common logic
run_git_update_and_install "$giturl" "$gitdir" installupdate "$force_update"



