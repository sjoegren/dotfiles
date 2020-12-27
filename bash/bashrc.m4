dnl vim: et ts=4 sw=4
# If not running interactively, don't do anything
case $- in
    *i*) stty -ixon ;;
      *) return;;
esac

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Solarized dircolors
eval $(dircolors DOTFILES_DIR/bash/dircolors-solarized/dircolors.ansi-dark)

# ---------------------------------
# Functions
# ---------------------------------

ifdef(`HAVE_rg', `
# Usage: gf (grepfilter) PATTERN [files...]
# Filter output through ripgrep and highlight matches.
gf() {
    local cmd="rg --no-column --no-line-number --colors match:bg:219 --colors match:fg:black"
    if [ -e "$2" ]; then
        $cmd "$1|" "${@:2}"
    else  # read from stdin
        $cmd "$1|"
    fi
}
')

# Copy stdin to tmux buffer and x-clipboard if available.
# On display output, inverse fg/bg to indicate tmux, color green for X.
_capture_output() {
    read out
    local format
ifdef(`HAVE_tmux', `
    if [ -n "$TMUX" ]; then
        echo -n "$out" | tmux load-buffer -
        format="${format}\e[7m"
    fi
')dnl
ifdef(`HAVE_xclip', `
    if [ -n "$DISPLAY" ]; then
        echo -n "$out" | xclip -in
        format="${format}\e[92m"
    fi
')dnl
    echo -e "${format:-}${out}\e[0m"
}

# Make named temporary file and print/capture filename.
# dotfiles-help: mktemp
_mktemp_copy_filename() {
    command -p mktemp $* | _capture_output
}
alias mktemp=_mktemp_copy_filename

# Usage: rp PATH | rp [-d] DIR | rp COMMAND
# Print and capture absolute path to file, dir, command, or file selected with fzf.
dnl m4: if realpath is available, use that in rp(), otherwise fall back to readlink -f.
rp() {
    local selected
    if [ $# -ge 1 ]; then
        if [ -f "$1" ]; then
            ifdef(`HAVE_realpath', `realpath --no-symlinks', `readlink -f') "$@" | _capture_output
        elif [ "$1" == "-d" ]; then
            shift
            ifdef(`HAVE_realpath', `realpath --no-symlinks', `readlink -f') "$@" | _capture_output
        elif hash "$1" 2> /dev/null; then
            cmdpath "$1"
            file $(type -fP "$1")
            return
        else
            # rp DIR: fzf find files in DIR
            ifdef(`HAVE_fzf', `', `return # no fzf')
            selected="$(FZF_DEFAULT_COMMAND="find '$1'" fzf)"
            [ -z "$selected" ] && return
            ifdef(`HAVE_realpath', `realpath --no-symlinks', `readlink -f')  | _capture_output
        fi
        return
    fi
    ifdef(`HAVE_fzf', `
    ifdef(`HAVE_realpath', `realpath --no-symlinks', `readlink -f') $(fzf) | _capture_output
    ')
}

# Lookup command in PATH and print/capture path to the file.
cmdpath() {
    type -fP "${1:?}" | _capture_output
}
complete -c cmdpath

syscmd(`git --version | check_version -q -r "version ([0-9]+\.[0-9]+\.[0-9]+)" -c 2.25 --mode=ge')dnl
# git hist between main..HEAD
hist() {
ifelse(sysval, `0', `dnl
    git config --local branch.master.remote > /dev/null
    if [ $? -eq 0 ]; then
        local default="master"
    elif [ $? -eq 1 ]; then
        local default="main"
    else
        return
    fi
    local current="$(git branch --show-current)"
    if [ "${current:-master}" == "$default" ]; then
        git hist -n 10
    else
        git hist -n 30 origin/$default~1..@
    fi
', `dnl
    git hist -n 10
')dnl
}

# Show diff with inter/intra-line changes in HTML.
hhdiffhtml() {
    hash hhdiff || return
    local tmpfile
    tmpfile="$(command -p mktemp --suffix=.html)"
    hhdiff --html $* > "$tmpfile"
    echo "Wrote diff to $tmpfile"
    xdg-open "$tmpfile"
}

ifdef(`HAVE_jq', `
# Usage: jql JSON_FILE
jql() {
	if [ ${#@} -eq 1 ]; then
		jq -C . $1 | less -R
	else
		jq -C $* | less -R
	fi
}')

# copy last command in history to clipboard
alias cath='head -n -0'
alias cphist='history 1 | perl -ne "print \$1 if /^(?:\s*\d+\s+)?(?:\[.+?\])?\s*(.*)\$/" | _capture_output'
alias d='dirs'
alias grep='grep --color=auto'
alias ll="ls -lh --time-style=long-iso"
alias ls="ls --color=auto"
alias mg='multigit.sh'
alias mv='mv -i'
alias o='popd'
alias p='pushd'
alias r='fc -s'
alias rm='rm -I'
alias tree='tree -C'
alias treefull='tree -Cfi'
alias v='vim -R'
alias l="ifdef(`HAVE_bat', `bat', `less -R')"

# Capture PWD in tmux/xclip
# dotfiles-help: pwdc
alias pwdc='pwd | _capture_output'

export EDITOR=vim

shopt -s checkwinsize
shopt -s globstar

export PATH=$(DOTFILES_DIR/bin/mergepaths.pl $PATH DOTFILES_DIR/bin $HOME/.local/bin $HOME/bin)

export HISTIGNORE='&:ls:ll:history*:cphist'
export HISTCONTROL='ignoreboth:erasedups'
export HISTTIMEFORMAT="[%F %T] "
export HISTSIZE=10000

source DOTFILES_DIR/bash/liquidprompt/liquidprompt

export RIPGREP_CONFIG_PATH=DOTFILES_DIR/ripgreprc

_nullglob_setting=$(shopt -p nullglob)
shopt -s nullglob
for f in DOTFILES_DIR/bash/*.bash; do
    . $f
done
DOTFILES=DOTFILES_DIR
for rcfile in ~/.bashrc.d/*.bash; do
    . $rcfile
done
unset DOTFILES
$_nullglob_setting  # restore
