return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,    -- must load at startup so the UI isn't unstyled
    priority = 1000, -- load before all other plugins
    opts = {
      flavour = 'mocha',
      integrations = {
        telescope = true,
        nvim_tree = true,
        treesitter = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.cmd.colorscheme('catppuccin')
    end,
  },
}
