local M = {}

-- Default configuration
local defaults = {
  root_patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn" },
  excluded_filetypes = {
    ["help"] = true,
    ["nofile"] = true,
    ["neo-tree"] = true,
  },
}

local plugin_name = "nvim-rooter"
local cache_key = "repo_root"

M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Create or clear the autocommand group
  local group = vim.api.nvim_create_augroup(plugin_name, { clear = true })

  -- Set up the autocommand
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = group,
    callback = function()
      local filetype = vim.bo.filetype
      if M.config.excluded_filetypes[filetype] then
        return -- Skip directory change for excluded filetypes
      end
      local root_dir = vim.fs.root(0, M.config.root_patterns)
      if root_dir then
        -- Change the working directory
        vim.api.nvim_set_current_dir(root_dir)

        -- Cache the repository name
        local bufnr = vim.api.nvim_get_current_buf()
        local repo_name = vim.fn.fnamemodify(root_dir, ":t")
        pcall(vim.api.nvim_buf_set_var, bufnr, cache_key, repo_name)
      end
    end,
  })
end

-- Function to get repository root name
function M.repo_root()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, cached = pcall(vim.api.nvim_buf_get_var, bufnr, cache_key)
  if ok then
    return cached
  end

  -- If not cached, compute and return (but don't cache here, as it's handled in autocommand)
  local root = vim.fs.root(0, M.config.root_patterns)
  if root then
    return vim.fn.fnamemodify(root, ":t")
  end
  return ""
end

return M
