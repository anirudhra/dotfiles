# . is POSIX version of "source"
. "${HOME}/.aliases"

#macos only, test by checking if "diskutil" command exists (macos-only)
if (( ${+commands[diskutil]} )); then 
    source <(fzf --zsh)
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

    eval "$(/usr/local/bin/brew shellenv)"

    export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    export VISUAL='vimr'
    export EDITOR='nvim'

    export GTK_PATH=/usr/local/lib/gtk-2.0
    #export PKG_CONFIG_PATH=/usr/local/Cellar/cairo/1.10.2/lib/pkgconfig
    export PATH="${HOME}/.local/bin:/usr/local/sbin:${PATH}"

    LESSPIPE=$(which src-hilite-lesspipe.sh)
    export LESSOPEN="| ${LESSPIPE} %s"
    export LESS=' -R -X -F '

    #shortcut for manim source
    . "$HOME/.local/bin/env"
    echo
    cowsay $(fortune -s)
    echo
else
    export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:${HOME}/.local/share/flatpak/exports/share:${XDG_DATA_DIRS}"
fi

# common for all
#fastfetch --config groups #enable only if presets are correctly installed both macos/linux, else failsafe below
fastfetch
echo
