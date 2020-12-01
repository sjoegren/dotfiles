_dirstack_file=/var/run/user/1000/dirstack.txt
dirstack() {
	cat <<-'EOF'
	dirstack commands:
	  pd   [DIR | ID]       go to new DIR, stack ID or dir on top of stack without argument.
	  pdl  [ID]             list dirstack or copy dir of ID.
	  pds  [REGEX]          go to first dir matching REGEX, or prompt for index.
	EOF
}

_init_dirstack() {
	touch $_dirstack_file
	_read_dirstack ${1:-$_dirstack_file}
}

_read_dirstack() {
	mapfile -t < <(sort -k 1 -t '|' -n -r "$1") _dirstack || return
}

_update_dirstack() {
	local entry dir timestamp
	# Put current directory on top of file
	echo "$(date +%s)|$PWD" > $_dirstack_file
	for entry in "${_dirstack[@]}"; do
		IFS='|' read -r timestamp dir <<<"$entry"
		if [ "$dir" != "$PWD" ]; then
			echo "$entry" >> $_dirstack_file
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
	local entry dir timestamp
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
	[ -z "$pds_found" ] && _init_dirstack
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

# pds [regex]
pds() {
	local dir timestamp
	_init_dirstack
	if [ -z "$1" ]; then
		_print_stack
		local sel
		read -p "go to index (empty cancels): " sel
		if [[ $sel =~ ^[0-9]+$ ]]; then
			pd $sel
		fi
		unset sel
		return
	fi
	for ((i = 0; i <= ${#_dirstack[*]} - 1; i++)); do
		# check if pattern $1 matches dirstack entry, except in $HOME
		if echo "${_dirstack[$i]//$HOME}" | grep -q -P "$1"; then
			IFS='|' read -r timestamp dir <<<"${_dirstack[$i]}"
			if [ "$dir" != "$PWD" ]; then
				printf "Found: %s   %s\n" "$(date -d@$timestamp '+%F %T')" "$dir"
				pds_found="$dir"
				break
			fi
		fi
	done
	if [ -n "$pds_found" ]; then
		pd "$pds_found"
	else
		echo "no match found"
	fi
	unset pds_found
	return
}

_print_stack() {
	local dir timestamp
	for ((i = 0; i <= ${#_dirstack[*]} - 1; i++)); do
		IFS='|' read -r timestamp dir <<<"${_dirstack[$i]}"
		printf "%2d  %s   %s\n" $i "$(date -d@$timestamp '+%F %T')" "$dir"
	done
}

pdl() {
	if ! [ -f "$_dirstack_file" ]; then
		echo "Dirstack is empty, add with: pd DIR"
		return
	fi
	local entry dir timestamp
	_init_dirstack
	if [ -n "$1" ] && [ -n "$TMUX" ]; then
		entry=$(_dirstack_get ${1:-}) || return
		IFS='|' read -r _ dir <<<"$entry"
		echo $dir | _capture_output
	else
		_print_stack
	fi
	unset _dirstack
}

complete -o nospace -F _cd pd

# TODO:
# - pdclear [index/all]
