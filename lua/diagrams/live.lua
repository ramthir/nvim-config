local M = {}

local buffer = require('diagrams.buffer')
local api    = require('diagrams.api')

local pending = {}

local function mark_conflict(bufnr)
  vim.b[bufnr].pandora_remote_conflict = true
  vim.notify('Diagram changed on Pandora. Your unsaved edits are kept; use :edit! to reload or :write! to overwrite.',
    vim.log.levels.WARN)
end

-- Every update is checked against the version the buffer holds, so the event for this
-- Neovim's own save (which carries no client ID) is recognised and ignored.
local function refresh(id, bufnr)
  local request = {}
  pending[id] = request
  local baseline = vim.b[bufnr].pandora_updated_at
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  api.get_async(id, function(diagram, err)
    if pending[id] ~= request then return end
    pending[id] = nil
    if not vim.api.nvim_buf_is_loaded(bufnr) or buffer.find(id) ~= bufnr then return end
    -- A save or manual reload while fetching makes this response obsolete.
    if vim.b[bufnr].pandora_updated_at ~= baseline then return end
    if not diagram then
      vim.notify('Could not refresh diagram ' .. id .. ': ' .. (err or 'request failed'), vim.log.levels.WARN)
      return
    end
    if diagram.updated_at == baseline then return end
    if vim.bo[bufnr].modified then
      mark_conflict(bufnr)
      return
    end
    if vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then return end
    buffer.reload(bufnr, diagram)
  end)
end

function M.on_event(event)
  local bufnr = buffer.find(event.id)
  if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then return end
  if event.type == 'diagram.updated' then
    refresh(event.id, bufnr)
  elseif event.type == 'diagram.deleted' then
    pending[event.id] = nil
    vim.notify('Diagram ' .. event.id .. ' was deleted on Pandora.', vim.log.levels.WARN)
  end
end

-- After the event stream (re)connects, changes made while it was down are found by
-- checking every open diagram.
function M.reconcile()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local id = tonumber(vim.api.nvim_buf_get_name(bufnr):match('^pandora://diagrams/(%d+)$'))
      if id then refresh(id, bufnr) end
    end
  end
end

function M.reset()
  pending = {}
end

return M
