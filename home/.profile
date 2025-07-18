# . is POSIX version of "source"
. "${HOME}/.aliases"

if [ -n "$TMUX" ]; then
  export TERM=screen-256color
fi

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
fi

HOST_PROFILE_ZSH="${HOME}/.profile.${HOST%%.*}"
HOST_PROFILE_BASH="${HOME}/.profile.${HOSTNAME%%.*}"

# hostname specific
# bash specific
[ -f "${HOST_PROFILE_BASH}" ] && . "${HOST_PROFILE_BASH}"

# for zsh
[ -f "${HOST_PROFILE_ZSH}" ] && . "${HOST_PROFILE_ZSH}"
