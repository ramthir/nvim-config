local M = {}

local function title_to_filename(title)
  return title
    :gsub('[<>:"/\\|?*]', " ")
    :gsub("%s+", " ")
    :gsub("^%s+", "")
    :gsub("[%. ]+$", "")
end

local function available_path(dir, base)
  local path = dir .. "/" .. base .. ".md"
  if vim.fn.filereadable(path) == 0 then return path end
  local i = 2
  repeat
    path = string.format("%s/%s (%d).md", dir, base, i)
    i = i + 1
  until vim.fn.filereadable(path) == 0
  return path
end

function M.create(config)
  vim.ui.input({ prompt = "Note title: " }, function(title)
    if not title or title:match("^%s*$") then return end
    title = title:match("^%s*(.-)%s*$")
    local base = title_to_filename(title)
    if base == "" then base = "Untitled" end
    local path = available_path(config.notes_path, base)
    local file = io.open(path, "w")
    if file then
      file:write(config.template(title))
      file:close()
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end)
end

return M
