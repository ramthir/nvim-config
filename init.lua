-- ~/.config/nvim/init.lua
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('core.options')
require('core.keymaps')
require('core.autocmds')

require('lazy').setup('plugins', {
  defaults = {
    lazy = true,   -- lazy load everything unless a plugin opts out
  },
  install = {
    colorscheme = { 'monokai-pro', 'habamax' },
  },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
})
