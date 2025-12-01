# vim: et ts=4 sw=4
#
# sourced from ./setup

tmpdir="${XDG_RUNTIME_DIR:-/tmp}"
cloned="$tmpdir/dotfiles.$(id -u).cloned"
github="${DOTFILES_GITHUB_URL:-https://github.com}"

test -d "${VIM_PLUGIN_DIR?}"

gitclone() {
    local localdir
    localdir="${2:-$(basename -s .git $1)}"
    if [ -e "$localdir" ]; then
        if [ "${DOTFILES_ENABLE_GIT_PULL:-1}" == 1 ]; then
            runlog git -C $localdir pull
        else
            log would run git -C $localdir pull
        fi
    else
        runlog git clone --depth 5 "$1" "$localdir"
    fi
}

if [ -e "$cloned" ]; then
    log "git repos was cloned recently, skipping... ($(ls -l $cloned))"
    return
fi

gitclone $github/junegunn/fzf-git.sh.git .fzf-git.sh
gitclone $github/liquidprompt/liquidprompt.git .liquidprompt

# Neovim plugins
pushd $VIM_PLUGIN_DIR
gitclone $github/HiPhish/jinja.vim
gitclone $github/airblade/vim-gitgutter
gitclone $github/haya14busa/is.vim
gitclone $github/junegunn/fzf.vim
gitclone $github/junegunn/vim-easy-align
gitclone $github/morhetz/gruvbox
gitclone $github/pearofducks/ansible-vim
gitclone $github/psf/black
gitclone $github/scrooloose/nerdtree
gitclone $github/tpope/vim-commentary
gitclone $github/tpope/vim-eunuch
gitclone $github/tpope/vim-fugitive
gitclone $github/tpope/vim-repeat
gitclone $github/tpope/vim-surround
gitclone $github/tpope/vim-unimpaired
gitclone $github/vim-airline/vim-airline
gitclone $github/vim-airline/vim-airline-themes
gitclone $github/vimwiki/vimwiki
popd

if [[ "$XDG_CURRENT_DESKTOP" == GNOME* ]]; then
    gnome_focus_workspace_cloned_dir=.focus-follows-workspace.git
    gitclone $github/christopher-l/focus-follows-workspace.git $gnome_focus_workspace_cloned_dir
fi

touch "$cloned"
