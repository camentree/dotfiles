--[[

 TODO:  
- :Tutor
- :help
- "<space>sh" to search help documentation

 NOTE: remember
- if errors, :checkhealth
- vim.o sets simple values; vim.opt sets list/map
- autocommands are functions that get run when something else happens
- :%s/old/new/g to change all occurences in file


 NOTE: keymaps
- [d and ]d     previous/next LSP diagnositc in buffer
- gg            beginning of file
- /             search (then `n` and `N` for next/previous)
- <space>q      diagnostics
- <C>           control
- <S>           shift
- <A>           alt
- <CR>          enter
- grd           go to definition of variable under cursor
- grt           go to type of variable under cursort
- *             highlight all occurences of word under cursor
- grn           rename variable under cursor
 
--]]

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- [[ OPTIONS ]]
vim.schedule(function()
	-- schedule settings after `UIEnter` to decrease startup time
	vim.o.clipboard = "unnamedplus"
end)

vim.o.number = true
vim.o.mouse = "a"
vim.o.showmode = false
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "auto"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = false
vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.scrolloff = 10 -- when scrolling how many lines to keep above/below cursor
vim.o.confirm = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

-- [[ DIAGNOSTICS ]]
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = { min = vim.diagnostic.severity.WARN } },
	virtual_text = true,
	jump = { float = true },
})

-- [[ BASIC KEYMAPS ]]
--vim.keymap.set(mode, key, function, metadata)
vim.keymap.set(
	"n",
	"<Esc>",
	"<cmd>nohlsearch<CR>",
	{ desc = "Escape to unhighlight search returns" }
)
vim.keymap.set(
	"n",
	"<leader>q",
	vim.diagnostic.setloclist,
	{ desc = "Open diagnostic [Q]uickfix list" }
)
vim.keymap.set(
	"n",
	"<C-h>",
	"<C-w><C-h>",
	{ desc = "Move focus to the left window" }
)
vim.keymap.set(
	"n",
	"<C-l>",
	"<C-w><C-l>",
	{ desc = "Move focus to the right window" }
)
vim.keymap.set(
	"n",
	"<C-j>",
	"<C-w><C-j>",
	{ desc = "Move focus to the lower window" }
)
vim.keymap.set(
	"n",
	"<C-k>",
	"<C-w><C-k>",
	{ desc = "Move focus to the upper window" }
)

