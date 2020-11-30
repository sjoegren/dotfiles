_init_dirstack() {
	touch /var/run/user/1000/dirstack.txt
	_read_dirstack
}

_read_dirstack() {
	mapfile -t < <(sort -k 1 -t '|' -n -r /var/run/user/1000/dirstack.txt) _dirstack || return
}

_update_dirstack() {
	_init_dirstack
	# Put current directory on top of file
	echo "$(date +%s)|$PWD" > /var/run/user/1000/dirstack.txt
	for entry in "${_dirstack[@]}"; do
		IFS='|' read -r timestamp dir <<<"$entry"
		if [ "$dir" != "$PWD" ]; then
			echo "$entry" >> /var/run/user/1000/dirstack.txt
		fi
	done
}

# _dirstack_get [index]
_dirstack_get() {
	if [ -n "$1" ]; then
		if [ -z "${_dirstack[$1]}" ]; then
			echo "no such index" >&2
			return 1
		fi
		echo ${_dirstack[$1]}
		return
	fi
	for entry in "${_dirstack[@]}"; do
		IFS='|' read -r timestamp dir <<<"$entry"
		if [ "$dir" != "$PWD" ]; then
			echo $entry
			return
		fi
	done
	echo "No directory found" >&2
	return 1
}

# pd [dir | index]
pd() {
	_init_dirstack
	local entry timestamp dir
	if [[ -z "$1" || $1 =~ ^[0-9]+$ ]]; then
		entry=$(_dirstack_get ${1:-}) || return
		IFS='|' read -r timestamp dir <<<"$entry"
		echo $dir
	else
		# assume $1 is a location cd can find (incl CDPATH)
		dir=$1
	fi
	cd $dir || return
	_update_dirstack || return
	unset _dirstack
}

pdl() {
	if ! [ -f "/var/run/user/1000/dirstack.txt" ]; then
		echo "Dirstack is empty, add with: pd DIR"
		return
	fi
	_init_dirstack
	for ((i = 0; i <= ${#_dirstack[*]} - 1; i++)); do
		IFS='|' read -r timestamp dir <<<"${_dirstack[$i]}"
		printf "%2d  %s   %s\n" $i "$(date -d@$timestamp +%T)" "$dir"
	done
	unset _dirstack
}

complete -o nospace -F _cd pd

# TODO:
# - pdclear [index/all]
