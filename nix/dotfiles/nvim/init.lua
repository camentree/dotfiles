--[[
--

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
- [d and ]d     previous/next LSP diagnostic in buffer
- gg            beginning of file
- /             search (then `n` and `N` for next/previous)
- <space>q      diagnostics
- <C>           control
- <S>           shift
- <A>           alt
- <CR>          enter
- grd           go to definition of variable under cursor
- grt           go to type of variable under cursor
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
vim.o.inccommand = "split"
vim.o.cursorline = false
vim.o.scrolloff = 25 -- when scrolling how many lines to keep above/below cursor
vim.o.confirm = true
vim.o.keymodel = "startsel"
vim.o.tabstop = 2
vim.o.shiftwidth = 2
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
	"z1",
	"<cmd>set foldlevel=1<CR>",
	{ desc = "Fold to level 1" }
)
vim.keymap.set(
	"n",
	"z2",
	"<cmd>set foldlevel=2<CR>",
	{ desc = "Fold to level 2" }
)
vim.keymap.set(
	"n",
	"z3",
	"<cmd>set foldlevel=3<CR>",
	{ desc = "Fold to level 3" }
)
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
vim.keymap.set("n", "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, desc = "Down by display line" })
vim.keymap.set("n", "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, desc = "Up by display line" })
vim.keymap.set("n", "<C-j>", "<C-d>", { desc = "Half page down" })
vim.keymap.set("n", "<C-k>", "<C-u>", { desc = "Half page up" })
vim.keymap.set("i", "<C-Left>", "<C-o>b", { desc = "Word back" })
vim.keymap.set("i", "<C-Right>", "<C-o>e<Right>", { desc = "Word forward" })
vim.keymap.set("i", "<C-a>", "<C-o>0", { desc = "Line start (Cmd+Left)" })
vim.keymap.set("i", "<C-e>", "<C-o>$", { desc = "Line end (Cmd+Right)" })
vim.keymap.set("i", "<C-BS>", "<C-w>", { desc = "Delete word back" })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "De-indent" })
vim.keymap.set("i", "<S-CR>", "<C-o>O", { desc = "New line above" })
vim.keymap.set("i", "<Up>", "<C-o>gk", { desc = "Move up by display line" })
vim.keymap.set("i", "<Down>", "<C-o>gj", { desc = "Move down by display line" })
vim.keymap.set("i", "<D-z>", "<C-o>u", { desc = "Undo" })
vim.keymap.set("i", "<D-S-z>", "<C-o><C-r>", { desc = "Redo" })
vim.keymap.set("v", "Y", function()
	vim.cmd('normal! "+y')
	vim.fn.setreg("+", vim.fn.system("pandoc -t plain --wrap=none", vim.fn.getreg("+")))
end, { desc = "Yank selection as rendered markdown" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(event)
		vim.keymap.set("n", "<leader>x", function()
			local line = vim.api.nvim_get_current_line()
			local pre, text = line:match("^(%s*[%-%*%+] )(.*)")
			if not pre then
				pre, text = "", line
			end
			local unwrapped = text:match("^~~(.*)~~$")
			if unwrapped then
				vim.api.nvim_set_current_line(pre .. unwrapped)
			else
				vim.api.nvim_set_current_line(pre .. "~~" .. text .. "~~")
			end
		end, { buffer = event.buf, desc = "Stri[x]ethrough line" })
	end,
})

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
	-- NMAC427/guess-indent.nvim
	{ "NMAC427/guess-indent.nvim", opts = {} },
	-- lewis6991/gitsigns.nvim
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
	-- folke/which-key.nvim
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
	-- nvim-telescope/telescope.nvim
	{
		"nvim-telescope/telescope.nvim",
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
	-- neovim/nvim-lspconfig
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
			{
				"WhoIsSethDaniel/mason-tool-installer.nvim",
				opts = {
					ensure_installed = {
						"lua-language-server",
						"stylua",
						"pyright",
						"ruff",
						"prettier",
					},
				},
			},
			{
				"j-hui/fidget.nvim",
				opts = {
					notification = { override_vim_notify = true },
				},
			},
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

			---@type table<string, vim.lsp.Config>
			local servers = {
				pyright = {},
				ruff = {
					capabilities = {
						general = {
							positionEncodings = { "utf-16" },
						},
					},
				},
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
			for name, server in pairs(servers) do
				vim.lsp.config(name, server)
				vim.lsp.enable(name)
			end
		end,
	},
	-- scalameta/nvim-metals
	{
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
				scalafmtConfigPath = ".scalafmt.conf",
				scalafixConfigPath = ".scalafix.conf",
				autoImportBuild = "all",
			}
			metals_config.find_root_dir_max_project_nesting = 10
			metals_config.init_options = {
				statusBarProvider = "off",
			}
			metals_config.capabilities =
				vim.lsp.protocol.make_client_capabilities()
			-- Workaround for Neovim 0.12 glob parser bug with Metals file patterns
			metals_config.capabilities.workspace.didChangeWatchedFiles.dynamicRegistration =
				false
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
	-- stevearc/conform.nvim
	{
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
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				scala = { lsp_format = "prefer" },
				python = { "ruff_organize_imports", "ruff_format" },
				markdown = { "prettier" },
			},
		},
	},
	-- saghen/blink.cmp
	{
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {},
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "default",
			},
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = {
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
			},
			sources = {
				default = { "lsp", "path" },
			},
			fuzzy = { implementation = "lua" },
			signature = { enabled = true },
		},
	},
	-- navarasu/onedark.nvim
	{
		"navarasu/onedark.nvim",
		priority = 1000,
		config = function()
			require("onedark").setup({
				style = "dark",
				transparent = true,
				colors = {
					fg = "#d5d0cb",
				},
			})
			require("onedark").load()
		end,
	},
	-- folke/todo-comments.nvim
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		---@module 'todo-comments'
		---@type TodoOptions
		---@diagnostic disable-next-line: missing-fields
		opts = { signs = false },
	},
	-- nvim-mini/mini.nvim
	{
		"nvim-mini/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.pairs").setup()
			require("mini.surround").setup()
			local statusline = require("mini.statusline")
			statusline.setup({
				use_icons = vim.g.have_nerd_font,
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
		end,
	},
	-- nvim-treesitter/nvim-treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"python",
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
	-- kevinhwang91/nvim-ufo
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "VimEnter",
		opts = {
			provider_selector = function()
				return { "treesitter", "indent" }
			end,
			fold_virt_text_handler = function(
				virtText,
				_lnum,
				endLnum,
				_width,
				_truncate
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
	-- MeanderingProgrammer/render-markdown.nvim
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
				icons = { "–", "–", "–", "–" },
			},
		},
		config = function(_, opts)
			-- Heading colors: defined once, applied to both render-markdown and treesitter
			local heading_colors = {
				"#7ec8e3",
				"#86c9c0",
				"#c678dd",
				"#e5c07b",
				"#b0b0b0",
				"#808080",
			}
			for i, color in ipairs(heading_colors) do
				local hl = { bold = true, fg = color }
				vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i .. "Bg", hl)
				vim.api.nvim_set_hl(
					0,
					"@markup.heading." .. i .. ".markdown",
					hl
				)
			end
			vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#2a2a35" })
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownCodeInline",
				{ bg = "#2a2a35" }
			)
			require("render-markdown").setup(opts)
		end,
	},
	-- uga-rosa/ccc.nvim
	{
		"uga-rosa/ccc.nvim",
		event = "BufReadPre",
		cmd = { "CccPick", "CccHighlighter", "CccConvert" },
		keys = {
			{ "<leader>cp", "<cmd>CccPick<cr>", desc = "[C]olor [P]icker" },
			{
				"<leader>ch",
				"<cmd>CccHighlighter<cr>",
				desc = "[C]olor [H]ighlighter toggle",
			},
		},
		opts = {
			highlighter = {
				auto_enable = true,
			},
		},
	},
	-- okuuva/auto-save.nvim
	{ "okuuva/auto-save.nvim", lazy = false, opts = {} },
})
vim.api.nvim_set_hl(0, "Folded", { bg = "#2a2a35", fg = "#808080" })
