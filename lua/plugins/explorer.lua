return {
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    -- Load on toggle key or direct command
    cmd = { 'NvimTreeToggle', 'NvimTreeFocus', 'NvimTreeFindFile' },
    keys = {
      { '<leader>e', '<cmd>NvimTreeToggle<CR>',   desc = 'Toggle file explorer' },
      { '<leader>E', '<cmd>NvimTreeFindFile<CR>', desc = 'Reveal file in explorer' },
    },
    config = function()
      -- Disable netrw in favour of nvim-tree
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require('nvim-tree').setup({
        sort = { sorter = 'case_sensitive' },
        view = {
          width = 50,
          side = 'left',
        },
        renderer = {
          group_empty = true,
          indent_markers = { enable = true },
          icons = {
            git_placement = 'before',
            show = { file = true, folder = true, folder_arrow = true, git = true },
          },
        },
        filters = {
          dotfiles = false, -- show dotfiles
          custom = { '.DS_Store', 'node_modules', '.git' },
        },
        git = { enable = true, ignore = false },
        filesystem_watchers = { enable = true },
        actions = {
          open_file = {
            quit_on_open = false,
            window_picker = { enable = false },
          },
        },
      })
    end,
  },
}
