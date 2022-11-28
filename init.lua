require('packer').startup(function()
	use 'wbthomason/packer.nvim'

	use 'williamboman/mason.nvim'
	use 'williamboman/mason-lspconfig.nvim'

	use 'neovim/nvim-lspconfig'
	use 'simrat39/rust-tools.nvim'

	use 'hrsh7th/nvim-cmp'
	use 'hrsh7th/cmp-nvim-lsp'
	use 'hrsh7th/cmp-nvim-lua'
	use 'hrsh7th/cmp-nvim-lsp-signature-help'
	use 'hrsh7th/cmp-vsnip'
	use 'hrsh7th/cmp-path'
	use 'hrsh7th/cmp-buffer'
	use 'hrsh7th/vim-vsnip'

	use 'nvim-treesitter/nvim-treesitter'
	use 'nvim-treesitter/nvim-treesitter-textobjects'

	use 'mfussenegger/nvim-dap'

	use {
		'nvim-telescope/telescope.nvim',
		requires = { {'nvim-lua/plenary.nvim'} }
	}

	use 'ellisonleao/gruvbox.nvim'
	use 'kyazdani42/nvim-web-devicons'

	use 'dstein64/vim-startuptime'
	use 'lewis6991/impatient.nvim'

	use 'numToStr/Comment.nvim'
	use 'kylechui/nvim-surround'
	use 'RRethy/vim-illuminate'
	use	'nvim-lualine/lualine.nvim'
	use 'nvim-tree/nvim-tree.lua'
	use 'j-hui/fidget.nvim'
	use 'folke/trouble.nvim'
	use 'folke/which-key.nvim'
	use 'samjwill/nvim-unception'
	use 'rmagatti/auto-session'
end)

require('impatient')

vim.opt.number = true
vim.opt.relativenumber = true
vim.wo.wrap = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.undofile = true
vim.opt.cursorline = true
vim.g.loaded_netrw = 1 -- disable netrw
vim.g.loaded_netrwPlugin = 1

vim.opt.completeopt = {'menuone', 'noselect', 'noinsert'}
vim.opt.shortmess = vim.opt.shortmess + { c = true}
vim.api.nvim_set_option('updatetime', 300)

vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
vim.wo.foldenable = false

vim.opt.background = 'dark'
require('gruvbox').setup({
	italic = false,
	overrides = {
		SignColumn = {bg = '#282828'}
	}
})
vim.cmd([[
colorscheme gruvbox
]])

-- Remember cursor position
vim.api.nvim_create_autocmd(
"BufReadPost",
{ command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]] }
)

-- Show cursor line only in active window
local cursorGrp = vim.api.nvim_create_augroup("CursorLine", { clear = true })
vim.api.nvim_create_autocmd(
{ "WinEnter" },
{ pattern = "*", command = "set cursorline", group = cursorGrp }
)
vim.api.nvim_create_autocmd(
{ "WinLeave" },
{ pattern = "* if &buftype != 'Trouble'", command = "set nocursorline", group = cursorGrp }
)

-- Strip trailing whitespaces
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	pattern = { "*" },
	command = [[%s/\s\+$//e]],
})


require("mason").setup()
require('Comment').setup()
require('nvim-surround').setup()
require('auto-session').setup()
require('fidget').setup()

require('lualine').setup {
	options = {
		theme = 'gruvbox-material',
		component_separators = { left = '', right = ''},
		section_separators = { left = '', right = ''},
	},
	sections = {
		lualine_a = {},
		lualine_b = {{'filename', path=1}},
		lualine_c = {'branch', 'diff', 'diagnostics'},
		lualine_x = {'filetype', 'progress'},
		lualine_y = {},
		lualine_z = {},
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = {{'filename', path=1}},
		lualine_x = {'progress'},
		lualine_y = {},
		lualine_z = {}
	},
}

require("nvim-tree").setup()

local trouble = require('trouble.providers.telescope')
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	pattern = { "quickfix" },
	callback = function()
	local ok, trouble = pcall(require, "trouble")
	if ok then
		vim.defer_fn(function()
			vim.cmd('cclose')
			trouble.open('quickfix')
		end, 0)
	end
	end,
})

local wk = require('which-key')
wk.register({
	["<leader>"] = {
		f = {
			name = "Fuzzy finder",
			f = { "<cmd> Telescope find_files<cr>", "Find files" },
			g = { "<cmd> Telescope live_grep<cr>", "Live grep" },
			b = { "<cmd> Telescope buffers<cr>", "Buffers" },
			c = { "<cmd> Telescope command_history<cr>", "Command history" },
			s = { "<cmd> Telescope search_history<cr>", "Search history" },
		},
		t = {
			name = "Trouble",
			t = { "<cmd> TroubleToggle<cr>", "Toggle" },
			w = { "<cmd> TroubleToggle workspace_diagnostics<cr>", "Workspace diagnostics" },
			d = { "<cmd> TroubleToggle document_diagnostics<cr>", "Document diagnostics" },
			l = { "<cmd> TroubleToggle loclist<cr>", "Loclist" },
			q = { "<cmd> TroubleToggle quickfix<cr>", "Quickfix" },
		},
		e = {
			name = "File explorer",
			e = { "<cmd> NvimTreeToggle<cr>", "Toggle" },
			f = { "<cmd> NvimTreeFindFile<cr>", "Find current file in the explorer" },
			c = { "<cmd> NvimTreeCollapse<cr>", "Collapse" },
		},
	},
	["]"] = {
		q = { function() require('trouble').next({skip_groups = true, jump = true}); end, "Next trouble item" },
		Q = { function() require('trouble').last({skip_groups = true, jump = true}); end, "Last trouble item" },
		a = { function() require('illuminate').goto_next_reference(false); end, "Next reference" },
	},
	["["] = {
		q = { function() require('trouble').previous({skip_groups = true, jump = true}); end, "Previous trouble item" },
		Q = { function() require('trouble').first({skip_groups = true, jump = true}); end, "First trouble item" },
		a = { function() require('illuminate').goto_prev_reference(false); end, "Previous reference" },
	},
	["s"] = {
		name = "Swap"
	}
})

