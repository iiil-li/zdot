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
	{ 'mtdl9/vim-log-highlighting' }
})

-- Basic settings
vim.opt.termguicolors = true
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Set colorscheme
vim.cmd [[colorscheme gruvbox]]

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
