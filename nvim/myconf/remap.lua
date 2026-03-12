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

-- Start interactive EasyAlign in visual mode (e.g. vipga)
vim.keymap.set('x', 'ga', '<Plug>(EasyAlign)')
vim.keymap.set('v', '<Enter>', '<Plug>(EasyAlign)')
-- Start interactive EasyAlign for a motion/text object (e.g. gaip)
-- Align GitHub flavored Markdown tables: gaip*|
vim.keymap.set('n', 'ga', '<Plug>(EasyAlign)')
