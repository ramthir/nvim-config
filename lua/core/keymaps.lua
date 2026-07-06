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

-- Notes
map('n', '<C-n>',      '<cmd>NotesSearch<CR>', { desc = 'Find notes' })
map('n', '<leader>ng', '<cmd>NotesGrep<CR>',   { desc = 'Grep notes' })
map('n', '<leader>nn', '<cmd>NotesCreate<CR>', { desc = 'New note' })

