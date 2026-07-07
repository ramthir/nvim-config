return {
  {
    'stevearc/conform.nvim',
    dependencies = {
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        opts = { ensure_installed = { 'prettier' } },
      },
    },
    event = 'BufWritePre',
    keys = {
      { '<leader>f', function() require('conform').format({ async = true }) end, desc = 'Format buffer' },
    },
    opts = {
      formatters_by_ft = {
        javascript      = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript      = { 'prettier' },
        typescriptreact = { 'prettier' },
        html            = { 'prettier' },
        css             = { 'prettier' },
        scss            = { 'prettier' },
        json            = { 'prettier' },
        yaml            = { 'prettier' },
        markdown        = { 'prettier' },
      },
      format_after_save = function(bufnr)
        local prettier_configs = {
          '.prettierrc', '.prettierrc.json', '.prettierrc.js',
          '.prettierrc.cjs', '.prettierrc.ts', '.prettierrc.yaml',
          '.prettierrc.yml', '.prettierrc.toml',
          'prettier.config.js', 'prettier.config.cjs', 'prettier.config.ts',
        }
        if not vim.fs.root(bufnr, prettier_configs) then return end
        return {}
      end,
    },
  },
}
