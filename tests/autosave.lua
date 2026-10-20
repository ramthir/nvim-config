-- Run: nvim --headless -u NONE -i NONE -l tests/autosave.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
require('core.autocmds')
local notifications = {}
vim.notify = function(message, level)
  notifications[#notifications + 1] = { message = message, level = level }
end
local path = vim.fn.tempname()
vim.api.nvim_buf_set_name(0, path)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unsaved edits' })
vim.bo.readonly = true
local function autosave()
  vim.api.nvim_exec_autocmds('InsertLeave', {})
end

autosave()
assert(#notifications == 1, 'A failed write must notify')
assert(notifications[1].message:find(path, 1, true), 'The warning must identify the file')
assert(notifications[1].message:find('E45', 1, true), 'The warning must include the write error')
assert(notifications[1].level == vim.log.levels.ERROR)
assert(vim.bo.modified, 'Failed autosaves must leave edits marked as unsaved')
assert(vim.fn.filereadable(path) == 0)
autosave()
autosave()
assert(#notifications == 1, 'Repeated failures must not spam notifications')

vim.bo.readonly = false
autosave()
assert(not vim.bo.modified, 'Autosave must recover when writing becomes possible')
assert(vim.fn.readfile(path)[1] == 'unsaved edits')
assert(not vim.b.autosave_failure_notified)

vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'next edits' })
vim.bo.readonly = true
autosave()
assert(#notifications == 2, 'A new failure after a successful save must notify again')
vim.bo.readonly = false
vim.cmd('silent write')
assert(not vim.b.autosave_failure_notified, 'A manual save must also reset warning suppression')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'final edits' })
vim.bo.readonly = true
autosave()
assert(#notifications == 3)

vim.bo.buftype = 'nofile'
autosave()
assert(#notifications == 3, 'Special buffers must still be excluded')
vim.cmd('enew!')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unnamed edits' })
autosave()
assert(#notifications == 3 and vim.bo.modified, 'Unnamed buffers must still be excluded')
vim.fn.delete(path)
print('Autosave error reporting regression checks passed')
vim.cmd('qa!')
