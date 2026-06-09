return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    -- Load only when a telescope command is triggered
    cmd = 'Telescope',
    keys = {
      { '<C-p>',      '<cmd>Telescope find_files<CR>',  desc = 'Find files' },
      { '<C-f>',      '<cmd>Telescope live_grep<CR>',   desc = 'Live grep' },
      { '<leader>ff', '<cmd>Telescope find_files<CR>',  desc = 'Find files' },
      { '<leader>fg', '<cmd>Telescope live_grep<CR>',   desc = 'Live grep' },
      { '<leader>fb', '<cmd>Telescope buffers<CR>',     desc = 'Buffers' },
      { '<leader>fh', '<cmd>Telescope help_tags<CR>',   desc = 'Help tags' },
      { '<leader>fr', '<cmd>Telescope oldfiles<CR>',    desc = 'Recent files' },
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          sorting_strategy = 'ascending',
          layout_config = { prompt_position = 'top' },
          file_ignore_patterns = { 'node_modules', '.git/' },
          preview = {
            treesitter = false, -- nvim-treesitter v1.x removed the API telescope uses
          },
        },
        pickers = {
          find_files = { hidden = true },
        },
      })
      pcall(telescope.load_extension, 'fzf')
    end,
  },
}
