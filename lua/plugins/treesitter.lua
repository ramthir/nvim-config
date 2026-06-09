return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' }, -- load once a file is open
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'lua', 'vim', 'vimdoc',
          'python', 'javascript', 'typescript', 'tsx',
          'go', 'rust', 'json', 'yaml', 'markdown', 'markdown_inline',
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
