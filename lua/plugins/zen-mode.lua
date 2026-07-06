return {
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    keys = {
      { '<leader>z', '<cmd>ZenMode<CR>', desc = 'Toggle Zen Mode' },
    },
    opts = {
      window = {
        width = 120,
        options = {
          wrap       = true,
          linebreak  = true,
          breakindent = true,
        },
      },
      plugins = {
        options = {
          laststatus = 0,
        },
      },
    },
  },
}
