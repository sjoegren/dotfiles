# vim: ft=gitconfig
[alias]
	alias = !git config --global --list | grep ^alias
	amend = commit --all --amend
	br = branch
	ci = commit
	co = checkout
	ctags = !.git/hooks/ctags
	hist = log --graph --pretty=format:'%Cred%h%Creset %Cblue%ad%Creset %s %Cgreen[%an] %C(auto)%d%Creset' --date=ifdef(`GIT_V1', `short', `human')
	st = status
[log]
	date = iso
[rebase]
	autoSquash = true
ifdef(`GIT_V1', `', `
[push]
	default = simple
')
[core]
	autocrlf = input
[grep]
	lineNumber = true
	patternType = perl
[merge]
	conflictStyle = diff3
	tool = vimdiff
[init]
	templatedir = ~/.dotfiles/git_template
[color]
	ui = auto
[include]
	path = ~/.gitconfig_local
