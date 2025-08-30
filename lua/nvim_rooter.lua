local M = {}

-- Default configuration
local defaults = {
  root_patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn" },
  display_notification = true,
  excluded_filetypes = {
    ["help"] = true,
    ["nofile"] = true,
    ["neo-tree"] = true,
  },
}

local plugin_name = "nvim-rooter"
local cache_name_key = plugin_name .. ":repo_name"

M.config = {}

local function repo_info(bufnr, cache_result)
  local root = vim.fs.root(bufnr, M.config.root_patterns)
  local name = ""
  if root then
    name = vim.fn.fnamemodify(root, ":t")
    if cache_result then
      pcall(vim.api.nvim_buf_set_var, bufnr, cache_name_key, name)
    end
  end
  return root, name
end

function M.set_root()
  local filetype = vim.bo.filetype
  if M.config.excluded_filetypes[filetype] then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local root_dir, _ = repo_info(bufnr, true)
  if root_dir then
    local current_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
    if vim.fn.fnamemodify(root_dir, ":p") == current_dir then
      return
    end
    vim.api.nvim_set_current_dir(root_dir)
    if M.config.display_notification then
      vim.notify("[cwd] " .. root_dir, vim.log.levels.INFO, { title = plugin_name })
    end
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  local group = vim.api.nvim_create_augroup(plugin_name, { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = group,
    callback = M.set_root
  })
end

-- Function to get repository root name
function M.repo_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, cached = pcall(vim.api.nvim_buf_get_var, bufnr, cache_name_key)
  if ok then
    return cached
  end
  local _, name = repo_info(bufnr, false)
  return name
end

return M
