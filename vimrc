" Set 'nocompatible' to ward off unexpected things that your distro might
" have made, as well as sanely reset options when re-sourcing .vimrc
set nocompatible

"------------------------------------------------------------
" plug.vim plugin manager (Install with :PlugInstall)
"------------------------------------------------------------
call plug#begin()
Plug 'christoomey/vim-tmux-navigator'
Plug 'davidhalter/jedi-vim'
Plug 'altercation/vim-colors-solarized'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'dir': '~/.dotfiles/fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'bronson/vim-trailing-whitespace'
call plug#end()

"------------------------------------------------------------
" Features
"------------------------------------------------------------

" These options and commands enable some very useful features in Vim, that
" no user should have to live without.

" Enable file type detection.
filetype plugin indent on

" Enable syntax highlighting
syntax on

" Specific settings for different filetypes
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=<:>

"------------------------------------------------------------
" jedi-vim settings
"------------------------------------------------------------
let g:jedi#use_tabs_not_buffers = 0     " use buffers for jedi-jumping
"let g:jedi#force_py_version = 3        " need vim with +python3 support
let g:jedi#show_call_signatures = 0

"------------------------------------------------------------
" Settings
"------------------------------------------------------------
" One of the most important options to activate. Allows you to switch from an
" unsaved buffer without saving it first. Also allows you to keep an undo
" history for multiple files. Vim will complain if you try to quit without
" saving, and swap files will keep you safe if your computer crashes.
set hidden

set wildmenu        " Better command-line completion
set number          " always show line numbers
set shiftwidth=4    " number of spaces to use for autoindenting
set softtabstop=4   " what happens when pressing <TAB>
set expandtab       " Expand tabs to spaces
set shiftround      " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch       " Show matching brace
set showmode        " Show mode I'm in
set showcmd         " Show command I'm typing
set ttyfast         " assume a fast terminal connection
set visualbell      " Try to flash instead
set t_vb=           " Turn off flashing too :-)
set nohlsearch      " turn off highlight searches
set mouse-=a
set updatetime=250  " Update vim-gitgutter faster
set textwidth=0     " Disable auto line-breaks
set ruler           " Display cursor position in status bar
set laststatus=2    " Always display status line
set directory=~/tmp/vim,.   " Swap files
let mapleader=","

" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Allow backspacing over autoindent, line breaks and start of insert action
set backspace=indent,eol,start

" When opening a new line and no filetype-specific indenting is enabled, keep
" the same indent as the line you're currently on. Useful for READMEs, etc.
set autoindent

" Stop certain movements from always going to the first character of a line.
" While this behaviour deviates from that of Vi, it does what most users
" coming from other editors would expect.
set nostartofline

" Set the command window height to 2 lines, to avoid many cases of having to
" "press <Enter> to continue"
"set cmdheight=2

" Incremental search
set incsearch

" If you have a pattern with at least one uppercase character,
" the search becomes case sensitive (:h usr_27)
set ignorecase
set ignorecase smartcase

" Remove - and = from filename completion
" Useful for <C-W> f, <C-X> <C-F>
set isfname-==

set background=dark
colorscheme solarized

" Overwrite colors from theme
hi String ctermfg=DarkMagenta

" Highlight ColorColumn
set colorcolumn=99

if has("gui_running")
  " GUI is running or is about to start.
  " Maximize gvim window
  set lines=999 columns=999
endif

"------------------------------------------------------------
" Mappings
"------------------------------------------------------------

" Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
" which is the default
map Y y$

" Enable swedish characters in insert mode
noremap! <Leader>å å
noremap! <Leader>Å Å
noremap! <Leader>ä ä
noremap! <Leader>Ä Ä
noremap! <Leader>ö ö
noremap! <Leader>Ö Ö

" Map swedish keys to something more useful
map! å `
map å `
map! Å $
map Å $
map! ö [
map ö [
map! ä ]
map ä ]
map! Ö {
map Ö {
map! Ä }
map Ä }

" Yank/put to clipboard
nnoremap <Leader>p "*p
nnoremap <Leader>P "*P
noremap <Leader>y "*y

nmap <C-n> :NERDTreeToggle<CR>
nmap <Leader>hl :set invhlsearch<CR>    " Toggle hlsearch
nmap <Leader>n :set nonumber!<CR>       " Toggle line numbers
set pastetoggle=<F2>                    " toggle :set paste/nopaste in insert mode

" Search for sub routine under cursor: ,x
nmap <leader>x yiw/^\s*\(sub\<bar>def\<bar>function\)\s\+<C-R>"<CR>

" Search for function definitions: ,f
nmap <leader>f /^\s*\(sub\<bar>def\<bar>function\)\s\+\w<CR>

" Search for word under cursor in new split-window
" ,w / ,W
nnoremap <Leader>w :let @/=expand("<cword>")<Bar>split<Bar>normal n<CR>
nnoremap <Leader>W :let @/='\<'.expand("<cword>").'\>'<Bar>split<Bar>normal n<CR>

" Search for visually highlighted text incl spec chars
vmap <silent> // y/<C-R>=escape(@", '\\/.*$^~[]')<CR><CR>

" Buffers - next/previous
nmap <TAB> :bn<CR>
nmap <S-TAB> :bp<CR>

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

" Easy window navigation (provided by plugin)
"map <C-h> <C-w>h
"map <C-j> <C-w>j
"map <C-k> <C-w>k
"map <C-l> <C-w>l

" Folding: create/toggle folds
inoremap <F11> <C-O>za
nnoremap <F11> za
onoremap <F11> <C-C>za
vnoremap <F11> zf

" fzf.vim
nnoremap <silent> <C-p> :Files<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>m :Marks<CR>
nnoremap <Leader>h :History<CR>
nnoremap <Leader>f :History/<CR>
nnoremap <Leader>g :GFiles<CR>

"------------------------------------------------------------
" Macros
"------------------------------------------------------------

" Insert TODO comment with timestamp
let @o="# TODO:  @ =strftime(\"%Y-%m-%d\")2Bhi"
