local M = {}

local RETRY_MS = 5000

local buffer    = require('notes.buffer')
local pandora   = require('notes.pandora')
local wikilinks = require('notes.wikilinks')

local pending = {}

local function mark_conflict(bufnr)
  vim.b[bufnr].pandora_remote_conflict = true
  vim.notify('Note changed on Pandora. Your unsaved edits are kept; use :edit! to reload or :write! to overwrite.',
    vim.log.levels.WARN)
end

-- Reconciliation also checks modified buffers, but only flags actual remote changes.
local function refresh_note(id, bufnr, reconcile)
  local request = {}
  pending[id] = request
  local baseline = vim.b[bufnr].pandora_updated_at
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  pandora.get_async(id, function(note, err)
    if pending[id] ~= request then return end
    pending[id] = nil
    if not vim.api.nvim_buf_is_loaded(bufnr) or buffer.find(id) ~= bufnr then return end
    -- A save or manual reload while fetching makes this response obsolete.
    if vim.b[bufnr].pandora_updated_at ~= baseline then return end
    if reconcile and note and note.updated_at == baseline then return end
    if vim.bo[bufnr].modified then
      if note or not reconcile then mark_conflict(bufnr) end
      return
    end
    if vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then return end
    if not note then
      vim.notify('Could not refresh note ' .. id .. ': ' .. (err or 'request failed'), vim.log.levels.WARN)
      return
    end
    buffer.reload(bufnr, note)
    wikilinks.refresh_all()
  end)
end

local function reconcile_notes()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local id = tonumber(vim.api.nvim_buf_get_name(bufnr):match('^pandora://notes/(%d+)$'))
      if id then
        wikilinks.invalidate(id)
        refresh_note(id, bufnr, true)
      end
    end
  end
  wikilinks.refresh_all()
end

local function on_event(event)
  -- Any newer event supersedes a pending reload, including our own saves/deletions.
  pending[event.id] = nil
  if event.source_id == pandora.client_id then return end

  local bufnr = buffer.find(event.id)

  if event.type == 'note.updated' then
    wikilinks.invalidate(event.id)
    if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
      if vim.bo[bufnr].modified then
        mark_conflict(bufnr)
      else
        refresh_note(event.id, bufnr, false)
      end
    end
    wikilinks.refresh_all()
  elseif event.type == 'note.deleted' then
    wikilinks.invalidate(event.id)
    wikilinks.refresh_all()
    if bufnr then
      vim.notify('Note ' .. event.id .. ' was deleted on Pandora.', vim.log.levels.WARN)
    end
  end
end

-- Splits the stream into events. An event ends at a blank line, and any partial
-- event is kept until the rest of it arrives.
local function parser()
  local pending = ''
  return function(chunk)
    -- Normalize after combining chunks so a split CRLF pair stays intact.
    pending = (pending .. chunk):gsub('\r\n', '\n')
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
local stopping = false
local connection

local function start()
  if stopping then return end
  local base_url = require('notes').config.base_url
  local parse = parser()
  local current = {}
  connection = current
  local reconciled = false
  stream = vim.system({ 'curl', '-sN', base_url .. '/api/events' }, {
    stdout = function(_, chunk)
      if not chunk then return end
      local events = parse(chunk)
      vim.schedule(function()
        if stopping or connection ~= current then return end
        -- The first stream data (including a heartbeat) confirms the connection.
        if not reconciled then
          reconciled = true
          reconcile_notes()
        end
        for _, event in ipairs(events) do on_event(event) end
      end)
    end,
  }, function()
    vim.schedule(function()
      if connection ~= current then return end
      connection = nil
      pending = {}
      stream = nil
      if not stopping then
        vim.defer_fn(function()
          if not stopping and not connection then start() end
        end, RETRY_MS)
      end
    end)
  end)
end

function M.stop()
  stopping = true
  connection = nil
  pending = {}
  if stream then
    pcall(function() stream:kill('sigterm') end)
    stream = nil
  end
end

-- Keeps one connection to Pandora's event stream open, and reconnects if it drops.
function M.start()
  if stream then return end
  stopping = false
  local group = vim.api.nvim_create_augroup('NotesLiveStream', { clear = true })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group    = group,
    callback = function() M.stop() end,
  })
  start()
end

return M
