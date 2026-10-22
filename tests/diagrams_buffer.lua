-- Run: nvim --headless -u NONE -i NONE -l tests/diagrams_buffer.lua
vim.opt.rtp:prepend(vim.fn.getcwd())

local remote = {
  id = 42,
  title = 'Test Diagram',
  content = '@startuml Test Diagram\nAlice -> Bob: Hello\n@enduml',
  updated_at = 'v1',
}
local available = false
local updates = 0
local notifications = {}
vim.notify = function(message) notifications[#notifications + 1] = message end

package.loaded['diagrams.api'] = {
  get = function(id)
    if not available then return nil, 'connection refused' end
    if id ~= 42 then return nil, 'Diagram not found' end
    return vim.deepcopy(remote)
  end,
  update = function(id, fields)
    updates = updates + 1
    remote.content = fields.content
    remote.updated_at = 'saved-' .. updates
    return vim.deepcopy(remote)
  end,
}

local buffer = require('diagrams.buffer')
buffer.setup()

vim.api.nvim_create_user_command('Diagram', function(opts)
  buffer.open_from(opts.args)
end, { nargs = '?' })

local function set_lines(text)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, '\n', { plain = true }))
end

-- Test: invalid diagram ID
notifications = {}
vim.cmd('Diagram invalid')
assert(#notifications > 0 and notifications[#notifications]:match('must be a number'), 'Invalid ID must report error')

-- Test: failed initial load
notifications = {}
vim.cmd('edit pandora://diagrams/42')
assert(notifications[#notifications]:match('Could not open diagram 42'), 'Failed load must report error')
set_lines('@startuml Local\n@enduml')
available = true
vim.cmd('write')
assert(updates == 0, 'A failed initial load must block normal saves')
assert(vim.bo.modified, 'Blocked save must preserve unsaved edits')
assert(notifications[#notifications]:match('has not loaded successfully'))

-- Test: successful reload and filetype
vim.cmd('edit!')
assert(vim.bo.filetype == 'plantuml', 'Buffer filetype must be plantuml')
assert(not vim.bo.modified, 'Reloaded buffer must not be modified')
assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') == remote.content, 'Content must match remote diagram')

-- Test: save diagram source
set_lines('@startuml Updated\nAlice -> Bob: Hi\n@enduml')
vim.cmd('write')
assert(updates == 1 and remote.content == '@startuml Updated\nAlice -> Bob: Hi\n@enduml', 'Normal save must update remote diagram')
assert(not vim.bo.modified, 'Successful save must clear modified flag')

-- Test: remote conflict detection
set_lines('@startuml Conflicting\n@enduml')
remote.updated_at = 'external-change'
vim.cmd('write')
assert(updates == 1, 'Remote version conflicts must block normal save')
assert(vim.bo.modified, 'Local edits must be preserved on conflict')
assert(notifications[#notifications]:match('Diagram changed on Pandora'), 'Conflict warning must be shown')

-- Test: force save
vim.cmd('write!')
assert(updates == 2, 'Explicit :write! must override remote conflict')
assert(not vim.bo.modified)

-- Test: reload from remote (:edit!)
remote.content = '@startuml Reloaded\nBob -> Alice: Received\n@enduml'
remote.updated_at = 'external-update'
set_lines('@startuml Discarded\n@enduml')
vim.cmd('edit!')
assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') == remote.content, ':edit! must discard local edits and reload remote')
assert(not vim.bo.modified)

-- Test: open via :Diagram <id>
vim.cmd('enew')
vim.cmd('Diagram 42')
assert(vim.api.nvim_buf_get_name(0):match('^pandora://diagrams/42$'), ':Diagram 42 must open diagram buffer')
assert(vim.bo.filetype == 'plantuml', 'Buffer opened via :Diagram must have plantuml filetype')

print('All diagrams buffer tests passed successfully')
vim.cmd('qa!')
