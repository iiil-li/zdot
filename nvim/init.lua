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

-- Mason setup
require("mason").setup()

-- Mason LSPConfig setup
require("mason-lspconfig").setup {
	ensure_installed = { "lua_ls", "ts_ls", "gopls", "html", "cssls", "bashls", "pyright", "ansiblels" }
}

-- LSP setup
local lsp_zero = require('lsp-zero')
local null_ls = require("null-ls")
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

-- Individual LSP server configurations
local lspconfig = require('lspconfig')

-- Lua setup
lspconfig.lua_ls.setup({
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
			},
			diagnostics = {
				globals = { 'vim' },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = {
				enable = false,
			},
		},
	},
})
--ts pls
lspconfig.ts_ls.setup {
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
	on_attach = function(client, bufnr)
		-- Updated: Disable formatting in favor of another plugin
		client.server_capabilities.documentFormattingProvider = true
		client.server_capabilities.documentRangeFormattingProvider = true

		-- Optional: Define custom key mappings or settings here
		-- Example: Set up buffer local keymaps for LSP
		local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
		local opts = { noremap = true, silent = true }

		-- Mappings (examples)
		buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
		buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
		buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
		buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
	end,
	settings = {
		-- Optional: Specific settings for tsserver
		javascript = {
			suggest = {
				autoImports = true,
			},
		},
		typescript = {
			suggest = {
				autoImports = true,
			},
		},
	},
}

-- Bash setup
lspconfig.bashls.setup({
	on_attach = lsp_zero.on_attach,
	filetypes = { "sh", "bash" },
	root_dir = lspconfig.util.find_git_ancestor or lspconfig.util.path.dirname,
})

--json
-- JSON LSP setup (using vscode-json-languageserver)
lspconfig.jsonls.setup({
	on_attach = function(client, bufnr)
		lsp_zero.on_attach(client, bufnr)

		-- Ensure document formatting on save is enabled
		if client.server_capabilities.documentFormattingProvider then
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ async = false })
				end
			})
		end
	end,
	filetypes = { "json", "jsonc" }, -- JSON and JSON with Comments
	settings = {
		json = {
			validate = { enable = true }, -- Enable validation of JSON files
			format = { enable = true } -- Enable auto-formatting for JSON
		},
	},
	root_dir = lspconfig.util.find_git_ancestor or lspconfig.util.path.dirname,
})
-- TexLab setup
lspconfig.texlab.setup({
	settings = {
		texlab = {
			auxDirectory = ".",
			bibtexFormatter = "texlab",
			build = {
				args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
				executable = "latexmk",
				forwardSearchAfter = false,
				onSave = true,
			},
			forwardSearch = {
				args = { "--synctex-forward", "%l:1:%f", "%p" },
				executable = "zathura",
			},
			latexFormatter = "latexindent",
			latexindent = {
				modifyLineBreaks = true,
			},
		},
	},
})

-- Markdown setup (marksman)
lspconfig.marksman.setup({
	-- If you want to pass any specific settings for marksman, add them here
})
-- Null-ls setup for markdownlint via Mason
null_ls.setup({
	sources = {
		-- Connect markdownlint installed via Mason
		null_ls.builtins.diagnostics.markdownlint.with({
			command = vim.fn.stdpath("data") .. "/mason/bin/markdownlint", -- Use Mason-installed markdownlint
			filetypes = { "markdown" },               -- Enable markdownlint for Markdown files
			extra_args = { "--disable", "MD013" },    -- Example: Disable MD013 (line length)
		}),
		-- You can also set up markdownlint for formatting
		null_ls.builtins.formatting.markdownlint.with({
			command = vim.fn.stdpath("data") .. "/mason/bin/markdownlint", -- Use Mason-installed markdownlint
		}),
	},
})

-- Optional: If you want automatic formatting on save
vim.cmd [[autocmd BufWritePre *.md lua vim.lsp.buf.format({ async = true })]]

-- Go setup
lspconfig.gopls.setup({
	on_attach = lsp_zero.on_attach,
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
})

-- Python setup
lspconfig.pyright.setup({
	on_attach = lsp_zero.on_attach,
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "off",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
			},
		},
	},
})

-- Ansible setup
lspconfig.ansiblels.setup({
	on_attach = lsp_zero.on_attach,
	settings = {
		ansible = {
			ansibleLint = {
				enabled = true,
			},
			executionEnvironment = {
				enabled = false,
			},
		},
	},
	filetypes = { "yaml.ansible", "ansible" },
})
-- HTML setup
lspconfig.html.setup({
	on_attach = lsp_zero.on_attach,
	filetypes = { "html" },
	init_options = {
		configurationSection = { "html", "css", "javascript" },
		embeddedLanguages = {
			css = true,
			javascript = true
		},
	},
	settings = {
		html = {
			format = {
				enable = true, -- Enable formatting
				wrapLineLength = 120,
				wrapAttributes = "auto",
			},
		},
	},
})

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
