#!/bin/bash
# Used in tmux to open a URL with pipe-pane
# Usage: <content> | open_url_stdin.sh [--first]

set -euo pipefail

first_match="${1:-}"

url=
while read -r line; do
    if [[ "$line" =~ (https?://[^[:space:]]+) ]]; then
        url="${BASH_REMATCH[1]}"
        [ -n "$first_match" ] && break
    fi
done
xdg-open "$url"
