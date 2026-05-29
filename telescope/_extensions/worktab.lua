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

  local max_name = 7
  for _, e in ipairs(entries) do
    local n = e.name or "[unnamed]"
    if #n > max_name then
      max_name = #n
    end
  end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 1 },
      { width = 3 },
      { width = max_name },
      { remaining = true },
    },
  })

  local function make_display(entry)
    local data = entry.value
    return displayer({
      data.is_current and "*" or " ",
      tostring(data.tabnr),
      data.name or "[unnamed]",
      data.preview or "",
    })
  end

  local function preview_for(handle)
    local wins = vim.api.nvim_tabpage_list_wins(handle)
    if #wins == 0 then
      return ""
    end
    local buf = vim.api.nvim_win_get_buf(wins[1])
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
      return "[No Name]"
    end
    return vim.fn.fnamemodify(name, ":~:.")
  end

  pickers
      .new(opts, {
        prompt_title = "Worktab",
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            entry.preview = preview_for(entry.handle)
            return {
              value = entry,
              ordinal = (entry.name or "") .. " " .. tostring(entry.tabnr) .. " " .. entry.preview,
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
