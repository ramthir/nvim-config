local M = {}

local api = require('diagrams.api')

local PATTERN = 'pandora://diagrams/*'

local function buffer_name(id)
  return 'pandora://diagrams/' .. id
end

-- Only digits are accepted, so nothing else from a typed path reaches a request.
local function diagram_id(name)
  return tonumber(name:match('^pandora://diagrams/(%d+)$'))
end

local function find_buffer(id)
  local name = buffer_name(id)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == name then return bufnr end
  end
end

M.find = find_buffer

-- Replaces a buffer's lines with a diagram's content, keeping the cursor where it was.
function M.reload(bufnr, diagram)
  local win    = vim.fn.bufwinid(bufnr)
  local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win) or nil
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(diagram.content, '\n', { plain = true }))
  vim.bo[bufnr].modified = false
  vim.b[bufnr].pandora_updated_at = diagram.updated_at
  vim.b[bufnr].pandora_remote_conflict = false
  if cursor then
    local row = math.min(cursor[1], vim.api.nvim_buf_line_count(bufnr))
    pcall(vim.api.nvim_win_set_cursor, win, { row, cursor[2] })
  end
end

-- :edit pandora://diagrams/123 and :edit! land here. The buffer is set up for saving
-- first, so a diagram that fails to load is never written to a file by mistake.
local function read(bufnr)
  vim.bo[bufnr].buftype  = 'acwrite'
  vim.bo[bufnr].swapfile = false
  -- A failed reload must not leave a previous version usable for saving.
  vim.b[bufnr].pandora_updated_at = nil

  local name = vim.api.nvim_buf_get_name(bufnr)
  local id   = diagram_id(name)
  if not id then
    vim.notify('Not a Pandora diagram path: ' .. name .. ' (use pandora://diagrams/<id>)', vim.log.levels.ERROR)
    return
  end

  local diagram, err = api.get(id)
  if not diagram then
    vim.notify('Could not open diagram ' .. id .. ': ' .. err, vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(diagram.content, '\n', { plain = true }))
  vim.bo[bufnr].modified = false
  vim.b[bufnr].pandora_updated_at = diagram.updated_at
  vim.b[bufnr].pandora_remote_conflict = false
  vim.bo[bufnr].filetype = 'plantuml'
end

local function save(bufnr, force)
  local id = diagram_id(vim.api.nvim_buf_get_name(bufnr))
  if not id then
    vim.notify('Not a Pandora diagram path; nothing saved.', vim.log.levels.ERROR)
    return
  end

  local baseline = vim.b[bufnr].pandora_updated_at
  if not force then
    if not baseline then
      vim.notify('Diagram has not loaded successfully; use :edit! to reload before saving.', vim.log.levels.ERROR)
      return
    end
    if vim.b[bufnr].pandora_remote_conflict then
      vim.notify('Diagram changed on Pandora; use :edit! to reload or :write! to overwrite.', vim.log.levels.ERROR)
      return
    end
    local remote, get_err = api.get(id)
    if not remote then
      vim.notify('Pandora save failed: ' .. get_err, vim.log.levels.ERROR)
      return
    end
    if remote.updated_at ~= baseline then
      vim.b[bufnr].pandora_remote_conflict = true
      vim.notify('Diagram changed on Pandora; use :edit! to reload or :write! to overwrite.', vim.log.levels.ERROR)
      return
    end
  end

  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
  local diagram, err = api.update(id, { content = content })
  if not diagram then
    vim.notify('Pandora save failed: ' .. err, vim.log.levels.ERROR)
    return
  end
  if diagram.content ~= content then
    M.reload(bufnr, diagram)
  else
    vim.b[bufnr].pandora_updated_at = diagram.updated_at
    vim.b[bufnr].pandora_remote_conflict = false
    vim.bo[bufnr].modified = false
  end
  vim.notify('Saved "' .. diagram.title .. '" to Pandora')
end

-- Makes pandora://diagrams/<id> a path Neovim can read and write.
function M.setup()
  local group = vim.api.nvim_create_augroup('DiagramsBuffers', { clear = true })

  vim.api.nvim_create_autocmd('BufReadCmd', {
    group    = group,
    pattern  = PATTERN,
    callback = function(ev) read(ev.buf) end,
  })

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    group    = group,
    pattern  = PATTERN,
    callback = function(ev) save(ev.buf, vim.v.cmdbang == 1) end,
  })
end

function M.open_id(id)
  vim.cmd.edit(buffer_name(id))
end

-- :Diagram <id> opens that diagram. With no ID it opens the number under the cursor, or asks
-- for one. Only digits are accepted, as for the full path.
function M.open_from(arg)
  local function open(text)
    text = vim.trim(text or '')
    if text == '' then return end
    if not text:match('^%d+$') then
      vim.notify('Diagram ID must be a number: ' .. text, vim.log.levels.ERROR)
      return
    end
    M.open_id(tonumber(text))
  end

  if vim.trim(arg or '') ~= '' then
    return open(arg)
  end

  -- expand() raises an error when there is no word under the cursor, for example on an empty line
  local found, word = pcall(vim.fn.expand, '<cword>')
  if found and word:match('^%d+$') then
    return open(word)
  end
  vim.ui.input({ prompt = 'Diagram ID: ' }, open)
end

return M
