#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Qogir-theme"
gitdir="Qogir-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -i fedora --tweaks round
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
