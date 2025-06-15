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
install="no"

# sync if repo doesn't exist
if [ ! -d "./${gitdir}" ]; then
  echo "Repo clone: ${giturl}"
  git clone "${giturl}" "${gitdir}"
  install="yes"
fi

# only install/update if sync was successful
if [ -d "./${gitdir}/.git" ]; then
  cd "${gitdir}" || exit
  syncstatus=$(git pull)
  if [ ! "${syncstatus}" == "Already up to date." ] || [ ${install} == "yes" ]; then
    echo "First install or repo updates. Running installer/updater..."
    installupdate
  else
    echo "No new updates, skipping installer/updater..."
  fi
  cd - || exit
fi
