local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
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
opt.showmode = false

-- Files
opt.backup = false
opt.swapfile = false
opt.undofile = true

-- Behaviour
opt.timeoutlen = 300
opt.updatetime = 250
opt.clipboard = 'unnamedplus'
opt.splitright = true
opt.splitbelow = true
opt.mouse = 'a'
opt.completeopt = 'menuone,noselect'
