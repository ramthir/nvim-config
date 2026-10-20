return {
  {
    dir = vim.fn.stdpath('config') .. '/lua/notes',
    name = 'notes',
    lazy = false,
    config = function()
      require('notes').setup()

      vim.api.nvim_create_user_command('Note', function(opts)
        require('notes.buffer').open_from(opts.args)
      end, { nargs = '?', desc = 'Open a Pandora note by ID' })

      -- User commands must start with a capital, so lower-case `:note` expands to `:Note`
      -- only when it is the whole command name being typed.
      vim.cmd([[cnoreabbrev <expr> note getcmdtype() == ':' && getcmdline() ==# 'note' ? 'Note' : 'note']])

      vim.api.nvim_create_user_command('NotesCreate', function()
        require('notes').create()
      end, { desc = 'Create a new note' })
    end,
  },
}
