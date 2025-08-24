# Guard variable to ensure sourcing only once
if [ -n "${SOURCED_PROFILE}" ]; then
  return 0 # Exit the script if already sourced
fi

# Set the guard variable
SOURCED_PROFILE=1

# . is POSIX version of "source"
#export ALIASES_HOME="${ALIASES_HOME:-$HOME}"   #if stowed, then they must be same as home, else the locaitons for <path>/dotfiles/home, default to home
#export DOTFILES_HOME="${DOTFILES_HOME:-$HOME}" #usually under /home/<user> but sometimes could be different, default to home

# below is more robust than above settings
if [[ -z "${DOTFILES_HOME}" ]]; then
  export DOTFILES_HOME="${HOME}"
fi

if [[ -z "${ALIASES_HOME}" ]]; then
  export ALIASES_HOME="${HOME}"
fi

. "${ALIASES_HOME}/.aliases"

#macos only, test by checking if "diskutil" command exists (macos-only)
#if (( ${+commands[diskutil]} )); then
if [[ "$OSTYPE" == "darwin"* ]]; then
  source <(fzf --zsh)
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

  eval "$(/usr/local/bin/brew shellenv)"

  export XDG_CONFIG_HOME=${HOME}/.config
  export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"
  export VISUAL='vimr'
  export EDITOR='nvim'

  export PATH="${HOME}/.local/bin:${PATH}"
  export PATH="./:/usr/local/sbin:${PATH}"

  LESSPIPE=$(which src-hilite-lesspipe.sh)
  export LESSOPEN="| ${LESSPIPE} %s"
  export LESS=' -R -X -F '

  echo
  cowsay $(fortune -s)
  echo
else
  export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:${HOME}/.local/share/flatpak/exports/share:${XDG_DATA_DIRS}"
  export PATH="./:${PATH}"
  export TERM="xterm-256color"
fi

HOST_PROFILE_ZSH="${ALIASES_HOME}/.profile.${HOST%%.*}"
HOST_PROFILE_BASH="${ALIASES_HOME}/.profile.${HOSTNAME%%.*}"

# hostname specific commands, both point to the same file and will run only once
# bash specific
[ -f "${HOST_PROFILE_BASH}" ] && . "${HOST_PROFILE_BASH}"

# for zsh
[ -f "${HOST_PROFILE_ZSH}" ] && . "${HOST_PROFILE_ZSH}"
