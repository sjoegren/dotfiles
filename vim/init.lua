-- vim: ft=lua ts=2
-- Neovim config
-- Plugins via native packages.

vim.opt.cursorline = true
vim.opt.colorcolumn = '100'
vim.opt.mouse = ''
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.shiftwidth = 0
vim.opt.tabstop = 4
vim.opt.softtabstop = -1
vim.opt.shiftround = true
vim.opt.showmatch = true
vim.opt.showmode = true
vim.opt.updatetime = 250		-- Update gutter faster (vim-gitgutter)
vim.opt.textwidth = 0
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.startofline = false

-- git hooks from git_template puts ctags file here.
vim.opt.tags:prepend('./.git/tags')
vim.opt.cpoptions:append({ d = true })

vim.opt.scrolloff = 1
vim.opt.sidescrolloff = 5

vim.opt.background = 'dark'
vim.cmd.colorscheme('gruvbox')

-- abbreviations
vim.cmd.cabbrev('set_ansible', 'set indentkeys-=-<CR>:set indentkeys-=<:>')

-- Plugin options
vim.g.airline_theme = 'gruvbox'
vim.g.airline_powerline_fonts = 1
vim.g['airline#extensions#branch#enabled'] = 0
vim.g['airline#extensions#virtualenv#enabled'] = 0

-- Do not register the default markdown file extensions as vimwiki files.
vim.g.vimwiki_ext2syntax = nil

vim.g.localvimrc_name = {'.lvimrc', '_vimrc_local.vim'}
vim.g.localvimrc_sandbox = 0
vim.g.localvimrc_persistent = 1

--
-- Mappings
--
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Easier completion commands (from :help ins-completion)
vim.keymap.set('i', '<C-]>', '<C-X><C-]>')
vim.keymap.set('i', '<C-F>', '<C-X><C-F>')
vim.keymap.set('i', '<C-D>', '<C-X><C-D>')
vim.keymap.set('i', '<C-L>', '<C-X><C-L>')

vim.keymap.set('n', 'Y', 'y$')

vim.keymap.set('n', 'Y', 'y$')

vim.keymap.set('n', '<C-n>', ':NERDTreeToggle<CR>')
vim.keymap.set('n', '<Leader>n', ':NERDTreeFind<CR>')

-- fzf.vim
vim.g.fzf_tags_command = 'git ctags || ctags -R'
vim.keymap.set('n', '<C-p>', ':Files<CR>')
vim.keymap.set('n', '<Leader>H', ':Files ~/<CR>')
vim.keymap.set('n', '<Leader>g', ':GFiles<CR>')
vim.keymap.set('n', '<Leader>G', ':GFiles?<CR>')
vim.keymap.set('n', '<Leader>b', ':Buffers<CR>')
vim.keymap.set('n', '<Leader>l', ':BLines<CR>')
vim.keymap.set('n', '<Leader>L', ':Lines<CR>')
vim.keymap.set('n', '<Leader>t', ':Tags<CR>')
vim.keymap.set('n', '<Leader>T', ':BTags<CR>')
vim.keymap.set('n', '<Leader>fm', ':Marks<CR>')
vim.keymap.set('n', '<Leader>h', ':History<CR>')
vim.keymap.set('n', '<Leader>f/', ':History/<CR>')
vim.keymap.set('n', '<Leader>fc', ':Commits<CR>')
vim.keymap.set('n', '<Leader>hh', ':Helptags<CR>')

vim.api.nvim_create_user_command(
	'Wikigrep',
	'call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>)." ~/vimwiki", 1, <bang>0)',
	{ bang = true, nargs = '*' }
)

-- Search for visually highlighted text incl spec chars
vim.keymap.set("v", "//", "y/<C-R>=escape(@\", '\\/.*$^~[]')<CR><CR>", { silent = true })

vim.keymap.set('n', '<leader><leader>g', ':GitGutterAll<CR>')

-- Start interactive EasyAlign in visual mode (e.g. vipga)
vim.keymap.set('x', 'ga', '<Plug>(EasyAlign)')
vim.keymap.set('v', '<Enter>', '<Plug>(EasyAlign)')
-- Start interactive EasyAlign for a motion/text object (e.g. gaip)
-- Align GitHub flavored Markdown tables: gaip*|
vim.keymap.set('n', 'ga', '<Plug>(EasyAlign)')

-- Reset cpoptions for all filetypes, after some plugin seemed to remove 'd'
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
	pattern = {"*"},
	callback = function(ev)
		vim.opt.cpoptions:append({ d = true })
	end
})

--
-- LSP
--
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
	pattern = {"*.py"},
	callback = function(ev)
		vim.lsp.start({
			name = 'python-lsp-server',
			cmd = {'pylsp'},
			root_dir = vim.fs.dirname(vim.fs.find(
				{'pyproject.toml', 'setup.py', 'requirements.txt'},
				{ upward = true }
			)[1]),
			settings = {
				pylsp = {
					plugins = {
						pycodestyle = {
							enabled = false
						},
						mccabe = {
							enabled = false
						},
						pyflakes = {
							enabled = false
						},
						flake8 = {
							enabled = true,
							maxLineLength = 88
						}
					}
				}
			}
		})
	end
})
