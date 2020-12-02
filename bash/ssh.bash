# ssh [ssh-args]
# without args, issue the last ssh command.
ssh() {
	local cache rv
	cache=~/.cache/last_ssh
	if [ $# -ge 1 ] && [ $1 != "-1" ]; then
		[ -e $cache ] && command mv $cache{,.1}
		echo "$@" > $cache
		command ssh "$@"
		history -s ssh "$@"
		rv=$?
		if [ $rv -ne 0 ] && [ -e $cache.1 ]; then
			command mv -f $cache{.1,}
		fi
		return $rv
	fi
	if [ "$1" == "-1" ]; then
		cache="$cache.1"
		shift
	fi
	if ! [ -r $cache ]; then
		echo "no cache file: $cache"
		command ssh
		return
	fi
	read -r line < $cache
	echo "run: ssh $line"
	command ssh $line
}
HISTIGNORE="$HISTIGNORE:ssh"
export HISTIGNORE
