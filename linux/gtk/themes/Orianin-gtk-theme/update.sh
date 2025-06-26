#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Orianin-gtk-theme"
gitdir="Orianin-gtk-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -s standard -f --tweaks dock primary
}

##---------------common installation/update script-------------------------#
source ${HOME}/.gitfuncs

# clone or update the repo
syncrepo ${giturl} ${gitdir}

# only install/update if clone/pull was successful
if [ $? -eq 0 ]; then
  cd ${gitdir} || exit 1
  installupdate # run the install/update script
  exit 0
else
  echo "Install/update script not run: ${giturl}"
  exit 1
fi
