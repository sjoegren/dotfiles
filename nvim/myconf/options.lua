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

-- Restrict Vimwiki's operation from other text files
vim.g.vimwiki_global_ext = 0

-- Reset cpoptions for all filetypes, after some plugin seemed to remove 'd'
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
	pattern = {"*"},
	callback = function(ev)
		vim.opt.cpoptions:append({ d = true })
	end
})
