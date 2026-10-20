local M = {}

local defaults = require("notes.config").defaults
M.config = vim.tbl_deep_extend("force", {}, defaults)

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})
  require("notes.live").start()
end

function M.search()
  require("notes.search").search(M.config)
end

function M.grep()
  require("notes.search").grep(M.config)
end

function M.create()
  require("notes.create").create(M.config)
end

return M
