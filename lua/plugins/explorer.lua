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

      local function on_attach(bufnr)
        local api = require('nvim-tree.api')
        api.config.mappings.default_on_attach(bufnr)

        -- Single left click selects and opens (default nvim-tree only opens on double-click)
        vim.keymap.set('n', '<LeftMouse>', function()
          vim.cmd('exec "normal! \\<LeftMouse>"') -- move cursor to the clicked line first
          api.node.open.edit()
        end, { buffer = bufnr, desc = 'Open on single click' })
      end

      require('nvim-tree').setup({
        on_attach = on_attach,
        sort = { sorter = 'case_sensitive' },
        view = {
          width = 50,
          side = 'left',
        },
        renderer = {
          group_empty = true,
          indent_markers = { enable = true },
          highlight_opened_files = 'name',
          icons = {
            git_placement = 'before',
            show = { file = true, folder = true, folder_arrow = true, git = true },
          },
        },
        update_focused_file = {
          enable = true,
        },
        filters = {
          dotfiles = false, -- show dotfiles
          custom = { '.DS_Store', 'node_modules', [[^\.git$]], '__pycache__' },
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
