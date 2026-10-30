-- Run from the repository root:
-- TELESCOPE_PATH=/path/to/telescope.nvim PLENARY_PATH=/path/to/plenary.nvim \
--   nvim --headless -u NONE -i NONE -l tests/telescope.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
for _, name in ipairs({ "TELESCOPE_PATH", "PLENARY_PATH" }) do
  vim.opt.runtimepath:append(assert(vim.env[name], name .. " is required"))
end
vim.o.columns, vim.o.lines = 120, 40

local telescope = require("telescope")
telescope.setup({ defaults = { sorting_strategy = "ascending", history = false } })
telescope.load_extension("worktab")
local worktab = require("worktab")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")

local function picker(prompt, has_selection, opts)
  vim.cmd.stopinsert()
  telescope.extensions.worktab.worktab(opts)
  local buf = vim.api.nvim_get_current_buf()
  local current = state.get_current_picker(buf)
  local completed
  current:register_completion_callback(function(p)
    completed = p:_get_prompt()
  end)
  current:set_prompt(prompt)
  assert(
    vim.wait(2000, function()
      return completed == prompt and (current:get_selection() ~= nil) == has_selection
    end, 10),
    "picker did not finish filtering: " .. prompt
  )
  return buf
end

local function enter(buf, mode)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode or "i")) do
    if map.lhs == "<CR>" then
      assert(map.callback, "Enter callback missing")
      map.callback()
      return
    end
  end
  error("Enter mapping missing")
end

local function count()
  return #vim.api.nvim_list_tabpages()
end

local function reset()
  vim.cmd("silent! tabonly!")
  worktab.set_name("home")
end

-- Unmatched input creates and enters one tab, preserving all spaces in its name.
reset()
local name = "  new workspace  "
enter(picker(name, false))
assert(count() == 2, "unmatched input did not create one tab")
assert(worktab.get_name() == name, "prompt name was changed")
local created = vim.api.nvim_get_current_tabpage()

-- A reopened picker sees the new tab; fuzzy matches still select existing tabs.
worktab.goto_tab("home")
enter(picker("nwsp", true), "n")
assert(count() == 2 and vim.api.nvim_get_current_tabpage() == created, "fuzzy selection changed")
worktab.goto_tab("home")
enter(picker(name, true))
assert(count() == 2 and vim.api.nvim_get_current_tabpage() == created, "same name duplicated")

-- Canceling an unmatched search does not create a tab.
local before = count()
actions.close(picker("canceled workspace", false))
assert(count() == before, "cancel created a tab")

-- A caller can filter all entries out. Empty input is still a no-op, and an
-- exact live name must be reused even though the picker has no matching entry.
local function empty_finder()
  return { finder = require("telescope.finders").new_table({ results = {} }) }
end
for _, prompt in ipairs({ "", "   ", "\t " }) do
  enter(picker(prompt, false, empty_finder()))
  assert(count() == before, "blank input created a tab")
end
worktab.goto_tab("home")
enter(picker(name, false, empty_finder()))
assert(
  count() == before and vim.api.nvim_get_current_tabpage() == created,
  "filtered duplicate created"
)

-- Renames after opening the picker are checked against the live tab list.
reset()
local original = vim.api.nvim_get_current_tabpage()
local buf = picker("renamed after opening", false)
worktab.set_name("renamed after opening", original)
enter(buf)
assert(
  count() == 1 and vim.api.nvim_get_current_tabpage() == original,
  "stale list created duplicate"
)

-- A selected tab closed while the picker is open must not be recreated.
reset()
local doomed = worktab.tabnew("closed selection")
worktab.goto_tab("home")
buf = picker("closed selection", true)
vim.cmd("tabclose! " .. vim.api.nvim_tabpage_get_number(doomed))
enter(buf)
assert(count() == 1 and worktab.get_name() == "home", "closed selection created a tab")

-- Reopening refreshes the list: a previously closed name can be created again.
enter(picker("closed selection", false))
assert(
  count() == 2 and worktab.get_name() == "closed selection",
  "closed name could not be recreated"
)

-- Blank search with the normal finder retains unnamed-tab selection behavior.
reset()
worktab.clear()
enter(picker("", true))
assert(count() == 1 and worktab.get_name() == nil, "unnamed selection changed")
print("worktab Telescope regressions passed")
vim.cmd("qa!")
