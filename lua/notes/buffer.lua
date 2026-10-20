local M = {}

local pandora   = require('notes.pandora')
local wikilinks = require('notes.wikilinks')

local function buffer_name(id)
  return 'pandora://note/' .. id
end

local function find_buffer(id)
  local name = buffer_name(id)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == name then return bufnr end
  end
end

-- The first Markdown heading is the title, as Pandora keeps them equal.
local function title_from(content)
  for line in content:gmatch('[^\n]*') do
    local title = line:match('^#%s+(.-)%s*$')
    if title then return title end
  end
end

local function save(bufnr)
  local id      = vim.b[bufnr].pandora_note_id
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
  local fields  = { content = content, title = title_from(content) }
  local note, err = pandora.update(id, fields)
  if not note then
    vim.notify('Pandora save failed: ' .. err, vim.log.levels.ERROR)
    return
  end
  wikilinks.set_title(id, note.title)
  vim.bo[bufnr].modified = false
  vim.notify('Saved "' .. note.title .. '" to Pandora')
end

local function attach(bufnr)
  wikilinks.attach(bufnr)

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer   = bufnr,
    callback = function() save(bufnr) end,
  })

  vim.keymap.set('n', '<CR>', function() M.follow() end, {
    buffer = bufnr,
    desc   = 'Follow wiki link',
  })
end

-- Opens a note in its own buffer, or switches to the buffer already open for it.
function M.open(note)
  local bufnr = find_buffer(note.id)
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(bufnr, buffer_name(note.id))
    vim.bo[bufnr].buftype   = 'acwrite'
    vim.bo[bufnr].swapfile  = false
    vim.bo[bufnr].filetype  = 'markdown'
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(note.content, '\n', { plain = true }))
    vim.bo[bufnr].modified  = false
    vim.b[bufnr].pandora_note_id = note.id
    attach(bufnr)
  end
  vim.api.nvim_set_current_buf(bufnr)
end

function M.open_id(id)
  local note, err = pandora.get(id)
  if not note then
    vim.notify('Could not open note ' .. id .. ': ' .. err, vim.log.levels.ERROR)
    return
  end
  M.open(note)
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

  local matches, err = pandora.search(target, { limit = 20, title_only = true })
  if not matches then
    vim.notify('Pandora search failed: ' .. err, vim.log.levels.ERROR)
    return
  end
  for _, note in ipairs(matches) do
    if note.title:lower() == target:lower() then
      return M.open(note)
    end
  end

  vim.ui.select({ 'Yes', 'No' }, { prompt = '"' .. target .. '" not found. Create it?' }, function(choice)
    if choice == 'Yes' then
      require('notes.create').create_titled(target)
    end
  end)
end

return M
