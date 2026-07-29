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

-- Applies `regex` (a vim.regex) to every match in `line`, passing each
-- matched substring through `transform` and splicing the result back in.
local function replace_matches(line, regex, transform)
  local out, pos = {}, 0
  while pos < #line do
    local s, e = regex:match_str(line:sub(pos + 1))
    if not s then
      table.insert(out, line:sub(pos + 1))
      break
    end
    table.insert(out, line:sub(pos + 1, pos + s))
    table.insert(out, transform(line:sub(pos + s + 1, pos + e)))
    pos = pos + e
  end
  return table.concat(out)
end

local CONNECTOR_PIPE_RE = vim.regex([[\(^\|\s\)\@<=|\(\s\|$\)\@=]])
local CONNECTOR_DASH_RE = vim.regex([[\(│\)\@<=-\{2,}\|-\{2,}\(│\)\@=]])

-- utxt's dedicated ascii-art renderer (sequence diagrams) draws proper
-- unicode box-drawing lines, but class-diagram relations go through a
-- separate layout step that only ever emits plain ASCII: a bare "|" between
-- boxes, and "--" runs bridging two box borders directly. Stacked ASCII "|"
-- rows leave visible gaps between them in most fonts, reading as a broken
-- line; rewrite them to the real box-drawing glyphs so they join up.
--
-- Guarded the same way as the dimming used to be: the pipe only converts
-- when whitespace-flanked (so a literal "|" inside a label is untouched),
-- and the dash run needs 2+ dashes touching an existing box border (so a
-- single "-visibility" marker right after a border, e.g.
-- "│-secret: string│", isn't mistaken for a connector).
local function harden_connectors(lines)
  for i, line in ipairs(lines) do
    if line:find('|', 1, true) then
      line = replace_matches(line, CONNECTOR_PIPE_RE, function()
        return '│'
      end)
    end
    if line:find('--', 1, true) then
      line = replace_matches(line, CONNECTOR_DASH_RE, function(m)
        return ('─'):rep(#m)
      end)
    end
    lines[i] = line
  end
  return lines
end

local function render(lines)
  lines = harden_connectors(lines)

  ensure_preview_buf()
  vim.bo[preview_buf].modifiable = true
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
  vim.bo[preview_buf].modifiable = false
  ensure_preview_win()

  vim.api.nvim_buf_call(preview_buf, function()
    vim.cmd('syntax clear')
    -- Dim box-drawing connector glyphs (utxt lines/joints, the
    -- double-line/shade chars used for note boxes, and the ASCII
    -- connectors harden_connectors() just rewrote into this same set) so
    -- text labels stand out and paths are easier to trace in busy diagrams.
    vim.cmd([[syntax match PlantumlPreviewConnector /[─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬░▒▓]/]])
    -- Sequence-diagram arrowheads are still plain ASCII (only dim when
    -- touching a ─ line, to avoid text like "a < b").
    vim.cmd([[syntax match PlantumlPreviewConnector /\(─\)\@<=>\|<\(─\)\@=/]])
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

-- format: 'utxt' (unicode box-drawing, default) or 'txt' (pure ASCII, safe
-- over any SSH terminal without UTF-8 support).
function M.preview(format)
  format = format or 'utxt'
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
  M._render_source(bufnr, cursor_line, format, false)
end

-- Shared by :PlantumlPreview and the debounced auto-refresh below.
--
-- is_auto: true when called from the debounced auto-refresh, which fires on
-- every few keystrokes and so routinely sees transient parse errors while a
-- block is still open (e.g. an unclosed `{`). In that case keep showing the
-- last successful render instead of blowing it away with an error screen;
-- only a manual :PlantumlPreview replaces the preview with error details.
function M._render_source(bufnr, cursor_line, format, is_auto)
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
          if is_auto then
            vim.notify('plantuml.preview: ' .. error_headline(result.stderr) .. ' (keeping last preview)', vim.log.levels.WARN)
          else
            render_error(result)
          end
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
      M._render_source(last_bufnr, last_cursor_line, last_format or 'utxt', true)
    end)
  )
end

return M
