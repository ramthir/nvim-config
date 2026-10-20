local M = {}

M.defaults = {
  base_url = "http://localhost",
  template = function(title)
    return string.format("# %s\n\n---\n\n#Note\n", title)
  end,
}

return M
