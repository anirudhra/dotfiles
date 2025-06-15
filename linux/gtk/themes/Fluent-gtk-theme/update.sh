#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl=https://github.com/vinceliuice/Fluent-gtk-theme
gitdir="Fluent-gtk-theme"

installupdate() {
  sudo ./install.sh -d /usr/share/themes -s standard -i fedora
}

##---------------common installation/update script-------------------------#
# sync if repo doesn't exist
if [ ! -d "./${gitdir}" ]; then
  echo "Repo clone: ${giturl}"
  git clone "${giturl}" "${gitdir}"
fi

# only install/update if sync was successful
if [ -d "./${gitdir}/.git" ]; then
  cd "${gitdir}" || exit
  git pull
  installupdate
  cd - || exit
fi