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

##---------------common installation/update script-------------------------#
source "${HOME}/dotfiles/linux/gitfuncs.sh"

clonerepo ${giturl} ${gitdir}
clone=$?
updaterepo ${giturl} ${gitdir}
update=$?

if [ "${clone}" == 1 ] || [ "${update}" == 1 ]; then
  cd "${gitdir}" || exit
  installupdate
fi
