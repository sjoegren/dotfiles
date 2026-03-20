-- dnf install python-lsp-server flake8
vim.lsp.config("python-lsp-server", {
	cmd = {'pylsp'},
	filetypes = {'python'},
	root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
	settings = {
		pylsp = {
			plugins = {
				flake8 = {
					enabled = true,
					maxLineLength = 88,
				},
				pycodestyle = {
					enabled = false
				}
			}
		}
	}
})
vim.lsp.enable("python-lsp-server")

-- dnf install nodejs-bash-language-server
vim.lsp.config("bashls", {
	cmd = { 'bash-language-server', 'start' },
	filetypes = { 'bash', 'sh' }
})
vim.lsp.enable("bashls")

-- npm install @ansible/ansible-language-server, update PATH
vim.lsp.config("ansiblels", {
	cmd = { "ansible-language-server", "--stdio" },
	filetypes = {'yaml.ansible'},
	root_markers = { "ansible.cfg", ".git" },
})
vim.lsp.enable("ansiblels")

vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end)
