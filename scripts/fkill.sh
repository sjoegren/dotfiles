#!/bin/bash
# Select a process with fzf to kill, or navigate to the tmux pane owning the process.
set -euo pipefail

if [ -n "${1:-}" ]; then
    args="$@"
else
    args="-u $(id -u) -o pid,s,bsdstart,args"
fi

temp=$(mktemp)
trap 'rm -f $temp' EXIT

ps --sort=-pid $args | fzf-tmux -- --multi --reverse --header-lines=1 \
    --no-sort --no-mouse --exact --cycle --keep-right \
    --bind "ctrl-t:execute(tmux selectp -m -t ${TMUX_PANE:-notmux}; _tmux_find_pane.py --pid {1} | xargs tmux switchc -t)" \
    --expect ctrl-p \
    --expect ctrl-k \
    --header 'CTRL-p: print, CTRL-t: goto tmux pane, Enter: SIGTERM, CTRL-k: SIGKILL' > $temp
[ $? -eq 0 ] || exit

{
    read -u 9 action  # One of --expect keys, or empty
    while read -u 9 line; do
        if [[ "$line" =~ [0-9]{4,} ]]; then
            pid=$BASH_REMATCH
            case "$action" in
                "ctrl-p")
                    echo $pid ;;
                ""|"ctrl-k")
                    # Since we guessed that the pid was the first large-ish
                    # number on the line, show the guessed process to user and
                    # ask for confirmation.
                    ps -p $pid uww
                    set +e
                    pane=$(_tmux_find_pane.py --pid $pid)
                    if [ $? -eq 0 ]; then
                        pane=" (tmux pane: $pane)"
                    else
                        pane=""
                    fi
                    set -e
                    read -p "kill "${action:+-KILL}" ${pid}${pane} ? [y\N]: " confirm
                    if [ "$confirm" == "y" ]; then
                        /usr/bin/kill --verbose "${action:+-KILL}" "$pid"
                    fi
                    ;;
            esac
        fi
    done
} 9<$temp
