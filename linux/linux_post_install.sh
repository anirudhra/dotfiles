#!/bin/bash
# (c) Anirudh Acharya 2024
# Fedora setup and Fedora/Debian dotfiles repo for thinkpad
# Run this script as non-root user AFTER the linux_install.sh script
# git config --global user.name "name"
# git config --global user.email "email"
# gh auth login: for browser based git login instead of token

echo
echo "==============================================================================================================="
echo "Starting automated POST-installer script. This should be run AFTER linux_install.sh script is run and "
echo "logging out and log back in. This should be run AFTER linux_install.sh script is run."
read -p "If not, Press Ctrl+C now to quit, else Press Enter to continue" -n1 -s
#echo "================================================================================================================"
echo

# check if running from the right directory
install_dir=$(pwd)
if [[ ${install_dir} != *"/dotfiles/linux"* ]]; then
  echo "Script invoked from incorrect directory!"
  echo "The current directory is: ${install_dir}"
  echo "Please run this script from .../dotfiles/linux directory"
  echo
  exit
fi

#git login
gh auth login #for browser based git login instead of token
git config --global core.editor "nano"

####################################################################################
# Zsh/oh-my-zsh plugins, all these are enabled in "stowed zshrc" already
####################################################################################
# install powerlevel10k
echo "Installing powerlevel10k and oh-my-zsh plugins..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

#install oh-my-zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"

####################################################################################
# EasyEffects pipewire audio enhancer plugins
####################################################################################
# manually install easy effects presets and gnome extensions for easy control (optional)
#echo "Installing EasyEffects presets..."
#bash -c "$(curl -fsSL https://raw.githubusercontent.com/JackHack96/PulseEffects-Presets/master/install.sh)"
# https://extensions.gnome.org/extension/4907/easyeffects-preset-selector/
# above is no longer needed: easyeffects presets now part of github repo and will be stowed

####################################################################################
# Restore GNOME shell extension sessings via config
####################################################################################

echo "Restoring GNOME shell extension settings..."
dconf load /org/gnome/shell/extensions/ <"${install_dir}/extensions/gnome_extensions_backup.dconf"

####################################################################################
# Install dotfiles with stow under /dotfiles/home directory - should be last in this file
####################################################################################

#backup existing files
local_profile="$HOME/.profile"
local_zshrc="$HOME/.zshrc"
local_aliases="$HOME/.aliases"
local_p10k="$HOME/.p10k.zsh"
local_nvim_dir="$HOME/.config/nvim"

if [ -e "${local_profile}" ]; then
  cp -rf "${local_profile}" "${local_profile}.bak"
fi
if [ -e "${local_zshrc}" ]; then
  cp -rf "${local_zshrc}" "${local_zshrc}.bak"
fi
if [ -e "${local_aliases}" ]; then
  cp -rf "${local_aliases}" "${local_aliases}.bak"
fi
if [ -e "${local_p10k}" ]; then
  cp -rf "${local_p10k}" "${local_p10k}.bak"
fi
if [ -d "${local_nvim_dir}" ]; then
  mv "${local_nvim_dir}" "${local_nvim_dir}.bak"
fi

# activate stow
echo "Stowing dotfiles..."
cd "${install_dir}/../home" || exit
stow --verbose=1 --target="$HOME" --stow --adopt .
# above will overwrite git repo if files already exist in $HOME,
# git restore . will restore with the correct versions, this is a trick to overwrite with repo files
git restore .
cd "${install_dir}" || exit

echo "==========================================================================================="
echo " All done, logout and log back in for changes to take effect."
echo "==========================================================================================="

####################################################################################
# END of script
####################################################################################
