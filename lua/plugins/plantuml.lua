return {
  {
    'aklt/plantuml-syntax',
    -- Also loaded for markdown so its syntax/plantuml.vim is on the
    -- runtimepath for g:markdown_fenced_languages to embed (see
    -- treesitter.lua, which routes markdown through the legacy :syntax
    -- engine specifically to support this).
    ft = { 'plantuml', 'markdown' },
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
