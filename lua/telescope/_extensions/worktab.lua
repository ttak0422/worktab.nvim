local ok, telescope = pcall(require, "telescope")
if not ok then
  error("worktab.nvim telescope extension requires nvim-telescope/telescope.nvim")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local worktab = require("worktab")

local function make_picker(opts)
  opts = opts or {}

  local entries = worktab.list()

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 1 },
      { width = 3 },
      { remaining = true },
    },
  })

  local function make_display(entry)
    local data = entry.value
    return displayer({
      data.is_current and "*" or " ",
      tostring(data.tabnr),
      data.name or "[unnamed]",
    })
  end

  pickers
      .new(opts, {
        prompt_title = "Worktab",
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            return {
              value = entry,
              ordinal = (entry.name or "") .. " " .. tostring(entry.tabnr),
              display = make_display,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection then
              worktab.goto_tab(selection.value.handle)
            end
          end)
          return true
        end,
      })
      :find()
end

return telescope.register_extension({
  exports = {
    worktab = make_picker,
  },
})
