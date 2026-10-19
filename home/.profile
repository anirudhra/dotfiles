# ==============================================================================
# Dotfiles Debug Logging: set to 1 to enable all debug logs, 0 to disable
# ==============================================================================
export DOTFILES_DEBUG="${DOTFILES_DEBUG:-0}"

# Exit immediately if shell is non-interactive (cron, OMV, scripts)
case "$-" in
*i*) ;;
*) return 0 2>/dev/null || exit 0 ;;
esac

# Guard variable to ensure sourcing only once
if [ -n "${SOURCED_PROFILE}" ]; then
  return 0 # Exit the script if already sourced
fi

# Set the guard variable
SOURCED_PROFILE=1

# set default, if not defined
if [[ -z "${DOTFILES_HOME}" ]]; then
  export DOTFILES_HOME="${HOME}"
fi

if [[ -z "${ALIASES_HOME}" ]]; then
  export ALIASES_HOME="${HOME}"
fi

# source the aliases file, posix way
. "${ALIASES_HOME}/.aliases"

#macos only, test by checking if "diskutil" command exists (macos-only)
#if (( ${+commands[diskutil]} )); then
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [ -n "${ZSH_VERSION:-}" ] && command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [ -n "${BASH_VERSION:-}" ] && command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash 2>/dev/null)"
  fi
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

  # /usr/local/bin/brew on Intel Macs and /opt/homebrew/bin/brew on Apple Silicon
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
  fi

  export XDG_CONFIG_HOME=${HOME}/.config
  export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"
  export VISUAL='vimr'
  export EDITOR='nvim'

  export PATH="/opt/local/bin:/usr/local/sbin:${HOME}/.local/bin:${PATH}"

  if command -v src-hilite-lesspipe.sh >/dev/null 2>&1; then
    export LESSOPEN="| $(command -v src-hilite-lesspipe.sh) %s"
    export LESS=' -R -X -F '
  fi

else
  export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:${HOME}/.local/share/flatpak/exports/share:${XDG_DATA_DIRS}"
fi

if command -v cowsay >/dev/null 2>&1 &&
  command -v fortune >/dev/null 2>&1; then
  cowsay "$(fortune -s)"
fi

# force fix for kitty terminals, tmux won't work otherwise for ssh
if [ "${TERM}" = "xterm-kitty" ]; then
  export TERM="xterm-256color"
fi

HOST_PROFILE_ZSH="${ALIASES_HOME}/.profile.${HOST%%.*}"
HOST_PROFILE_BASH="${ALIASES_HOME}/.profile.${HOSTNAME%%.*}"

# hostname specific commands (source once)
if [ -n "${HOST_PROFILE_BASH}" ] && [ -f "${HOST_PROFILE_BASH}" ]; then
  . "${HOST_PROFILE_BASH}"
elif [ -n "${HOST_PROFILE_ZSH}" ] && [ -f "${HOST_PROFILE_ZSH}" ]; then
  . "${HOST_PROFILE_ZSH}"
fi

# Ensure ~/.local/bin is in PATH portably
if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi
