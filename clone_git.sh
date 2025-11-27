# vim: et ts=4 sw=4

tmpdir="${XDG_RUNTIME_DIR:-/tmp}"
cloned="$tmpdir/dotfiles.$(id -u).cloned"

test -d "${VIM_PLUGIN_DIR?}"

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
        runlog git clone --depth 5 "$1" "$localdir"
    fi
}

if [ -e "$cloned" ]; then
    log "git repos was cloned recently, skipping... ($(ls -l $cloned))"
    return
fi

gitclone https://github.com/junegunn/fzf-git.sh.git .fzf-git.sh
gitclone https://github.com/liquidprompt/liquidprompt.git .liquidprompt

# Neovim plugins
gitclone https://github.com/psf/black $VIM_PLUGIN_DIR/black
gitclone https://github.com/junegunn/fzf.vim $VIM_PLUGIN_DIR/fzf.vim
gitclone https://github.com/junegunn/vim-easy-align $VIM_PLUGIN_DIR/vim-easy-align
gitclone https://github.com/airblade/vim-gitgutter $VIM_PLUGIN_DIR/gitgutter
gitclone https://github.com/morhetz/gruvbox $VIM_PLUGIN_DIR/gruvbox
gitclone https://github.com/haya14busa/is.vim $VIM_PLUGIN_DIR/is.vim
gitclone https://github.com/HiPhish/jinja.vim $VIM_PLUGIN_DIR/jinja.vim
gitclone https://github.com/scrooloose/nerdtree $VIM_PLUGIN_DIR/nerdtree
gitclone https://github.com/tpope/vim-commentary $VIM_PLUGIN_DIR/vim-commentary
gitclone https://github.com/tpope/vim-eunuch $VIM_PLUGIN_DIR/vim-eunuch
gitclone https://github.com/tpope/vim-repeat $VIM_PLUGIN_DIR/vim-repeat
gitclone https://github.com/tpope/vim-surround $VIM_PLUGIN_DIR/vim-surround
gitclone https://github.com/tpope/vim-unimpaired $VIM_PLUGIN_DIR/vim-unimpaired
gitclone https://github.com/vim-airline/vim-airline $VIM_PLUGIN_DIR/vim-airline
gitclone https://github.com/vim-airline/vim-airline-themes $VIM_PLUGIN_DIR/vim-airline-themes
gitclone https://github.com/vimwiki/vimwiki $VIM_PLUGIN_DIR/vimwiki

touch "$cloned"
