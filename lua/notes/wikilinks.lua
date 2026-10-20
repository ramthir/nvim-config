local M = {}

local HL_GROUP = 'NotesWikiLink'
local ns       = vim.api.nvim_create_namespace('NotesWikiLinks')

-- Titles looked up from Pandora, keyed by note ID. Uncached titles are fetched in the
-- background so redraws and edits never block on network calls. A failed lookup is
-- remembered for a while, so a missing note or a server that is down is not retried
-- on every redraw.
local MISS_TTL_MS = 30000
local titles   = {}
local misses   = {}
local inflight = {}

local function parse(inner)
  local target, label = inner:match('^(.-)|(.*)$')
  return target or inner, label
end

local apply_highlights

local function note_buffers()
  local bufs = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr):match('^pandora://notes/%d+$') then
      bufs[#bufs + 1] = bufnr
    end
  end
  return bufs
end

local function title_for(id)
  if titles[id] then return titles[id] end
  if misses[id] and vim.uv.now() - misses[id] < MISS_TTL_MS then return nil end
  if inflight[id] then return nil end
  inflight[id] = true
  require('notes.pandora').get_async(id, function(note)
    inflight[id] = nil
    if not note then
      misses[id] = vim.uv.now()
      return
    end
    misses[id] = nil
    titles[id] = note.title
    M.refresh_all()
  end)
  return nil
end

function M.set_title(id, title)
  titles[id]   = title
  misses[id]   = nil
  inflight[id] = nil
end

function M.invalidate(id)
  titles[id]   = nil
  misses[id]   = nil
  inflight[id] = nil
end

function M.refresh(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
    apply_highlights(bufnr)
  end
end

function M.refresh_all()
  for _, bufnr in ipairs(note_buffers()) do
    apply_highlights(bufnr)
  end
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
apply_highlights = function(bufnr)
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
        end_col       = e,
        conceal       = '',
        virt_text     = { { text, HL_GROUP } },
        virt_text_pos = 'inline',
        priority      = 200,
      })
      search = e + 1
    end
  end
end

function M.attach(bufnr)
  local group = vim.api.nvim_create_augroup('NotesWikiLinks' .. bufnr, { clear = true })

  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.wo[win].conceallevel = 2
  end
  apply_highlights(bufnr)

  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertLeave', 'TextChanged' }, {
    group    = group,
    buffer   = bufnr,
    callback = function(ev)
      for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
        vim.wo[win].conceallevel = 2
      end
      apply_highlights(ev.buf)
    end,
  })
end

return M
