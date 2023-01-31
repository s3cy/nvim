local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup({
	{
		"ellisonleao/gruvbox.nvim",
		config = function()
			local colors = require("gruvbox.palette")
			require("gruvbox").setup({
				italic = false,
				overrides = {
					SignColumn = { bg = colors.dark0 },
					GruvboxRedSign = { fg = colors.bright_red, bg = colors.dark0 },
					GruvboxGreenSign = { fg = colors.bright_green, bg = colors.dark0 },
					GruvboxYellowSign = { fg = colors.bright_yellow, bg = colors.dark0 },
					GruvboxBlueSign = { fg = colors.bright_blue, bg = colors.dark0 },
					GruvboxPurpleSign = { fg = colors.bright_purple, bg = colors.dark0 },
					GruvboxAquaSign = { fg = colors.bright_aqua, bg = colors.dark0 },
					GruvboxOrangeSign = { fg = colors.bright_orange, bg = colors.dark0 },
					MatchParen = { bg = colors.dark2, underline = true, bold = false },
					Visual = { bg = colors.dark4 },
				},
			})
		end,
	},
	"nvim-lua/plenary.nvim",
	"kyazdani42/nvim-web-devicons",
	"b0o/mapx.nvim",
	"folke/which-key.nvim",
	{
		"dstein64/vim-startuptime",
		config = function()
			vim.g.startuptime_exe_args = {
				"+let g:auto_session_enabled = v:false", -- disable auto-session
			}
			vim.g.startuptime_tries = 10
		end,
		cmd = "StartupTime",
	},
	{
		"rmagatti/auto-session",
		config = function()
			require("auto-session").setup({
				log_level = "error",
				pre_save_cmds = {
					"NvimTreeClose",
					"DiffviewClose",
					"TroubleClose",
					"DapTerminate",
					function()
						require("dapui").close()
					end,
				},
			})
		end,
		lazy = false,
	},

	{
		"neovim/nvim-lspconfig",
		config = function()
			require("mason").setup()

			local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
			function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
				opts = opts or {}
				opts.border = opts.border or "rounded"
				return orig_util_open_floating_preview(contents, syntax, opts, ...)
			end

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local mason_lspconfig = require("mason-lspconfig")
			mason_lspconfig.setup()
			mason_lspconfig.setup_handlers({
				function(server_name)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
						on_attach = function(client, bufnr)
							require("lsp-inlayhints").on_attach(client, bufnr)
						end,
						settings = {
							gopls = {
								analyses = {
									unusedparams = true,
									shadow = true,
								},
								staticcheck = true,
								hints = {
									assignVariableTypes = true,
								},
							},
						},
						init_options = {
							usePlaceholders = true,
						},
					})
				end,
				["rust_analyzer"] = function()
					local extension_path = vim.env.HOME .. "/.vscode/extensions/vadimcn.vscode-lldb-1.8.1/"
					local codelldb_path = extension_path .. "adapter/codelldb"
					local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

					local rt = require("rust-tools")
					rt.setup({
						server = {
							capabilities = capabilities,
							on_attach = function(client, bufnr)
								require("lsp-inlayhints").on_attach(client, bufnr)
								vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
							end,
						},
						tools = {
							inlay_hints = {
								auto = false,
							},
						},
						dap = {
							adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
						},
					})
				end,
			})
		end,
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"simrat39/rust-tools.nvim",
		},
		event = "BufReadPre",
	},
	{
		"tamago324/nlsp-settings.nvim",
		config = function()
			require("nlspsettings").setup({
				append_default_schemas = true,
				open_strictly = true,
			})
		end,
		-- cmd = { "LspSettings" },
		lazy = false,
	},
	{
		"lvimuser/lsp-inlayhints.nvim",
		branch = "anticonceal",
		config = function()
			require("lsp-inlayhints").setup()
		end,
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			vim.defer_fn(function()
				local null_ls = require("null-ls")
				null_ls.setup({
					sources = {
						null_ls.builtins.formatting.stylua,
						null_ls.builtins.formatting.dprint,
					},
				})
			end, 50)
		end,
		event = "VeryLazy",
	},
	{
		"olexsmir/gopher.nvim",
		ft = "go",
	},

	{
		"L3MON4D3/LuaSnip",
		event = { "InsertEnter" },
	},
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local complete = function()
				if not cmp.visible() then
					cmp.complete()
					vim.wait(500, function()
						return cmp.visible()
					end)
				end

				local entry = cmp.get_selected_entry()
				if not entry then
					cmp.select_next_item()
				end
			end

			local super_tab = function(fallback)
				if cmp.visible() then
					local entry = cmp.get_selected_entry()
					if not entry then
						cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
					else
						cmp.confirm()
					end
				elseif luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				elseif has_words_before() then
					complete()
				else
					fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
				end
			end

			local super_s_tab = function()
				if cmp.visible() then
					cmp.confirm()
				elseif luasnip.jumpable(-1) then
					luasnip.jump(-1)
				end
			end

			local abort = function()
				cmp.abort()
				cmp.core:reset()
			end

			cmp.setup({
				completion = {
					autocomplete = false,
				},
				-- Enable LSP snippets
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = {
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<Up>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<Down>"] = cmp.mapping.select_next_item(),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping(abort, { "i", "s" }),
					["<Tab>"] = cmp.mapping(super_tab, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(super_s_tab, { "i", "s" }),
				},
				-- Installed sources:
				sources = {
					{ name = "path" }, -- file paths
					{ name = "nvim_lsp" }, -- from language server
					{ name = "nvim_lsp_signature_help" }, -- display function signatures with current parameter emphasized
					{ name = "nvim_lua" }, -- complete neovim's Lua runtime API such vim.lsp.*
					{ name = "buffer" }, -- source current buffer
					{ name = "luasnip" }, -- nvim-cmp source for luasnip
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				formatting = {
					fields = { "menu", "abbr", "kind" },
					format = function(entry, item)
						local menu_icon = {
							nvim_lsp = "λ",
							luasnip = "⋗",
							buffer = "Ω",
							path = "🖫",
						}
						item.menu = menu_icon[entry.source.name]
						return item
					end,
				},
			})
		end,
		event = { "InsertEnter" },
		dependencies = {
			"LuaSnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
			"saadparwaiz1/cmp_luasnip",
		},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "vim", "lua" },
				auto_install = true,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				ident = { enable = true },
				rainbow = {
					enable = true,
					extended_mode = true,
					max_file_lines = nil,
				},
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
						},
						goto_next_end = {
							["]M"] = { query = "@function.outer", desc = "Next method end" },
						},
						goto_previous_start = {
							["[m"] = { query = "@function.outer", desc = "Previous method start" },
						},
						goto_previous_end = {
							["[M"] = { query = "@function.outer", desc = "Previous method end" },
						},
					},
				},
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		event = "BufReadPost",
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		config = function()
			require("treesitter-context").setup()
			vim.api.nvim_set_hl(0, "TreesitterContext", { link = "CursorLine" })
			vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { link = "CursorLineNr" })
		end,
		event = "BufReadPre",
	},

	{
		"mfussenegger/nvim-dap",
		config = function()
			vim.defer_fn(function()
				local dap = require("dap")
				local dapui = require("dapui")
				dapui.setup({
					layouts = {
						{
							elements = {
								"console",
								"repl",
							},
							size = 0.25,
							position = "bottom",
						},
						{
							elements = {
								"watches",
								"stacks",
								"breakpoints",
							},
							size = 45,
							position = "left",
						},
					},
				})
				dap.listeners.after.event_initialized["dapui_config"] = function()
					dapui.open()
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					dapui.close()
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					dapui.close()
				end

				dap.adapters.codelldb = {
					type = "server",
					port = "${port}",
					executable = {
						command = "codelldb",
						args = { "--port", "${port}" },
					},
				}
				require("nvim-dap-virtual-text").setup()
			end, 50)
		end,
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
		},
		event = "VeryLazy",
	},
	{
		"leoluz/nvim-dap-go",
		config = function()
			require("dap-go").setup()
			vim.cmd([[
 				command! GoDebug :lua require"dap-go".debug_test()
 				command! GoDebugLast :lua require"dap-go".debug_last_test()
 			]])
		end,
		ft = "go",
	},

	{
		"ibhagwan/fzf-lua",
		config = function()
			local fzf_lua = require("fzf-lua")
			fzf_lua.setup({})
			fzf_lua.register_ui_select({}, true) -- silent = true
		end,
		event = "VeryLazy",
	},
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup({
				options = {
					theme = "gruvbox-material",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = {},
					lualine_b = { { "filename", path = 1 } },
					lualine_c = { "branch", "diff", "diagnostics" },
					lualine_x = { "filetype", "progress" },
					lualine_y = {},
					lualine_z = {},
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { { "filename", path = 1 } },
					lualine_x = { "progress" },
					lualine_y = {},
					lualine_z = {},
				},
				tabline = {
					lualine_a = {},
					lualine_b = { "windows" },
					lualine_c = {},
					lualine_x = {},
					lualine_y = {
						{
							"lsp_progress",
							display_components = { "lsp_client_name", "spinner" },
							spinner_symbols = { "🌑 ", "🌒 ", "🌓 ", "🌔 ", "🌕 ", "🌖 ", "🌗 ", "🌘 " },
						},
					},
					lualine_z = { "tabs" },
				},
				extensions = {
					"toggleterm",
				},
			})
		end,
		dependencies = {
			"arkav/lualine-lsp-progress",
		},
		event = "VeryLazy",
	},
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "TroubleClose" },
	},
	{
		"akinsho/toggleterm.nvim",
		config = function()
			require("toggleterm").setup({
				size = 20,
				shade_terminals = false,
			})
		end,
		keys = "<C-space>",
	},
	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			require("nvim-tree").setup()
		end,
		cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile", "NvimTreeCollapse", "NvimTreeClose" },
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
	},

	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
		keys = {
			{ "gc", nil, mode = { "n", "x" } },
			{ "gb", nil, mode = { "n", "x" } },
			"gcc",
			"gbc",
		},
	},
	{
		"kylechui/nvim-surround",
		config = function()
			require("nvim-surround").setup()
		end,
		event = "VeryLazy",
	},
	{
		"RRethy/vim-illuminate",
		config = function()
			require("illuminate").configure({
				delay = 0,
			})
			vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "MatchParen" })
			vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "MatchParen" })
			vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "MatchParen" })
		end,
		event = "BufReadPost",
	},
	{
		"s3cy/term-util.nvim",
		event = "VeryLazy",
	},
	"cshuaimin/ssr.nvim",
	{
		"andymass/vim-matchup",
		event = "BufReadPost",
	},
	{
		"tpope/vim-abolish",
		event = "CmdlineEnter",
		keys = {
			{ "crc", nil, desc = "camelCase" },
			{ "crm", nil, desc = "MixedCase" },
			{ "cr_", nil, desc = "snake_case" },
			{ "crs", nil, desc = "snake_case" },
			{ "cru", nil, desc = "SNAKE_UPPERCASE" },
			{ "crU", nil, desc = "SNAKE_UPPERCASE" },
			{ "cr-", nil, desc = "dash-case" },
			{ "crk", nil, desc = "kebab-case" },
			{ "cr.", nil, desc = "dot.case" },
			{ "cr<space>", nil, desc = "space case" },
			{ "crt", nil, desc = "Title Case" },
		},
	},
	{
		"AckslD/nvim-neoclip.lua",
		config = function()
			require("neoclip").setup({
				enable_persistent_history = true,
				continuous_sync = true,
				on_paste = {
					set_reg = true,
				},
				prompt = "Clip> ",
				keys = {
					fzf = {
						select = false,
						paste = "default",
						paste_behind = false,
					},
				},
			})
		end,
		dependencies = {
			"kkharji/sqlite.lua",
		},
		event = "VeryLazy",
	},
	{
		"ojroques/nvim-osc52",
		keys = { '"+y', '"*y' },
	},
	"cbochs/portal.nvim",
	{
		"andrewferrier/debugprint.nvim",
		config = function()
			require("debugprint").setup({
				create_keymaps = false,
				display_counter = false,
			})
		end,
	},
}, {
	defaults = { lazy = true },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.undofile = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.showtabline = 2 -- always
vim.g.loaded_netrw = 1 -- disable netrw
vim.g.loaded_netrwPlugin = 1

vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
vim.opt.shortmess = vim.opt.shortmess + { c = true }
vim.api.nvim_set_option("updatetime", 300)

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
vim.wo.foldenable = false

vim.opt.background = "dark"
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
vim.api.nvim_create_autocmd({ "WinEnter" }, {
	pattern = "*",
	callback = function()
		vim.opt.cursorline = true
	end,
	group = cursorGrp,
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
	pattern = "*",
	callback = function()
		if vim.bo.filetype ~= "Trouble" then
			vim.opt.cursorline = false
		end
	end,
	group = cursorGrp,
})

-- Strip trailing whitespaces
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	pattern = { "*" },
	command = [[%s/\s\+$//e]],
})

-- Open 'trouble' instead of quickfix/loclist
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	pattern = { "quickfix" },
	callback = function()
		local buftype = "quickfix"
		if vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0 then
			buftype = "loclist"
		end

		local ok, trouble = pcall(require, "trouble")
		if ok then
			vim.api.nvim_win_close(0, true)
			trouble.toggle(buftype)
			vim.opt.cursorline = true
		end
	end,
})

