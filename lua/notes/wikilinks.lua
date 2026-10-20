local M = {}

local HL_GROUP = 'NotesWikiLink'
local ns       = vim.api.nvim_create_namespace('NotesWikiLinks')

-- Titles looked up from Pandora, keyed by note ID. Only successful lookups are kept,
-- so a server that is down is retried on the next redraw.
local titles = {}

local function parse(inner)
  local target, label = inner:match('^(.-)|(.*)$')
  return target or inner, label
end

local function title_for(id)
  if titles[id] == nil then
    local note = require('notes.pandora').get(id)
    if not note then return nil end
    titles[id] = note.title
  end
  return titles[id]
end

function M.set_title(id, title)
  titles[id] = title
end

function M.link_under_cursor()
  local line   = vim.api.nvim_get_current_line()
  local col    = vim.api.nvim_win_get_cursor(0)[2] + 1
  local search = 1
  while true do
    local s, e, inner = line:find('%[%[([^%]]+)%]%]', search)
    if not s then break end
    if col >= s and col <= e then return (parse(inner)) end
    search = e + 1
  end
end

-- Hides each [[link]] and draws its text in its place: the label when given,
-- otherwise the target's title. Links are not rewritten, so saving keeps the IDs.
local function apply_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local search = 1
    while true do
      local s, e, inner = line:find('%[%[([^%]]+)%]%]', search)
      if not s then break end
      local target, label = parse(inner)
      local id   = tonumber(target:match('^%d+$'))
      local text = label or (id and title_for(id)) or target
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, s - 1, {
        end_col      = e,
        conceal      = '',
        virt_text    = { { text, HL_GROUP } },
        virt_text_pos = 'inline',
        priority     = 200,
      })
      search = e + 1
    end
  end
end

function M.attach(bufnr)
  local group = vim.api.nvim_create_augroup('NotesWikiLinks' .. bufnr, { clear = true })

  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertLeave', 'TextChanged' }, {
    group    = group,
    buffer   = bufnr,
    callback = function(ev)
      vim.wo.conceallevel = 2
      apply_highlights(ev.buf)
    end,
  })
end

return M
