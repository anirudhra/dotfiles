#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Orchis-theme"
gitdir="Orchis-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -s standard -f --tweaks dock primary
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
