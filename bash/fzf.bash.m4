ifdef(`HAVE_fzf', `', `return')
ifdef(`HAVE_fd', `
export FZF_DEFAULT_COMMAND="fd --type f"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
')
export FZF_DEFAULT_OPTS="--height 40% --ansi"
. /usr/share/fzf/shell/key-bindings.bash

# Select mv command from history and suggest to undo it.
undo_mv() {
	local lines old_dest old_src new_src REPLY
	mapfile -t lines < <(python -c 'import shlex,sys,os.path; print(*map(os.path.expanduser, shlex.split(sys.argv[1])), sep="\n")' "$(READLINE_LINE="'mv " __fzf_history__)")
	if [ ${#lines[*]} -lt 3 ] || [ ${lines[0]} != "mv" ]; then
		echo "Not a mv command"
		return
	fi
	old_dest="${lines[$(( ${#lines[*]} - 1 ))]}"
	old_src="${lines[$(( ${#lines[*]} - 2 ))]}"
	if [ -d "$old_dest" ]; then
		new_src="$(realpath -e "$old_dest")/$(basename "$old_src")"
	elif [ -e "$old_dest" ]; then
		new_src="$old_dest"
	fi
	if ! [ -e "$new_src" ]; then
		echo "source doesn't exist: $new_src"
		return
	fi
	cmd=(mv -iv "$new_src" "$old_src")
	read -p "${cmd[*]} [y/N]? : "
	if [ "$REPLY" == "y" ]; then
		${cmd[*]}
	fi
}
export HISTIGNORE="$HISTIGNORE:undo_mv"

# Usage: remove_from_path [-n|--no-export]
# Remove selected items from PATH
remove_from_path() {
	local out newpath rv oldpath
	out=$(tr : '\n' <<< "$PATH" | fzf-tmux -- --reverse --multi)
	rv=$?
	oldpath="$PATH"
	if [ $rv -eq 0 ]; then
		newpath="$(mergepaths.pl --delete "$(echo "$out" | tr '\n' :)" "$PATH")"
		if [ -z "$*" ]; then
			export PATH="$newpath"
			echo "# restore path:"
			echo "export PATH='$oldpath'"
		fi
		envprint.pl '^PATH$'
	fi
}

# fzf select files, copy absolute paths to tmux buffers, one per file.
# Use tmux choose-buffer from magic-menu and select buffers to paste.
copy_paths() {
	local -a files
	local i
	[ -n "$TMUX" ] || return
	files=( $(fzf-tmux -- --multi --preview-window right:hidden --preview 'bat {}' --bind 'ctrl-p:toggle-preview' --reverse --header 'Select files to load to tmux buffers (CTRL-P preview)') )
	[ $? -eq 0 ] || return
	for ((i = 0; i < ${#files[*]}; i++)); do
		tmux loadb - <<<"$(realpath "${files[$i]}")"
	done
	tmux display "Copied ${#files[*]} paths to tmux buffers"
}


#
# git key bindings (https://junegunn.kr/2016/07/fzf-git/)
# --------------------------------------
is_in_git_repo() {
	git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
	fzf-tmux -d 65% -- "$@" --border
}

_fzf_gf() {
	is_in_git_repo || return
	git -c color.status=always status --short |
		fzf-down -m --ansi --nth 2..,.. \
		--preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -'$LINES |
		cut -c4- | sed 's/.* -> //'
}

_fzf_gb() {
	is_in_git_repo || return
	git branch -a --color=always | grep -v '/HEAD\s' | sort |
		fzf-down --ansi --multi --tac --preview-window right:70% \
		--preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
		sed 's/^..//' | cut -d' ' -f1 |
		sed 's#^remotes/##'
}

_fzf_gt() {
	is_in_git_repo || return
	git tag --sort -version:refname |
		fzf-down --multi --preview-window right:70% \
		--preview 'git show --color=always {} | head -'$LINES
}

_fzf_gh() {
	is_in_git_repo || return
	local tmp key line
	local -a ids
	tmp=$(command mktemp)
	git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
		fzf-tmux -d 75% -- --ansi --no-sort --reverse --multi \
		--expect ctrl-f,ctrl-o,alt-s \
		--bind "ctrl-s:execute(grep -o '[a-f0-9]\{7,\}' <<< {} | xargs git show --color=always | delta --paging always > /dev/tty)" \
		--bind "alt-p:toggle-preview" \
		--header 'CTRL-f|s|o (commit --fixup/show/checkout), ALT-s git show, ALT-p preview' \
		--preview-window hidden \
		--preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES > $tmp
		# keep first line (--expect key) lines with commit id's
	# Open output file $tmp and read first line for --expect key and selected commit ids.
	{
		read -u 9 key  # One of --expect keys, or empty
		while read -u 9 line; do
			if [[ "$line" =~ ([a-f0-9]{7,}) ]]; then
				ids+=("$BASH_REMATCH")
			fi
		done
	} 9<$tmp
	rm $tmp
	[ ${#ids[*]} -eq 0 ] && return
	case "$key" in
		ctrl-f) echo "git commit --fixup ${ids[0]}"; return ;;
		ctrl-o) echo "git checkout ${ids[0]}"; return ;;
		alt-s) echo -n "git show " ;;
		*)
	esac
	echo ${ids[*]}
}

_fzf_gr() {
	is_in_git_repo || return
	git remote -v | awk '{print $1 "\t" $2}' | uniq |
		fzf-down --tac \
		--preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
		cut -d$'\t' -f1
}

_fzf_gstash() {
	is_in_git_repo || return
	git stash list |
		fzf-down \
		--preview 'cut -d: -f1 <<< {} | xargs git stash show --patch | head -200 | delta --paging never' |
		cut -d: -f1
}

bind '"\er": redraw-current-line'

# git fzf select filenames from git status to command line
# dotfiles-help: Ctrl-g Ctrl-s
bind '"\C-g\C-s": "$(_fzf_gf)\e\C-e\er"'

# git fzf select branches to command line
# dotfiles-help: Ctrl-g Ctrl-b
bind '"\C-g\C-b": "$(_fzf_gb)\e\C-e\er"'

# git fzf select tags to command line
# dotfiles-help: Ctrl-g Ctrl-t
bind '"\C-g\C-t": "$(_fzf_gt)\e\C-e\er"'

# git fzf select commit hashes to command line, possibly with specific commands.
# dotfiles-help: Ctrl-g Ctrl-h
bind '"\C-g\C-h": "$(_fzf_gh)\e\C-e\er"'

# git fzf select stash
# dotfiles-help: Ctrl-g Ctrl-o
bind '"\C-g\C-o": "$(_fzf_gstash)\e\C-e\er"'
