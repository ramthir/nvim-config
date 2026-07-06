local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local general = augroup('General', { clear = true })

local function set_highlights()
  vim.api.nvim_set_hl(0, 'SpellBad',      { undercurl = true, sp = '#ff6188' })
  vim.api.nvim_set_hl(0, 'ColorColumn',   { bg = '#3a3631' })
  vim.api.nvim_set_hl(0, 'NotesWikiLink',        { fg = '#78dce8', underline = true, sp = '#78dce8' })
  vim.api.nvim_set_hl(0, 'NotesWikiLinkBracket', { fg = '#727072' })

  -- Remove code block background
  vim.api.nvim_set_hl(0, '@markup.raw.block',                { bg = 'NONE' })
  vim.api.nvim_set_hl(0, '@markup.raw.block.markdown',       { bg = 'NONE' })
  vim.api.nvim_set_hl(0, '@markup.raw.delimiter.markdown',   { bg = 'NONE', fg = '#727072' })
  vim.api.nvim_set_hl(0, '@text.literal.block.markdown',     { bg = 'NONE' })

  -- Table headers yellow
  vim.api.nvim_set_hl(0, '@markup.heading.markdown', { fg = '#ffd866', bold = true })

  -- Bold text yellow, ** delimiters gray
  vim.api.nvim_set_hl(0, '@markup.strong.markdown_inline',           { fg = '#ffd866', bold = true })
  vim.api.nvim_set_hl(0, '@markup.strong.delimiter.markdown_inline', { fg = '#5b595c' })

  -- Italic text purple, * or _ delimiters gray
  vim.api.nvim_set_hl(0, '@markup.italic.markdown_inline',           { fg = '#ab9df2', italic = true })
  vim.api.nvim_set_hl(0, '@markup.italic.delimiter.markdown_inline', { fg = '#5b595c' })

  -- Monokai Pro orange for markdown heading markers and list markers
  local orange = '#fc9867'
  for i = 1, 6 do
    vim.api.nvim_set_hl(0, '@markup.heading.' .. i .. '.marker.markdown', { fg = orange, bold = true })
  end
  vim.api.nvim_set_hl(0, '@markup.list.markdown', { fg = orange })
end
autocmd('ColorScheme', { group = general, callback = set_highlights })
set_highlights()


-- Auto-save on leaving insert mode, losing focus, or normal-mode text change
autocmd({ 'InsertLeave', 'FocusLost', 'TextChanged' }, {
  group = general,
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].modified
      and vim.bo[buf].buftype == ''
      and vim.api.nvim_buf_get_name(buf) ~= ''
    then
      vim.cmd('silent! write')
    end
  end,
})

-- Restore last cursor position
autocmd('BufReadPost', {
  group = general,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Flash yanked region and sync to tmux clipboard
autocmd('TextYankPost', {
  group = general,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 })
    if vim.v.event.operator == 'y' then
      local text = vim.fn.getreg('"')
      local encoded = vim.fn.system('base64 | tr -d "\n"', text)
      if vim.env.TMUX then
        io.write('\027Ptmux;\027\027]52;c;' .. encoded .. '\007\027\\')
      else
        io.write('\027]52;c;' .. encoded .. '\007')
      end
      io.flush()
    end
  end,
})

-- Remove trailing whitespace on save
autocmd('BufWritePre', {
  group = general,
  callback = function()
    local pos = vim.fn.getpos('.')
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos('.', pos)
  end,
})

-- Equalise splits on resize
autocmd('VimResized', {
  group = general,
  command = 'tabdo wincmd =',
})

-- Filetype indentation overrides
local ft = augroup('FiletypeIndent', { clear = true })

autocmd('FileType', {
  group = ft,
  pattern = { 'lua', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'html', 'css', 'json', 'yaml' },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

autocmd('FileType', {
  group = ft,
  pattern = 'go',
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

autocmd('FileType', {
  group = general,
  pattern = 'markdown',
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 120
    vim.schedule(function()
      vim.opt_local.formatoptions:append('aw')
    end)
  end,
})