require('nvim-treesitter.configs').setup({
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["iB"] = { query = "@block.inner", desc = "inner Block" },
				["aB"] = { query = "@block.outer", desc = "outer Block" },
				["ib"] = { query = "@call.inner", desc = "inner block" },
				["ab"] = { query = "@call.outer", desc = "outer block" },
				["ic"] = { query = "@conditional.inner", desc = "inner Conditional" },
				["ac"] = { query = "@conditional.outer", desc = "outer Conditional" },
				["im"] = { query = "@function.inner", desc = "inner Method" },
				["am"] = { query = "@function.outer", desc = "outer Method" },
				["il"] = { query = "@loop.inner", desc = "inner Loop" },
				["al"] = { query = "@loop.outer", desc = "outer Loop" },
				["ia"] = { query = "@parameter.inner", desc = "inner Argument" },
				["aa"] = { query = "@parameter.outer", desc = "outer Argument" },
				["is"] = { query = "@statement.outer", desc = "inner Sentence" },
				["as"] = { query = "@statement.outer", desc = "outer Sentence" },
			},
		},
		swap = {
			enable = true,
			swap_next = {
				["sa"] = { query = "@parameter.inner", desc = "swap next Argument" },
				["ss"] = { query = "@statement.outer", desc = "swap next Sentence" },
			},
			swap_previous = {
				["sA"] = { query = "@parameter.inner", desc = "swap next Argument" },
				["sS"] = { query = "@statement.outer", desc = "swap next Sentence" },
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = {
				["]m"] = { query = "@function.outer", desc = "Next method start" },
				["]]"] = { query = "@class.outer", desc = "Next class start" },
			},
			goto_next_end = {
				["]M"] = { query = "@function.outer", desc = "Next method end" },
				["]["] = { query = "@class.outer", desc = "Next class end" },
			},
			goto_previous_start = {
				["[m"] = { query = "@function.outer", desc = "Previous method start" },
				["[["] = { query = "@class.outer", desc = "Previous class start" },
			},
			goto_previous_end = {
				["[M"] = { query = "@function.outer", desc = "Previous method end" },
				["[]"] = { query = "@class.outer", desc = "Previous class end" },
			}
		},
	},
})

require('telescope').setup({
	defaults = {
		mappings = {
		},
	},
})

local rt = require("rust-tools")
rt.setup({
	server = {
		on_attach = function(_, bufnr)
			-- Hover actions
			vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
			-- Code action groups
			vim.keymap.set("n", "ga", rt.code_action_group.code_action_group, { buffer = bufnr })
		end,
	},
	dap = {
	}
})

local sign = function(opts)
	vim.fn.sign_define(opts.name, {
		texthl = opts.name,
		text = opts.text,
		numhl = ''
	})
end

sign({name = 'DiagnosticSignError', text = ''})
sign({name = 'DiagnosticSignWarn', text = ''})
sign({name = 'DiagnosticSignHint', text = ''})
sign({name = 'DiagnosticSignInfo', text = ''})

vim.diagnostic.config({
	virtual_text = false,
	signs = true,
	update_in_insert = true,
	underline = true,
	severity_sort = false,
	float = {
		border = 'rounded',
		source = 'always',
		header = '',
		prefix = '',
	},
})

vim.cmd([[
set signcolumn=yes
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])

local cmp = require'cmp'
cmp.setup({
	-- Enable LSP snippets
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body)
		end,
	},
	mapping = {
		['<C-p>'] = cmp.mapping.select_prev_item(),
		['<C-n>'] = cmp.mapping.select_next_item(),
		-- Add tab support
		['<S-Tab>'] = cmp.mapping.select_prev_item(),
		['<Tab>'] = cmp.mapping.select_next_item(),
		['<C-S-f>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.close(),
		['<CR>'] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Insert,
			select = true,
		})
	},
	-- Installed sources:
	sources = {
		{ name = 'path' },                              -- file paths
		{ name = 'nvim_lsp', keyword_length = 3 },      -- from language server
		{ name = 'nvim_lsp_signature_help'},            -- display function signatures with current parameter emphasized
		{ name = 'nvim_lua', keyword_length = 2},       -- complete neovim's Lua runtime API such vim.lsp.*
		{ name = 'buffer', keyword_length = 2 },        -- source current buffer
		{ name = 'vsnip', keyword_length = 2 },         -- nvim-cmp source for vim-vsnip
		{ name = 'calc'},                               -- source for math calculation
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	formatting = {
		fields = {'menu', 'abbr', 'kind'},
		format = function(entry, item)
			local menu_icon ={
				nvim_lsp = 'λ',
				vsnip = '⋗',
				buffer = 'Ω',
				path = '🖫',
			}
			item.menu = menu_icon[entry.source.name]
			return item
		end,
	},
})

require('nvim-treesitter.configs').setup {
	ensure_installed = { "vim", "lua", "rust", "toml" },
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting=false,
	},
	ident = { enable = true },
	rainbow = {
		enable = true,
		extended_mode = true,
		max_file_lines = nil,
	}
}

