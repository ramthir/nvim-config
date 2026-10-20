local map = vim.keymap.set

-- Escape shortcut
map('i', 'jk', '<Esc>')

-- File ops
map('n', '<leader>w', '<cmd>w<CR>')
map('n', '<leader>q', '<cmd>q<CR>')

-- Clear search highlights
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Window navigation
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Resize windows
map('n', '<C-Up>',    '<cmd>resize -2<CR>')
map('n', '<C-Down>',  '<cmd>resize +2<CR>')
map('n', '<C-Left>',  '<cmd>vertical resize -2<CR>')
map('n', '<C-Right>', '<cmd>vertical resize +2<CR>')

-- Move selected lines
map('v', 'J', ":m '>+1<CR>gv=gv")
map('v', 'K', ":m '<-2<CR>gv=gv")

-- Paste without overwriting register
map('x', '<leader>p', '"_dP')

-- Buffer navigation
map('n', '<Tab>',   '<cmd>bnext<CR>')
map('n', '<S-Tab>', '<cmd>bprevious<CR>')
map('n', '<leader>x', '<cmd>bdelete<CR>')

-- Keep cursor centred when jumping
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

-- Terminal toggle
local term_buf = nil
local term_win = nil

function toggle_terminal()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
  elseif term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.cmd('split')
    vim.cmd('wincmd j')
    vim.cmd('resize 15')
    vim.api.nvim_win_set_buf(0, term_buf)
    term_win = vim.api.nvim_get_current_win()
    vim.cmd('startinsert')
  else
    vim.cmd('split | wincmd j | resize 15 | terminal')
    term_buf = vim.api.nvim_get_current_buf()
    term_win = vim.api.nvim_get_current_win()
    vim.cmd('startinsert')
  end
end

map('n', '<leader>t', toggle_terminal, { desc = 'Toggle terminal' })
map('t', '<leader>t', '<C-\\><C-n><cmd>lua toggle_terminal()<CR>', { desc = 'Toggle terminal' })
map('t', '<C-\\><C-n>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
map('t', 'jk', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Notes
map('n', '<leader>nn', '<cmd>NotesCreate<CR>', { desc = 'New note' })

