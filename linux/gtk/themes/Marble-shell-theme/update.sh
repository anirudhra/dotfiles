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