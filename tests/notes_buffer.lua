-- Run: nvim --headless -u NONE -i NONE -l tests/notes_buffer.lua
vim.opt.rtp:prepend(vim.fn.getcwd())

local remote = { id = 123, title = 'Test', content = '# Test', updated_at = 'v1' }
local available = false
local updates = 0
local notifications = {}
vim.notify = function(message) notifications[#notifications + 1] = message end
package.loaded['notes.wikilinks'] = {
  set_title = function() end,
  attach = function() end,
  refresh = function() end,
  refresh_all = function() end,
}
package.loaded['notes.pandora'] = {
  get = function()
    if not available then return nil, 'connection refused' end
    return vim.deepcopy(remote)
  end,
  update = function(_, fields)
    updates = updates + 1
    remote.content = fields.content
    remote.title = fields.title or remote.title
    remote.updated_at = 'saved-' .. updates
    return vim.deepcopy(remote)
  end,
}
require('notes.buffer').setup()

vim.cmd('edit pandora://notes/123')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# Local edits' })
available = true
vim.cmd('write')
assert(updates == 0, 'A failed initial load must block normal saves, even after the API recovers')
assert(vim.bo.modified, 'Blocked saves must preserve unsaved edits')
assert(notifications[#notifications]:match('has not loaded successfully'))
assert(remote.content == '# Test', 'Blocked saves must leave the remote note intact')

vim.cmd('edit!')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# Saved edits' })
vim.cmd('write')
assert(updates == 1 and remote.content == '# Saved edits', 'Successful reloads must restore normal saving')
assert(not vim.bo.modified)

available = false
vim.cmd('edit!')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# After failed reload' })
available = true
vim.cmd('write')
assert(updates == 1, 'A failed reload must invalidate the old baseline')
assert(vim.bo.modified)

vim.cmd('edit!')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# Conflicting edits' })
remote.updated_at = 'external-change'
vim.cmd('write')
assert(updates == 1, 'Remote version conflicts must still block normal saves')
assert(vim.bo.modified)
vim.cmd('write!')
assert(updates == 2, 'Explicit force saves must still override conflicts')

vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# Offline edits' })
available = false
vim.cmd('write')
assert(updates == 2 and vim.bo.modified, 'Failed version checks must preserve local edits')

vim.cmd('edit!')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# Explicit overwrite' })
available = true
vim.cmd('write!')
assert(updates == 3, 'Explicit force saves must remain available without a baseline')
print('Notes buffer regression checks passed')
vim.cmd('qa!')
