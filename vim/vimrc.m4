changequote(`[[', `]]')dnl
set nocompatible
"------------------------------------------------------------
" plug.vim plugin manager (Install with :PlugInstall)
"------------------------------------------------------------
call plug#begin()
Plug 'bronson/vim-trailing-whitespace'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'kana/vim-textobj-user'
Plug 'michaeljsmith/vim-indent-object'
Plug 'mihais/vim-mark'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'morhetz/gruvbox'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'beloglazov/vim-textobj-quotes'
ifdef([[BASIC_CONFIG]], [[" essential plugins]], [[dnl
dnl these are only included if not BASIC_CONFIG
Plug 'airblade/vim-gitgutter'
Plug 'bps/vim-textobj-python'
Plug 'editorconfig/editorconfig-vim'
Plug 'embear/vim-localvimrc'
Plug 'gilligan/textobj-gitgutter'
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'google/yapf', { 'rtp': 'plugins/vim', 'for': 'python' }
Plug 'haya14busa/is.vim'
Plug 'jparise/vim-graphql'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vimwiki/vimwiki'
if v:version > 800
    Plug 'psf/black'
    Plug 'dense-analysis/ale'
    Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
endif
]])
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

if exists(':packadd')
    packadd! matchit
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
set colorcolumn=100
set wildmenu        " Better command-line completion
set number          " always show line numbers
set relativenumber
set shiftwidth=0    " 0 is same as ts
set tabstop=4
set softtabstop=-1  " same as shiftwidth
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
set complete=.,w,i

" Remove - and = from filename completion
" Useful for <C-W> f, <C-X> <C-F>
set isfname-==

" git hooks from git_template puts ctags file here.
set tags^=./.git/tags
set cpoptions+=d

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

set background=dark
colorscheme gruvbox

let g:airline_theme = 'gruvbox'
let g:airline#extensions#branch#enabled = 0
ifdef([[HAVE_POWERLINE_FONTS]], [[let g:airline_powerline_fonts=1]])
let g:airline#extensions#virtualenv#enabled = 0

" Specific settings for different filetypes
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=<:>

" python.vim
let python_highlight_all = 1

" Do not register the default markdown file extensions as vimwiki files.
let g:vimwiki_ext2syntax = {}

let g:localvimrc_name = ['.lvimrc', '_vimrc_local.vim']

"------------------------------------------------------------
" Mappings
"------------------------------------------------------------

nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

" Easier completion commands (from :help ins-completion)
inoremap <C-]> <C-X><C-]>
inoremap <C-F> <C-X><C-F>
inoremap <C-D> <C-X><C-D>
inoremap <C-L> <C-X><C-L>

" Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
" which is the default
map Y y$

nmap <C-n> :NERDTreeToggle<CR>

" fzf.vim settings
let g:fzf_tags_command = 'git ctags || ctags -R'
nmap <C-p> :Files<CR>
nmap <Leader>H :Files ~/<CR>
nmap <Leader>g :GFiles<CR>
nmap <Leader>G :GFiles?<CR>
nmap <Leader>b :Buffers<CR>
nmap <Leader>l :BLines<CR>
nmap <Leader>L :Lines<CR>
nmap <Leader>t :Tags<CR>
nmap <Leader>T :BTags<CR>
nmap <Leader>fm :Marks<CR>
nmap <Leader>h :History<CR>
nmap <Leader>f/ :History/<CR>
nmap <Leader>fc :Commits<CR>
nmap <Leader>hh :Helptags<CR>

ifdef([[BASIC_CONFIG]], , [[
" :Wikigrep! PATTERN - run rg in vimwiki and launch fzf
command! -bang -nargs=* Wikigrep call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>)." ~/vimwiki", 1, <bang>0)
nmap <Leader>wt :VimwikiTOC<CR>

nmap <Leader><Leader>f :Black<CR>
]])

" Search for word under cursor in new split-window
" ,w / ,W
nnoremap <Leader>w :let @/='\<'.expand("<cword>").'\>'<Bar>split<Bar>normal n<CR>
nnoremap <Leader>W :let @/=expand("<cWORD>")<Bar>split<Bar>normal n<CR>

" Search for visually highlighted text incl spec chars
vmap <silent> // y/<C-R>=escape(@", '\\/.*$^~[]')<CR><CR>

" edit/source vimrc
nmap <silent> <leader>ev :tabedit $MYVIMRC.m4<CR>
nmap <silent> <leader>sv :source $MYVIMRC<CR>

nmap <leader><leader>g :GitGutterAll<CR>

nmap <silent> [v <Plug>(ale_previous_wrap)
nmap <silent> ]v <Plug>(ale_next_wrap)

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
vmap <Enter> <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
" Align GitHub flavored Markdown tables: gaip*|
nmap ga <Plug>(EasyAlign)

let @j='0"tyiwwviW//VN<...VngJ0"tPjk'

if filereadable(expand('~/.vimrc_local'))
  source ~/.vimrc_local
endif

function! InsertTodoComment()
    let c = split(&commentstring, '%s')[0] . "TODO(GIT_USER_NAME): "
    return c
endfunction
let @c="=InsertTodoComment()a"

" vim: ft=vim et sw=2
