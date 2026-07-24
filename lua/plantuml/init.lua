local M = {}

local preview_buf = nil
local preview_win = nil
local jar_path = nil

local last_bufnr = nil
local last_cursor_line = nil
local last_format = nil
local debounce_timer = vim.uv.new_timer()

function M.setup(opts)
  jar_path = opts and opts.jar_path

  local group = vim.api.nvim_create_augroup('PlantumlAutoPreview', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = { 'plantuml', 'markdown' },
    callback = function(args)
      vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'InsertLeave' }, {
        group = group,
        buffer = args.buf,
        callback = function()
          M._schedule_refresh(args.buf, vim.api.nvim_win_get_cursor(0)[1])
        end,
      })
    end,
  })
end

-- Finds the plantuml/puml fenced code block under the cursor in a markdown
-- buffer, or falls back to the whole buffer for standalone .puml files.
local function get_source(bufnr, cursor_line)
  local ft = vim.bo[bufnr].filetype

  if ft == 'plantuml' then
    return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
  end

  if ft ~= 'markdown' then
    vim.notify('plantuml.preview: not a plantuml or markdown buffer', vim.log.levels.WARN)
    return nil
  end

  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

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
  if not FORMAT_FLAGS[format] then
    vim.notify('plantuml.preview: unknown format "' .. format .. '" (use txt or utxt)', vim.log.levels.ERROR)
    return
  end
  if not jar_path then
    vim.notify('plantuml.preview: no jar_path configured, call require("plantuml").setup({ jar_path = ... })', vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  last_bufnr, last_cursor_line, last_format = bufnr, cursor_line, format
  M._render_source(bufnr, cursor_line, format)
end

-- Shared by :PlantumlPreview and the debounced auto-refresh below.
function M._render_source(bufnr, cursor_line, format)
  local source = get_source(bufnr, cursor_line)
  if not source then
    return
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local cwd = bufname ~= '' and vim.fn.fnamemodify(bufname, ':h') or vim.fn.getcwd()

  vim.system(
    { 'java', '-jar', jar_path, FORMAT_FLAGS[format], '-pipe', '-charset', 'UTF-8' },
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

-- Debounces re-renders so edits to a plantuml/markdown buffer refresh an
-- already-open preview automatically, without shelling out on every
-- keystroke. Never opens the preview on its own.
function M._schedule_refresh(bufnr, cursor_line)
  if not (preview_win and vim.api.nvim_win_is_valid(preview_win)) then
    return
  end
  if not jar_path then
    return
  end
  last_bufnr, last_cursor_line = bufnr, cursor_line
  debounce_timer:stop()
  debounce_timer:start(
    300,
    0,
    vim.schedule_wrap(function()
      M._render_source(last_bufnr, last_cursor_line, last_format or 'txt')
    end)
  )
end

return M
