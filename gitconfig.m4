dnl vim: ft=gitconfig
syscmd(`git --version | check_version -q -r "version ([0-9]+\.[0-9]+\.[0-9]+)" -c 2.21')dnl
[alias]
	alias = !git config --global --list | grep ^alias
	amend = commit --all --amend
	br = branch
	ci = commit
	co = checkout
	ctags = !.git/hooks/ctags
	hist = log --graph --pretty=format:'%Cred%h%Creset %Cblue%ad%Creset %s %Cgreen[%an] %C(auto)%d%Creset' --date=ifelse(sysval, `0', `human', `short')
	st = status
[log]
	date = iso
[rebase]
	autoSquash = true
ifelse(sysval, `0', `dnl
[push]
	default = simple
', `')dnl
[pull]
	ff = only
[core]
	autocrlf = input
[grep]
	lineNumber = true
	patternType = extended
[merge]
	conflictStyle = diff3
	tool = vimdiff
[init]
	templatedir = ~/.dotfiles/git_template
[color]
	ui = auto
[include]
	path = ~/.gitconfig_local
