return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('mason').setup()

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      pcall(function()
        capabilities = require('cmp_nvim_lsp').default_capabilities()
      end)

      local on_attach = function(_, bufnr)
        local map = function(keys, cmd, desc)
          vim.keymap.set('n', keys, cmd, { buffer = bufnr, desc = desc })
        end
        map('gd',         vim.lsp.buf.definition,    'Go to definition')
        map('gD',         vim.lsp.buf.declaration,   'Go to declaration')
        map('gi',         vim.lsp.buf.implementation,'Go to implementation')
        map('gr',         vim.lsp.buf.references,    'References')
        map('K',          vim.lsp.buf.hover,         'Hover docs')
        map('<leader>rn', vim.lsp.buf.rename,        'Rename')
        map('<leader>ca', vim.lsp.buf.code_action,   'Code action')
        map('<leader>d',  vim.diagnostic.open_float, 'Diagnostic float')
        map('[d',         vim.diagnostic.goto_prev,  'Prev diagnostic')
        map(']d',         vim.diagnostic.goto_next,  'Next diagnostic')
      end

      -- Apply defaults to all servers (Neovim 0.11 API)
      vim.lsp.config('*', {
        capabilities = capabilities,
        on_attach = on_attach,
      })

      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'pyright', 'ts_ls', 'gopls' },
        automatic_enable = true, -- calls vim.lsp.enable() for each installed server
      })
    end,
  },
}
