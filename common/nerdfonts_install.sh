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
nerdfonts_list=("Agave" "AnonymousPro" "Arimo" "AurulentSansMono" "BigBlueTerminal" "BitstreamVeraSansMono" "CascadiaCode" "CodeNewRoman" "ComicShannsMono" "Cousine" "DaddyTimeMono" "DejaVuSansMono" "FantasqueSansMono" "FiraCode" "FiraMono" "Gohu" "Go-Mono" "Hack" "Hasklig" "HeavyData" "Hermit" "iA-Writer" "IBMPlexMono" "InconsolataGo" "InconsolataLGC" "Inconsolata" "IosevkaTerm" "JetBrainsMono" "Lekton" "LiberationMono" "Lilex" "Meslo" "Monofur" "Monoid" "Mononoki" "MPlus" "NerdFontsSymbolsOnly" "Noto" "OpenDyslexic" "Overpass" "ProFont" "ProggyClean" "RobotoMono" "ShareTechMono" "SourceCodePro" "SpaceMono" "Terminus" "Tinos" "UbuntuMono" "Ubuntu" "VictorMono")

echo
echo
PS3="Enter a number: "

select font_name in "${nerdfonts_list[@]}" "Quit"; do

  if [ -n "${font_name}" ]; then

    echo "Starting ${font_name} Nerd Font download..."

    if [ "$(command -v curl)" ]; then
      echo "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
      curl -OL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
      echo "creating fonts folder: ${HOME}/.fonts"
      mkdir -p "$HOME/.fonts"
      echo "unzip the ${font_name}.zip"
      unzip "${font_name}.zip" -d "$HOME/.fonts/${font_name}/"
      fc-cache -fv
      echo "done!"
      rm -f "${font_name}.zip"
      break

    elif [ "$(command -v wget)" ]; then
      echo "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
      wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
      echo "creating fonts folder: ${HOME}/.fonts"
      mkdir -p "$HOME/.fonts"
      echo "unzip the ${font_name}.zip"
      unzip "${font_name}.zip" -d "$HOME/.fonts/${font_name}/"
      fc-cache -fv
      echo "done!"
      break

    else
      echo "Cannot find curl/wget. Please install either first!"
      break
    fi
  else
    echo "Select a vaild ${font_name} Nerd Font with the number in front of it."
    continue
  fi
done
