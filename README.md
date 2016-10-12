# dotfiles

My config files, featuring bash, tmux, vim and others.

# Installation

Clone repo:

    cd
    git clone https://github.com/akselsjogren/dotfiles.git
    ln -s dotfiles .dotfiles    # needed by internal references

Create symlinks for the config files needed, e.g:

    ln -s .dotfiles/bash/bashrc .bashrc
    ln -s .dotfiles/vim .vim
    ln -s .dotfiles/vimrc .vimrc

# License

Released under The Unlicense license (see [UNLICENSE](UNLICENSE) for details).
Some scripts, with explicit license info included are released under the MIT license.
