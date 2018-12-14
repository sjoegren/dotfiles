#!/bin/bash

# Display a list of the last 20 git commits and prompt to select one.
# The selected commit sha1 is copied to tmux buffer.

set -eu
IFS=$'\n'

commit_array=( $(git log --oneline --color=never --decorate --max-count=20) )
for (( i=0; i < ${#commit_array[*]}; i++ ))
do
    printf "%2d : %s\n" $i ${commit_array[$i]}
done

read -p "Select commit: " selected

IFS=$' '
read commit_id _ <<< "${commit_array[$selected]}"
if [ -n "$TMUX" ]; then
    echo -n $commit_id | tmux load-buffer -
else
    echo "Not in tmux, cannot copy..."
fi
echo ${commit_array[$selected]}
