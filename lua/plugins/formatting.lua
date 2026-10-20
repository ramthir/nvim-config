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
      { '<A-F>',     function() require('conform').format({ async = true }) end, desc = 'Format buffer' },
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
      },
      format_after_save = function(bufnr)
        local filename = vim.api.nvim_buf_get_name(bufnr)
        if filename == '' then return end
        -- Reuse Conform's supported config names and package.json key detection.
        local prettier = require('conform.formatters.prettier')
        if not prettier.cwd(prettier, {
          buf = bufnr,
          filename = filename,
          dirname = vim.fs.dirname(filename),
        }) then return end
        return {}
      end,
    },
  },
}
