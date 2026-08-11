return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<M-l>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = { enabled = false },
        filetypes = {
          markdown = true,
          gitcommit = false,
          gitrebase = false,
          help = false,
        },
      })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    -- `dependencies` only orders loading relative to copilot.lua; without an
    -- explicit trigger of its own, lazy.nvim (defaults.lazy = true) never
    -- loads this plugin at all, so copilot_cmp.setup() never runs and the
    -- "copilot" cmp source (see completion.lua) never registers.
    event = "InsertEnter",
    config = function()
      -- Patch an upstream bug (zbirenbaum/copilot-cmp#128, #133, both open,
      -- unmerged): source.lua checks `self.client.is_stopped()` without a
      -- colon, so `self` never reaches the LSP client method. Neovim only
      -- accepts that through a deprecated compat shim removed in 0.13,
      -- which prints "client.is_stopped is deprecated" on every completion
      -- check. Re-implement the same check with a proper method call.
      local source = require("copilot_cmp.source")
      source.is_available = function(self)
        if self.client:is_stopped() or self.client.name ~= "copilot" then
          return false
        end

        local get_source_client = function()
          if vim.lsp.get_clients == nil then
            return vim.lsp.get_active_clients({ bufnr = vim.api.nvim_get_current_buf(), id = self.client.id })
          end
          return vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf(), id = self.client.id })
        end

        return next(get_source_client()) ~= nil
      end

      require("copilot_cmp").setup()
    end,
  },
}
