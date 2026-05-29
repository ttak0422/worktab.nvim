local VAR_NAME = "worktab_name"

local M = {}

---@param tabpage integer|nil  tabpage handle (0 or nil = current)
---@return integer handle
local function resolve(tabpage)
  if not tabpage or tabpage == 0 then
    return vim.api.nvim_get_current_tabpage()
  end
  return tabpage
end

---Set a name on a tabpage.
---@param name string
---@param tabpage integer|nil  tabpage handle (default: current)
function M.set_name(name, tabpage)
  vim.validate({ name = { name, "string" } })
  vim.api.nvim_tabpage_set_var(resolve(tabpage), VAR_NAME, name)
end

---Get the name assigned to a tabpage.
---@param tabpage integer|nil
---@return string|nil
function M.get_name(tabpage)
  local ok, name = pcall(vim.api.nvim_tabpage_get_var, resolve(tabpage), VAR_NAME)
  if ok and type(name) == "string" and name ~= "" then
    return name
  end
  return nil
end

---Clear the name for a tabpage.
---@param tabpage integer|nil
function M.clear(tabpage)
  pcall(vim.api.nvim_tabpage_del_var, resolve(tabpage), VAR_NAME)
end

---@class WorktabEntry
---@field tabnr integer
---@field handle integer
---@field name string|nil
---@field is_current boolean

---List every tabpage with its current name.
---@return WorktabEntry[]
function M.list()
  local current = vim.api.nvim_get_current_tabpage()
  local out = {}
  for i, handle in ipairs(vim.api.nvim_list_tabpages()) do
    out[#out + 1] = {
      tabnr = i,
      handle = handle,
      name = M.get_name(handle),
      is_current = handle == current,
    }
  end
  return out
end

---Switch focus to the tab matching `target`.
---@param target integer|string  tabpage handle (integer) or name (string)
---@return boolean ok
function M.goto_tab(target)
  if type(target) == "number" then
    if vim.api.nvim_tabpage_is_valid(target) then
      vim.api.nvim_set_current_tabpage(target)
      return true
    end
    return false
  end
  for _, entry in ipairs(M.list()) do
    if entry.name == target then
      vim.api.nvim_set_current_tabpage(entry.handle)
      return true
    end
  end
  return false
end

return M
