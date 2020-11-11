#!/bin/bash

set -euo pipefail

tmux_target="${1:-}"

debug() {
	if [ -n "${DEBUG:-}" ]; then
		echo "DEBUG: $*"
	fi
}

IFS=';'
panes="$(tmux display -p '#{P:#P:#{pane_current_command}:#{pane_pid};}')"
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
