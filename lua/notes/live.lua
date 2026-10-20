local M = {}

local RETRY_MS = 5000

local buffer  = require('notes.buffer')
local pandora = require('notes.pandora')

local function on_event(event)
  if event.source_id == pandora.client_id then return end

  local bufnr = buffer.find(event.id)
  if not bufnr then return end

  if event.type == 'note.updated' then
    if vim.bo[bufnr].modified then
      vim.notify('Note changed on Pandora. Your unsaved edits are kept; saving will overwrite the change.',
        vim.log.levels.WARN)
      return
    end
    local note = pandora.get(event.id)
    if note then buffer.reload(bufnr, note) end
  elseif event.type == 'note.deleted' then
    vim.notify('Note ' .. event.id .. ' was deleted on Pandora.', vim.log.levels.WARN)
  end
end

-- Splits the stream into events. An event ends at a blank line, and any partial
-- event is kept until the rest of it arrives.
local function parser()
  local pending = ''
  return function(chunk)
    pending = pending .. chunk
    local events = {}
    while true do
      local block, rest = pending:match('^(.-)\n\n(.*)$')
      if not block then break end
      pending = rest
      local data = block:match('\ndata: ([^\n]*)') or block:match('^data: ([^\n]*)')
      local ok, event = pcall(vim.json.decode, data or '')
      if ok and type(event) == 'table' then events[#events + 1] = event end
    end
    return events
  end
end

local stream

local function start()
  local base_url = require('notes').config.base_url
  local parse = parser()
  stream = vim.system({ 'curl', '-sN', base_url .. '/api/events' }, {
    stdout = function(_, chunk)
      if not chunk then return end
      for _, event in ipairs(parse(chunk)) do
        vim.schedule(function() on_event(event) end)
      end
    end,
  }, function()
    vim.schedule(function()
      stream = nil
      vim.defer_fn(start, RETRY_MS)
    end)
  end)
end

-- Keeps one connection to Pandora's event stream open, and reconnects if it drops.
function M.start()
  if stream then return end
  start()
end

return M
