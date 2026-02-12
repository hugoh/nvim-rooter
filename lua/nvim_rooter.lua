local M = { config = {} }

local defaults = {
	root_patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn" },
	auto = true, -- automatically change working directory on buffer change
	confirm = false, -- confirm before automatically changing directory
	display_notification = true,
}

local plugin_name = "nvim-rooter"
local cd_skip_key = plugin_name .. ":cd_skip"

local function is_normal_buffer(bufnr) return vim.api.nvim_buf_get_option(bufnr, "buftype") == "" end

-- Return the root directory corresponding to the current buffer, or nil
function M.get_root()
	local bufnr = vim.api.nvim_get_current_buf()
	if not is_normal_buffer(bufnr) then return end
	return vim.fs.root(bufnr, M.config.root_patterns)
end

-- Check if current dir is a project root
function M.is_cwd_root()
	local buf_root = M.get_root()
	return buf_root and buf_root == vim.uv.cwd() or false, buf_root
end

local function confirm_set_root(root_dir)
	local ok, skip = pcall(vim.api.nvim_buf_get_var, 0, cd_skip_key)
	local previously_skipped = ok and skip
	if previously_skipped then return false end
	local confirm = vim.fn.confirm(string.format('Change to project root?\n"%s"', root_dir), "&Yes\n&No", 1)
	if confirm == 2 then
		vim.api.nvim_buf_set_var(0, cd_skip_key, true)
		return false
	end
	return true
end

-- Changes directory to project root
-- Will only confirm if not triggered manually
-- manual: boolean indicating if the change was manually triggered
function M.set_root(manual)
	local is_root_dir, root_dir = M.is_cwd_root()
	if is_root_dir or not root_dir then return end
	if not manual and M.config.confirm then
		if not confirm_set_root(root_dir) then return end
	end
	vim.api.nvim_set_current_dir(root_dir)
	if M.config.display_notification then
		vim.notify("[cwd] " .. root_dir, vim.log.levels.INFO, { title = plugin_name })
	end
end

-- Plugin setup
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", defaults, opts or {})

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
