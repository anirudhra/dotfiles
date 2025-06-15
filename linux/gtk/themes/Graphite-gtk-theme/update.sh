#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Graphite-gtk-theme"
gitdir="Fluent-icon-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -t blue --tweaks nord darker
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