-- [[ AUTOCOMMANDS ]]
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup(
		"kickstart-highlight-yank",
		{ clear = true }
	),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- [[ PLUGINS ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require("lazy").setup({
	{ "NMAC427/guess-indent.nvim", opts = {} },
	{
		"lewis6991/gitsigns.nvim",
		---@module 'gitsigns'
		---@type Gitsigns.Config
		---@diagnostic disable-next-line: missing-fields
		opts = {
			signs = {
				add = { text = "+" }, ---@diagnostic disable-line: missing-fields
				change = { text = "~" }, ---@diagnostic disable-line: missing-fields
				delete = { text = "_" }, ---@diagnostic disable-line: missing-fields
				topdelete = { text = "‾" }, ---@diagnostic disable-line: missing-fields
				changedelete = { text = "~" }, ---@diagnostic disable-line: missing-fields
			},
			current_line_blame = false,
			current_line_blame_opts = {
				delay = 300,
			},
		},
		config = function(_, opts)
			require("gitsigns").setup(opts)
			-- Show git blame only in visual mode
			vim.api.nvim_create_autocmd("ModeChanged", {
				pattern = "*:[vV\x16]*",
				callback = function()
					require("gitsigns").toggle_current_line_blame(true)
				end,
			})
			vim.api.nvim_create_autocmd("ModeChanged", {
				pattern = "[vV\x16]*:*",
				callback = function()
					require("gitsigns").toggle_current_line_blame(false)
				end,
			})
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VimEnter",
		---@module 'which-key'
		---@type wk.Opts
		---@diagnostic disable-next-line: missing-fields
		opts = {
			delay = 300,
			icons = { mappings = vim.g.have_nerd_font },
			spec = {
				{ "<leader>s", group = "[S]earch", mode = { "n", "v" } },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
				{ "gr", group = "LSP Actions", mode = { "n" } },
			},
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		enabled = true,
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
			local builtin = require("telescope.builtin")
			vim.keymap.set(
				"n",
				"<leader>sh",
				builtin.help_tags,
				{ desc = "[S]earch [H]elp" }
			)
			vim.keymap.set(
				"n",
				"<leader>sk",
				builtin.keymaps,
				{ desc = "[S]earch [K]eymaps" }
			)
			vim.keymap.set("n", "<leader>sf", function()
				builtin.find_files({ hidden = true })
			end, { desc = "[S]earch [F]iles" })
			vim.keymap.set(
				"n",
				"<leader>ss",
				builtin.builtin,
				{ desc = "[S]earch [S]elect Telescope" }
			)
			vim.keymap.set(
				{ "n", "v" },
				"<leader>sw",
				builtin.grep_string,
				{ desc = "[S]earch current [W]ord" }
			)
			vim.keymap.set(
				"n",
				"<leader>sg",
				builtin.live_grep,
				{ desc = "[S]earch by [G]rep" }
			)
			vim.keymap.set(
				"n",
				"<leader>sd",
				builtin.diagnostics,
				{ desc = "[S]earch [D]iagnostics" }
			)
			vim.keymap.set(
				"n",
				"<leader>sr",
				builtin.resume,
				{ desc = "[S]earch [R]esume" }
			)
			vim.keymap.set(
				"n",
				"<leader>s.",
				builtin.oldfiles,
				{ desc = '[S]earch Recent Files ("." for repeat)' }
			)
			vim.keymap.set(
				"n",
				"<leader>sc",
				builtin.commands,
				{ desc = "[S]earch [C]ommands" }
			)
			vim.keymap.set(
				"n",
				"<leader><leader>",
				builtin.buffers,
				{ desc = "[ ] Find existing buffers" }
			)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup(
					"telescope-lsp-attach",
					{ clear = true }
				),
				callback = function(event)
					local buf = event.buf
					vim.keymap.set(
						"n",
						"grr",
						builtin.lsp_references,
						{ buffer = buf, desc = "[G]oto [R]eferences" }
					)
					vim.keymap.set(
						"n",
						"gri",
						builtin.lsp_implementations,
						{ buffer = buf, desc = "[G]oto [I]mplementation" }
					)
					vim.keymap.set(
						"n",
						"grd",
						builtin.lsp_definitions,
						{ buffer = buf, desc = "[G]oto [D]efinition" }
					)
					vim.keymap.set(
						"n",
						"gO",
						builtin.lsp_document_symbols,
						{ buffer = buf, desc = "Open Document Symbols" }
					)
					vim.keymap.set(
						"n",
						"gW",
						builtin.lsp_dynamic_workspace_symbols,
						{ buffer = buf, desc = "Open Workspace Symbols" }
					)
					vim.keymap.set(
						"n",
						"grt",
						builtin.lsp_type_definitions,
						{ buffer = buf, desc = "[G]oto [T]ype Definition" }
					)
				end,
			})
			vim.keymap.set("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find(
					require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					})
				)
			end, { desc = "[/] Fuzzily search in current buffer" })
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"mason-org/mason.nvim",
				---@module 'mason.settings'
				---@type MasonSettings
				---@diagnostic disable-next-line: missing-fields
				opts = {},
			},
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup(
					"kickstart-lsp-attach",
					{ clear = true }
				),
				callback = function(event)
					vim.keymap.set(
						{ "n", "x" },
						"gra",
						vim.lsp.buf.code_action,
						{
							buffer = event.buf,
							desc = "LSP: [G]oto Code [A]ction",
						}
					)
					vim.keymap.set("n", "grn", vim.lsp.buf.rename, {
						buffer = event.buf,
						desc = "LSP: [R]e[n]ame",
					})
					vim.keymap.set("n", "grD", vim.lsp.buf.declaration, {
						buffer = event.buf,
						desc = "LSP: [G]oto [D]eclaration",
					})
					local client =
						vim.lsp.get_client_by_id(event.data.client_id)
					if
						client
						and client:supports_method(
							"textDocument/documentHighlight",
							event.buf
						)
					then
						local highlight_augroup = vim.api.nvim_create_augroup(
							"kickstart-lsp-highlight",
							{ clear = false }
						)
						vim.api.nvim_create_autocmd(
							{ "CursorHold", "CursorHoldI" },
							{
								buffer = event.buf,
								group = highlight_augroup,
								callback = vim.lsp.buf.document_highlight,
							}
						)
						vim.api.nvim_create_autocmd(
							{ "CursorMoved", "CursorMovedI" },
							{
								buffer = event.buf,
								group = highlight_augroup,
								callback = vim.lsp.buf.clear_references,
							}
						)
						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup(
								"kickstart-lsp-detach",
								{ clear = true }
							),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({
									group = "kickstart-lsp-highlight",
									buffer = event2.buf,
								})
							end,
						})
					end
					if
						client
						and client:supports_method(
							"textDocument/inlayHint",
							event.buf
						)
					then
						vim.keymap.set("n", "<leader>th", function()
							vim.lsp.inlay_hint.enable(
								not vim.lsp.inlay_hint.is_enabled({
									bufnr = event.buf,
								})
							)
						end, {
							buffer = event.buf,
							desc = "[T]oggle Inlay [H]ints",
						})
					end
				end,
			})

			-- Enable the following language servers
			--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
			--  See `:help lsp-config` for information about keys and how to configure
			---@type table<string, vim.lsp.Config>
			local servers = {
				-- clangd = {},
				-- gopls = {},
				-- pyright = {},
				-- rust_analyzer = {},
				--
				-- Some languages (like typescript) have entire language plugins that can be useful:
				--    https://github.com/pmizio/typescript-tools.nvim
				--
				-- But for many setups, the LSP (`ts_ls`) will work just fine
				-- ts_ls = {},

				stylua = {}, -- Used to format Lua code

				-- Special Lua Config, as recommended by neovim help docs
				lua_ls = {
					on_init = function(client)
						if client.workspace_folders then
							local path = client.workspace_folders[1].name
							if
								path ~= vim.fn.stdpath("config")
								and (
									vim.uv.fs_stat(path .. "/.luarc.json")
									or vim.uv.fs_stat(path .. "/.luarc.jsonc")
								)
							then
								return
							end
						end

						client.config.settings.Lua = vim.tbl_deep_extend(
							"force",
							client.config.settings.Lua,
							{
								runtime = {
									version = "LuaJIT",
									path = { "lua/?.lua", "lua/?/init.lua" },
								},
								workspace = {
									checkThirdParty = false,
									-- NOTE: this is a lot slower and will cause issues when working on your own configuration.
									--  See https://github.com/neovim/nvim-lspconfig/issues/3189
									library = vim.tbl_extend(
										"force",
										vim.api.nvim_get_runtime_file("", true),
										{
											"${3rd}/luv/library",
											"${3rd}/busted/library",
										}
									),
								},
							}
						)
					end,
					settings = {
						Lua = {},
					},
				},
			}

			-- Ensure the servers and tools above are installed
			--
			-- To check the current status of installed tools and/or manually install
			-- other tools, you can run
			--    :Mason
			--
			-- You can press `g?` for help in this menu.
			for name, server in pairs(servers) do
				vim.lsp.config(name, server)
				vim.lsp.enable(name)
			end
		end,
	},

	{ -- Scala LSP (Metals)
		"scalameta/nvim-metals",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		ft = { "scala", "sbt", "java" },
		opts = function()
			local metals_config = require("metals").bare_config()
			metals_config.settings = {
				showImplicitArguments = true,
				showImplicitConversionsAndClasses = true,
				showInferredType = true,
				superMethodLensesEnabled = true,
				-- Use scalafmt for formatting (reads .scalafmt.conf from project root)
				scalafmtConfigPath = ".scalafmt.conf",
				-- Enable scalafix code actions (reads .scalafix.conf from project root)
				codeActionLiteralSupport = true,
				scalafixRulesDependencies = {},
			}
			metals_config.init_options = {
				statusBarProvider = "off",
			}
			metals_config.capabilities =
				vim.lsp.protocol.make_client_capabilities()
			return metals_config
		end,
		config = function(self, metals_config)
			local nvim_metals_group =
				vim.api.nvim_create_augroup("nvim-metals", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = self.ft,
				group = nvim_metals_group,
				callback = function()
					require("metals").initialize_or_attach(metals_config)
				end,
			})
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({
						async = true,
						lsp_format = "fallback",
					})
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		---@module 'conform'
		---@type conform.setupOpts
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				-- Scala formatting is handled by Metals LSP (scalafmt) via lsp_format fallback
				scala = { lsp_format = "prefer" },
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- You can use 'stop_after_first' to run the first available formatter from the list
				-- javascript = { "prettierd", "prettier", stop_after_first = true },
			},
		},
	},

	{ -- Autocompletion
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {
			-- Snippet Engine
			{
				"L3MON4D3/LuaSnip",
				version = "2.*",
				build = (function()
					-- Build Step is needed for regex support in snippets.
					-- This step is not supported in many windows environments.
					-- Remove the below condition to re-enable on windows.
					if
						vim.fn.has("win32") == 1
						or vim.fn.executable("make") == 0
					then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- `friendly-snippets` contains a variety of premade snippets.
					--    See the README about individual language/framework/plugin snippets:
					--    https://github.com/rafamadriz/friendly-snippets
					-- {
					--   'rafamadriz/friendly-snippets',
					--   config = function()
					--     require('luasnip.loaders.from_vscode').lazy_load()
					--   end,
					-- },
				},
				opts = {},
			},
		},
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				-- 'default' (recommended) for mappings similar to built-in completions
				--   <c-y> to accept ([y]es) the completion.
				--    This will auto-import if your LSP supports it.
				--    This will expand snippets if the LSP sent a snippet.
				-- 'super-tab' for tab to accept
				-- 'enter' for enter to accept
				-- 'none' for no mappings
				--
				-- For an understanding of why the 'default' preset is recommended,
				-- you will need to read `:help ins-completion`
				--
				-- No, but seriously. Please read `:help ins-completion`, it is really good!
				--
				-- All presets have the following mappings:
				-- <tab>/<s-tab>: move to right/left of your snippet expansion
				-- <c-space>: Open menu or open docs if already open
				-- <c-n>/<c-p> or <up>/<down>: Select next/previous item
				-- <c-e>: Hide menu
				-- <c-k>: Toggle signature help
				--
				-- See :h blink-cmp-config-keymap for defining your own keymap
				preset = "default",

				-- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
				--    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
			},

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			completion = {
				-- By default, you may press `<c-space>` to show the documentation.
				-- Optionally, set `auto_show = true` to show the documentation after a delay.
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
			},

			sources = {
				default = { "lsp", "path", "snippets" },
			},

			snippets = { preset = "luasnip" },

			-- Blink.cmp includes an optional, recommended rust fuzzy matcher,
			-- which automatically downloads a prebuilt binary when enabled.
			--
			-- By default, we use the Lua implementation instead, but you may enable
			-- the rust implementation via `'prefer_rust_with_warning'`
			--
			-- See :h blink-cmp-config-fuzzy for more information
			fuzzy = { implementation = "lua" },

			-- Shows a signature help window while you type arguments for a function
			signature = { enabled = true },
		},
	},

	-- Colorscheme
	{
		"navarasu/onedark.nvim",
		priority = 1000,
		config = function()
			require("onedark").setup({
				style = "dark",
				transparent = true,
			})
			require("onedark").load()
		end,
	},

	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		---@module 'todo-comments'
		---@type TodoOptions
		---@diagnostic disable-next-line: missing-fields
		opts = { signs = false },
	},

	{ -- Collection of various small independent plugins/modules
		"nvim-mini/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			-- Simple and easy statusline.
			--  You could remove this setup call if you don't like it,
			--  and try some other statusline plugin
			local statusline = require("mini.statusline")
			-- set use_icons to true if you have a Nerd Font
			statusline.setup({
				use_icons = vim.g.have_nerd_font,
				-- You can configure sections in the statusline by overriding their
				-- default behavior. For example, here we set the section for
				-- cursor location to LINE:COLUMN
				content = {
					active = function()
						local mode, mode_hl =
							statusline.section_mode({ trunc_width = 120 })
						mode = mode:sub(1, 1)
						local filename = vim.fn.expand("%:~:.")
						local filetype = vim.bo.filetype
						local location = "%2l:%-2v"

						return statusline.combine_groups({
							{ hl = mode_hl, strings = { mode } },
							{
								hl = "MiniStatuslineFilename",
								strings = { filename },
							},
							"%=",
							{
								hl = "MiniStatuslineFileinfo",
								strings = { filetype },
							},
							{ hl = mode_hl, strings = { location } },
						})
					end,
				},
			})

			-- Statusline colors: forest green mode sections, grey filepath, bold text
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeNormal",
				{ bg = "#2e5a1e", fg = "#e0e0e0", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeInsert",
				{ bg = "#7ec8e3", fg = "#1e1e1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeVisual",
				{ bg = "#e5c07b", fg = "#1e1e1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeReplace",
				{ bg = "#e06c75", fg = "#1e1e1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeCommand",
				{ bg = "#c678dd", fg = "#1e1e1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineFilename",
				{ bg = "#3a3a3a", fg = "#808080", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineFileinfo",
				{ bg = "#4a4a4a", fg = "#d0d0d0", bold = true }
			)

			-- ... and there is more!
			--  Check out: https://github.com/nvim-mini/mini.nvim
		end,
	},

	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"scala",
				"vim",
				"vimdoc",
			},
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		},
		config = function(_, opts)
			require("nvim-treesitter").setup(opts)
		end,
	},

	{ -- VS Code-style folding
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "VimEnter",
		opts = {
			provider_selector = function()
				return { "treesitter", "indent" }
			end,
			-- Show closing line as virtual text beneath the fold
			fold_virt_text_handler = function(
				virtText,
				lnum,
				endLnum,
				width,
				truncate
			)
				local endLine = vim.api.nvim_buf_get_lines(
					0,
					endLnum - 1,
					endLnum,
					false
				)[1]
				local endText = vim.trim(endLine)
				table.insert(virtText, { "  ... " .. endText, "Comment" })
				return virtText
			end,
		},
		config = function(_, opts)
			require("ufo").setup(opts)
			vim.keymap.set(
				"n",
				"zR",
				require("ufo").openAllFolds,
				{ desc = "Open all folds" }
			)
			vim.keymap.set(
				"n",
				"zM",
				require("ufo").closeAllFolds,
				{ desc = "Close all folds" }
			)
		end,
	},

	-- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
	-- init.lua. If you want these files, they are in the repository, so you can just download them and
	-- place them in the correct locations.

	-- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
	--
	--  Here are some example plugins that I've included in the Kickstart repository.
	--  Uncomment any of the lines below to enable them (you will need to restart nvim).
	--
	-- require 'kickstart.plugins.debug',
	-- require 'kickstart.plugins.indent_line',
	-- require 'kickstart.plugins.lint',
	-- require 'kickstart.plugins.autopairs',
	-- require 'kickstart.plugins.neo-tree',
	-- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommended keymaps

	-- Render markdown inline in the buffer
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			heading = {
				icons = {},
				sign = false,
				backgrounds = {
					"RenderMarkdownH1Bg",
					"RenderMarkdownH2Bg",
					"RenderMarkdownH3Bg",
					"RenderMarkdownH4Bg",
					"RenderMarkdownH5Bg",
					"RenderMarkdownH6Bg",
				},
			},
			code = {
				sign = false,
				style = "full",
				language_icon = false,
				highlight = "RenderMarkdownCode",
			},
			bullet = {
				sign = false,
				icons = { "⦁", "⦁", "⦁", "⦁" },
			},
		},
		config = function(_, opts)
			-- Heading styles: bold, no background
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownH1Bg",
				{ bold = true, fg = "#7ec8e3" }
			)
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownH2Bg",
				{ bold = true, fg = "#86c9c0" }
			)
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownH3Bg",
				{ bold = true, fg = "#c678dd" }
			)
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownH4Bg",
				{ bold = true, fg = "#e5c07b" }
			)
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownH5Bg",
				{ bold = true, fg = "#b0b0b0" }
			)
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownH6Bg",
				{ bold = true, fg = "#808080" }
			)
			-- Inline code and code blocks
			vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#2a2a35" })
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownCodeInline",
				{ bg = "#2a2a35" }
			)
			require("render-markdown").setup(opts)
		end,
	},

	-- Auto-save
	{ "okuuva/auto-save.nvim", lazy = false, opts = {} },
	--
	-- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
	-- Or use telescope!
	-- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
	-- you can continue same window with `<space>sr` which resumes last telescope search
}, { ---@diagnostic disable-line: missing-fields
	ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

-- NOTE: Background transparency is handled by onedark's `transparent = true` setting

-- Folded line: subtle background highlight
vim.api.nvim_set_hl(0, "Folded", { bg = "#2a2a35", fg = "#808080" })

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
