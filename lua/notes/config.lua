local M = {}

M.defaults = {
  notes_path = "~/Workspace/notes",
  template = function(title)
    return string.format("# %s\n\n---\n\n#Note\n", title)
  end,
}

return M
