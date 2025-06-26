#!/bin/bash

##---------------git specific part-----------------------------------------#
giturl="https://github.com/bikass/kora"
gitdir="kora-icon-theme"

installupdate() {
  sudo cp -r kora* /usr/share/icons
}

##---------------common installation/update script-------------------------#
source ${HOME}/dotfiles/linux/gitfuncs.sh

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


