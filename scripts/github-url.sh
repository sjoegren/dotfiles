#!/bin/bash
# List repo directories and feed to fzf, open URL to selected repo.
# Or if within git repo, open URL to current repo.
set -euo pipefail

# foo@fqdn.bar:path/to/repo.git => https://fqdn.bar/path/to/repo
# ssh://foo@fqdn.bar/path/to/repo.git => https://fqdn.bar/path/to/repo
# ssh://foo@fqdn.bar:22/path/to/repo.git => https://fqdn.bar/path/to/repo
make_web_url() {
	perl -pe 's#^(?:\w+://)?\w+@([\w\.]+)(?::\d+)?[:/](\S+?)(?:\.git)?$#https://\1/\2#'
}

if git rev-parse --show-toplevel &> /dev/null; then
	remote="$(perl -W -lne '/^\[remote "(.+)"\]/ && (print($1) && exit)' "$(git rev-parse --show-toplevel)/.git/config")"
	git config --local remote.$remote.url | make_web_url | xargs xdg-open
	exit 0
fi

cache_file=$HOME/.cache/github-urls.txt

# Remove cache file if it's older than one day
if [ -e "$cache_file" ]; then
	mtime=$(stat -c %Y $cache_file)
	limit=$(date -d '1 day ago' +%s)
	if [ $mtime -lt $limit ]; then
		mv -v $cache_file{,.old}
	fi
fi

# Cache doesn't exist, find all .git directories (and thus, git repos) and get
# url to remote called origin. Make http URLs from git@ urls.
if ! [ -e "$cache_file" ]; then
	# echo "Finding git repos in $HOME ..."
	fd --type directory --glob --hidden --no-ignore-vcs --ignore-file <(echo "$HOME/.*") \
		--exec git -C '{//}' config --local remote.origin.url \; \
		.git "$HOME" \
		| make_web_url | sort -u > "$cache_file" || :
fi

repo="$(fzf-tmux -- --reverse < "$cache_file")"
[ $? -eq 0 ] || exit
[ -n "$repo" ] || exit
xdg-open "$repo"
