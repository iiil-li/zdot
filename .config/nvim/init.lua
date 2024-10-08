vim.g.mapleader = " "
vim.opt.clipboard = "unnamedplus"
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
local uv = vim.uv or vim.loop
-- Auto-install lazy.nvim if not present
if not uv.fs_stat(lazypath) then
	print('Installing lazy.nvim....')
	vim.fn.system({
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable', -- latest stable release
		lazypath,
	})
	print('Done.')
end
vim.opt.rtp:prepend(lazypath)

-- Lazy's list of plugins
require('lazy').setup({
	{ 'folke/tokyonight.nvim' },
	{ 'VonHeikemen/lsp-zero.nvim', branch = 'v3.x' },
	{ 'neovim/nvim-lspconfig' },
	{ 'hrsh7th/cmp-nvim-lsp' },
	{ 'hrsh7th/nvim-cmp' },
	{
		"jose-elias-alvarez/null-ls.nvim",
		dependencies = { "nvim-lua/plenary.nvim" }, -- Null-ls depends on plenary.nvim
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.diagnostics.markdownlint.with({
						command = vim.fn.stdpath("data") .. "/mason/bin/markdownlint", -- Path to markdownlint installed via Mason
						filetypes = { "markdown" },
						extra_args = { "--disable", "MD013" }, -- Disable specific rule, e.g., MD013 (line length)
					}),
					null_ls.builtins.formatting.markdownlint.with({
						command = vim.fn.stdpath("data") .. "/mason/bin/markdownlint", -- Formatting using markdownlint
					}),
				},
			})
		end,
	},

	{ 'L3MON4D3/LuaSnip' },
	{ 'ellisonleao/gruvbox.nvim' },
	{
		'nvim-treesitter/nvim-treesitter',
		build = ':TSUpdate'
	},
	-- Add Telescope
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.5',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	-- Add Harpoon
	{
		'ThePrimeagen/harpoon',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{ 'williamboman/mason.nvim',           config = true },
	{ 'williamboman/mason-lspconfig.nvim', config = true },
	--log highlihgting
	{ 'mtdl9/vim-log-highlighting' }
})

-- Basic settings
vim.opt.termguicolors = true
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Set colorscheme
vim.cmd [[colorscheme gruvbox]]

-- LSP setup
local lsp_zero = require('lsp-zero').preset({})
require("mason").setup()
require('mason-lspconfig').setup()


lsp_zero.on_attach(function(client, bufnr)
	lsp_zero.default_keymaps({ buffer = bufnr })

	-- Formatting on save
	if client.server_capabilities.documentFormattingProvider then
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function() vim.lsp.buf.format({ async = false }) end
		})
	end

	-- Keybinding for manual formatting
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>",
		{ noremap = true, silent = true })
end)

lsp_zero.setup()

-- Lazy install an LSP when requested
local function install_lsp(lsp_name)
	vim.cmd('MasonInstall ' .. lsp_name)
end

-- Function to check and install LSP on request
local function request_lsp_install(lsp_name)
	local present, lspconfig = pcall(require, 'lspconfig')

	if present and lspconfig[lsp_name] then
		lspconfig[lsp_name].setup({})
	else
		print('LSP not found. Installing ' .. lsp_name .. '...')
		install_lsp(lsp_name)
	end
end

-- Command to install LSP dynamically (e.g., `:LspInstall bashls`)
vim.api.nvim_create_user_command('LspInstall', function(opts)
	request_lsp_install(opts.args)
end, {
	nargs = 1,
	complete = function()
		-- Return a list of available LSPs for autocompletion
		return vim.tbl_keys(require('mason-lspconfig.mappings.server').package_to_lspconfig)
	end,
})

-- Example keybinding to install LSPs (optional)
vim.api.nvim_set_keymap('n', '<leader>li', ':LspInstall<Space>', { noremap = true, silent = false })

-- Optional: If you want automatic formatting on save
vim.cmd [[autocmd BufWritePre *.md lua vim.lsp.buf.format({ async = true })]]

-- Enable line wrapping for log files
vim.cmd [[ autocmd BufRead,BufNewFile *.log setlocal wrap ]]

-- nvim-cmp setup
local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
	mapping = cmp.mapping.preset.insert({
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-f>'] = cmp_action.luasnip_jump_forward(),
		['<C-b>'] = cmp_action.luasnip_jump_backward(),
		['<CR>'] = cmp.mapping.confirm({ select = false }),
		['<Tab>'] = cmp_action.tab_complete(),
		['<S-Tab>'] = cmp_action.select_prev_or_fallback(),
	})
})
-- Toggle "document mode" on and off
vim.api.nvim_set_keymap('n', '<leader>d', ':lua ToggleDocumentMode()<CR>', { noremap = true, silent = true })

-- Function to toggle between document mode and normal mode
function ToggleDocumentMode()
	if vim.opt.wrap:get() then
		-- Disable document mode
		vim.opt.wrap = false
		vim.opt.linebreak = false
		vim.opt.colorcolumn = ""
		vim.opt.number = true -- Turn line numbers back on
	else
		-- Enable document mode
		vim.opt.linebreak = true
		vim.opt.textwidth = 80
		vim.opt.colorcolumn = "80"
		vim.opt.number = false
	end
end

-- Treesitter setup
require 'nvim-treesitter.configs'.setup {
	ensure_installed = { "javascript", "typescript", "lua", "bash", "html", "css", "go" },
	highlight = {
		enable = true
	},
	fold = { enable = true },
	indent = { enable = true }
}

-- Folding settings
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false -- Disable folding at startup.
vim.opt.foldlevel = 99

-- Keymaps for folding
vim.keymap.set('n', '<space>f', 'za', { noremap = true, silent = true, desc = "Toggle fold under cursor" })
vim.keymap.set('n', '<space>F', 'zA', { noremap = true, silent = true, desc = "Toggle all folds under cursor" })
vim.keymap.set('n', 'zR', 'zR', { noremap = true, silent = true, desc = "Open all folds" })
vim.keymap.set('n', 'zM', 'zM', { noremap = true, silent = true, desc = "Close all folds" })

-- Telescope setup
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Harpoon setup
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)
