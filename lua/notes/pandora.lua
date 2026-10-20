local M = {}

M.NODE_TYPES = {
  "document", "task", "project", "week", "status", "priority", "company", "contact",
  "role", "technology", "city", "education", "application", "team", "folder",
  "component", "specification", "decision", "environment", "month", "year",
  "meeting", "meeting_minutes", "resource",
}

local PAGE_SIZE = 200

-- Sent with every request. Pandora copies it onto the events it publishes for a save,
-- so this Neovim can tell its own saves apart from changes made elsewhere.
M.client_id = 'nvim-' .. vim.fn.getpid()

local function encode(value)
  return (tostring(value):gsub("[^%w%-_%.~]", function(c)
    return string.format("%%%02X", c:byte())
  end))
end

local function query_string(params)
  local parts = {}
  for _, key in ipairs({ "query", "limit", "title_only" }) do
    local value = params[key]
    if value ~= nil then
      parts[#parts + 1] = key .. "=" .. encode(value)
    end
  end
  return #parts > 0 and ("?" .. table.concat(parts, "&")) or ""
end

-- Calls the Pandora REST API. Returns the decoded body, or nil and a message.
-- Request bodies go to curl on stdin, so note text is never part of a shell string.
local function build_request(method, path, body)
  local base_url = require("notes").config.base_url
  local cmd = {
    "curl", "-sS", "--max-time", "10", "-X", method,
    "-H", "Content-Type: application/json",
    "-H", "X-Client-Id: " .. M.client_id,
    "-w", "\n%{http_code}",
  }
  local opts = { text = true }
  if body then
    vim.list_extend(cmd, { "--data-binary", "@-" })
    opts.stdin = vim.json.encode(body)
  end
  cmd[#cmd + 1] = base_url .. "/api/notes" .. path
  return cmd, opts
end

local function parse_response(res)
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "request failed")
  end

  local payload, status = (res.stdout or ""):match("^(.*)\n(%d+)$")
  if not status then
    return nil, "invalid response from Pandora"
  end
  status = tonumber(status)
  local ok, decoded = pcall(vim.json.decode, payload)
  if status >= 400 then
    local detail = ok and type(decoded) == "table" and decoded.detail
    return nil, type(detail) == "string" and detail or ("HTTP " .. status)
  end
  if not ok then
    return nil, "invalid response from Pandora"
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

-- One page of notes matching the query. Returns nil and a message on failure.
function M.search(query, opts)
  opts = opts or {}
  return request("GET", query_string({
    query = query or "",
    limit = opts.limit or PAGE_SIZE,
    title_only = opts.title_only and "true" or nil,
  }))
end

function M.get(id)
  return request("GET", "/" .. id)
end

function M.get_async(id, callback)
  return request_async("GET", "/" .. id, nil, callback)
end

function M.create(fields)
  return request("POST", "", fields)
end

function M.update(id, fields)
  return request("PUT", "/" .. id, fields)
end

return M
