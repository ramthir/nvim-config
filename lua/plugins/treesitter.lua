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

      -- Neovim 0.10+ native treesitter highlighting.
      -- Markdown is excluded: Neovim's legacy :syntax engine is skipped
      -- entirely for any buffer with treesitter highlighting active, and
      -- only that legacy engine supports embedding another filetype's
      -- syntax (g:markdown_fenced_languages) inside a fenced code block —
      -- needed so ```plantuml fences get real highlighting, since no
      -- treesitter grammar for plantuml exists.
      vim.g.markdown_fenced_languages = {
        'javascript', 'js=javascript', 'jsx=javascriptreact', 'javascriptreact',
        'typescript', 'ts=typescript', 'tsx=typescriptreact', 'typescriptreact',
        'python', 'lua', 'go', 'rust', 'php',
        'bash', 'sh=bash', 'zsh=bash',
        'html', 'css', 'json', 'yaml', 'yml=yaml',
        'plantuml', 'puml=plantuml',
      }

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev)
          if ev.match == 'markdown' then
            -- Neovim core's own ftplugin/markdown.lua unconditionally
            -- starts treesitter highlighting before this autocmd runs;
            -- undo it so the legacy :syntax engine (and
            -- g:markdown_fenced_languages) takes over instead.
            vim.treesitter.stop(ev.buf)
            vim.bo[ev.buf].syntax = 'markdown'
            return
          end
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
