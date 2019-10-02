#!/bin/bash
# Install minimal subset of dotfiles without dotbot, for older OSes without
# sane git versions and such.

set -euo pipefail

DOTDIR="${DOTDIR:-dotfiles}"

cd
ln -sfT "$DOTDIR" .dotfiles
ln -sfT "$DOTDIR/bash/bash_profile" .bash_profile
ln -sfT "$DOTDIR/bash/bashrc" .bashrc
ln -sfT "$DOTDIR/bash/liquidpromptrc" .liquidpromptrc
ln -sfT "$DOTDIR/inputrc" .inputrc
ln -sfT "$DOTDIR/vim" .vim
ln -sfT "$DOTDIR/gitconfig" .gitconfig
mkdir -p tmp/vim
chmod -R 700 tmp/vim
touch .vimrc_local

cd "$DOTDIR"
git submodule update --init --recursive

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
