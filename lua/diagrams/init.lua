local M = {}

M.config = {
  base_url = 'http://localhost',
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  require('diagrams.buffer').setup()
end

return M
