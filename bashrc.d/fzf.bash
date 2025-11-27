# vim: ft=bash noexpandtab

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"

DOTFILES_FZF_BASH_BINDINGS=${DOTFILES_FZF_BASH_BINDINGS:-/usr/share/fzf/shell/key-bindings.bash}
if ! [ -f $DOTFILES_FZF_BASH_BINDINGS ]; then
	return
fi

# Disable fd use with DOTFILES_ENABLE_FD=0
if [ "${DOTFILES_ENABLE_FD:-1}" == "1" ]; then
	export FZF_DEFAULT_COMMAND="fd --type f"
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

	# Use fd (https://github.com/sharkdp/fd) instead of the default find
	# command for listing path candidates.
	# - The first argument to the function ($1) is the base path to start traversal
	# - See the source code (completion.{bash,zsh}) for the details.
	_fzf_compgen_path() {
		fd --hidden --follow --exclude ".git" . "$1"
	}

	# Use fd to generate the list for directory completion
	_fzf_compgen_dir() {
		fd --type d --hidden --follow --exclude ".git" . "$1"
	}
fi

export FZF_DEFAULT_OPTS="--ansi --no-mouse --height=~75%"
source $DOTFILES_FZF_BASH_BINDINGS

. ~/.fzf-git.sh/fzf-git.sh

# Complete fzf git files
# dotfiles-help: CTRL-G CTRL-F

# Complete fzf git branches
# dotfiles-help: CTRL-G CTRL-B

# Complete fzf git tags
# dotfiles-help: CTRL-G CTRL-T

# Complete fzf git remotes
# dotfiles-help: CTRL-G CTRL-R

# Complete fzf git commit hashes
# dotfiles-help: CTRL-G CTRL-H

# Complete fzf git stashes
# dotfiles-help: CTRL-G CTRL-S

# Complete fzf git for-each-ref
# dotfiles-help: CTRL-G CTRL-E

# man ** - fzf completion
_fzf_complete_man() {
	_fzf_complete -i -- "$@" < <(
		fd --max-depth 2 --type f --extension gz . \
			$(manpath -g | tr ':' ' ') \
			--exec echo "{/.}" 2>/dev/null
		)
	}
_fzf_complete_man_post() {
	perl -pe 's/\.\d$//'
}
complete -F _fzf_complete_man -o default -o bashdefault man

_fzf_setup_completion path l bat
