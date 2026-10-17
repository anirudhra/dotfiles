#!/bin/bash
# Originally downloaded from: https://raw.githubusercontent.com/officialrajdeepsingh/nerd-fonts-installer
# Select the Nerd Font from https://www.nerdfonts.com/font-downloads
# Testing with ShellCheck
# Modified by Anirudh Acharya

echo
echo "############################"
echo "[-] Download Nerd Fonts [-]"
echo "############################"
echo
echo "Select Nerd Font to install:"

NERDFONTS_LIST=("Agave" "AnonymousPro" "Arimo" "AurulentSansMono" "BigBlueTerminal" "BitstreamVeraSansMono" "CascadiaCode" "CodeNewRoman" "ComicShannsMono" "Cousine" "DaddyTimeMono" "DejaVuSansMono" "FantasqueSansMono" "FiraCode" "FiraMono" "Gohu" "Go-Mono" "Hack" "Hasklig" "HeavyData" "Hermit" "iA-Writer" "IBMPlexMono" "InconsolataGo" "InconsolataLGC" "Inconsolata" "IosevkaTerm" "JetBrainsMono" "Lekton" "LiberationMono" "Lilex" "Meslo" "Monofur" "Monoid" "Mononoki" "MPlus" "NerdFontsSymbolsOnly" "Noto" "OpenDyslexic" "Overpass" "ProFont" "ProggyClean" "RobotoMono" "ShareTechMono" "SourceCodePro" "SpaceMono" "Terminus" "Tinos" "UbuntuMono" "Ubuntu" "VictorMono")
echo
echo
PS3="Enter a number: "

select FONT_NAME in "${NERDFONTS_LIST[@]}" "Quit"; do

  if [ -n "${FONT_NAME}" ]; then

    echo "Starting ${FONT_NAME} Nerd Font download..."

    if [ "$(command -v curl)" ]; then
      echo "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
      curl -OL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
      echo "creating fonts folder: ${HOME}/.fonts"
      mkdir -p "${HOME}/.fonts"
      echo "unzip the ${FONT_NAME}.zip"
      unzip "${FONT_NAME}.zip" -d "${HOME}/.fonts/${FONT_NAME}/"
      fc-cache -fv
      echo "done!"
      rm -f "${FONT_NAME}.zip"
      break

    elif [ "$(command -v wget)" ]; then
      echo "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
      wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
      echo "creating fonts folder: ${HOME}/.fonts"
      mkdir -p "${HOME}/.fonts"
      echo "unzip the ${FONT_NAME}.zip"
      unzip "${FONT_NAME}.zip" -d "${HOME}/.fonts/${FONT_NAME}/"
      fc-cache -fv
      echo "done!"
      break

    else
      echo "Cannot find curl/wget. Please install either first!"
      break
    fi
  else
    echo "Select a vaild ${FONT_NAME} Nerd Font with the number in front of it."
    continue
  fi
done
