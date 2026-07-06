local M = {}

local HL_GROUP = 'NotesWikiLink'
local ns       = vim.api.nvim_create_namespace('NotesWikiLinks')

local function get_link_under_cursor()
  local line   = vim.api.nvim_get_current_line()
  local col    = vim.api.nvim_win_get_cursor(0)[2] + 1
  local search = 1
  while true do
    local s, e, label = line:find('%[%[([^%]|]+)|?[^%]]*%]%]', search)
    if not s then break end
    if col >= s and col <= e then return label end
    search = e + 1
  end
end

local function apply_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local search = 1
    while true do
      local s, e = line:find('%[%[[^%]]*%]%]', search)
      if not s then break end
      local row = lnum - 1
      -- [[ brackets — gray + underline
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, s - 1, {
        end_col = s + 1, hl_group = 'NotesWikiLinkBracket', priority = 200,
      })
      -- link text — normal color + underline
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, s + 1, {
        end_col = e - 2, hl_group = HL_GROUP, priority = 200,
      })
      -- ]] brackets — gray + underline
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, e - 2, {
        end_col = e, hl_group = 'NotesWikiLinkBracket', priority = 200,
      })
      search = e + 1
    end
  end
end

function M.follow(config)
  local label = get_link_under_cursor()
  if not label then
    vim.notify('No wiki link under cursor', vim.log.levels.WARN)
    return
  end

  local matches = vim.fn.globpath(config.notes_path, '**/' .. label .. '.md', false, true)
  if #matches > 0 then
    vim.cmd('edit ' .. vim.fn.fnameescape(matches[1]))
    return
  end

  vim.ui.select({ 'Yes', 'No' }, { prompt = '"' .. label .. '" not found. Create it?' }, function(choice)
    if choice == 'Yes' then
      local path = config.notes_path .. '/' .. label .. '.md'
      vim.cmd('edit ' .. vim.fn.fnameescape(path))
    end
  end)
end

function M.setup(config)
  vim.api.nvim_set_hl(0, HL_GROUP,                { fg = '#78dce8', underline = true, sp = '#78dce8' })
  vim.api.nvim_set_hl(0, 'NotesWikiLinkBracket', { fg = '#727072' })

  local group = vim.api.nvim_create_augroup('NotesWikiLinks', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertLeave', 'TextChanged' }, {
    group    = group,
    pattern  = '*.md',
    callback = function(ev) apply_highlights(ev.buf) end,
  })

  vim.api.nvim_create_autocmd('FileType', {
    group    = group,
    pattern  = 'markdown',
    callback = function()
      vim.keymap.set('n', '<CR>', function() M.follow(config) end, {
        buffer = true,
        desc   = 'Follow wiki link',
      })
    end,
  })
end

return M
