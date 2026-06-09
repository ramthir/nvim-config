return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      -- v1.x API: no more require('nvim-treesitter.configs').setup()
      require('nvim-treesitter').setup({
        ensure_installed = {
          'lua', 'vim', 'vimdoc',
          'python', 'javascript', 'typescript', 'tsx',
          'go', 'rust', 'json', 'yaml', 'markdown', 'markdown_inline',
        },
        auto_install = true,
      })
    end,
  },
}
