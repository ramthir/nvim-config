local M = {}

local pandora = require('notes.pandora')

local function tag_text(tags)
  return table.concat(vim.tbl_map(function(t) return '#' .. t end, tags), ' ')
end

-- Builds picker items from Pandora notes. Sorted for the full list; the server's
-- order is kept for content search.
local function to_items(notes, sorted)
  local sorter = require('notes.sort')
  local icons  = require('notes.icons')
  local items  = {}
  for _, note in ipairs(notes) do
    local tags          = sorter.tags(note.content)
    local icon, icon_hl = icons.get(tags, note.node_type)
    items[#items + 1] = {
      note       = note,
      title      = note.title,
      tags       = tags,
      icon       = icon,
      icon_hl    = icon_hl,
      updated_at = note.updated_at or '',
    }
  end
  if sorted then return sorter.sort(items) end
  return items
end

local displayer

local function entry_maker(item)
  displayer = displayer or require('telescope.pickers.entry_display').create({
    separator = ' ',
    items = { { width = 2 }, { remaining = true }, { remaining = true } },
  })
  return {
    value    = item.note,
    display  = function(entry)
      return displayer({
        { entry.icon, entry.icon_hl },
        entry.title,
        { #entry.tags > 0 and tag_text(entry.tags) or '', 'TelescopeResultsComment' },
      })
    end,
    ordinal  = item.title .. ' ' .. tag_text(item.tags),
    title    = item.title,
    tags     = item.tags,
    icon     = item.icon,
    icon_hl  = item.icon_hl,
  }
end

local function previewer()
  return require('telescope.previewers').new_buffer_previewer({
    title = 'Note',
    define_preview = function(self, entry)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value.content, '\n', { plain = true }))
      vim.bo[self.state.bufnr].filetype = 'markdown'
    end,
  })
end

local function open_selected(prompt_bufnr)
  local actions      = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  actions.select_default:replace(function()
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    if selection then
      require('notes.buffer').open(selection.value)
    end
  end)
  return true
end

local function has_telescope()
  local ok = pcall(require, 'telescope')
  if not ok then
    vim.notify('notes.nvim: telescope.nvim is required', vim.log.levels.ERROR)
  end
  return ok
end

-- Every note, filtered by title and tags as you type.
function M.search(config)
  if not has_telescope() then return end

  local notes, err = pandora.list_all()
  if not notes then
    vim.notify('Pandora list failed: ' .. err, vim.log.levels.ERROR)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf    = require('telescope.config').values

  pickers.new({}, {
    prompt_title  = 'Notes',
    finder        = finders.new_table({
      results     = to_items(notes, true),
      entry_maker = entry_maker,
    }),
    sorter        = conf.generic_sorter({}),
    previewer     = previewer(),
    attach_mappings = open_selected,
  }):find()
end

-- Notes whose content matches what you type, searched by Pandora on each change.
function M.grep(config)
  if not has_telescope() then return end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')

  pickers.new({}, {
    prompt_title  = 'Search Notes',
    finder        = finders.new_dynamic({
      fn = function(prompt)
        if prompt == '' then return {} end
        local notes, err = pandora.search(prompt, { limit = 100 })
        if not notes then
          vim.notify('Pandora search failed: ' .. err, vim.log.levels.ERROR)
          return {}
        end
        return to_items(notes, false)
      end,
      entry_maker = entry_maker,
    }),
    sorter        = require('telescope.sorters').empty(),
    previewer     = previewer(),
    attach_mappings = open_selected,
  }):find()
end

return M
