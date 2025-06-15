#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/elementary/sound-theme"
gitdir="elementary-sounds"

installupdate() {
  # update/install per dir commands
  meson build --prefix=/usr
  cd build || exit
  ninja
  sudo ninja install
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