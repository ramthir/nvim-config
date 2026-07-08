return {
  {
    'stevearc/aerial.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      { '<leader>a', '<cmd>Telescope aerial<CR>', desc = 'Document outline' },
    },
    config = function()
      require('aerial').setup({
        backends = { 'treesitter', 'lsp' },
        layout = { min_width = 30 },
        show_guides = true,
      })
      require('telescope').load_extension('aerial')
    end,
  },
}
