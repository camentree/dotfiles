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
--
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- [[ OPTIONS ]]
vim.schedule(function()
	-- schedule settings after `UIEnter` to decrease startup time
	vim.o.clipboard = "unnamedplus"
	if os.getenv("SSH_TTY") then
		local osc52 = require("vim.ui.clipboard.osc52")
		vim.g.clipboard = {
			name = "OSC 52",
			copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
			paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
		}
	end
end)
vim.o.number = true
vim.o.mouse = "a"
vim.o.showmode = false
vim.o.breakindent = true
vim.o.linebreak = true
vim.o.showbreak = "↳ "
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "auto"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.laststatus = 3 -- global statusline

vim.o.inccommand = "split"
vim.o.fillchars = "eob: "
vim.o.cursorline = false
vim.o.scrolloff = 0 -- when scrolling how many lines to keep above/below cursor
vim.o.confirm = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
-- nvim ships linematch:40 by default; drop it so the value below isn't a duplicate.
vim.opt.diffopt:remove("linematch:40")
vim.opt.diffopt:append("linematch:60")
vim.o.termguicolors = true
vim.o.autoread = true
vim.o.title = false
vim.o.guicursor = "n-v-c-sm:block,i-ci-ve-t:ver25,r-cr-o:hor20"
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	command = "checktime",
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TermOpen" }, {
	callback = function()
		if vim.bo.buftype == "terminal" then
			vim.schedule(function()
				if vim.bo.buftype == "terminal" then
					vim.cmd.startinsert()
				end
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.wo.wrap = true
		vim.wo.sidescrolloff = 0
	end,
})

-- Terminal-mode paste: forward clipboard to the child PTY wrapped in bracketed-paste
-- sequences. nvim's :terminal otherwise strips them, which breaks Claude Code's
-- multi-line paste detection. Bound to Alt+V to avoid colliding with Ctrl+V
-- (Claude Code's image-paste shortcut) and Cmd+V (Ghostty's own paste).
vim.keymap.set("t", "<M-v>", function()
	local text = vim.fn.getreg("+")
	local chan = vim.bo.channel
	if chan ~= 0 then
		vim.api.nvim_chan_send(chan, "\27[200~" .. text .. "\27[201~")
	end
end, { desc = "Paste clipboard with bracketed paste" })

-- Single Esc exits terminal mode. To send a literal Esc to the running program,
-- use <C-V><Esc>.
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

local function terminal_mouse(lhs)
	return function()
		local pos = vim.fn.getmousepos()
		if pos.winid == 0 or pos.winid == vim.api.nvim_get_current_win() then
			return ""
		end
		return [[<C-\><C-n>]] .. lhs
	end
end

for _, lhs in ipairs({
	"<LeftMouse>",
	"<LeftDrag>",
	"<LeftRelease>",
	"<2-LeftMouse>",
	"<3-LeftMouse>",
	"<4-LeftMouse>",
	"<MiddleMouse>",
	"<RightMouse>",
}) do
	vim.keymap.set("t", lhs, terminal_mouse(lhs), {
		expr = true,
		replace_keycodes = true,
		desc = "Stay in terminal mode on in-window click",
	})
end

local original_path = vim.env.PATH
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function(args)
		local file = vim.api.nvim_buf_get_name(args.buf)
		if file == "" then
			return
		end
		local found = vim.fs.find(".venv", {
			upward = true,
			type = "directory",
			path = vim.fs.dirname(file),
			stop = vim.env.HOME,
		})
		if #found == 0 then
			return
		end
		local venv = found[1]
		if vim.env.VIRTUAL_ENV == venv then
			return
		end
		vim.env.VIRTUAL_ENV = venv
		vim.env.PATH = venv .. "/bin:" .. original_path
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	command = "wincmd =",
})

-- [[ DIAGNOSTICS ]]
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = { min = vim.diagnostic.severity.WARN } },
	virtual_text = false,
	-- Full-text diagnostics on their own lines below the code (Neovim 0.11+).
	-- Swap in `{ current_line = true }` to limit to the cursor's line only.
	virtual_lines = false,
	-- virtual_lines = { current_line = true },
	jump = { on_jump = "float" },
})

-- Pop a float with the full diagnostic message after the cursor sits still.
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, { focus = false })
	end,
})