-- Osc52 yank
local function copy(lines, _)
	require("osc52").copy(table.concat(lines, "\n"))
end

local function paste()
	return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end

vim.g.clipboard = {
	name = "osc52",
	copy = { ["+"] = copy, ["*"] = copy },
	paste = { ["+"] = paste, ["*"] = paste },
}

-- Diagnostic
local sign = function(opts)
	vim.fn.sign_define(opts.name, {
		texthl = opts.name,
		text = opts.text,
		numhl = "",
	})
end

sign({ name = "DiagnosticSignError", text = "" })
sign({ name = "DiagnosticSignWarn", text = "" })
sign({ name = "DiagnosticSignHint", text = "" })
sign({ name = "DiagnosticSignInfo", text = "" })

vim.diagnostic.config({
	virtual_text = false,
	float = {
		close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
		border = "rounded",
		header = "",
		source = "always",
		prefix = "",
		scope = "cursor",
	},
})

vim.api.nvim_create_autocmd("CursorHold", {
	buffer = bufnr,
	callback = function()
		for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
			-- check if floating window exists
			if vim.api.nvim_win_get_config(winid).zindex then
				return
			end
		end
		vim.diagnostic.open_float({ focusable = false })
	end,
})

-- Keymapping
m = require("mapx").setup({ global = "force", whichkey = true })
nnoremap("<leader><leader>", "<cmd>lua require('fzf-lua').resume()<cr>", "Args")
nnoremap("<leader>a", "<cmd>lua require('fzf-lua').args()<cr>", "Args")
nnoremap("<leader>f", "<cmd>lua require('fzf-lua').files()<cr>", "Find files")
nnoremap("<leader>g", "<cmd>lua require('fzf-lua').grep({search = ''})<cr>", "Grep string")
nnoremap("<leader>b", "<cmd>lua require('fzf-lua').buffers()<cr>", "Buffers")
nnoremap("<leader>m", "<cmd>lua require('fzf-lua').marks()<cr>", "Marks")
nnoremap("<leader>o", "<cmd>lua require('portal').jump_backward()<cr>", "Portal: Jump backward")
nnoremap("<leader>i", "<cmd>lua require('portal').jump_forward()<cr>", "Portal: Jump backward")
nnoremap("<leader>p", "<cmd>lua require('neoclip.fzf')()<cr>", "Clipboard history")
nnoremap("<leader>r", "<cmd>lua vim.lsp.buf.rename()<cr>", "LSP: Rename")

