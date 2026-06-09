return {
  {
    'loctvl842/monokai-pro.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      filter = 'pro',        -- pro | octagon | machine | ristretto | spectrum | classic
      transparent_background = false,
      terminal_colors = true,
      devicons = true,
      styles = {
        comment = { italic = true },
        keyword = { italic = true },
        type = { italic = false },
        storageclass = { italic = false },
        structure = { italic = false },
        parameter = { italic = true },
        annotation = { italic = true },
        tag_attribute = { italic = true },
      },
    },
    config = function(_, opts)
      require('monokai-pro').setup(opts)
      vim.cmd.colorscheme('monokai-pro')
    end,
  },
}
