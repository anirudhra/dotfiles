#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/vinceliuice/Jasper-gtk-theme"
gitdir="Jasper-gtk-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -t blue
}

##---------------common installation/update script-------------------------#
source "${HOME}/.gitfuncs"

# clone or update the repo
syncrepo "${giturl}" "${gitdir}"

# only install/update if clone/pull was successful
if [ $? -eq 0 ]; then
  cd "${gitdir}" || exit 1
  installupdate # run the install/update script
  exit 0
else
  echo "Install/update script not run: ${giturl}"
  exit 1
fi


