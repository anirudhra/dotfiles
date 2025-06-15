#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl=https://github.com/vinceliuice/Fluent-gtk-theme
gitdir="Fluent-gtk-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -s standard -i fedora
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

