#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl=https://github.com/vinceliuice/Fluent-gtk-theme
gitdir="Fluent-gtk-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -s standard -i fedora
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