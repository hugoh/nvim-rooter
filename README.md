# nvim-rooter 🌳

A minimalist (100 LOC) Neovim plugin that changes your working directory to the project root when opening files:

- Automatic and manual (`Rooter` command) modes
- Option to be prompted to confirm the directory change
- Get the repo path with `repo_name()` function

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
	scope = "nvim", -- cd scope: nvim, tab, win
	auto = true, -- automatically change working directory
	confirm = false, -- confirm before automatically changing directory
	display_notification = true,
}
```

## Usage

Just open a file:

1. Opens a file in your project
2. nvim-rooter changes directory to project root if one is found, and displays a notification (optional)

## API

### `require("nvim_rooter").repo_name()`

The `repo_name()` function is useful for [lualine](https://github.com/nvim-lualine/lualine.nvim) configurations, e.g.:

```lua
lualine_b = { require("nvim_rooter").repo_name, "branch", "diff", "diagnostics" }
```

### `require("nvim_rooter").set_root()`

If `auto` is set to false, you can set the directory with `:Rooter` or:

```lua
require("nvim_rooter").set_root()
```

### `require("nvim_rooter").is_setting_root()`

If you need to do some scripting based on directory changes (e.g., `DirChanged` event), `is_setting_root()` indicates if the directory change was triggered by `nvim-rooter`.

## Customization

Override any defaults in your setup:

```lua
require("nvim_rooter").setup({
    root_patterns = { ".git", "Makefile" },  -- Custom root markers
})
```

## Testing

To run tests locally:

```bash
make test
```

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) installed via Lazy.

## Alternatives

- [ahmedkhalf/project.nvim](https://github.com/ahmedkhalf/project.nvim)
- [DrKJeff16/project.nvim](https://github.com/DrKJeff16/project.nvim)
- [notjedi/nvim-rooter.lua](https://github.com/notjedi/nvim-rooter.lua)
- [ygm2/nvim-rooter.lua](https://github.com/ygm2/nvim-rooter.lua)
- [wsdjeg/rooter.nvim](https://github.com/wsdjeg/rooter.nvim)
