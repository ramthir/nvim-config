return {
  {
    dir = vim.fn.stdpath('config') .. '/lua/diagrams',
    name = 'diagrams',
    lazy = false,
    config = function()
      require('diagrams').setup()

      vim.api.nvim_create_user_command('Diagram', function(opts)
        require('diagrams.buffer').open_from(opts.args)
      end, { nargs = '?', desc = 'Open a Pandora diagram by ID' })

      -- User commands must start with a capital, so lower-case `:diagram` expands to `:Diagram`
      -- only when it is the whole command name being typed.
      vim.cmd([[cnoreabbrev <expr> diagram getcmdtype() == ':' && getcmdline() ==# 'diagram' ? 'Diagram' : 'diagram']])
    end,
  },
}