nnoremap("<leader>e", "<cmd>NvimTreeToggle<cr>", "NvimTree: Toggle")
nnoremap("-", "<cmd>NvimTreeFindFile<cr>", "NvimTree: Focus file")

m.nname("<leader>d", "Diffview")
nnoremap("<leader>dd", "<cmd>DiffviewOpen<cr>", "Diffview: Open")
nnoremap("<leader>df", "<cmd>DiffviewFileHistory<cr>", "Diffview: File history")
xnoremap("<leader>df", ":DiffviewFileHistory<cr>", "Diffview: File history")

nnoremap("<space>b", "<cmd>DapToggleBreakpoint<cr>", "DAP: Toggle breakpoint")
nnoremap("<space>k", "<cmd>lua require('dapui').eval()<cr>", "DAP: Evaluate")
xnoremap("<space>k", "<cmd>lua require('dapui').eval()<cr>", "DAP: Evaluate")

m.nname("<leader>t", "Trouble")
nnoremap("<leader>tt", "<cmd>TroubleToggle<cr>", "Trouble: Toggle")
nnoremap("<leader>tw", "<cmd>TroubleToggle workspace_diagnostics<cr>", "Trouble: Workspace diagnostics")
nnoremap("<leader>td", "<cmd>TroubleToggle document_diagnostics<cr>", "Trouble: Document diagnostics")
nnoremap("<leader>tl", "<cmd>TroubleToggle loclist<cr>", "Trouble: Loclist")
nnoremap("<leader>tq", "<cmd>TroubleToggle quickfix<cr>", "Trouble: Quickfix")

