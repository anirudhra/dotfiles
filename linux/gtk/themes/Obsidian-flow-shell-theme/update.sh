#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/JustDeax/Obsidian-flow-shell-theme"
gitdir="Obsidian-flow-shell-theme"

installupdate() {
  python install.py --blue --gray --filled
  #sudo python install.py --blue --gray --filled
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
