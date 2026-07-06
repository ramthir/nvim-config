local M = {}

local function extract_title(path)
  local f = io.open(path, "r")
  if not f then return nil end
  for line in f:lines() do
    local title = line:match("^#%s+(.-)%s*$")
    if title then
      f:close()
      return title
    end
  end
  f:close()
  return nil
end

local function build_entries(notes_path)
  local sorter = require("notes.sort")
  local icons  = require("notes.icons")
  local paths  = vim.fn.globpath(notes_path, "**/*.md", false, true)
  local entries = {}
  for _, path in ipairs(paths) do
    local filename = vim.fn.fnamemodify(path, ":t:r")
    local tags          = sorter.read_tags(path)
    local icon, icon_hl = icons.get(tags)
    entries[#entries + 1] = {
      path     = path,
      title    = extract_title(path) or filename,
      filename = filename,
      mtime    = vim.fn.getftime(path),
      tags     = tags,
      icon     = icon,
      icon_hl  = icon_hl,
    }
  end
  return sorter.sort(entries)
end

function M.search(config)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("notes.nvim: telescope.nvim is required", vim.log.levels.ERROR)
    return
  end

  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local displayer    = require("telescope.pickers.entry_display").create({
    separator = " ",
    items = { { width = 2 }, { remaining = true }, { remaining = true } },
  })

  local function make_display(entry)
    return displayer({
      { entry.icon, entry.icon_hl },
      entry.title,
      { entry.filename, "TelescopeResultsComment" },
    })
  end

  pickers.new({}, {
    prompt_title = "Notes",
    finder = finders.new_table({
      results = build_entries(config.notes_path),
      entry_maker = function(entry)
        return {
          value    = entry.path,
          display  = make_display,
          ordinal  = entry.title .. " " .. entry.filename,
          path     = entry.path,
          title    = entry.title,
          filename = entry.filename,
          icon     = entry.icon,
          icon_hl  = entry.icon_hl,
        }
      end,
    }),
    sorter    = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
  }):find()
end

function M.grep(config)
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("notes.nvim: telescope.nvim is required", vim.log.levels.ERROR)
    return
  end
  builtin.live_grep({
    prompt_title = "Search Notes",
    cwd          = config.notes_path,
    glob_pattern = "*.md",
  })
end

return M
