return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    -- Load when a file is opened, not at startup
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('mason').setup()
      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'pyright', 'ts_ls', 'gopls' },
        automatic_installation = true,
      })

      local lspconfig = require('lspconfig')
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- Will be overridden by cmp-nvim-lsp if nvim-cmp is loaded
      pcall(function()
        capabilities = require('cmp_nvim_lsp').default_capabilities()
      end)

      local on_attach = function(_, bufnr)
        local map = function(keys, cmd, desc)
          vim.keymap.set('n', keys, cmd, { buffer = bufnr, desc = desc })
        end
        map('gd',         vim.lsp.buf.definition,     'Go to definition')
        map('gD',         vim.lsp.buf.declaration,    'Go to declaration')
        map('gi',         vim.lsp.buf.implementation, 'Go to implementation')
        map('gr',         vim.lsp.buf.references,     'References')
        map('K',          vim.lsp.buf.hover,          'Hover docs')
        map('<leader>rn', vim.lsp.buf.rename,         'Rename')
        map('<leader>ca', vim.lsp.buf.code_action,    'Code action')
        map('<leader>e',  vim.diagnostic.open_float,  'Diagnostic float')
        map('[d',         vim.diagnostic.goto_prev,   'Prev diagnostic')
        map(']d',         vim.diagnostic.goto_next,   'Next diagnostic')
      end

      local servers = { 'lua_ls', 'pyright', 'ts_ls', 'gopls' }
      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end
    end,
  },
}
