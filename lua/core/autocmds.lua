local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local general = augroup('General', { clear = true })

local function set_highlights()
  vim.api.nvim_set_hl(0, 'SpellBad',    { undercurl = true, sp = '#ff6188' })
  vim.api.nvim_set_hl(0, 'VirtColumn80',  { fg = '#5a5020' })
  vim.api.nvim_set_hl(0, 'VirtColumn120', { fg = '#5a2020' })
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

-- Flash yanked region
autocmd('TextYankPost', {
  group = general,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 })
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
  end,
})
