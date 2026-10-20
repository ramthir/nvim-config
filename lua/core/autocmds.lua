local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local general = augroup('General', { clear = true })

local function set_highlights()
  vim.api.nvim_set_hl(0, 'SpellBad',      { undercurl = true, sp = '#ff6188' })
  vim.api.nvim_set_hl(0, 'ColorColumn',   { bg = '#3a3631' })
  vim.api.nvim_set_hl(0, 'NotesWikiLink', { fg = '#78dce8', underline = true, sp = '#78dce8' })

  -- Remove code block background
  vim.api.nvim_set_hl(0, '@markup.raw.block',                { bg = 'NONE' })
  vim.api.nvim_set_hl(0, '@markup.raw.block.markdown',       { bg = 'NONE' })
  vim.api.nvim_set_hl(0, '@markup.raw.delimiter.markdown',   { bg = 'NONE', fg = '#727072' })
  vim.api.nvim_set_hl(0, '@text.literal.block.markdown',     { bg = 'NONE' })

  -- Table headers yellow
  vim.api.nvim_set_hl(0, '@markup.heading.markdown', { fg = '#ffd866', bold = true })

  -- Markdown buffers use the legacy :syntax engine, not treesitter (see
  -- plugins/treesitter.lua), so the @markup.* groups below don't apply to
  -- them. markdownH1 already renders yellow via its default link to Title;
  -- markdownBold links to htmlBold, which has no color, so set it to match.
  vim.api.nvim_set_hl(0, 'markdownBold', { fg = '#ffd866', bold = true })
  vim.api.nvim_set_hl(0, 'markdownBoldDelimiter', { fg = '#5b595c' })

  -- Inline code green, backtick delimiters gray (markdownCode has no
  -- default link, so it's unstyled otherwise)
  vim.api.nvim_set_hl(0, 'markdownCode', { fg = '#a9dc76', bg = '#403e41' })
  vim.api.nvim_set_hl(0, 'markdownCodeDelimiter', { fg = '#5b595c', bg = '#403e41' })

  -- List markers (-, *, +, 1.) red (markdownOrderedListMarker links to
  -- markdownListMarker, which otherwise links to htmlTagName)
  vim.api.nvim_set_hl(0, 'markdownListMarker', { fg = '#ff6188' })

  -- Table pipes and separator rows gray (see after/syntax/markdown.vim;
  -- core markdown.vim has no table support to hook a default link onto)
  vim.api.nvim_set_hl(0, 'markdownTableDelimiter', { fg = '#5b595c' })

  -- Table header row text yellow, matching headings
  vim.api.nvim_set_hl(0, 'markdownTableHeader', { fg = '#ffd866', bold = true })

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


-- Return to normal mode on focus lost
autocmd('FocusLost', {
  group = general,
  callback = function()
    local mode = vim.fn.mode()
    if mode == 'i' or mode == 'v' or mode == 'V' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
    end
  end,
})

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

-- Markdown whitespace can carry meaning (hard breaks and fenced code).
-- Keep it intact, while retaining the Markdown "Kr," sign-off hard break.
autocmd('BufWritePre', {
  group = general,
  callback = function()
    local pos = vim.fn.getpos('.')
    if vim.bo.filetype == 'markdown' then
      vim.cmd([[%s/^Kr,\s*$/Kr,  /e]])
    else
      vim.cmd([[%s/\s\+$//e]])
    end
    vim.fn.setpos('.', pos)
  end,
})

-- Equalise splits on resize
autocmd('VimResized', {
  group = general,
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('tabdo wincmd =')
    if vim.api.nvim_tabpage_is_valid(tab) then
      vim.api.nvim_set_current_tabpage(tab)
    end
  end,
})

-- Auto-reload files changed outside Neovim
autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  group = general,
  callback = function()
    if vim.fn.getcmdwintype() == '' then
      vim.cmd('checktime')
    end
  end,
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
    vim.opt_local.textwidth = 0
    vim.schedule(function()
      vim.opt_local.formatoptions:remove({ 't', 'a', 'w' })
    end)
  end,
})
