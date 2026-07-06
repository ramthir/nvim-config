return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      require('nvim-treesitter').setup({
        ensure_installed = {
          'lua', 'vim', 'vimdoc',
          'python', 'javascript', 'typescript', 'tsx',
          'go', 'rust', 'php', 'bash',
          'html', 'css', 'json', 'yaml', 'markdown', 'markdown_inline',
        },
        auto_install = true,
      })

      -- Neovim 0.10+ native treesitter highlighting
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
