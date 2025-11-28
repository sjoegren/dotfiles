# vim: ft=bash noexpandtab

[ "${dotfiles_os_id:-}" == "fedora" ] || return

# Solarized dircolors
eval $(dircolors ~/.dotfiles/dircolors)

eval "$(zoxide init --cmd cd bash)"

# Copy stdin to tmux buffer and clipboard if available.
# On display output, inverse fg/bg to indicate tmux, color green for X.
# Overrides function in main .bashrc
_capture_output() {
	read out
	local format
	if [ -n "$TMUX" ]; then
		echo -n "$out" | tmux load-buffer -
		format="${format}\e[7m"
	fi
	echo -n "$out" | wl-copy -p
	format="${format}\e[92m"
	echo -e "${format:-}${out}\e[0m"
}

# Make named temporary file and print/capture filename.
# dotfiles-help: mktemp
_mktemp_copy_filename() {
	command -p mktemp $* | _capture_output
}
alias mktemp=_mktemp_copy_filename

# Usage: rp [PATH | COMMAND | [-d] DIR]
# Print and capture absolute path (realpath) to file, dir, command, or file selected with fzf.
rp() {
	local selected
	if [ $# -ge 1 ]; then
		if [ -f "$1" ]; then
			realpath --no-symlinks "$@" | _capture_output
		elif [ "$1" == "-d" ]; then
			shift
			realpath --no-symlinks "$@" | _capture_output
		elif type -fP "$1" 2> /dev/null; then
			cmdpath "$1"
			file $(type -fP "$1")
			return
		else
			# rp DIR: fzf find files in DIR
			selected="$(FZF_DEFAULT_COMMAND="find '$1'" fzf)"
			[ -z "$selected" ] && return
			realpath --no-symlinks  | _capture_output
		fi
		return
	fi
	realpath --no-symlinks $(FZF_DEFAULT_COMMAND='fd' fzf) | _capture_output
}

# Lookup command in PATH and print/capture path to the file.
cmdpath() {
	type -fP "${1:?}" | _capture_output
}
complete -c cmdpath

# git hist between main..HEAD
hist() {
	git config --local branch.main.remote > /dev/null
	if [ $? -eq 0 ]; then
		local default="main"
	elif [ $? -eq 1 ]; then
		local default="master"
	else
		return
	fi
	local current="$(git branch --show-current)"
	if [ "${current:-main}" == "$default" ]; then
		git hist -n 10
	else
		parent="origin/${default}~1"
		if git log -n 1 "$parent" &>/dev/null; then
			git hist -n 30 origin/$default~1..@
		else
			git hist -n 30
		fi
	fi
}

# Launch fzf to select passwordstore entry to copy to clipboard
pw() {
	fd -t f --base-directory ~/.password-store | fzf-tmux -- --reverse | sed 's/\.gpg$//' | xargs pass show --clip
}
HISTIGNORE="$HISTIGNORE:pw"

# Start new ssh-agent and load PKCS11 keys for each connection
sshfw() {
	local cmd=''
	cmd+='ssh-add -cs /usr/lib64/p11-kit-proxy.so &&'
	cmd+='  echo -e "\n$(ssh-add -l)\n" &&'
	cmd+='  exec ssh'
	cmd+='    -o PKCS11Provider=none'
	cmd+='    -o PasswordAuthentication=no'
	cmd+='    -o GSSAPIAuthentication=no'
	cmd+='    -o PubkeyAuthentication=yes'
	cmd+='    -A "$@"'
	ssh-agent -- /bin/sh -c "$cmd" -- "$@"
}
_fzf_setup_completion host sshfw

#
# Settings overriding .bashrc
#

alias l='bat'
alias vim=nvim
