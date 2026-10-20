-- Run: nvim --headless -u NONE -i NONE -l tests/notes_reconnect.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local connections, retries, requests, notifications = {}, {}, {}, {}
vim.notify = function(message) notifications[#notifications + 1] = message end
vim.defer_fn = function(callback) retries[#retries + 1] = callback end
package.loaded['notes'] = { config = { base_url = 'http://mock' } }
package.loaded['notes.wikilinks'] = {
  invalidate = function() end, refresh_all = function() end,
  set_title = function() end, refresh = function() end,
}
package.loaded['notes.pandora'] = {
  client_id = 'test-client',
  get = function() error('Reconciliation must be asynchronous') end,
  get_async = function(id, callback) requests[id] = callback end,
}
vim.system = function(_, opts, complete)
  connections[#connections + 1] = { stdout = opts.stdout, complete = complete }
  return { kill = function() end }
end
local function flush()
  local done = false
  vim.schedule(function() done = true end)
  assert(vim.wait(1000, function() return done end))
end
local function make_buffer(id, modified)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, 'pandora://notes/' .. id)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'local-' .. id })
  vim.bo[buf].modified = modified or false
  vim.b[buf].pandora_updated_at = 'v1'
  return buf
end
local function content(buf) return vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] end
local function reply(id, version)
  requests[id]({ id = id, title = 'Note ' .. id, content = 'remote-' .. id, updated_at = version })
end
local clean = make_buffer(105)
local edited = make_buffer(106, true)
local unchanged = make_buffer(107, true)
local other = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(other, '/tmp/not-a-pandora-note.md')
local live = require('notes.live')
live.start()
connections[1].stdout(nil, 'retry: 5000\n\n')
flush()
reply(105, 'v1')
reply(106, 'v1')
reply(107, 'v1')
assert(content(clean) == 'local-105', 'Unchanged clean notes need no reload')
assert(not vim.b[edited].pandora_remote_conflict, 'Unchanged remote versions must not flag local edits')

connections[1].complete({ code = 1 })
flush()
assert(#retries == 1)
retries[1]()
assert(#connections == 2)
requests = {}
connections[2].stdout(nil, 'retry: 5000\n\n') -- Pandora's initial frame; no update event is replayed
flush()
assert(requests[105] and requests[106] and requests[107], 'Reconnect must reconcile every loaded note')
reply(105, 'v2')
reply(106, 'v2')
reply(107, 'v1')
assert(content(clean) == 'remote-105' and not vim.bo[clean].modified, 'Missed changes must reload clean notes')
assert(content(edited) == 'local-106' and vim.bo[edited].modified, 'Reconnect must preserve unsaved edits')
assert(vim.b[edited].pandora_remote_conflict, 'Changed remote versions must flag a conflict')
assert(not vim.b[unchanged].pandora_remote_conflict, 'Unchanged remote versions must not flag a conflict')
requests = {}
connections[2].stdout(nil, ': another heartbeat\n\n')
flush()
assert(next(requests) == nil, 'Reconcile once per connection, not on every heartbeat')

connections[2].complete({ code = 1 })
flush()
retries[2]()
connections[3].stdout(nil, ': heartbeat\n\n')
flush()
vim.api.nvim_buf_set_lines(clean, 0, -1, false, { 'typed during reconnect' })
reply(105, 'v3')
assert(content(clean) == 'typed during reconnect' and vim.bo[clean].modified)
assert(vim.b[clean].pandora_remote_conflict)
local late = requests[107]
live.stop()
late({ id = 107, title = 'Late', content = 'stale', updated_at = 'v3' })
assert(content(unchanged) == 'local-107', 'Stopping must invalidate reconciliation responses')
connections[3].stdout(nil, ': late heartbeat\n\n')
requests = {}
flush()
assert(next(requests) == nil, 'Closed connections must not restart reconciliation')
print('Pandora reconnect reconciliation regression checks passed')
vim.cmd('qa!')
