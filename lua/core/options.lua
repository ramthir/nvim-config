local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = false
opt.signcolumn = 'yes'

-- Indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.colorcolumn = '80,120'
opt.showmode = false

-- Files
opt.backup = false
opt.swapfile = false
opt.undofile = true

-- Behaviour
opt.timeoutlen = 300
opt.updatetime = 250
opt.splitright = true
opt.splitbelow = true
opt.mouse = 'a'
opt.completeopt = 'menuone,noselect'
