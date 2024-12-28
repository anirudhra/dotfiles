# . is POSIX version of "source"
. ~/.aliases

#macos only
if (( ${+commands[open]} )); then 
    source <(fzf --zsh)
    test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

    echo
    eval "$(/usr/local/bin/brew shellenv)"

    export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    export VISUAL='vimr'
    export EDITOR='nvim'

    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
    fi

    export GTK_PATH=/usr/local/lib/gtk-2.0
    export PKG_CONFIG_PATH=/usr/local/Cellar/cairo/1.10.2/lib/pkgconfig
    export PATH="/usr/local/sbin:$PATH"

    LESSPIPE=$(which src-hilite-lesspipe.sh)
    export LESSOPEN="| ${LESSPIPE} %s"
    export LESS=' -R -X -F '

    echo
    cowsay $(fortune -s)
    echo
fi

fastfetch
echo
