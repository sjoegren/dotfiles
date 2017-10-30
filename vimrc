set nocompatible

"------------------------------------------------------------
" plug.vim plugin manager (Install with :PlugInstall)
"------------------------------------------------------------
call plug#begin()
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'airblade/vim-gitgutter'
Plug 'altercation/vim-colors-solarized'
Plug 'bps/vim-textobj-python'
Plug 'bronson/vim-trailing-whitespace'
Plug 'christoomey/vim-tmux-navigator'
Plug 'kana/vim-textobj-user'
Plug 'michaeljsmith/vim-indent-object'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'w0rp/ale'
Plug 'sjl/gundo.vim'
Plug 'mfukar/robotframework-vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

"------------------------------------------------------------
" Features
"------------------------------------------------------------

if has('autocmd')
  filetype plugin indent on
endif
if has('syntax') && !exists('g:syntax_on')
  syntax enable
endif

"------------------------------------------------------------
" Settings
"------------------------------------------------------------
" One of the most important options to activate. Allows you to switch from an
" unsaved buffer without saving it first. Also allows you to keep an undo
" history for multiple files. Vim will complain if you try to quit without
" saving, and swap files will keep you safe if your computer crashes.
set hidden

set autoread
set cursorline      " Highlight line of cursor
set colorcolumn=120
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
set mouse-=a
set updatetime=250  " Update vim-gitgutter faster
set textwidth=0     " Disable auto line-breaks
set ruler           " Display cursor position in status bar
set laststatus=2    " Always display status line
set directory=~/tmp/vim,.   " Swap files
let mapleader=","

" Searching
set hlsearch
set incsearch
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

" Scan current buffer, buffers in other windows and tags for <C-N> completion
set complete-=i

" Remove - and = from filename completion
" Useful for <C-W> f, <C-X> <C-F>
set isfname-==

if !&scrolloff
  set scrolloff=1
endif
if !&sidescrolloff
  set sidescrolloff=5
endif

set display+=lastline

if &listchars ==# 'eol:$'
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
endif

if v:version > 703 || v:version == 703 && has("patch541")
  set formatoptions+=j " Delete comment character when joining commented lines
endif

set t_Co=16             " Set vim support to 16 colors
set background=dark
colorscheme solarized

let g:airline_theme='solarized'
let g:airline#extensions#branch#enabled = 0

if has("gui_running")
  " GUI is running or is about to start.
  " Maximize gvim window
  set lines=999 columns=999
endif

" Specific settings for different filetypes
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=<:>

let g:ale_set_loclist = 0

" python.vim
let python_highlight_all = 1

"------------------------------------------------------------
" Mappings
"------------------------------------------------------------

" Easier completion commands (from :help ins-completion)
inoremap <C-]> <C-X><C-]>
inoremap <C-F> <C-X><C-F>
inoremap <C-D> <C-X><C-D>
inoremap <C-L> <C-X><C-L>

" Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
" which is the default
map Y y$

" Kill line from cursor and return to insert
imap <C-k> <esc>lC

nmap <C-n> :NERDTreeToggle<CR>

" Search for word under cursor in new split-window
" ,w / ,W
nnoremap <Leader>w :let @/=expand("<cword>")<Bar>split<Bar>normal n<CR>
nnoremap <Leader>W :let @/='\<'.expand("<cword>").'\>'<Bar>split<Bar>normal n<CR>

" Search for visually highlighted text incl spec chars
vmap <silent> // y/<C-R>=escape(@", '\\/.*$^~[]')<CR><CR>

" edit/source vimrc
nmap <silent> <leader>ev :split $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

" NERDCommenter
vmap cc <plug>NERDCommenterAlignLeft
vmap cu <plug>NERDCommenterUncomment

nmap <leader>gg yiw:Glgrep <C-R>"<CR>

" trick to override mappings after plugins are loaded
autocmd VimEnter * nmap [x <Plug>(ale_previous)
autocmd VimEnter * nmap ]x <Plug>(ale_next)

" Insert TODO comment with timestamp
let @o="# TODO:  @ =strftime(\"%Y-%m-%d\")2Bhi"

nnoremap <leader>u :GundoToggle<CR>

source ~/.vimrc_local

" vim: set ft=vim et sw=2
