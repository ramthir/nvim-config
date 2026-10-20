-- Run: nvim --headless -u NONE -i NONE -l tests/markdown_options.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
require('core.autocmds')

local function markdown_buffer()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].formatoptions = 'tcqaw'
  vim.bo[buf].filetype = 'markdown'
  return buf
end

local function flush()
  local done = false
  vim.schedule(function() done = true end)
  assert(vim.wait(1000, function() return done end), 'Scheduled callbacks did not finish')
end

local markdown = markdown_buffer()
local other = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(other)
vim.bo[other].formatoptions = 'tcqaw'
flush()
assert(vim.bo[markdown].formatoptions == 'cq', 'Deferred setup must target the original Markdown buffer')
assert(vim.bo[other].formatoptions == 'tcqaw', 'Switching buffers must not change the new buffer options')
assert(vim.api.nvim_get_current_buf() == other, 'Deferred setup must not change the current buffer')

local changed = markdown_buffer()
vim.bo[changed].filetype = 'text'
flush()
assert(vim.bo[changed].formatoptions == 'tcqaw', 'Skip buffers that are no longer Markdown')

local deleted = markdown_buffer()
vim.api.nvim_buf_delete(deleted, { force = true })
flush() -- must not access a deleted buffer

print('Markdown deferred setup regression checks passed')
vim.cmd('qa!')
