export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40%"
. /usr/share/fzf/shell/key-bindings.bash

# Print/capture selected git commit.
getcommit() {
    local sha1 description
    read -r _ sha1 description < <(git hist | fzf --no-sort --preview "git show --color=always {2}")
    echo "$sha1 - $description"
    echo $sha1 | _capture_output
}