nnoremap("ga", "<cmd>lua vim.lsp.buf.code_action()<cr>", "LSP: Code action")
nnoremap("gr", "<cmd>lua require('fzf-lua').lsp_references()<cr>", "LSP: References")
nnoremap("gi", "<cmd>lua require('fzf-lua').lsp_implementations()<cr>", "LSP: Implementations")
nnoremap("gq", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", "LSP: Format")
nnoremap("gd", "<cmd>lua vim.lsp.buf.definition()<cr>", "LSP: Definition")
nnoremap("gD", "<cmd>lua vim.lsp.buf.type_definition()<cr>", "LSP: Declaration")

nnoremap("gp", function()
	return require("debugprint").debugprint({ motion = true })
end, "expr", "DebugPrint: Operator")
nnoremap("gP", function()
	return require("debugprint").debugprint({ motion = true, above = true })
end, "expr", "DebugPrintAbove: Operator")
xnoremap("gp", function()
	return require("debugprint").debugprint({ variable = true })
end, "expr", "DebugPrint: Operator")
xnoremap("gP", function()
	return require("debugprint").debugprint({ variable = true, above = true })
end, "expr", "DebugPrintAbove: Operator")
nnoremap("gpp", function()
	return require("debugprint").debugprint()
end, "expr", "DebugPrint")
nnoremap("gpP", function()
	return require("debugprint").debugprint({ above = true })
end, "expr", "DebugPrintAbove")
nnoremap("gpd", "<cmd>DeleteDebugPrints<cr>", "DebugPrint: Delete")
xnoremap("gpd", ":DeleteDebugPrints<cr>", "DebugPrint: Delete")

nnoremap("]q", "<cmd>lua require('trouble').next({ skip_groups = true, jump = true })<cr>", "Trouble: Next item")
nnoremap(
	"[q",
	"<cmd>lua require('trouble').previous({ skip_groups = true, jump = true })<cr>",
	"Trouble: Previous item"
)
nnoremap("]Q", "<cmd>lua require('trouble').last({ skip_groups = true, jump = true })<cr>", "Trouble: Last item")
nnoremap("[Q", "<cmd>lua require('trouble').first({ skip_groups = true, jump = true })<cr>", "Trouble: First item")

nnoremap("]r", "<cmd>lua require('illuminate').goto_next_reference(true)<cr>", "Next reference")
nnoremap("[r", "<cmd>lua require('illuminate').goto_prev_reference(true)<cr>", "Previous reference")
nnoremap("K", "<cmd>lua vim.lsp.buf.hover()<cr>", "LSP: hover")

nnoremap("<leader>s", "<cmd>lua require('ssr').open()<cr>", "Structural search and replace")
xnoremap("<leader>s", "<cmd>lua require('ssr').open()<cr>", "Structural search and replace")

local toggleterm = function()
	local tt = require("toggleterm")
	local count = vim.v.count
	if count == 0 then
		tt.toggle_all(false)
	else
		tt.toggle_command(nil, count)
	end
end
tnoremap("<C-space>", toggleterm, "silent", "Toggle term")
nnoremap("<C-space>", toggleterm, "silent", "Toggle term")
tnoremap("<M-space>", toggleterm, "silent", "Toggle term")
nnoremap("<M-space>", toggleterm, "silent", "Toggle term")

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

-- `Q` to edit the default register; `"aQ` to edit register 'a'.
-- TIPS: macros are stored in registers.
nnoremap(
	"Q",
	":<C-u><C-r><C-r>='let @' . v:register . ' = ' . string(getreg(v:register))<CR><C-f><LEFT>",
	"Edit Registers"
)
