return {
  {
    dir = '~/Workspace/notes.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    cmd = { 'NotesSearch', 'NotesGrep', 'NotesCreate' },
    keys = {
      { '<C-n>',      '<cmd>NotesSearch<CR>',  desc = 'Find notes' },
      { '<leader>ng', '<cmd>NotesGrep<CR>',    desc = 'Grep notes' },
      { '<leader>nn', '<cmd>NotesCreate<CR>',  desc = 'New note' },
    },
    config = function()
      require('notes').setup({
        notes_path = '~/Workspace/notes',
      })
    end,
  },
}
