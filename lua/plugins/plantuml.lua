return {
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
    end,
  },
}
