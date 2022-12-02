require('impatient')

require('packer').startup(function()
	use 'wbthomason/packer.nvim'

	use { 'williamboman/mason.nvim', config = function()
		require("mason").setup()
	end}
	use 'williamboman/mason-lspconfig.nvim'

	use 'neovim/nvim-lspconfig'
	use { 'simrat39/rust-tools.nvim', config = function()
		local rt = require("rust-tools")
		rt.setup({
			server = {
			},
			dap = {
			}
		})
	end}

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
	use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
	use 'stevearc/dressing.nvim'

	use 'ellisonleao/gruvbox.nvim'
	use 'kyazdani42/nvim-web-devicons'

	use 'dstein64/vim-startuptime'
	use 'lewis6991/impatient.nvim'

	use { 'numToStr/Comment.nvim', config = function()
		require('Comment').setup()
	end}
	use { 'kylechui/nvim-surround', config = function()
		require('nvim-surround').setup()
	end}
	use 'RRethy/vim-illuminate'
	use	{ 'nvim-lualine/lualine.nvim', config = function()
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
	end}
	use { 'nvim-tree/nvim-tree.lua', config = function()
		require("nvim-tree").setup({
			view = {
				mappings = {
					list = {
						{ key = "?", action = "toggle_help" },
					},
				},
			},
		})
	end}
	use { 'j-hui/fidget.nvim', config = function()
		require('fidget').setup()
	end}
	use 'folke/trouble.nvim'
	use 'folke/which-key.nvim'
	-- use 'samjwill/nvim-unception'
	-- use { 'rmagatti/auto-session', config = function()
	-- 	require('auto-session').setup()
	-- end}
	use { 'akinsho/toggleterm.nvim', config = function()
		require("toggleterm").setup({
			size = 20,
			shade_terminals = false,
		})
	end}
	use { 'gbprod/substitute.nvim', config = function()
		require('substitute').setup()
	end}
	use 'sindrets/diffview.nvim'
end)

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

-- Open 'trouble' instead of quickfix
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

local grep_string = function()
	local cword = vim.fn.expand("<cword>")
	require("telescope.builtin").grep_string({
		search = "",
		default_text = "'" .. cword,
		on_complete = cword ~= "" and {
			function(picker)
				local mode = vim.fn.mode()
				local keys = mode ~= "n" and "<ESC>" or ""
				vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes(keys .. [[$v^ll<C-g>]], true, false, true),
				"n",
				true
				)
				-- should you have more callbacks, just pop the first one
				table.remove(picker._completion_callbacks, 1)
				-- copy mappings s.t. eg <C-n>, <C-p> works etc
				vim.tbl_map(function(mapping)
					vim.api.nvim_buf_set_keymap(0, "s", mapping.lhs, mapping.rhs, {})
				end, vim.api.nvim_buf_get_keymap(0, "i"))
			end,
		} or nil,
	})
end

local wk = require('which-key')
wk.register({
	["<leader>"] = {
		f = { "<cmd> Telescope find_files<cr>", "Find files" },
		g = { grep_string, "Grep string" },
		d = {
			name = "Diffview",
			d = { "<cmd> DiffviewOpen<cr>", "Open" },
			f = { "<cmd> DiffviewFileHistory<cr>", "File history" },
		},
		t = {
			name = "Trouble",
			t = { "<cmd> TroubleToggle<cr>", "Toggle" },
			w = { "<cmd> TroubleToggle workspace_diagnostics<cr>", "Workspace diagnostics" },
			d = { "<cmd> TroubleToggle document_diagnostics<cr>", "Document diagnostics" },
			l = { "<cmd> TroubleToggle loclist<cr>", "Loclist" },
			q = { "<cmd> TroubleToggle quickfix<cr>", "Quickfix" },
		},
		e = { "<cmd> NvimTreeToggle<cr>", "File explorer" },
		a = { vim.lsp.buf.code_action, "Lsp code action" },
		r = { vim.lsp.buf.rename, "Lsp rename" },
	},
	["g"] = {
		r = { "<cmd> Telescope lsp_references<cr>", "Lsp references" },
		i = { "<cmd> Telescope lsp_implementations<cr>", "Lsp implementations" },
	},
	["]"] = {
		q = { function() require('trouble').next({skip_groups = true, jump = true}); end, "Next trouble item" },
		Q = { function() require('trouble').last({skip_groups = true, jump = true}); end, "Last trouble item" },
		r = { function() require('illuminate').goto_next_reference(true); end, "Next reference" },
	},
	["["] = {
		q = { function() require('trouble').previous({skip_groups = true, jump = true}); end, "Previous trouble item" },
		Q = { function() require('trouble').first({skip_groups = true, jump = true}); end, "First trouble item" },
		r = { function() require('illuminate').goto_prev_reference(true); end, "Previous reference" },
	},
	["s"] = {
		name = "Swap"
	},
	["K"] = { vim.lsp.buf.hover, "Lsp hover" }
})

vim.keymap.set("n", "s", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })
vim.keymap.set("n", "ss", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
vim.keymap.set("n", "S", "<cmd>lua require('substitute').eol()<cr>", { noremap = true })
vim.keymap.set("x", "s", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })
vim.keymap.set("n", "<leader>s", "<cmd>lua require('substitute.range').operator()<cr>", { noremap = true })
vim.keymap.set("x", "<leader>s", "<cmd>lua require('substitute.range').visual()<cr>", { noremap = true })
vim.keymap.set("n", "<leader>ss", "<cmd>lua require('substitute.range').word()<cr>", { noremap = true })

