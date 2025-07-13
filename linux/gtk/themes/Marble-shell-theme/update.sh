#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/Fausto-Korpsvart/Marble-shell-theme"
gitdir="Marble-shell-theme"

installupdate() {
  python install.py --blue --gray --panel-no-pill --filled
  # use either no-pill or floating panel
  #python install.py --blue --gray --floating-panel --filled

  # use following for installing gdm background, first install dependencies though
  #sudo python install.py --blue --gray --panel-no-pill --filled --gdm --gdm-image ~/Pictures/GDM/gdm7.jpg
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


