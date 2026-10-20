local M = {}

-- Asks for a node type, creates the note in Pandora, and opens it.
function M.create_titled(title)
  vim.ui.select(require('notes.pandora').NODE_TYPES, { prompt = 'Note type: ' }, function(node_type)
    if not node_type then return end
    local template = require('notes').config.template
    local note, err = require('notes.pandora').create({
      title     = title,
      content   = template(title),
      node_type = node_type,
    })
    if not note then
      vim.notify('Pandora create failed: ' .. err, vim.log.levels.ERROR)
      return
    end
    require('notes.buffer').open_id(note.id)
  end)
end

function M.create()
  vim.ui.input({ prompt = 'Note title: ' }, function(title)
    if not title or title:match('^%s*$') then return end
    M.create_titled(vim.trim(title))
  end)
end

return M
