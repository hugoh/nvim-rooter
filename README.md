# nvim-rooter 🌳

A minimalist (60 LOC) Neovim plugin that changes your working directory to the project root when opening files:

- Automatic and manual (`Rooter` command) modes
- Option to be prompted to confirm the directory change

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
	auto = true, -- automatically change working directory on buffer change
	confirm = false, -- confirm before automatically changing directory
	display_notification = true,
}
```

## Usage

Just open a file:

1. Opens a file in your project
2. nvim-rooter changes directory to project root if one is found, and displays a notification (optional)

## API

### `require("nvim_rooter").get_root()`

Returns the root directory of the project for the current buffer, or `nil` if no root is found:

```lua
local root = require("nvim_rooter").get_root()
if root then
  print("Project root: " .. root)
end
```

### `require("nvim_rooter").is_cwd_root()`

Checks if the current working directory is already the project root. Returns a boolean and the root directory:

```lua
local is_root, root = require("nvim_rooter").is_cwd_root()
if is_root then
  print("Already at project root: " .. root)
end
```

### `require("nvim_rooter").set_root(manual)`

Changes the working directory to the project root. The `manual` parameter (default: `false`) indicates if the change was manually triggered:

- When `manual` is `true`, directory changes are not subject to the `confirm` setting
- When `manual` is `false` and `confirm` is enabled, the user will be prompted before changing

```lua
require("nvim_rooter").set_root()  -- Auto mode
require("nvim_rooter").set_root(true)  -- Manual mode (via :Rooter command)
```

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
