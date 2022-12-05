local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function()
	use 'wbthomason/packer.nvim'

	use { 'williamboman/mason.nvim', config = function()
		require("mason").setup()
	end}
	use 'williamboman/mason-lspconfig.nvim'

	use 'neovim/nvim-lspconfig'
	use { 'simrat39/rust-tools.nvim', config = function()
		local extension_path = vim.env.HOME .. '/.vscode/extensions/vadimcn.vscode-lldb-1.8.1/'
		local codelldb_path = extension_path .. 'adapter/codelldb'
		local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'

		local rt = require("rust-tools")
		rt.setup({
			server = {
			},
			dap = {
				adapter = require('rust-tools.dap').get_codelldb_adapter(
					codelldb_path, liblldb_path)
			}
		})
	end}

	use { 'hrsh7th/nvim-cmp', config = function()
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
				['<C-b>'] = cmp.mapping.scroll_docs(-4),
				['<C-f>'] = cmp.mapping.scroll_docs(4),
				['<C-Space>'] = cmp.mapping.complete(),
				['<C-e>'] = cmp.mapping.close()
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
	end}
	use 'hrsh7th/cmp-nvim-lsp'
	use 'hrsh7th/cmp-nvim-lua'
	use 'hrsh7th/cmp-nvim-lsp-signature-help'
	use 'hrsh7th/cmp-vsnip'
	use 'hrsh7th/cmp-path'
	use 'hrsh7th/cmp-buffer'
	use 'hrsh7th/vim-vsnip'

	use {
		'nvim-treesitter/nvim-treesitter',
		config = function()
			require('nvim-treesitter.configs').setup {
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
		end
	}
	use {
		'nvim-treesitter/nvim-treesitter-textobjects',
		config = function()
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
		end
	}
	use 'nvim-treesitter/nvim-treesitter-context'

	use 'mfussenegger/nvim-dap'
	use {
		"rcarriga/nvim-dap-ui",
		config = function()
			require("dapui").setup()
		end,
		requires = {"mfussenegger/nvim-dap"}
	}

	use {
		'nvim-telescope/telescope.nvim',
		config = function()
			require('telescope').setup({
				pickers = {
					buffers = {
						mappings = {
							i = {
								["<C-k>"] = "delete_buffer"
							},
							n = {
								["<C-k>"] = "delete_buffer"
							},
						},
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
			require('telescope').load_extension('neoclip')
			require('telescope').load_extension('macroscope')
		end,
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
			tabline = {
				lualine_a = {'windows'},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {'tabs'}
			},
			extensions = {
				'nvim-tree',
				'toggleterm'
			}
		}
	end}
	use { 'nvim-tree/nvim-tree.lua', config = function()
		require("nvim-tree").setup({
		})
	end}
	use { 'j-hui/fidget.nvim', config = function()
		require('fidget').setup()
	end}
	use 'folke/trouble.nvim'
	use 'folke/which-key.nvim'
	use 'b0o/mapx.nvim'
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
	use { 'chentoast/marks.nvim', config = function()
		require'marks'.setup {
			force_write_shada = true
		}
	end}
	use {
		'AckslD/nvim-neoclip.lua',
		requires = {
			{'kkharji/sqlite.lua', module = 'sqlite'},
		},
		config = function()
			require('neoclip').setup ({
				enable_persistent_history = true,
				continuous_sync = true,
				keys = {
					telescope = {
						i = {
							select = '<cr>',
							paste = false,
							paste_behind = false,
							replay = false,
							delete = '<C-k>',
						},
						n = {
							select = '<cr>',
							paste = false,
							paste_behind = false,
							replay = false,
							delete = '<C-k>',
						},
					},
				},
			})
		end
	}

	if packer_bootstrap then
		require('packer').sync()
	end
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

-- Diagnostic
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


-- Keymapping
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

m = require('mapx').setup{ global = true, whichkey = true }
telescope_builtin = require('telescope.builtin')
nnoremap("-", "<cmd>NvimTreeFindFile<cr>", "File explorer")
nnoremap("<leader>e", "<cmd>NvimTreeToggle<cr>", "File explorer toggle")
nnoremap("<leader>a", vim.lsp.buf.code_action, "LSP: Code action")
nnoremap("<leader>r", vim.lsp.buf.rename, "LSP: Rename")
nnoremap("<leader>f", function() telescope_builtin.find_files(); end, "Find files")
nnoremap("<leader>g", grep_string, "Grep string")
nnoremap("<leader>b", function() telescope_builtin.buffers({sort_lastused = true}); end, "Buffers")
nnoremap("<leader>m", function() telescope_builtin.marks(); end, "Marks")
nnoremap("<leader>p", function() require('telescope').extensions.neoclip.default(); end, "Clipboard history")
nnoremap("<leader>q", function() require('telescope').extensions.macroscope.default(); end, "Macro history")

m.nname("<leader>d", "Diffview")
nnoremap("<leader>dd", "<cmd>DiffviewOpen<cr>", "Diffview: Open")
nnoremap("<leader>df", "<cmd>DiffviewFileHistory<cr>", "Diffview: File history")

m.nname("<leader>t", "Trouble")
nnoremap("<leader>tt", "<cmd>TroubleToggle<cr>", "Trouble: Toggle")
nnoremap("<leader>tw", "<cmd>TroubleToggle workspace_diagnostics<cr>", "Trouble: Workspace diagnostics")
nnoremap("<leader>tw", "<cmd>TroubleToggle document_diagnostics<cr>", "Trouble: Document diagnostics")
nnoremap("<leader>tw", "<cmd>TroubleToggle loclist<cr>", "Trouble: Loclist")
nnoremap("<leader>tw", "<cmd>TroubleToggle quickfix<cr>", "Trouble: Quickfix")

nnoremap("gr", function() telescope_builtin.lsp_references(); end, "LSP: References")
nnoremap("gi", function() telescope_builtin.lsp_implementations(); end, "LSP: Implementations")

local trouble = require('trouble')
nnoremap("]q", function() trouble.next({skip_groups = true, jump = true}); end, "Trouble: Next item")
nnoremap("[q", function() trouble.previous({skip_groups = true, jump = true}); end, "Trouble: Previous item")
nnoremap("]Q", function() trouble.last({skip_groups = true, jump = true}); end, "Trouble: Last item")
nnoremap("[Q", function() trouble.first({skip_groups = true, jump = true}); end, "Trouble: First item")

local illuminate = require('illuminate')
nnoremap("]r", function() illuminate.goto_next_reference(true); end, "Next reference")
nnoremap("[r", function() illuminate.goto_prev_reference(true); end, "Previous reference")
nnoremap("K", vim.lsp.buf.hover, "LSP: hover")

local substitute = require('substitute')
nnoremap("s", function() substitute.operator(); end, "Substitute: operator")
nnoremap("ss", function() substitute.line(); end, "Substitute: line")
xnoremap("s", function() substitute.visual(); end, "Substitute: visual")

local substitute_range = require('substitute.range')
nnoremap("<leader>s", function() substitute_range.operator(); end, "Substitute: range operator")
nnoremap("<leader>ss", function() substitute_range.word(); end, "Substitute: range word")
xnoremap("<leader>s", function() substitute_range.visual(); end, "Substitute: range visual")

local substitute_exchange = require('substitute.exchange')
nnoremap("sx", function() substitute_exchange.operator(); end, "Substitute: exchange operator")
nnoremap("sxx", function() substitute_exchange.line(); end, "Substitute: exchange line")
xnoremap("sx", function() substitute_exchange.visual(); end, "Substitute: exchange visual")

tnoremap("<C-t>", [[<cmd>exe v:count1 . "ToggleTerm"<cr>]], "silent", "Toggle term")
nnoremap("<C-t>", [[<cmd>exe v:count1 . "ToggleTerm"<cr>]], "silent", "Toggle term")
inoremap("<C-t>", [[<esc><cmd>exe v:count1 . "ToggleTerm"<cr>]], "silent", "Toggle term")

-- Shell-style command moves
cnoremap("<C-a>", "<Home>")
cnoremap("<C-f>", "<Right>")
cnoremap("<C-b>", "<Left>")
cnoremap("<M-b>", "<S-Left>")
cnoremap("<M-f>", "<S-Right>")
cnoremap("<C-n>", "<Down>")
cnoremap("<C-p>", "<Up>")

nmap("<M-w>", "<C-w>")
tmap("<M-w>", "<C-\\><C-n><C-w>")

-- Faster window switching
nnoremap("<M-h>", "<cmd>wincmd h<cr>", "Go to the left window")
nnoremap("<M-j>", "<cmd>wincmd j<cr>", "Go to the down window")
nnoremap("<M-k>", "<cmd>wincmd k<cr>", "Go to the up window")
nnoremap("<M-l>", "<cmd>wincmd l<cr>", "Go to the right window")
nnoremap("<M-q>", "<cmd>wincmd q<cr>", "Quit a window")
nnoremap("<M-s>", "<cmd>wincmd s<cr>", "Split window")
nnoremap("<M-v>", "<cmd>wincmd v<cr>", "Split window vertically")
tnoremap("<M-h>", "<cmd>wincmd h<cr>", "Go to the left window")
tnoremap("<M-j>", "<cmd>wincmd j<cr>", "Go to the down window")
tnoremap("<M-k>", "<cmd>wincmd k<cr>", "Go to the up window")
tnoremap("<M-l>", "<cmd>wincmd l<cr>", "Go to the right window")
tnoremap("<M-q>", "<cmd>wincmd q<cr>", "Quit a window")
tnoremap("<M-s>", "<cmd>wincmd s<cr>", "Split window")
tnoremap("<M-v>", "<cmd>wincmd v<cr>", "Split window vertically")
tnoremap("<Esc>", "<C-\\><C-n>", "Exit insert mode")

