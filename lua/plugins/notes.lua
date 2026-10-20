return {
  {
    dir = vim.fn.stdpath('config') .. '/lua/notes',
    name = 'notes',
    lazy = false,
    config = function()
      require('notes').setup()

      vim.api.nvim_create_user_command('NotesCreate', function()
        require('notes').create()
      end, { desc = 'Create a new note' })
    end,
  },
}
