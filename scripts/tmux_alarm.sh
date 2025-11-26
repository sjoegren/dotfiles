#!/bin/bash
set -eu

pidfile="/var/run/user/$(id -u)/$(basename "$0").pid"
statusfile="/var/run/user/$(id -u)/$(basename "$0").status"
opt_set=
alarm_arg=

usage() {
	cat <<-EOF
	Usage: $0 options

	Wait until the given timestamp has passed, then sound the alarm by
	modifying tmux status bar.

	Options:
	  --set timestamp       String accepted by "date --date", e.g. HH:MM, "20 min"
	  --clear, --kill       Clear current alarm by killing the running process.
	  --status [variable]   Print status of running process.
	EOF
	exit
}

cleanup() {
	rm -f "$pidfile" "$statusfile"
}

# Kill another alarm process that is currently running.
clear_alarm() {
	if [ -e "$pidfile" ]; then
		kill "$(cat "$pidfile")" || :
	fi
    cleanup
	exit
}

# status_right_msg MSG [fgcolor]
status_right_msg() {
	tmux set -g status-right "#[fg=colour235,bg=colour233]#[fg=colour250,bg=colour235] %H:%M:%S #[fg=${2:-colour130},bg=black,bold] [ $1 ]"
}

# Set time_left_s and return 0 if time_left_s > 0
time_left() {
	(( time_left_s = alarm_time - $(date +%s) ))
	(( time_left_s > 0 ))
}

failed() {
	status_right_msg "$(basename $0) exited" red
    cleanup
	exit 1
}

# Signal handler; someone (probably $0 --status) wants us to wake from sleep
# and report current status to a named pipe that the same someone is reading
# from.
report_status() {
	{
		cat <<-EOF >&9
			pid=$$
			alarm_time=$alarm_time_str
			time_left=$time_left_s
		EOF
	} 9>"$statusfile"
}

# print_status varname
# Read status from the named pipe written to by report_status().
print_status() {
	{
		if [ "$1" == 'all' ]; then
			cat <&9
		else
			awk -F= '$1 == "'"$1"'" { print $2 }' <&9
		fi
	} 9<"$statusfile"
	rm -f "$statusfile"
}

quit() {
	# Kill child jobs (sleep)
	kill -s SIGTERM $(jobs -p)
	status_right_msg "alarm cleared" colour34
	sleep 3
	tmux source-file ~/.tmux.conf
    cleanup
	exit 0
}

orig_args=( "$@" )
while [ -n "${1:-}" ]; do
	case "$1" in
		--set)              opt_set=1; shift; break ;;
		--kill|--clear)     clear_alarm ;;
		--status)
			mkfifo "$statusfile"
			kill -s USR1 "$(cat "$pidfile")"
			print_status "${2:-all}"
			exit
			;;
		-h|--help)          usage ;;
		-*)
			echo "unknown option: $1" >&2
			usage
			;;
	esac
done

if [ -n "${opt_set:-}" ]; then
	alarm_arg="$@"
fi
test -n "$alarm_arg" || usage

# Set the alarm

# Acquire exclusive lock and store pid in file, or exit if other process has the lock.
[ "${FLOCKER:-}" != "$pidfile" ] && exec env FLOCKER="$pidfile" flock -xn "$pidfile" "$0" "${orig_args[@]}"
echo $$ > $pidfile

trap failed ERR
trap quit TERM INT
trap report_status USR1

alarm_time=$(date --date "$alarm_arg" +%s)
alarm_time_str=$(date --date "@$alarm_time" +%X)

status_right_msg "alarm set $alarm_time_str"

alarm_color=207  # pink

while time_left; do
	if [ $time_left_s -lt 300 ]; then
		# < 5m remaining, make alarm time brighter as a hint.
		(( col = alarm_color - $time_left_s / 60 ))  # 202-207
		status_right_msg "alarm set $alarm_time_str" colour$col
	fi
	sleep 30 &
	wait -f || :
done

# Now, sound the alarm!
tmux set -g status-style bg=colour$alarm_color
status_right_msg "ALARM $alarm_time_str (C-a r to clear)" colour$alarm_color
