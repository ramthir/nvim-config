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
      require("copilot_cmp").setup()
    end,
  },
}
