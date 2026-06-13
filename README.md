# worktab.nvim

Neovim's built-in tabs only carry a page number, which makes it hard to tell at a
glance what each tab is *for*. `worktab.nvim` is a small extension that lets you
attach a **name** to each tab.

- Small command surface for creating named tabs
- API-first by design — you keep control of how the tabline renders
- Names are stored on `vim.t` (tabpage variables), so closing a tab cleans them
  up automatically; no autocmds needed
- Optional picker for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Lua API

```lua
local worktab = require("worktab")

worktab.set_name("api")              -- set the current tab's name to "api"
worktab.set_name("api", tabpage)     -- set on a specific tabpage handle

worktab.get_name()                   -- string|nil — nil if no name is set
worktab.get_name(tabpage)            -- look up by tabpage handle

worktab.clear()                      -- remove the current tab's name
worktab.tabnew("api")                -- create a new tab named "api"
worktab.list()                       -- list every tab's entry
worktab.goto_tab("api")              -- switch by name or tabpage handle
```

## Commands

```vim
:Tabnew api
```

Creates a new tabpage and assigns it the name `api`.

Return value of `list()`:

```lua
{
  { tabnr = 1, handle = 1, name = "api",  is_current = false },
  { tabnr = 2, handle = 4, name = "test", is_current = true  },
  { tabnr = 3, handle = 6, name = nil,    is_current = false },
}
```

## Telescope integration

Load the bundled extension to switch tabs from a picker:

```lua
require("telescope").load_extension("worktab")
```

Then run `:Telescope worktab worktab` (or
`require("telescope").extensions.worktab.worktab()`).

## License

MIT
