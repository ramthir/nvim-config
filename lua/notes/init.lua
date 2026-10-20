local M = {}

local defaults = require("notes.config").defaults
M.config = vim.tbl_deep_extend("force", {}, defaults)

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})
  require("notes.buffer").setup()
  require("notes.live").start()
end

function M.create()
  require("notes.create").create()
end

return M
