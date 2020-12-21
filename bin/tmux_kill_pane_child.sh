#!/bin/bash
# Usage: tmux_kill_pane_child.sh [-t :win.pane]
# Example:
#   > tmux_kill_pane_child.sh
#   Pane  Child PID  Child command
#     2   1626187    vim /tmp/tmp.S5nltZ1Wfj
#     3   1624144    /usr/bin/python
#     4   1624027    watch date
#   Which panes process to kill? [2] (0 to cancel) 3
#   kill pid 1624144 (/usr/bin/python) [y/N] y


set -euo pipefail

debug() {
	if [ -n "${DEBUG:-}" ]; then
		echo "DEBUG: $*"
	fi
}

if [[ "${1:-}" == *-h* ]]; then
	while read -r line; do
		[[ "$line" =~ ^[^#] ]] && break
		[[ "$line" =~ ^#\  ]] && echo "${line:2}"
	done < $0
	exit 0
fi

IFS=';'
panes="$(tmux display -p $* '#{P:#P:#{pane_current_command}:#{pane_pid};}')"
echo "Pane  Child PID  Child command"
for pane in $panes; do
	IFS=':' read -r pane_id pane_cmd pane_pid <<< $pane
	debug "[$LINENO] pane_id: $pane_id, pane_pid: $pane_pid, pane_cmd: $pane_cmd"
	set +e
	child=$(ps --ppid $pane_pid -o pid=,args=)
	retval=$?
	set -e
	if [ $retval -ne 0 ]; then
		printf "  %-2d  (no child process)\n" $pane_id
		continue
	fi
	IFS=' ' read child_pid child_cmd <<<"$child"
	debug "[$LINENO] child_pid: $child_pid, child_cmd: $child_cmd"
	if [ $child_pid == $$ ]; then
		continue
	fi
	printf "  %-2d  %-9s  %s\n" $pane_id $child_pid "$child_cmd"
	pids[$pane_id]=$child_pid
	commands[$pane_id]="$child_cmd"
	if [ -z "${default_choice:-}" ]; then
		default_choice=$pane_id
	fi
done

read -p "Which panes process to kill? [$default_choice] (0 to cancel) " index
if [ -z "${index:-}" ]; then
	index=$default_choice
elif [ "$index" == "0" ]; then
	exit 0
fi
echo -n "kill pid ${pids[$index]} (${commands[$index]}) "
read -p "[y/N] " confirm
if [ "${confirm:-n}" == y ]; then
	kill ${pids[$index]}
fi