-- [[ BASIC KEYMAPS ]]
--vim.keymap.set(mode, key, function, metadata)
vim.keymap.set(
	"n",
	"<Esc>",
	"<cmd>nohlsearch<CR>",
	{ desc = "Escape to unhighlight search returns" }
)
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "[W]rite file" })
vim.keymap.set("n", "<leader>q", function()
	if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
		vim.cmd("lclose")
	else
		vim.diagnostic.setloclist()
	end
end, { desc = "Toggle diagnostic [Q]uickfix list" })
vim.keymap.set("n", "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, desc = "Down by display line" })
vim.keymap.set("n", "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, desc = "Up by display line" })
vim.keymap.set({ "n", "v" }, "<Down>", "gj", { desc = "Down by display line" })
vim.keymap.set({ "n", "v" }, "<Up>", "gk", { desc = "Up by display line" })
vim.keymap.set({ "n", "v" }, "<Home>", "g0", { desc = "Display line start" })
vim.keymap.set({ "n", "v" }, "<End>", "g$", { desc = "Display line end" })
do
	local url_tlds = {
		com = true,
		org = true,
		net = true,
		io = true,
		dev = true,
		ai = true,
		co = true,
		app = true,
		me = true,
		info = true,
		biz = true,
		gov = true,
		edu = true,
		tech = true,
		cloud = true,
		xyz = true,
	}

	local function slugify_heading(text)
		return text:lower():gsub("[^%w%s%-]", ""):gsub("%s+", "-")
	end

	local function classify_target(target)
		if target:match("^%w+://") then
			return "url"
		end
		if target:match("^www%.") then
			return "url"
		end
		if target:match("[?&]") then
			return "url"
		end
		if target:match(":%d+:?%d*$") then
			return "filepath"
		end
		local first_segment = target:match("^([^/]+)") or target
		local ext = first_segment:match("%.([%w]+)$")
		if ext and url_tlds[ext:lower()] then
			return "url"
		end
		return "filepath"
	end

	local function open_target_url(target)
		if not target:match("^%w+://") then
			target = "https://" .. target
		end
		vim.ui.open(target)
	end

	local function jump_to_heading_anchor(anchor)
		local goal = slugify_heading(anchor)
		for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
			local heading = line:match("^#+%s+(.+)$")
			if heading and slugify_heading(heading) == goal then
				vim.api.nvim_win_set_cursor(0, { lnum, 0 })
				return
			end
		end
	end

	local function resolve_path(path)
		if path:match("^/") or path:match("^~") then
			return path
		end
		if vim.bo.buftype == "" then
			local buffer_dir = vim.fn.expand("%:p:h")
			if buffer_dir ~= "" then
				return buffer_dir .. "/" .. path
			end
		end
		return path
	end

	local function open_target_filepath(target, open_cmd)
		local path, line, col = target:match("^(.-):(%d+):(%d+)$")
		if not path then
			path, line = target:match("^(.-):(%d+)$")
		end
		local anchor
		if not path then
			path, anchor = target:match("^(.-)#(.+)$")
		end
		path = path or target
		if path ~= "" then
			vim.cmd[open_cmd](vim.fn.fnameescape(resolve_path(path)))
		end
		if line then
			vim.api.nvim_win_set_cursor(
				0,
				{ tonumber(line), tonumber(col or 0) }
			)
		elseif anchor then
			jump_to_heading_anchor(anchor)
		end
	end

	local function find_target_under_cursor()
		local line = vim.api.nvim_get_current_line()
		local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1

		local pos = 1
		while true do
			local start_idx, end_idx, _, target =
				line:find("%[([^%]]*)%]%(([^%)]+)%)", pos)
			if not start_idx then
				break
			end
			if cursor_col >= start_idx and cursor_col <= end_idx then
				return target
			end
			pos = end_idx + 1
		end

		local valid_char = "[%w%-_./:?=&%%#~]"
		if
			cursor_col > #line
			or not line:sub(cursor_col, cursor_col):match(valid_char)
		then
			return nil
		end
		local start_col = cursor_col
		while
			start_col > 1
			and line:sub(start_col - 1, start_col - 1):match(valid_char)
		do
			start_col = start_col - 1
		end
		local end_col = cursor_col
		while
			end_col < #line
			and line:sub(end_col + 1, end_col + 1):match(valid_char)
		do
			end_col = end_col + 1
		end
		return line:sub(start_col, end_col)
	end

	local function gx(open_cmd)
		local target = find_target_under_cursor()
		if not target or target == "" then
			return
		end
		if classify_target(target) == "url" then
			open_target_url(target)
		else
			open_target_filepath(target, open_cmd)
		end
	end

	vim.keymap.set({ "n", "x" }, "gx", function()
		gx("edit")
	end, { desc = "Open URL/filepath under cursor" })
	vim.keymap.set({ "n", "x" }, "gX", function()
		gx("vsplit")
	end, { desc = "Open filepath under cursor in vsplit" })
end
vim.keymap.set("n", "<C-j>", "<C-d>", { desc = "Half page down" })
vim.keymap.set("n", "<C-k>", "<C-u>", { desc = "Half page up" })
vim.keymap.set("i", "<C-Left>", "<C-o>b", { desc = "Word back" })
vim.keymap.set("i", "<C-Right>", "<C-o>e<Right>", { desc = "Word forward" })
vim.keymap.set("i", "<M-b>", "<C-o>b", { desc = "Word back (Option+Left)" })
vim.keymap.set(
	"i",
	"<M-f>",
	"<C-o>e<Right>",
	{ desc = "Word forward (Option+Right)" }
)
vim.keymap.set("i", "<C-a>", "<C-o>g0", { desc = "Line start (Cmd+Left)" })
vim.keymap.set("i", "<C-e>", "<C-o>g$", { desc = "Line end (Cmd+Right)" })
vim.keymap.set("i", "<C-BS>", "<C-w>", { desc = "Delete word back" })
vim.keymap.set("i", "<A-BS>", "<C-w>", { desc = "Delete word back (Option)" })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "De-indent" })
vim.keymap.set("i", "<S-CR>", "<C-o>o", { desc = "New line below" })
vim.keymap.set("i", "<D-CR>", "<C-o>O", { desc = "New line above" })
vim.keymap.set("i", "<Up>", "<C-o>gk", { desc = "Move up by display line" })
vim.keymap.set("i", "<Down>", "<C-o>gj", { desc = "Move down by display line" })
vim.keymap.set("n", "<D-/>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set(
	"i",
	"<D-/>",
	"<C-o>gcc",
	{ remap = true, desc = "Toggle comment" }
)
vim.keymap.set("v", "<D-/>", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "Y", function()
	vim.cmd('normal! "+y')
	vim.fn.setreg(
		"+",
		vim.fn.system("pandoc -t plain --wrap=none", vim.fn.getreg("+"))
	)
end, { desc = "Yank selection as rendered markdown" })
vim.keymap.set(
	"n",
	"<leader>fr",
	[[:%s/\<<C-r><C-w>\>//g<Left><Left>]],
	{ desc = "[F]ind and [R]eplace word under cursor" }
)
vim.keymap.set(
	"v",
	"<leader>fr",
	[["zy:%s/\V<C-r>=escape(@z,'/\')<CR>//g<Left><Left>]],
	{ desc = "[F]ind and [R]eplace selection" }
)
local function create_sidebar_mapping(keys, env_var, description)
	vim.keymap.set({ "n", "i", "t" }, keys, function()
		local raw = vim.env[env_var]
		if not raw or raw == "" then
			vim.notify(env_var .. " is not set", vim.log.levels.WARN)
			return
		end
		local path = vim.fn.fnamemodify(vim.fn.expand(raw), ":p")
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.api.nvim_buf_get_name(buf) == path then
				vim.api.nvim_win_close(win, false)
				return
			end
		end
		vim.cmd("botright vsplit " .. vim.fn.fnameescape(path))
		vim.api.nvim_win_set_width(0, math.floor(vim.o.columns * 0.4))
	end, { desc = description })
end
create_sidebar_mapping("<C-/>", "NOTEBOOK_PATH", "Toggle Notebook")
create_sidebar_mapping("<C-.>", "TODO_PATH", "Toggle ToDo")

-- [[ AUTOCOMMANDS ]]
local indent_by_filetype = {
	markdown = { width = 4, expandtab = true },
	python = { width = 4, expandtab = true },
	lua = { width = 2, expandtab = true },
	nix = { width = 2, expandtab = true },
	scala = { width = 2, expandtab = true },
	typescript = { width = 2, expandtab = true },
	typescriptreact = { width = 2, expandtab = true },
	javascript = { width = 2, expandtab = true },
	javascriptreact = { width = 2, expandtab = true },
	json = { width = 2, expandtab = true },
	yaml = { width = 2, expandtab = true },
}
vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.tbl_keys(indent_by_filetype),
	callback = function(event)
		local cfg = indent_by_filetype[vim.bo[event.buf].filetype]
		vim.bo[event.buf].expandtab = cfg.expandtab
		vim.bo[event.buf].tabstop = cfg.width
		vim.bo[event.buf].shiftwidth = cfg.width
		vim.bo[event.buf].softtabstop = cfg.width
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(event)
		local function cycle_todo(line)
			local indent, marker, rest = line:match("^(%s*)([%-%*%+] )(.*)$")
			if not marker then
				return line
			end
			local checked = rest:match("^%[[xX]%] (.*)$")
			if checked then
				return indent .. marker .. "[ ] " .. checked
			end
			local unchecked = rest:match("^%[ %] (.*)$")
			return indent .. marker .. "[x] " .. (unchecked or rest)
		end
		vim.keymap.set("n", "<leader>x", function()
			vim.api.nvim_set_current_line(
				cycle_todo(vim.api.nvim_get_current_line())
			)
		end, { buffer = event.buf, desc = "Toggle todo: [ ] <-> [x]" })
		vim.keymap.set("x", "<leader>x", function()
			local first = vim.fn.line("v")
			local last = vim.fn.line(".")
			if first > last then
				first, last = last, first
			end
			local lines =
				vim.api.nvim_buf_get_lines(event.buf, first - 1, last, false)
			for i, line in ipairs(lines) do
				lines[i] = cycle_todo(line)
			end
			vim.api.nvim_buf_set_lines(event.buf, first - 1, last, false, lines)
			vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
				"n",
				false
			)
		end, { buffer = event.buf, desc = "Cycle todos in selection" })
	end,
})
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
	rocks = { enabled = false, hererocks = false },
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
			-- Hunk staging keymaps
			vim.keymap.set(
				"n",
				"<leader>gs",
				"<cmd>Gitsigns stage_hunk<CR>",
				{ desc = "Git stage hunk" }
			)
			vim.keymap.set(
				"v",
				"<leader>gs",
				":Gitsigns stage_hunk<CR>",
				{ desc = "Git stage lines" }
			)
			vim.keymap.set(
				"n",
				"<leader>gr",
				"<cmd>Gitsigns reset_hunk<CR>",
				{ desc = "Git reset hunk" }
			)
			vim.keymap.set(
				"v",
				"<leader>gr",
				":Gitsigns reset_hunk<CR>",
				{ desc = "Git reset lines" }
			)
			vim.keymap.set(
				"n",
				"<leader>gu",
				"<cmd>Gitsigns undo_stage_hunk<CR>",
				{ desc = "Git undo stage hunk" }
			)
			vim.keymap.set(
				"n",
				"<leader>gp",
				"<cmd>Gitsigns preview_hunk<CR>",
				{ desc = "Git preview hunk" }
			)
			vim.keymap.set(
				"n",
				"]h",
				"<cmd>Gitsigns next_hunk<CR>",
				{ desc = "Next git hunk" }
			)
			vim.keymap.set(
				"n",
				"[h",
				"<cmd>Gitsigns prev_hunk<CR>",
				{ desc = "Prev git hunk" }
			)
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
				{ "<leader>f", group = "[F]ind (buffer)", mode = { "n", "v" } },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
				{ "gr", group = "LSP Actions", mode = { "n" } },
			},
		},
	},
	-- folke/snacks.nvim (picker)
	{
		"folke/snacks.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			explorer = { replace_netrw = true },
			picker = {
				ui_select = true,
				win = {
					input = {
						keys = {
							["<D-CR>"] = { "edit_vsplit", mode = { "n", "i" } },
						},
					},
				},
				sources = {
					explorer = {
						hidden = true,
						ignored = false,
						follow_file = true,
						auto_close = false,
						layout = {
							preset = "sidebar",
							preview = false,
							layout = { width = 35 },
						},
						win = {
							list = {
								keys = {
									["<D-CR>"] = "edit_vsplit",
									["<C-b>"] = "close",
								},
							},
						},
					},
					files = { follow = true },
					grep = { follow = true },
					grep_word = { follow = true },
				},
			},
		},
		keys = {
			{
				"<C-b>",
				function()
					local explorers = Snacks.picker.get({ source = "explorer" })
					if explorers[1] then
						explorers[1]:close()
					else
						Snacks.explorer()
					end
				end,
				mode = { "n", "i", "t" },
				desc = "Toggle file explorer",
			},
			{
				"<leader>sh",
				function()
					Snacks.picker.help()
				end,
				desc = "[S]earch [H]elp",
			},
			{
				"<leader>sk",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "[S]earch [K]eymaps",
			},
			{
				"<leader>sf",
				function()
					Snacks.picker.files({ hidden = true })
				end,
				desc = "[S]earch [F]iles",
			},
			{
				"<leader>ss",
				function()
					Snacks.picker.pickers()
				end,
				desc = "[S]earch [S]elect picker",
			},
			{
				"<leader>sw",
				function()
					Snacks.picker.grep_word()
				end,
				mode = { "n", "v" },
				desc = "[S]earch current [W]ord",
			},
			{
				"<leader>sg",
				function()
					Snacks.picker.grep()
				end,
				desc = "[S]earch by [G]rep",
			},
			{
				"<leader>sd",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "[S]earch [D]iagnostics",
			},
			{
				"<leader>sr",
				function()
					Snacks.picker.resume()
				end,
				desc = "[S]earch [R]esume",
			},
			{
				"<leader>s.",
				function()
					Snacks.picker.recent()
				end,
				desc = "[S]earch Recent Files",
			},
			{
				"<leader>sc",
				function()
					Snacks.picker.commands()
				end,
				desc = "[S]earch [C]ommands",
			},
			{
				"<leader>s/",
				function()
					Snacks.picker.grep_buffers()
				end,
				desc = "[S]earch in Open Files",
			},
			{
				"<leader>sn",
				function()
					Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "[S]earch [N]eovim files",
			},
			{
				"<leader><leader>",
				function()
					Snacks.picker.buffers()
				end,
				desc = "[ ] Find existing buffers",
			},
			{
				"<leader>/",
				function()
					Snacks.picker.lines()
				end,
				desc = "[/] Fuzzily search in current buffer",
			},
			{
				"<leader>/",
				function()
					vim.cmd('normal! "zy')
					Snacks.picker.lines({ pattern = vim.fn.getreg("z") })
				end,
				mode = "v",
				desc = "[/] Search selection in current buffer",
			},
			{
				"grr",
				function()
					Snacks.picker.lsp_references()
				end,
				desc = "[G]oto [R]eferences",
			},
			{
				"gri",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "[G]oto [I]mplementation",
			},
			{
				"grd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "[G]oto [D]efinition",
			},
			{
				"grt",
				function()
					Snacks.picker.lsp_type_definitions()
				end,
				desc = "[G]oto [T]ype Definition",
			},
			{
				"gO",
				function()
					Snacks.picker.lsp_symbols()
				end,
				desc = "Open Document Symbols",
			},
			{
				"gW",
				function()
					Snacks.picker.lsp_workspace_symbols()
				end,
				desc = "Open Workspace Symbols",
			},
		},
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
						"typescript-language-server",
						"eslint-lsp",
					},
				},
			},
			{
				"j-hui/fidget.nvim",
				opts = {
					-- LSP progress is shown in the statusline instead; keep fidget
					-- for vim.notify only.
					progress = {
						ignore = {
							function()
								return true
							end,
						},
					},
					notification = {
						override_vim_notify = true,
						window = { winblend = 0 },
					},
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
				ts_ls = {},
				eslint = {},
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
				serverProperties = { "-Xmx4g", "-XX:+UseG1GC" },
				bloopJvmProperties = { "-Xmx16g", "-XX:+UseG1GC" },
				shutdownBloopOnEditorClose = true,
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
				"<leader>F",
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
				if vim.bo[bufnr].filetype == "markdown" then
					return nil
				end
				return {
					timeout_ms = 3000,
					lsp_format = "fallback",
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				scala = { lsp_format = "prefer" },
				python = { "ruff_organize_imports", "ruff_format" },
				markdown = { "prettier" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				html = { "prettier" },
				yaml = { "prettier" },
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
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "accept", "fallback" },
				["<Esc>"] = { "cancel", "fallback" },
			},
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = {
				menu = {
					border = "rounded",
					scrollbar = false,
					draw = {
						padding = { 1, 1 },
						gap = 1,
					},
				},
				documentation = {
					auto_show = false,
					auto_show_delay_ms = 500,
					window = { border = "rounded" },
				},
			},
			signature = { enabled = true, window = { border = "rounded" } },
			sources = {
				default = { "lsp", "path" },
			},
			fuzzy = { implementation = "prefer_rust" },
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
			vim.api.nvim_set_hl(
				0,
				"@markup.strikethrough",
				{ strikethrough = true }
			)
			vim.api.nvim_set_hl(
				0,
				"@markup.bold",
				{ bold = true, fg = "#d19a66" }
			)
			vim.api.nvim_set_hl(
				0,
				"@markup.italic",
				{ italic = true, fg = "#98c379" }
			)
			vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "#1e1e1e" })
			vim.api.nvim_set_hl(
				0,
				"BlinkCmpMenuSelection",
				{ bg = "#3a3a3a", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"BlinkCmpLabelMatch",
				{ fg = "#e5c07b", bold = true }
			)
			vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1e3a2a" })
			vim.api.nvim_set_hl(
				0,
				"DiffDelete",
				{ bg = "#3a1e22", fg = "#5a3a3e" }
			)
			vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2a2e3a" })
			vim.api.nvim_set_hl(0, "DiffText", { bg = "#3a4a6a", bold = true })
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
	-- folke/zen-mode.nvim
	{
		"folke/zen-mode.nvim",
		keys = {
			{
				"<C-;>",
				function()
					-- zen-mode runs :normal on open, which can't execute from
					-- terminal mode; leave it first, then toggle on the next tick.
					if vim.api.nvim_get_mode().mode == "t" then
						vim.api.nvim_feedkeys(
							vim.api.nvim_replace_termcodes(
								"<C-\\><C-n>",
								true,
								false,
								true
							),
							"n",
							false
						)
						vim.schedule(function()
							require("zen-mode").toggle()
						end)
						return
					end
					require("zen-mode").toggle()
				end,
				mode = { "n", "i", "t" },
				desc = "Zen mode (center current window)",
			},
		},
		opts = {
			window = {
				backdrop = 1,
				width = 100,
			},
			on_open = function(win)
				local buf = vim.api.nvim_win_get_buf(win)
				vim.wo[win].number = vim.bo[buf].buftype ~= "terminal"
			end,
		},
	},
	-- nvim-mini/mini.nvim
	{
		"nvim-mini/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()
			local statusline = require("mini.statusline")
			local lsp_progress = { active = false }
			local spinner_frames = {
				"⠋",
				"⠙",
				"⠹",
				"⠸",
				"⠼",
				"⠴",
				"⠦",
				"⠧",
				"⠇",
				"⠏",
			}
			local spinner_index = 1
			local spinner_timer = nil
			local function stop_spinner()
				if spinner_timer then
					spinner_timer:stop()
					spinner_timer:close()
					spinner_timer = nil
				end
			end
			local function start_spinner()
				if spinner_timer then
					return
				end
				spinner_timer = vim.uv.new_timer()
				spinner_timer:start(
					0,
					100,
					vim.schedule_wrap(function()
						spinner_index = (spinner_index % #spinner_frames) + 1
						vim.cmd("redrawstatus")
					end)
				)
			end
			vim.api.nvim_create_autocmd("LspProgress", {
				callback = function(args)
					local value = args.data
						and args.data.params
						and args.data.params.value
					if not value or not value.kind then
						return
					end
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if value.kind == "end" then
						lsp_progress = { active = false }
						stop_spinner()
					else
						lsp_progress = {
							active = true,
							name = client and client.name or "lsp",
							title = value.title,
							message = value.message,
							percentage = value.percentage,
						}
						start_spinner()
					end
					vim.cmd("redrawstatus")
				end,
			})
			local function section_lsp()
				if vim.bo.buftype == "terminal" then
					return ""
				end
				local clients = vim.lsp.get_clients({ bufnr = 0 })
				if #clients == 0 then
					return ""
				end
				if lsp_progress.active then
					local parts = { lsp_progress.title or "working" }
					if lsp_progress.message then
						parts[#parts + 1] = lsp_progress.message
					end
					if lsp_progress.percentage then
						parts[#parts + 1] = lsp_progress.percentage .. "%"
					end
					return spinner_frames[spinner_index]
						.. " "
						.. (lsp_progress.name or "lsp")
						.. ": "
						.. table.concat(parts, " ")
				end
				local names = {}
				for _, client in ipairs(clients) do
					names[#names + 1] = client.name
				end
				return "● " .. table.concat(names, ", ")
			end
			statusline.setup({
				use_icons = vim.g.have_nerd_font,
				content = {
					active = function()
						local mode, mode_hl =
							statusline.section_mode({ trunc_width = 120 })
						local is_terminal = vim.bo.buftype == "terminal"
						local filename = is_terminal and ""
							or vim.fn.expand("%:~:.")
						local label
						if is_terminal then
							local name = vim.api.nvim_buf_get_name(0)
							local cmd = name:match(":([^:]+)$") or name
							cmd = cmd:gsub(";.*$", "")
							label = vim.fn.fnamemodify(cmd, ":t")
						else
							label = vim.bo.filetype
						end

						return statusline.combine_groups({
							{ hl = mode_hl, strings = { mode } },
							{
								hl = "MiniStatuslineFilename",
								strings = { filename },
							},
							"%=",
							{
								hl = "MiniStatuslineLsp",
								strings = { section_lsp() },
							},
							{ hl = mode_hl, strings = { label } },
						})
					end,
				},
			})
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeNormal",
				{ bg = "#7ec8e3", fg = "#1c1a1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeInsert",
				{ bg = "#98c379", fg = "#1c1a1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeVisual",
				{ bg = "#e5c07b", fg = "#1c1a1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeReplace",
				{ bg = "#e06c75", fg = "#1c1a1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeCommand",
				{ bg = "#c678dd", fg = "#1c1a1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineModeOther",
				{ bg = "#98c379", fg = "#1c1a1e", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineFilename",
				{ bg = "#1c1a1e", fg = "#b0aaa0", bold = true }
			)
			vim.api.nvim_set_hl(
				0,
				"MiniStatuslineLsp",
				{ bg = "#1c1a1e", fg = "#86c9c0" }
			)
		end,
	},
	-- nvim-treesitter/nvim-treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local parsers = {
				"bash",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"python",
				"scala",
				"sql",
				"vim",
				"vimdoc",
				"yaml",
			}
			require("nvim-treesitter").install(parsers)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = {
					"bash",
					"html",
					"lua",
					"markdown",
					"python",
					"scala",
					"sql",
					"vim",
					"help",
					"yaml",
				},
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
	-- kevinhwang91/nvim-ufo
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "VimEnter",
		opts = {
			provider_selector = function()
				return { "lsp", "indent" }
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
			local ufo = require("ufo")
			vim.keymap.set(
				"n",
				"zR",
				ufo.openAllFolds,
				{ desc = "Open all folds" }
			)
			vim.keymap.set(
				"n",
				"zM",
				ufo.closeAllFolds,
				{ desc = "Close all folds" }
			)
			vim.keymap.set(
				"n",
				"z0",
				ufo.closeAllFolds,
				{ desc = "Fold to level 0 (close all)", nowait = true }
			)
			vim.keymap.set("n", "z1", function()
				ufo.closeFoldsWith(1)
			end, { desc = "Fold to level 1" })
			vim.keymap.set("n", "z2", function()
				ufo.closeFoldsWith(2)
			end, { desc = "Fold to level 2" })
			vim.keymap.set("n", "z3", function()
				ufo.closeFoldsWith(3)
			end, { desc = "Fold to level 3" })
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
				icons = { "▎ ", "▎ ", "▎ ", "▎ ", "▎ ", "▎ " },
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
				inline_pad = 1,
			},
			bullet = {
				icons = { "–", "–", "–", "–" },
			},
			checkbox = {
				checked = {
					scope_highlight = "RenderMarkdownTodoDone",
				},
			},
			latex = { enabled = false },
			html = {
				comment = { conceal = false },
			},
			anti_conceal = { disabled_modes = { "n" } },
			win_options = {
				concealcursor = { rendered = "n" },
			},
		},
		config = function(_, opts)
			-- Heading colors: defined once, applied to both render-markdown and treesitter
			local heading_colors = {
				"#86c9c0",
				"#e06c75",
				"#c678dd",
				"#7ec8e3",
				"#98c379",
				"#e5c07b",
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
			vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#1e1e28" })
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownCodeInline",
				{ bg = "#1e1e28", fg = "#8e82ce" }
			)
			vim.api.nvim_set_hl(
				0,
				"@markup.raw.markdown_inline",
				{ bg = "#1e1e28", fg = "#8e82ce" }
			)
			vim.api.nvim_set_hl(
				0,
				"@markup.strong.markdown_inline",
				{ bold = true, fg = "#e06c75" }
			)
			vim.api.nvim_set_hl(
				0,
				"@markup.italic.markdown_inline",
				{ italic = true, fg = "#98c379" }
			)
			vim.api.nvim_set_hl(0, "RenderMarkdownChecked", { fg = "#98c379" })
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownUnchecked",
				{ fg = "#b0aaa0" }
			)
			vim.api.nvim_set_hl(
				0,
				"RenderMarkdownTodoDone",
				{ fg = "#b0aaa0", strikethrough = true }
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
	-- akinsho/toggleterm.nvim
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		keys = {
			{
				"<C-`>",
				function()
					require("toggleterm").toggle(1, nil, nil, "horizontal")
				end,
				mode = { "n", "i", "t" },
				desc = "Toggle Terminal",
			},
		},
		opts = {
			size = function(term)
				if term.direction == "vertical" then
					return math.floor(vim.o.columns * 0.4)
				end
				return 20
			end,
			shade_terminals = false,
			start_in_insert = true,
			persist_mode = false,
		},
	},
	-- willothy/flatten.nvim
	{
		"willothy/flatten.nvim",
		config = true,
		lazy = false,
		priority = 1001,
	},
	-- okuuva/auto-save.nvim
	{
		"okuuva/auto-save.nvim",
		lazy = false,
		opts = {
			condition = function(buf)
				for _, win in ipairs(vim.fn.win_findbuf(buf)) do
					return not vim.wo[win].diff
				end
				return true
			end,
		},
	},
	-- coder/claudecode.nvim
	{
		"coder/claudecode.nvim",
		opts = {
			auto_start = true,
			focus_after_send = true,
			track_selection = true,
			terminal = {
				provider = "native",
				split_side = "right",
				split_width_percentage = 0.4,
				auto_close = true,
			},
			diff_opts = {
				layout = "vertical",
				open_in_new_tab = true,
				hide_terminal_in_new_tab = true,
			},
		},
		keys = {
			{
				"<C-,>",
				"<cmd>ClaudeCode<cr>",
				mode = { "n", "t" },
				desc = "Toggle Claude Code",
			},
			{
				"<leader>af",
				"<cmd>ClaudeCodeFocus<cr>",
				desc = "[A]I [F]ocus Claude",
			},
			{
				"<leader>as",
				"<cmd>ClaudeCodeSend<cr>",
				mode = "v",
				desc = "[A]I [S]end selection",
			},
			{
				"<leader>aa",
				"<cmd>ClaudeCodeDiffAccept<cr>",
				desc = "[A]I [A]ccept diff",
			},
			{
				"<leader>ad",
				"<cmd>ClaudeCodeDiffDeny<cr>",
				desc = "[A]I [D]eny diff",
			},
		},
	},
	-- dlyongemallo/diffview-plus.nvim
	{
		-- Maintained diffview fork; repo is "diffview-plus" but the Lua module
		-- is still "diffview", so main must be set explicitly.
		"dlyongemallo/diffview-plus.nvim",
		main = "diffview",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
		keys = {
			{
				"<leader>gd",
				function()
					if
						#vim.fs.find(
							".git",
							{ upward = true, path = vim.uv.cwd() }
						) > 0
					then
						vim.cmd("DiffviewOpen")
						return
					end

					-- A fullstack worktree is a plain directory of symlinks to the
					-- per-repo worktrees, so it's not a repo itself and diffview has
					-- nothing to open. Diff each linked repo that has changes instead.
					-- `-C` takes no space: `-C{path}`.
					local cwd = vim.uv.cwd()
					local repositories, changed = {}, {}
					for name, kind in vim.fs.dir(cwd) do
						if kind == "directory" or kind == "link" then
							local path = vim.fs.joinpath(cwd, name)
							if
								#vim.fs.find(".git", { path = path, depth = 1 })
								> 0
							then
								table.insert(repositories, name)
								local status = vim.system({
									"git",
									"-C",
									path,
									"status",
									"--porcelain",
								}):wait()
								if vim.trim(status.stdout or "") ~= "" then
									table.insert(changed, path)
								end
							end
						end
					end

					if #repositories == 0 then
						vim.cmd("DiffviewOpen")
					elseif #changed == 0 then
						table.sort(repositories)
						vim.notify(
							"No changes in " .. table.concat(repositories, ", ")
						)
					else
						table.sort(changed)
						for _, path in ipairs(changed) do
							vim.cmd("DiffviewOpen -C" .. path)
						end
					end
				end,
				desc = "Diffview open",
			},
			{ "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
			{
				"<leader>gh",
				"<cmd>DiffviewFileHistory<cr>",
				desc = "Diffview file history",
			},
			{
				"<leader>gw",
				function()
					if vim.tbl_contains(vim.opt.diffopt:get(), "iwhiteall") then
						vim.opt.diffopt:remove("iwhiteall")
						vim.notify("diff: showing whitespace")
					else
						vim.opt.diffopt:append("iwhiteall")
						vim.notify("diff: ignoring whitespace")
					end
					pcall(vim.cmd, "DiffviewRefresh")
				end,
				desc = "Diffview toggle whitespace",
			},
		},
		opts = {
			view = {
				default = { layout = "diff1_inline" },
				-- diff1_inline runs with 'diff' off, so nvim-ufo attaches and adds
				-- structural folds that the default foldlevel=0 then closes over the
				-- hunks. Inline does no unchanged-region folding of its own, so nothing
				-- is lost; this does disable it for the diff2 layouts, which we don't use.
				foldlevel = 99,
			},
		},
	},
})

vim.api.nvim_set_hl(0, "Folded", { bg = "#1e1e28", fg = "#808080" })
