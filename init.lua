local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
		vim.cmd([[packadd packer.nvim]])
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

require("packer").startup(function()
	use("wbthomason/packer.nvim")
	use("nvim-lua/plenary.nvim")

	use({
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup()

			local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
			function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
				opts = opts or {}
				opts.border = opts.border or "rounded"
				return orig_util_open_floating_preview(contents, syntax, opts, ...)
			end

			require("mason-lspconfig").setup_handlers({
				function(server_name)
					require("lspconfig")[server_name].setup({})
				end,
				["rust_analyzer"] = function()
					local extension_path = vim.env.HOME .. "/.vscode/extensions/vadimcn.vscode-lldb-1.8.1/"
					local codelldb_path = extension_path .. "adapter/codelldb"
					local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

					local rt = require("rust-tools")
					rt.setup({
						server = {
							on_attach = function(_, bufnr)
								vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
							end,
						},
						dap = {
							adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
						},
					})
				end,
			})
		end,
		requires = {
			"williamboman/mason-lspconfig.nvim",
			"neovim/nvim-lspconfig",
			"simrat39/rust-tools.nvim",
		},
	})
	use({
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.stylua,
				},
			})

			local rust_tool = {
				method = null_ls.methods.CODE_ACTION,
				filetypes = { "rust" },
				generator = {
					fn = function(params)
						local ok, rt = pcall(require, "rust-tools")
						if not ok then
							return
						end

						local actions = {}
						table.insert(actions, {
							title = "expand macro",
							action = function()
								vim.api.nvim_buf_call(params.bufnr, rt.expand_macro.expand_macro)
							end,
						})
						table.insert(actions, {
							title = "join lines",
							action = function()
								vim.api.nvim_buf_call(params.bufnr, rt.join_lines.join_lines)
							end,
						})

						return actions
					end,
				},
			}
			null_ls.register(rust_tool)

			local lsp_rename = {
				method = null_ls.methods.CODE_ACTION,
				filetypes = {},
				generator = {
					fn = function(params)
						local actions = {}
						local active_clients = vim.lsp.get_active_clients({ bufnr = params.bufnr })
						local cap_rename = false
						for _, val in pairs(active_clients) do
							if val.server_capabilities.renameProvider then
								cap_rename = true
								break
							end
						end

						if cap_rename then
							table.insert(actions, {
								title = "rename",
								action = function()
									vim.api.nvim_buf_call(params.bufnr, vim.lsp.buf.rename)
								end,
							})
						end

						return actions
					end,
				},
			}
			null_ls.register(lsp_rename)
		end,
	})

	use({
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

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

			cmp.setup({
				completion = {
					autocomplete = false,
				},
				-- Enable LSP snippets
				snippet = {
					expand = function(args)
						require('luasnip').lsp_expand(args.body)
					end,
				},
				mapping = {
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping(complete, { "i", "s" }),
					["<C-e>"] = cmp.mapping.abort(),
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
					{ name = "calc" }, -- source for math calculation
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
	})
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-nvim-lua")
	use("hrsh7th/cmp-nvim-lsp-signature-help")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-buffer")
	use("L3MON4D3/LuaSnip")
	use("saadparwaiz1/cmp_luasnip")

	use({
		"nvim-treesitter/nvim-treesitter",
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
						},
					},
				},
			})
		end,
		requires = {
			{
				"nvim-treesitter/nvim-treesitter-textobjects",
				after = "nvim-treesitter",
			},
			{
				"nvim-treesitter/nvim-treesitter-context",
				after = "nvim-treesitter",
			},
		},
	})

	use("mfussenegger/nvim-dap")
	use({
		"rcarriga/nvim-dap-ui",
		config = function()
			require("dapui").setup()
		end,
		requires = { "mfussenegger/nvim-dap" },
	})

	use({
		"ibhagwan/fzf-lua",
		config = function()
			require("fzf-lua").register_ui_select()
		end,
	})

	use("ellisonleao/gruvbox.nvim")
	use("kyazdani42/nvim-web-devicons")

	use("dstein64/vim-startuptime")
	use("lewis6991/impatient.nvim")

	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})
	use({
		"kylechui/nvim-surround",
		config = function()
			require("nvim-surround").setup()
		end,
	})
	use("RRethy/vim-illuminate")
	use({
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
					lualine_a = { "windows" },
					lualine_b = {},
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
					"nvim-tree",
					"toggleterm",
				},
			})
		end,
		requires = {
			"arkav/lualine-lsp-progress",
		},
	})
	use("folke/trouble.nvim")
	use("folke/which-key.nvim")
	use("b0o/mapx.nvim")
	use({
		"olimorris/persisted.nvim",
		config = function()
			require("persisted").setup({
				use_git_branch = true,
				before_save = function()
					vim.cmd("DiffviewClose")
					vim.cmd("TroubleClose")
				end,
				should_autosave = function()
					if vim.bo.filetype == "alpha" then
						return false
					end
					return true
				end,
			})
			-- require("telescope").load_extension("persisted")
		end,
	})
	use({
		"akinsho/toggleterm.nvim",
		config = function()
			require("toggleterm").setup({
				size = 20,
				shade_terminals = false,
			})
		end,
	})
	use("s3cy/term-util.nvim")
	use({
		"gbprod/substitute.nvim",
		config = function()
			require("substitute").setup()
		end,
	})
	use("sindrets/diffview.nvim")
	use({
		"chentoast/marks.nvim",
		config = function()
			require("marks").setup({
				force_write_shada = true,
			})
		end,
	})
	use({
		"AckslD/nvim-neoclip.lua",
		requires = {
			{ "kkharji/sqlite.lua", module = "sqlite" },
		},
		config = function()
			require("neoclip").setup({
				enable_persistent_history = true,
				continuous_sync = true,
				prompt = "Clip> ",
				keys = {
					fzf = {
						paste = false,
						paste_behind = false,
					},
				},
			})
		end,
	})
	use({
		"goolord/alpha-nvim",
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")
			dashboard.section.header.val = {
				[[                               __                ]],
				[[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
				[[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
				[[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
				[[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
				[[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
			}
			dashboard.section.buttons.val = {
				dashboard.button("f", "  Find file", ":lua require('fzf-lua').files()<cr>"),
				dashboard.button("g", "  Grep word", ":lua require('fzf-lua').live_grep_resume()<cr>"),
				dashboard.button("l", "  Load session", ":SessionLoad<cr>"),
				dashboard.button("q", "  Quit NVIM", ":qa<cr>"),
			}
			dashboard.config.opts.noautocmd = true
			alpha.setup(dashboard.config)
		end,
	})
	use({ "ojroques/nvim-osc52" })

	if packer_bootstrap then
		require("packer").sync()
	end
end)

if packer_bootstrap then
	return
end

require("impatient")

require("fzf-lua").setup({
	winopts = {
		border = false,
		fullscreen = true,
	},
	keymap = {},
	files = {
		fzf_opts = {
			["--history"] = vim.fn.stdpath("data") .. "/databases/fzf-lua-files-history",
		},
	},
	grep = {
		fzf_opts = {
			["--history"] = vim.fn.stdpath("data") .. "/databases/fzf-lua-grep-history",
		},
	},
})

vim.opt.number = true
vim.opt.relativenumber = true
vim.wo.wrap = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.undofile = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.g.loaded_netrw = 1 -- disable netrw
vim.g.loaded_netrwPlugin = 1

vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
vim.opt.shortmess = vim.opt.shortmess + { c = true }
vim.api.nvim_set_option("updatetime", 300)

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
vim.wo.foldenable = false

vim.opt.background = "dark"
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
	},
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
m = require("mapx").setup({ global = true, whichkey = true })
nnoremap("<leader>a", "<cmd>lua require('fzf-lua').args()<cr>", "Args")
nnoremap("<leader>f", "<cmd>lua require('fzf-lua').files()<cr>", "Find files")
nnoremap("<leader>g", "<cmd>lua require('fzf-lua').live_grep_resume()<cr>", "Grep string")
nnoremap("<leader>b", "<cmd>lua require('fzf-lua').buffers()<cr>", "Buffers")
nnoremap("<leader>m", "<cmd>lua require('fzf-lua').marks()<cr>", "Marks")
nnoremap("<leader>o", "<cmd>lua require('fzf-lua').lsp_document_symbols()<cr>", "Symbols outline")
nnoremap("<leader>p", "<cmd>lua require('neoclip.fzf')()<cr>", "Clipboard history")

m.nname("<leader>d", "Diffview")
nnoremap("<leader>dd", "<cmd>DiffviewOpen<cr>", "Diffview: Open")
nnoremap("<leader>df", "<cmd>DiffviewFileHistory<cr>", "Diffview: File history")
vnoremap("<leader>df", ":DiffviewFileHistory<cr>", "Diffview: File history")

m.nname("<leader>t", "Trouble")
nnoremap("<leader>tt", "<cmd>TroubleToggle<cr>", "Trouble: Toggle")
nnoremap("<leader>tw", "<cmd>TroubleToggle workspace_diagnostics<cr>", "Trouble: Workspace diagnostics")
nnoremap("<leader>td", "<cmd>TroubleToggle document_diagnostics<cr>", "Trouble: Document diagnostics")
nnoremap("<leader>tl", "<cmd>TroubleToggle loclist<cr>", "Trouble: Loclist")
nnoremap("<leader>tq", "<cmd>TroubleToggle quickfix<cr>", "Trouble: Quickfix")

nnoremap("ga", "<cmd>lua vim.lsp.buf.code_action()<cr>", "LSP: Code action")
nnoremap("gr", "<cmd>lua require('fzf-lua').lsp_references()<cr>", "LSP: References")
nnoremap("gi", "<cmd>lua require('fzf-lua').lsp_implementations()<cr>", "LSP: Implementations")
nnoremap("gq", "<cmd>lua vim.lsp.buf.format()<cr>", "LSP: Format")
nnoremap("gd", "<cmd>lua vim.lsp.buf.definition()<cr>", "LSP: Definition")
nnoremap("gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", "LSP: Declaration")

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

nnoremap("s", "<cmd>lua require('substitute').operator()<cr>", "Substitute: operator")
nnoremap("ss", "<cmd>lua require('substitute').line()<cr>", "Substitute: line")
vnoremap("s", "<cmd>lua require('substitute').visual()<cr>", "Substitute: visual")

nnoremap("<leader>s", "<cmd>lua require('substitute.range').operator()<cr>", "Substitute: range operator")
nnoremap("<leader>ss", "<cmd>lua require('substitute.range').word()<cr>", "Substitute: range word")
vnoremap("<leader>s", "<cmd>lua require('substitute.range').visual()<cr>", "Substitute: range visual")

nnoremap("sx", "<cmd>lua require('substitute.exchange').operator()<cr>", "Substitute: exchange operator")
nnoremap("sxx", "<cmd>lua require('substitute.exchange').line()<cr>", "Substitute: exchange line")

tnoremap("<C-t>", "<cmd>exe v:count1 . 'ToggleTerm'<cr>", "silent", "Toggle term")
nnoremap("<C-t>", "<cmd>exe v:count1 . 'ToggleTerm'<cr>", "silent", "Toggle term")
inoremap("<C-t>", "<esc><cmd>exe v:count1 . 'ToggleTerm'<cr>", "silent", "Toggle term")

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
