dnl vim: ft=sh et ts=4 sw=4
changequote([[,]])dnl
# If not running interactively, don't do anything
case $- in
    *i*) stty -ixon ;;
      *) return;;
esac

DOTFILES=$HOME/.dotfiles

# Solarized dircolors
eval `dircolors $DOTFILES/bash/dircolors-solarized/dircolors.ansi-dark`

# ---------------------------------
# Functions
# ---------------------------------

# Usage: grepfilter PATTERN [files...]
# Show contents of a file, but use grep to highlight a pattern
grepfilter() {
    if [ -e "$2" ]; then
        command grep --color=always -E "$1|" "${@:2}"
    else
        command grep --color=always -E "$1|"
    fi
}

# return 0 (ok) if xclip is installed and a display is connected
_have_xclip() {
    [ -n "$DISPLAY" ] || return 1
    command -pv xclip &> /dev/null
}

# Copy stdin to tmux buffer and x-clipboard if available.
# On display output, inverse fg/bg to indicate tmux, color green for X.
_capture_output() {
    read out
    local format=''
    if [ -n "$TMUX" ]; then
        echo -n "$out" | tmux load-buffer -
        format="${format}\e[7m"
    fi
    if _have_xclip; then
        echo -n "$out" | xclip -in
        format="${format}\e[92m"
    fi
    echo -e "${format}${out}\e[0m"
}

# Copy output of mktemp to clipboard (if xclip is available)
_mktemp_copy_filename() {
    command -p mktemp --tmpdir $USER.XXX $* | _capture_output
}
alias mktemp='_mktemp_copy_filename'

# Print absolute path to files
dnl m4: if `realpath` is available, use that in rp(), otherwise fall back to `readlink -f`.
syscmd([[hash realpath 2> /dev/null]])dnl
rp() {
    ifelse(sysval, [[0]], [[realpath --no-symlinks]], [[readlink -f]]) "$@" | _capture_output
}

# Lookup command in PATH and print/capture path to the file.
cmdpath() {
    type -fP "${1:?}" | _capture_output
}
complete -c cmdpath

# copy last command in history to clipboard
alias cath='head -n -0'
alias cphist='history 1 | perl -ne "print \$1 if /^(?:\s*\d+\s+)?(?:\[.+?\])?\s*(.*)\$/" | _capture_output'
alias d='dirs'
alias grep='grep --color=auto'
alias hist='git hist -10'
alias ll="ls -lh --time-style=long-iso"
alias ls="ls --color=auto"
alias mg='multigit.sh'
alias mv='mv -i'
alias o='popd'
alias p='pushd'
alias pwdc='pwd | _capture_output'
alias r='fc -s'
alias rm='rm -I'
alias tree='tree -C'
alias treefull='tree -Cfi'
alias v='vim -R'
VIMRUNTIME=`vim -e -T dumb --cmd 'exe "set t_cm=\<C-M>"|echo $VIMRUNTIME|quit' | tr -d '\015' `
alias l="$VIMRUNTIME/macros/less.sh"

export EDITOR=vim

shopt -s checkwinsize
shopt -s globstar

export PATH=`$DOTFILES/bin/mergepaths.pl $PATH $DOTFILES/bin`

export HISTIGNORE='&:ls:ll:history*:cphist'
export HISTCONTROL='ignoreboth:erasedups'
export HISTTIMEFORMAT="[%F %T] "

source $DOTFILES/bash/liquidprompt/liquidprompt

_nullglob_setting=$(shopt -p nullglob)
shopt -s nullglob
for rcfile in ~/.bashrc.d/*.bash; do
    . $rcfile
done
$_nullglob_setting  # restore
