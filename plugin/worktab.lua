vim.api.nvim_create_user_command("Tabnew", function(opts)
  require("worktab").tabnew(opts.args)
end, {
  nargs = "+",
  desc = "Create a named tabpage",
})
