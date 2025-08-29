# nvim-rooter 🌳

A minimalist (< 60 LOC) Neovim plugin that automatically changes your working directory to the project root when opening files.

I wrote this because alternatives were either doing way more than I wanted, were not working for me, and I needed a function to return the root name.

## Features
- Zero configuration required
- Function to return repo name

## Installation

### With Lazy.nvim
```lua
{
    "hugoh/nvim-rooter",
    opts = {
        -- Optional custom configuration
    }
}
```

### With Packer.nvim
```lua
use {
    "your-username/nvim-rooter",
    config = function()
        require("nvim-rooter").setup()
    end
}
```

## Default Configuration
```lua
{
  root_patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn" },
  display_notification = true,
  excluded_filetypes = {
    ["help"] = true,
    ["nofile"] = true,
    ["neo-tree"] = true,
  },
}
```

## Usage
Just open a file:
1. Opens a file in your project
2. nvim-rooter changes directory to project root if one is found, and displays a notification (optional)

The `repo_name()` function is useful for [lualine](https://github.com/nvim-lualine/lualine.nvim) configurations, e.g.:
```lua
lualine_b = { require("nvim_rooter").repo_name, "branch", "diff", "diagnostics" }
```

## Customization
Override any defaults in your setup:
```lua
require("nvim_rooter").setup({
    root_patterns = { ".git", "Makefile" },  -- Custom root markers
    excluded_filetypes = {
        ["neo-tree"] = false  -- Enable for neo-tree
    }
})
```

## Testing

To run tests locally:

```bash
./test.sh
```

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) installed via Lazy.

## Alternatives

While nvim-rooter focuses on minimalism and repo name access, you might also consider:
- [project.nvim](https://github.com/ahmedkhalf/project.nvim) - More feature-rich project management with pattern matching
- [nvim-rooter.lua](https://github.com/ygm2/nvim-rooter.lua) - Port of vim-rooter with additional configuration options
