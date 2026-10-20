local M = {}

local pandora   = require('notes.pandora')
local wikilinks = require('notes.wikilinks')

local PATTERN = 'pandora://notes/*'

local function buffer_name(id)
  return 'pandora://notes/' .. id
end

-- Only digits are accepted, so nothing else from a typed path reaches a request.
local function note_id(name)
  return tonumber(name:match('^pandora://notes/(%d+)$'))
end

local function find_buffer(id)
  local name = buffer_name(id)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == name then return bufnr end
  end
end

M.find = find_buffer

-- Replaces a buffer's lines with a note's content, keeping the cursor where it was.
function M.reload(bufnr, note)
  local win    = vim.fn.bufwinid(bufnr)
  local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win) or nil
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(note.content, '\n', { plain = true }))
  vim.bo[bufnr].modified = false
  wikilinks.set_title(note.id, note.title)
  wikilinks.refresh(bufnr)
  if cursor then
    local row = math.min(cursor[1], vim.api.nvim_buf_line_count(bufnr))
    pcall(vim.api.nvim_win_set_cursor, win, { row, cursor[2] })
  end
end

-- The first Markdown heading outside a fenced code block is the title, as Pandora keeps them equal.
local function title_from(content)
  local in_fence = false
  for line in content:gmatch('[^\n]*') do
    if line:match('^```') then
      in_fence = not in_fence
    elseif not in_fence then
      local title = line:match('^#%s+(.-)%s*$')
      if title then return title end
    end
  end
end

-- :edit pandora://notes/123 and :edit! land here. The buffer is set up for saving
-- first, so a note that fails to load is never written to a file by mistake.
local function read(bufnr)
  vim.bo[bufnr].buftype  = 'acwrite'
  vim.bo[bufnr].swapfile = false

  local name = vim.api.nvim_buf_get_name(bufnr)
  local id   = note_id(name)
  if not id then
    vim.notify('Not a Pandora note path: ' .. name .. ' (use pandora://notes/<id>)', vim.log.levels.ERROR)
    return
  end

  local note, err = pandora.get(id)
  if not note then
    vim.notify('Could not open note ' .. id .. ': ' .. err, vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(note.content, '\n', { plain = true }))
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].filetype = 'markdown'
  wikilinks.set_title(id, note.title)
  wikilinks.attach(bufnr)

  vim.keymap.set('n', '<CR>', function() M.follow() end, {
    buffer = bufnr,
    desc   = 'Follow wiki link',
  })
end

local function save(bufnr)
  local id = note_id(vim.api.nvim_buf_get_name(bufnr))
  if not id then
    vim.notify('Not a Pandora note path; nothing saved.', vim.log.levels.ERROR)
    return
  end
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
  local fields  = { content = content, title = title_from(content) }
  local note, err = pandora.update(id, fields)
  if not note then
    vim.notify('Pandora save failed: ' .. err, vim.log.levels.ERROR)
    return
  end
  if note.content ~= content then
    M.reload(bufnr, note)
  else
    wikilinks.set_title(id, note.title)
    vim.bo[bufnr].modified = false
  end
  wikilinks.refresh_all()
  vim.notify('Saved "' .. note.title .. '" to Pandora')
end

-- Makes pandora://notes/<id> a path Neovim can read and write.
function M.setup()
  local group = vim.api.nvim_create_augroup('NotesBuffers', { clear = true })

  vim.api.nvim_create_autocmd('BufReadCmd', {
    group    = group,
    pattern  = PATTERN,
    callback = function(ev) read(ev.buf) end,
  })

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    group    = group,
    pattern  = PATTERN,
    callback = function(ev) save(ev.buf) end,
  })
end

function M.open_id(id)
  vim.cmd.edit(buffer_name(id))
end

-- :Note <id> opens that note. With no ID it opens the number under the cursor, or asks
-- for one. Only digits are accepted, as for the full path.
function M.open_from(arg)
  local function open(text)
    text = vim.trim(text or '')
    if text == '' then return end
    if not text:match('^%d+$') then
      vim.notify('Note ID must be a number: ' .. text, vim.log.levels.ERROR)
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
  vim.ui.input({ prompt = 'Note ID: ' }, open)
end

function M.follow()
  local target = wikilinks.link_under_cursor()
  if not target then
    vim.notify('No wiki link under cursor', vim.log.levels.WARN)
    return
  end

  if target:match('^%d+$') then
    return M.open_id(tonumber(target))
  end

  local matches, err = pandora.search(target, { limit = 200, title_only = true })
  if not matches then
    vim.notify('Pandora search failed: ' .. err, vim.log.levels.ERROR)
    return
  end
  for _, note in ipairs(matches) do
    if note.title:lower() == target:lower() then
      return M.open_id(note.id)
    end
  end

  vim.ui.select({ 'Yes', 'No' }, { prompt = '"' .. target .. '" not found. Create it?' }, function(choice)
    if choice == 'Yes' then
      require('notes.create').create_titled(target)
    end
  end)
end

return M
