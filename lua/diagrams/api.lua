local M = {}

M.client_id = 'nvim-' .. vim.fn.getpid()

local function get_base_url()
  local ok_diag, diagrams = pcall(require, 'diagrams')
  if ok_diag and diagrams.config and diagrams.config.base_url then
    return diagrams.config.base_url
  end
  local ok_notes, notes = pcall(require, 'notes')
  if ok_notes and notes.config and notes.config.base_url then
    return notes.config.base_url
  end
  return 'http://localhost'
end

-- Calls the Pandora REST API. Returns the decoded body, or nil and a message.
-- Request bodies go to curl on stdin, so diagram text is never part of a shell string.
local function build_request(method, path, body)
  local base_url = get_base_url()
  local cmd = {
    'curl', '-sS', '--max-time', '10', '-X', method,
    '-H', 'Content-Type: application/json',
    '-H', 'X-Client-Id: ' .. M.client_id,
    '-w', '\n%{http_code}',
  }
  local opts = { text = true }
  if body then
    vim.list_extend(cmd, { '--data-binary', '@-' })
    opts.stdin = vim.json.encode(body)
  end
  cmd[#cmd + 1] = base_url .. '/api/diagrams' .. path
  return cmd, opts
end

local function parse_response(res)
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or 'request failed')
  end

  local payload, status = (res.stdout or ''):match('^(.*)\n(%d+)$')
  if not status then
    return nil, 'invalid response from Pandora'
  end
  status = tonumber(status)
  local ok, decoded = pcall(vim.json.decode, payload)
  if status >= 400 then
    local detail = ok and type(decoded) == 'table' and decoded.detail
    return nil, type(detail) == 'string' and detail or ('HTTP ' .. status)
  end
  if not ok then
    return nil, 'invalid response from Pandora'
  end
  return decoded
end

local function request(method, path, body)
  local cmd, opts = build_request(method, path, body)
  return parse_response(vim.system(cmd, opts):wait())
end

local function request_async(method, path, body, callback)
  local cmd, opts = build_request(method, path, body)
  vim.system(cmd, opts, function(res)
    local decoded, err = parse_response(res)
    vim.schedule(function()
      callback(decoded, err)
    end)
  end)
end

function M.get(id)
  return request('GET', '/' .. id)
end

function M.get_async(id, callback)
  return request_async('GET', '/' .. id, nil, callback)
end

function M.update(id, fields)
  return request('PUT', '/' .. id, fields)
end

return M
