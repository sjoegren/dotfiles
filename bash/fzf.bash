export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40%"
. /usr/share/fzf/shell/key-bindings.bash

# Print/capture selected git commit.
getcommit() {
    local sha1 description
    read -r _ sha1 description < <(git hist | fzf --no-sort --preview "git show --color=always {2}")
    echo "$sha1 - $description"
    echo $sha1 | _capture_output
}


#
# git key bindings (https://junegunn.kr/2016/07/fzf-git/)
# --------------------------------------
is_in_git_repo() {
	git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
	fzf-tmux --height 50% "$@" --border
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
	git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
		fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
		--header 'Press CTRL-S to toggle sort' \
		--preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
		grep -o "[a-f0-9]\{7,\}"
}

_fzf_gr() {
	is_in_git_repo || return
	git remote -v | awk '{print $1 "\t" $2}' | uniq |
		fzf-down --tac \
		--preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
		cut -d$'\t' -f1
}

bind '"\er": redraw-current-line'

# git fzf select filenames from git status to command line
# dotfiles-help: Ctrl-g Ctrl-f
bind '"\C-g\C-f": "$(_fzf_gf)\e\C-e\er"'

# git fzf select branches to command line
# dotfiles-help: Ctrl-g Ctrl-b
bind '"\C-g\C-b": "$(_fzf_gb)\e\C-e\er"'

# git fzf select tags to command line
# dotfiles-help: Ctrl-g Ctrl-t
bind '"\C-g\C-t": "$(_fzf_gt)\e\C-e\er"'

# git fzf select commit hashes to command line
# dotfiles-help: Ctrl-g Ctrl-h
bind '"\C-g\C-h": "$(_fzf_gh)\e\C-e\er"'
