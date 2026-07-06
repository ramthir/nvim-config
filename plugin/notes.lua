if vim.g.loaded_notes_nvim then return end
vim.g.loaded_notes_nvim = true

vim.api.nvim_set_hl(0, "NotesIconTodo",     { fg = "#e5c07b", default = true })
vim.api.nvim_set_hl(0, "NotesIconOngoing",  { fg = "#61afef", default = true })
vim.api.nvim_set_hl(0, "NotesIconDone",     { fg = "#98c379", default = true })
vim.api.nvim_set_hl(0, "NotesIconPin",      { fg = "#e06c75", default = true })
vim.api.nvim_set_hl(0, "NotesIconMeeting",  { fg = "#c678dd", default = true })
vim.api.nvim_set_hl(0, "NotesIconCalendar", { fg = "#56b6c2", default = true })
vim.api.nvim_set_hl(0, "NotesIconContact",  { fg = "#c678dd", default = true })
vim.api.nvim_set_hl(0, "NotesIconFamily",   { fg = "#e06c75", default = true })
vim.api.nvim_set_hl(0, "NotesIconGift",     { fg = "#e06c75", default = true })
vim.api.nvim_set_hl(0, "NotesIconWork",     { fg = "#61afef", default = true })
vim.api.nvim_set_hl(0, "NotesIconProject",  { fg = "#e5c07b", default = true })
vim.api.nvim_set_hl(0, "NotesIconHoliday",  { fg = "#e5c07b", default = true })
vim.api.nvim_set_hl(0, "NotesIconIdea",     { fg = "#e5c07b", default = true })
vim.api.nvim_set_hl(0, "NotesIconDefault",  { fg = "#e5c07b", default = true })

require('notes').setup({ notes_path = '~/Workspace/notes' })

vim.api.nvim_create_user_command("NotesSearch", function()
  require("notes").search()
end, { desc = "Search notes by filename" })

vim.api.nvim_create_user_command("NotesGrep", function()
  require("notes").grep()
end, { desc = "Search notes by content" })

vim.api.nvim_create_user_command("NotesCreate", function()
  require("notes").create()
end, { desc = "Create a new note" })
