# vim: et ts=4 sw=4

gitclone() {
    local localdir
    localdir="${2:-$(basename $1)}"
    if [ -e "$localdir" ]; then
        if [ "${DOTFILES_ENABLE_GIT_PULL:-1}" == 1 ]; then
            runlog git -C $localdir pull
        else
            log would run git -C $localdir pull
        fi
    else
        runlog git clone "$1" "$localdir"
    fi
}

gitclone https://github.com/junegunn/fzf-git.sh.git .fzf-git.sh
gitclone https://github.com/liquidprompt/liquidprompt.git .liquidprompt
