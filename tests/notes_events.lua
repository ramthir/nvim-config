-- Run: nvim --headless -u NONE -i NONE -l tests/notes_events.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local stdout
local handled = {}
package.loaded['notes'] = { config = { base_url = 'http://mock' } }
package.loaded['notes.buffer'] = { find = function() return nil end }
package.loaded['notes.pandora'] = { client_id = 'local' }
package.loaded['notes.wikilinks'] = {
  invalidate = function(id) handled[#handled + 1] = id end,
  refresh_all = function() end,
}
vim.system = function(_, opts)
  stdout = opts.stdout
  return { kill = function() end }
end
local live = require('notes.live')
local function flush()
  local done = false
  vim.schedule(function() done = true end)
  assert(vim.wait(1000, function() return done end))
end
local function frame(id, newline)
  return 'event: note.updated' .. newline .. 'data: '
    .. vim.json.encode({ id = id, type = 'note.updated' }) .. newline .. newline
end
local function check(chunks, expected)
  handled = {}
  live.start()
  for _, chunk in ipairs(chunks) do stdout(nil, chunk) end
  flush()
  assert(vim.deep_equal(handled, expected), vim.inspect({ expected = expected, actual = handled }))
  live.stop()
end
check({ frame(105, '\n') }, { 105 })
local crlf = frame(105, '\r\n')
check({ crlf }, { 105 })
for split = 1, #crlf - 1 do
  check({ crlf:sub(1, split), crlf:sub(split + 1) }, { 105 })
end
local mixed = ': heartbeat\r\n\r\n' .. frame(105, '\r\n') .. frame(106, '\n')
local bytes = {}
for i = 1, #mixed do bytes[#bytes + 1] = mixed:sub(i, i) end
check(bytes, { 105, 106 })
check({ frame(105, '\r\n') .. 'data: {"id":' }, { 105 })
print('LF/CRLF stream parsing regression checks passed')
vim.cmd('qa!')
