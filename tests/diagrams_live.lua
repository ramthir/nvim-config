-- Run: nvim --headless -u NONE -i NONE -l tests/diagrams_live.lua
vim.opt.rtp:prepend(vim.fn.getcwd())

local requests, notifications = {}, {}
vim.notify = function(message) notifications[#notifications + 1] = message end
package.loaded['diagrams.api'] = {
  get = function() error('Live updates must never call the synchronous API') end,
  get_async = function(id, callback) requests[#requests + 1] = { id = id, callback = callback } end,
}

local live   = require('diagrams.live')
local buffer = require('diagrams.buffer')

local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buf, 'pandora://diagrams/42')

local function reset()
  requests, notifications = {}, {}
  live.reset()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'one', 'two', 'three' })
  vim.api.nvim_win_set_cursor(0, { 2, 1 })
  vim.bo[buf].modified = false
  vim.b[buf].pandora_updated_at = 'v1'
  vim.b[buf].pandora_remote_conflict = false
end
local function lines() return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n') end
local function diagram(content, updated_at)
  return { id = 42, title = 'T', content = content, updated_at = updated_at }
end
local function updated(id) live.on_event({ type = 'diagram.updated', id = id or 42 }) end

-- A clean buffer reloads after the fetch, never before, and keeps its cursor row.
reset()
updated()
assert(lines() == 'one\ntwo\nthree', 'The handler must return before the request completes')
assert(#requests == 1 and requests[1].id == 42)
requests[1].callback(diagram('one\nTWO\nthree\nfour', 'v2'))
assert(lines() == 'one\nTWO\nthree\nfour' and not vim.bo[buf].modified)
assert(vim.b[buf].pandora_updated_at == 'v2')
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, 'The cursor stays on its line')

-- Unsaved edits are kept, flagged and warned about.
reset()
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { 'edited' })
updated()
requests[1].callback(diagram('remote', 'v2'))
assert(lines() == 'edited\ntwo\nthree' and vim.bo[buf].modified)
assert(vim.b[buf].pandora_remote_conflict == true)
assert(#notifications == 1 and notifications[1]:find('changed on Pandora'))

-- The event for this Neovim's own save changes nothing, even with later edits.
reset()
updated()
requests[1].callback(diagram('same as saved', 'v1'))
assert(lines() == 'one\ntwo\nthree' and #notifications == 0 and not vim.b[buf].pandora_remote_conflict)
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { 'typed after saving' })
updated()
requests[2].callback(diagram('same as saved', 'v1'))
assert(lines() == 'typed after saving\ntwo\nthree' and #notifications == 0 and not vim.b[buf].pandora_remote_conflict)

-- A save or reload while fetching makes the response obsolete.
reset()
updated()
vim.b[buf].pandora_updated_at = 'v3'
requests[1].callback(diagram('remote', 'v2'))
assert(lines() == 'one\ntwo\nthree' and #notifications == 0)

-- So does an edit made while fetching.
reset()
updated()
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { 'typed while fetching' })
vim.bo[buf].modified = false
requests[1].callback(diagram('remote', 'v2'))
assert(lines() == 'typed while fetching\ntwo\nthree')

-- A newer event supersedes a request still in flight.
reset()
updated()
updated()
requests[1].callback(diagram('first', 'v2'))
assert(lines() == 'one\ntwo\nthree', 'The older request is ignored')
requests[2].callback(diagram('second', 'v3'))
assert(lines() == 'second')

-- A failed fetch warns and changes nothing.
reset()
updated()
requests[1].callback(nil, 'connection refused')
assert(lines() == 'one\ntwo\nthree' and #notifications == 1 and notifications[1]:find('connection refused'))

-- A deleted diagram warns; a diagram that is not open is ignored.
reset()
live.on_event({ type = 'diagram.deleted', id = 42 })
assert(#notifications == 1 and notifications[1]:find('42') and notifications[1]:find('deleted'))
reset()
updated(7)
live.on_event({ type = 'diagram.deleted', id = 7 })
assert(#requests == 0 and #notifications == 0)

-- Reconcile checks every open diagram buffer and nothing else.
reset()
local other = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(other, 'pandora://notes/42')
live.reconcile()
assert(#requests == 1 and requests[1].id == 42)
requests[1].callback(diagram('while down', 'v2'))
assert(lines() == 'while down')
reset()
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { 'edited' })
live.reconcile()
requests[1].callback(diagram('while down', 'v2'))
assert(lines() == 'edited\ntwo\nthree' and vim.b[buf].pandora_remote_conflict == true)

-- The notes event stream hands diagram events to this module, and reconnects check open diagrams.
local stdout
vim.system = function(_, opts)
  stdout = opts.stdout
  return { kill = function() end }
end
package.loaded['notes'] = { config = { base_url = 'http://mock' } }
package.loaded['notes.buffer'] = { find = function() return nil end }
package.loaded['notes.pandora'] = { client_id = 'test-client', get_async = function() end }
package.loaded['notes.wikilinks'] = { invalidate = function() end, refresh_all = function() end }
local notes_live = require('notes.live')
reset()
notes_live.start()
stdout(nil, ': heartbeat\n\n')
vim.wait(1000, function() return #requests > 0 end)
assert(#requests == 1 and requests[1].id == 42, 'Connecting checks the open diagrams')
requests[1].callback(diagram('one\ntwo\nthree', 'v1'))
stdout(nil, 'event: diagram.updated\ndata: ' .. vim.json.encode({ id = 42, type = 'diagram.updated' }) .. '\n\n')
vim.wait(1000, function() return #requests > 1 end)
assert(#requests == 2 and requests[2].id == 42, 'A diagram event reaches the diagram module')
notes_live.stop()

print('Diagram live update regression checks passed')
