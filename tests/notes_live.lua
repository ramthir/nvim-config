-- Run: nvim --headless -u NONE -i NONE -l tests/notes_live.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local requests, notifications = {}, {}
local stdout
vim.notify = function(message) notifications[#notifications + 1] = message end
package.loaded['notes'] = { config = { base_url = 'http://mock' } }
package.loaded['notes.wikilinks'] = {
  invalidate = function() end, refresh_all = function() end,
  set_title = function() end, refresh = function() end,
}
package.loaded['notes.pandora'] = {
  client_id = 'test-client',
  get = function() error('Live updates must never call the synchronous API') end,
  get_async = function(id, callback) requests[#requests + 1] = callback end,
}
vim.system = function(_, opts)
  stdout = opts.stdout
  return { kill = function() end }
end
local live = require('notes.live')
live.start()
local function flush()
  local done = false
  vim.schedule(function() done = true end)
  assert(vim.wait(1000, function() return done end))
end
local function event(kind, source)
  stdout(nil, 'data: ' .. vim.json.encode({ id = 105, type = kind or 'note.updated', source_id = source }) .. '\n\n')
  flush()
end
local function note(content)
  return { id = 105, title = 'Test', content = content, updated_at = content }
end
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buf, 'pandora://notes/105')
local function reset()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'original' })
  vim.bo[buf].modified = false
  vim.b[buf].pandora_updated_at = 'v1'
  vim.b[buf].pandora_remote_conflict = false
end
local function content() return vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] end
reset()
event()
assert(content() == 'original', 'The event handler must return before the request completes')
requests[#requests](note('remote'))
assert(content() == 'remote' and not vim.bo[buf].modified)

reset()
event()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'local edit' })
requests[#requests](note('remote'))
assert(content() == 'local edit' and vim.bo[buf].modified)
assert(vim.b[buf].pandora_remote_conflict, 'Edits during a fetch must be retained as a conflict')
local count = #requests
event()
assert(#requests == count, 'Already modified buffers must not start a reload')

reset()
event()
local old = requests[#requests]
event()
local newer = requests[#requests]
newer(note('newest'))
old(note('stale'))
assert(content() == 'newest', 'Out-of-order responses must not roll back content')

for _, kind in ipairs({ 'note.updated', 'note.deleted' }) do
  reset()
  event()
  old = requests[#requests]
  event(kind, kind == 'note.updated' and 'test-client' or nil)
  old(note('stale'))
  assert(content() == 'original', 'Own saves and deletion events must invalidate pending reloads')
end

reset()
event()
vim.b[buf].pandora_updated_at = 'manually-saved-version'
requests[#requests](note('stale'))
assert(content() == 'original', 'A save or manual reload must supersede the pending response')

reset()
event()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'saved local edit' })
vim.bo[buf].modified = false
requests[#requests](note('stale'))
assert(content() == 'saved local edit', 'Changed content must not be replaced even if no longer marked modified')

reset()
event()
requests[#requests](nil, 'offline')
assert(content() == 'original' and not vim.bo[buf].modified)
assert(notifications[#notifications]:match('offline'), 'Fetch failures must be reported')

event()
old = requests[#requests]
live.stop()
old(note('stale'))
assert(content() == 'original', 'Stopping must invalidate pending reloads')

live.start()
-- A diagram with the same ID neither cancels the pending note reload nor reaches the note code.
reset()
event()
local before = #requests
event('diagram.updated')
event('diagram.deleted')
assert(#requests == before, 'Diagram events must not fetch notes')
requests[#requests](note('remote'))
assert(content() == 'remote', 'A diagram event must not cancel a pending note reload')

-- A failing diagram handler does not stop the note events after it.
local diagrams_live = package.loaded['diagrams.live']
package.loaded['diagrams.live'] = { on_event = function() error('boom') end }
reset()
event('diagram.updated')
assert(notifications[#notifications]:match('Diagram update failed'))
event()
requests[#requests](note('after failure'))
assert(content() == 'after failure', 'Note events must still be handled')
package.loaded['diagrams.live'] = diagrams_live

event()
old = requests[#requests]
vim.api.nvim_buf_delete(buf, { force = true })
old(note('stale')) -- must not access a deleted buffer
live.stop()
print('Asynchronous live note update regression checks passed')
vim.cmd('qa!')
