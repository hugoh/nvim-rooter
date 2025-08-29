-- Reset to bare runtime
vim.opt.runtimepath = vim.fn.getenv("VIMRUNTIME")

-- Add plenary plugin root to runtimepath
local plenary_path = vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
vim.opt.runtimepath:append(plenary_path)

-- Load plenary test harness
require("plenary.busted")

-- Add the plugin under test (cwd)
vim.opt.runtimepath:append(vim.loop.cwd())
