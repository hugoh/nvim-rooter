local M = { config = {} }

local defaults = {
	root_patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn" },
	scope = "nvim", -- cd scope: nvim, tab, win
	auto = true, -- automatically change working directory
	confirm = false, -- confirm before automatically changing directory
	display_notification = true,
}

local plugin_name = "nvim-rooter"
local cd_skip_key = plugin_name .. ":cd_skip"

local set_root_in_progress = false
local cd_function, getcwd_args

local function is_normal_buffer(bufnr) return vim.api.nvim_buf_get_option(bufnr, "buftype") == "" end

local function current_dir() return vim.fn.getcwd(getcwd_args[1], getcwd_args[2]) end

-- Changes directory to project root
-- Will only confirm if not triggered manually
-- manual: boolean indicating if the change was manually triggered
function M.set_root(manual)
	local bufnr = vim.api.nvim_get_current_buf()
	if not is_normal_buffer(bufnr) then return end
	local root_dir = vim.fs.root(bufnr, M.config.root_patterns)
	if not root_dir then return end
	if vim.fs.normalize(root_dir) == current_dir() then return end
	if M.config.confirm and not manual then
		local ok, skip = pcall(vim.api.nvim_buf_get_var, bufnr, cd_skip_key)
		local previously_skipped = ok and skip
		if previously_skipped then return end
		local confirm = vim.fn.confirm(string.format('Change to project root?\n"%s"', root_dir), "&Yes\n&No", 2)
		if confirm == 2 then
			vim.api.nvim_buf_set_var(bufnr, cd_skip_key, true)
			return
		end
	end
	set_root_in_progress = true
	cd_function(root_dir)
	set_root_in_progress = false
	if M.config.display_notification then
		vim.notify("[cwd] " .. root_dir, vim.log.levels.INFO, { title = plugin_name })
	end
end

-- Indicates that a change of root is in progress
function M.is_setting_root() return set_root_in_progress end

-- Plugin setup
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", defaults, opts or {})

	local cd_function_options = {
		["tab"] = function(dir) vim.cmd.tcd({ args = { dir }, mods = { silent = true } }) end,
		["win"] = function(dir) vim.api.nvim_win_set_option(0, "cd", dir) end,
		nvim = vim.api.nvim_set_current_dir,
	}
	cd_function = cd_function_options[M.config.scope] or cd_function_options.nvim
	local getcwd_args_options = {
		["tab"] = { -1, 0 },
		["win"] = { 0, 0 },
		nvim = { -1, -1 },
	}
	getcwd_args = getcwd_args_options[M.config.scope] or getcwd_args_options.nvim

	if M.config.auto then
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			group = vim.api.nvim_create_augroup(plugin_name, { clear = true }),
			callback = function() return M.set_root(false) end,
			nested = true,
		})
	end

	vim.api.nvim_create_user_command(
		"Rooter",
		function() M.set_root(true) end,
		{ desc = "Set the current working directory to the repository root" }
	)
end

return M
