# vim: ft=bash noexpandtab

# If not running interactively, don't do anything
case $- in
	*i*) stty -ixon ;;
	*) return;;
esac

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

if [ -e ~/.liquidprompt/liquidprompt ]; then
	source ~/.liquidprompt/liquidprompt
fi

DOTFILES="$HOME/.dotfiles"

# ---------------------------------
# Functions
# ---------------------------------

# Copy stdin to tmux buffer
_capture_output() {
	read out
	local format
	if [ -n "$TMUX" ]; then
		echo -n "$out" | tmux load-buffer -
		format="${format}\e[7m"
	fi
	echo -e "${format:-}${out}\e[0m"
}

alias gd='git diff'
alias gg='git status'
alias grep='grep --color=auto'
alias ll="ls -lh --time-style=long-iso"
alias ls="ls --color=auto"
alias mv='mv -i'
alias rm='rm -I'
alias tree='tree -C'
alias l='less -R'

export EDITOR=vim
export GIT_EDITOR=vim

shopt -s checkwinsize
shopt -s globstar

export PATH="$($DOTFILES/scripts/mergepaths.pl $PATH $DOTFILES/scripts $HOME/.local/bin)"
export HISTIGNORE='&:ls:ll:history*'
export HISTCONTROL='ignoreboth:erasedups'
export HISTTIMEFORMAT="[%F %T] "
export HISTSIZE=10000

dotfiles_os_id="$(. /etc/os-release && echo $ID)"  # fedora, rocky
export dotfiles_os_id
if [ -d ~/.bashrc.d ]; then
	shopt -s nullglob
	for rcfile in ~/.bashrc.d/*.bash; do
		source $rcfile
	done
	unset rcfile
	shopt -u nullglob
fi
unset dotfiles_os_id
