return {
  {
    'aklt/plantuml-syntax',
    -- Eager, not ft-triggered: g:markdown_fenced_languages needs
    -- syntax/plantuml.vim on the runtimepath *before* any markdown buffer's
    -- FileType event fires (see treesitter.lua, which routes markdown
    -- through the legacy :syntax engine specifically to support this).
    -- ft = { 'plantuml', 'markdown' } raced that same FileType event -
    -- when this plugin's lazy-load autocmd ran after treesitter.lua's,
    -- core markdown.vim's `syntax include syntax/plantuml.vim` fired before
    -- the plugin was on rtp, throwing E484.
    lazy = false,
  },
  {
    dir = vim.fn.stdpath('config') .. '/lua/plantuml',
    name = 'plantuml',
    lazy = false,
    config = function()
      vim.filetype.add({
        extension = {
          puml = 'plantuml',
          plantuml = 'plantuml',
        },
      })

      require('plantuml').setup({
        jar_path = '/opt/plantuml/plantuml-1.2026.6.jar',
      })

      vim.api.nvim_create_user_command('PlantumlPreview', function(opts)
        require('plantuml').preview(opts.args ~= '' and opts.args or nil)
      end, {
        desc = 'Render PlantUML (whole buffer, or fence under cursor in markdown) as text art',
        nargs = '?',
        complete = function()
          return { 'txt', 'utxt' }
        end,
      })

      vim.keymap.set('n', '<leader>pv', '<cmd>PlantumlPreview<CR>', { desc = 'Preview PlantUML diagram' })
      vim.keymap.set('n', '<A-d>', '<cmd>PlantumlPreview<CR>', { desc = 'Preview PlantUML diagram' })
    end,
  },
}
