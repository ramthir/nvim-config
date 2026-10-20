-- Run: nvim --headless -u NONE -i NONE -l tests/whitespace.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
require('core.autocmds')

local function clean(filetype, lines, expected)
  vim.bo.filetype = filetype
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 2, 1 })
  vim.api.nvim_exec_autocmds('BufWritePre', {})
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(vim.deep_equal(actual, expected), vim.inspect({ filetype = filetype, actual = actual, expected = expected }))
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 2, 1 }), 'Cleanup must preserve the cursor')
end

local markdown = { 'Hard break  ', 'Next line', 'Single space ', '```text', 'code \t  ', '```', '   ', 'Kr,' }
local expected = vim.deepcopy(markdown)
expected[#expected] = 'Kr,  '
clean('markdown', markdown, expected)
clean('markdown', expected, expected) -- repeated saves are stable
for _, filetype in ipairs({ 'lua', 'text', '' }) do
  clean(filetype, { 'trailing  ', 'line\t ', 'Kr,', 'Kr,  ', '   ' }, { 'trailing', 'line', 'Kr,', 'Kr,', '' })
end
print('Whitespace regression checks passed')
vim.cmd('qa!')
