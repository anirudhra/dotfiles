#!/bin/bash
# git clone, pull helper functions
# used/sourced in other scripts
#

##---------------common installation/update script-------------------------#
# syntax: clonerepo(giturl, localdirecotry)
# retuns 1 if fresh clone was performed, else 0
clonerepo() {
  cloned=0

  giturl=$1
  gitdir=$2

  # sync if repo doesn't exist
  if [ ! -d "./${gitdir}" ]; then
    echo "Repo cloned: ${giturl}"
    git clone "${giturl}" "${gitdir}"
    cloned=1
  else
    echo "Repo exists. Run update function to check for any new updates."
  fi

  return "${cloned}"
}

# syntax: updaterepo(giturl, localdirecotry)
# retuns 1 if repo was updated, else 0
updaterepo() {
  update=0
  # only install/update if sync was successful
  if [ -d "./${gitdir}/.git" ]; then
    cd "${gitdir}" || exit
    syncstatus=$(git pull)
    if [ ! "${syncstatus}" == "Already up to date." ]; then
      update=1
      echo "Repo updated: ${giturl}"
    else
      echo "No new updates."
    fi
    cd - || exit
  else
    echo "Repo does not exist. Run clone function first."
  fi

  return "${update}"
}
