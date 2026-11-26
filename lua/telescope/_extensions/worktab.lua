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

local function open_exact_or_create(name)
  -- Check the live list, which can differ from the picker's snapshot.
  if name:find("%S") and not worktab.goto_tab(name) then
    worktab.tabnew(name)
  end
end

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
        attach_mappings = function(prompt_bufnr, map)
          for _, mode in ipairs({ "i", "n" }) do
            map(mode, "<C-o>", function()
              local picker = action_state.get_current_picker(prompt_bufnr)
              local line = vim.api.nvim_buf_get_lines(prompt_bufnr, 0, 1, false)[1] or ""
              local name = line:sub(#picker.prompt_prefix + 1)
              if not name:find("%S") then return end
              actions.close(prompt_bufnr)
              open_exact_or_create(name)
            end)
          end
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            local name = action_state.get_current_line()
            actions.close(prompt_bufnr)
            if selection then
              worktab.goto_tab(selection.value.handle)
            else
              open_exact_or_create(name)
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
