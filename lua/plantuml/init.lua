local M = {}

local preview_buf = nil
local preview_win = nil
local jar_path = nil

function M.setup(opts)
  jar_path = opts and opts.jar_path
end

-- Finds the plantuml/puml fenced code block under the cursor in a markdown
-- buffer, or falls back to the whole buffer for standalone .puml files.
local function get_source()
  local ft = vim.bo.filetype

  if ft == 'plantuml' then
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  end

  if ft ~= 'markdown' then
    vim.notify('plantuml.preview: not a plantuml or markdown buffer', vim.log.levels.WARN)
    return nil
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local start_line
  for i = cursor_line, 1, -1 do
    local line = buf_lines[i]
    if line:match('^%s*```+%s*p%l*uml%s*$') then
      start_line = i
      break
    elseif i ~= cursor_line and line:match('^%s*```+%s*$') then
      break
    end
  end
  if not start_line then
    vim.notify('plantuml.preview: no plantuml code fence under cursor', vim.log.levels.WARN)
    return nil
  end

  local end_line
  for i = start_line + 1, #buf_lines do
    if buf_lines[i]:match('^%s*```+%s*$') then
      end_line = i
      break
    end
  end
  if not end_line then
    vim.notify('plantuml.preview: unterminated code fence', vim.log.levels.WARN)
    return nil
  end

  local fence_lines = {}
  for i = start_line + 1, end_line - 1 do
    table.insert(fence_lines, buf_lines[i])
  end

  local text = table.concat(fence_lines, '\n')
  if not text:match('@startuml') then
    text = '@startuml\n' .. text .. '\n@enduml'
  end
  return text
end

local function ensure_preview_buf()
  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    return
  end
  preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].buftype = 'nofile'
  vim.bo[preview_buf].bufhidden = 'hide'
  vim.bo[preview_buf].swapfile = false
  vim.api.nvim_buf_set_name(preview_buf, 'PlantUML Preview')
  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = preview_buf, silent = true })
end

local function ensure_preview_win()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    return
  end
  vim.cmd('vsplit')
  preview_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  vim.wo[preview_win].wrap = false
  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].signcolumn = 'no'
end

local function render(lines)
  ensure_preview_buf()
  vim.bo[preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.bo[preview_buf].modifiable = false
  ensure_preview_win()

  vim.api.nvim_buf_call(preview_buf, function()
    vim.cmd('syntax clear')
  end)
end

-- Extracts a short human-readable message from plantuml's stderr, e.g.
-- "ERROR\n1\ncannot include monokai-theme.puml" -> "cannot include monokai-theme.puml".
local function error_headline(stderr)
  local lines = vim.split(stderr or '', '\n', { plain = true, trimempty = true })
  return lines[#lines] or 'render failed'
end

local function render_error(result)
  local headline = error_headline(result.stderr)
  local lines = { 'ERROR: ' .. headline, '' }
  vim.list_extend(lines, vim.split(result.stdout or '', '\n', { plain = true }))

  ensure_preview_buf()
  vim.bo[preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.bo[preview_buf].modifiable = false
  ensure_preview_win()

  vim.api.nvim_buf_call(preview_buf, function()
    vim.cmd('syntax clear')
    vim.cmd([[syntax match PlantumlPreviewErrorMarker /\^\^\^*/]])
    vim.cmd([[syntax match PlantumlPreviewErrorText /\c\%>1l\<\(cannot\|error\|syntax error\|no diagram found\)\>.*/]])
    vim.cmd([[syntax match PlantumlPreviewErrorHeader /\%1l.*/]])
    vim.cmd('highlight default link PlantumlPreviewErrorMarker Error')
    vim.cmd('highlight default link PlantumlPreviewErrorText WarningMsg')
    vim.cmd('highlight default link PlantumlPreviewErrorHeader ErrorMsg')
  end)

  vim.notify('plantuml.preview: ' .. headline, vim.log.levels.ERROR)
end

local FORMAT_FLAGS = { txt = '-ttxt', utxt = '-tutxt' }

-- format: 'txt' (pure ASCII, safe over any SSH terminal) or 'utxt' (unicode
-- box-drawing, nicer but needs a UTF-8 capable terminal/font).
function M.preview(format)
  format = format or 'txt'
  local flag = FORMAT_FLAGS[format]
  if not flag then
    vim.notify('plantuml.preview: unknown format "' .. format .. '" (use txt or utxt)', vim.log.levels.ERROR)
    return
  end
  if not jar_path then
    vim.notify('plantuml.preview: no jar_path configured, call require("plantuml").setup({ jar_path = ... })', vim.log.levels.ERROR)
    return
  end

  local source = get_source()
  if not source then
    return
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  local cwd = bufname ~= '' and vim.fn.fnamemodify(bufname, ':h') or vim.fn.getcwd()

  vim.system(
    { 'java', '-jar', jar_path, flag, '-pipe', '-charset', 'UTF-8' },
    { stdin = source, text = true, cwd = cwd },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          render_error(result)
          return
        end
        render(vim.split(result.stdout, '\n', { plain = true }))
      end)
    end
  )
end

return M