vim.cmd([[
autocmd TermEnter term://*toggleterm#*
      \ tnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>
nnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>
inoremap <silent><c-t> <Esc><Cmd>exe v:count1 . "ToggleTerm"<CR>

" `Alt-w` is the universal window swiching key for both regular buffers and
" terminal buffers.
nnoremap <A-w> <C-w>
nnoremap <A-w><A-b> <C-w>b
nnoremap <A-w><A-c> <C-w>c
nnoremap <A-w><A-d> <C-w>d
nnoremap <A-w><A-f> <C-w>f
nmap <A-w><A-g> <C-w>g
nnoremap <A-w><A-h> <C-w>h
nnoremap <A-w><A-i> <C-w>i
nnoremap <A-w><A-j> <C-w>j
nnoremap <A-w><A-k> <C-w>k
nnoremap <A-w><A-l> <C-w>l
nnoremap <A-w><A-n> <C-w>n
nnoremap <A-w><A-o> <C-w>o
nnoremap <A-w><A-p> <C-w>p
nnoremap <A-w><A-q> <C-w>q
nnoremap <A-w><A-r> <C-w>r
nnoremap <A-w><A-s> <C-w>s
nnoremap <A-w><A-t> <C-w>t
nnoremap <A-w><A-v> <C-w>v
nnoremap <A-w><A-w> <C-w>w
nnoremap <A-w><A-x> <C-w>x
nnoremap <A-w><A-z> <C-w>z
nnoremap <A-w><A-]> <C-w>]
nnoremap <A-w><A-^> <C-w>^
nnoremap <A-w><A-_> <C-w>_

tnoremap <A-w> <C-\><C-n><C-w>
tnoremap <A-w><A-b> <C-\><C-n><C-w>b
tnoremap <A-w><A-c> <C-\><C-n><C-w>c
tnoremap <A-w><A-d> <C-\><C-n><C-w>d
tnoremap <A-w><A-f> <C-\><C-n><C-w>f
tmap <A-w><A-g> <C-\><C-n><C-w>g
tnoremap <A-w><A-h> <C-\><C-n><C-w>h
tnoremap <A-w><A-i> <C-\><C-n><C-w>i
tnoremap <A-w><A-j> <C-\><C-n><C-w>j
tnoremap <A-w><A-k> <C-\><C-n><C-w>k
tnoremap <A-w><A-l> <C-\><C-n><C-w>l
tnoremap <A-w><A-n> <C-\><C-n><C-w>n
tnoremap <A-w><A-o> <C-\><C-n><C-w>o
tnoremap <A-w><A-p> <C-\><C-n><C-w>p
tnoremap <A-w><A-q> <C-\><C-n><C-w>q
tnoremap <A-w><A-r> <C-\><C-n><C-w>r
tnoremap <A-w><A-s> <C-\><C-n><C-w>s
tnoremap <A-w><A-t> <C-\><C-n><C-w>t
tnoremap <A-w><A-v> <C-\><C-n><C-w>v
tnoremap <A-w><A-w> <C-\><C-n><C-w>w
tnoremap <A-w><A-x> <C-\><C-n><C-w>x
tnoremap <A-w><A-z> <C-\><C-n><C-w>z
tnoremap <A-w><A-]> <C-\><C-n><C-w>]
tnoremap <A-w><A-^> <C-\><C-n><C-w>^
tnoremap <A-w><A-_> <C-\><C-n><C-w>_

" Shell-style command moves
cnoremap <C-a> <HOME>
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>
cnoremap <A-b> <S-Left>
cnoremap <A-f> <S-Right>
cnoremap <C-n> <DOWN>
cnoremap <C-p> <UP>

" Faster window switching
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-q> <C-w>q
nnoremap <A-s> <C-w>s
nnoremap <A-v> <C-w>v
tnoremap <A-j> <C-\><C-n><C-w>j
tnoremap <A-k> <C-\><C-n><C-w>k
tnoremap <A-l> <C-\><C-n><C-w>l
tnoremap <A-q> <C-\><C-n><C-w>q
tnoremap <A-h> <C-\><C-n><C-w>h
tnoremap <A-s> <C-\><C-n><C-w>s
tnoremap <A-v> <C-\><C-n><C-w>v

" Faster tab switching
nnoremap <A-t> :tabnext<CR>
nnoremap <A-T> :tabprevious<CR>
tnoremap <A-t> <C-\><C-n><C-w>:tabnext<CR>
tnoremap <A-T> <C-\><C-n><C-w>:tabprevious<CR>

" Esc to exit terminal insert mode
tnoremap <Esc> <C-\><C-n>

" `Q` to edit the default register; `"aQ` to edit register 'a'.
" TIPS: macros are stored in registers.
nnoremap Q :<C-u><C-r><C-r>='let @' . v:register .
			\ ' = ' . string(getreg(v:register))<CR><C-f><LEFT>
]])

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
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
		}
	}
})
require('telescope').load_extension('fzf')

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

