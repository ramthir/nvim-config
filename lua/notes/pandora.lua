local M = {}

M.NODE_TYPES = {
  "document", "task", "project", "week", "status", "priority", "company", "contact",
  "role", "technology", "city", "education", "application", "team", "folder",
  "component", "specification", "decision", "environment", "month", "year",
  "meeting", "meeting_minutes", "resource",
}

local PAGE_SIZE = 200

local function encode(value)
  return (tostring(value):gsub("[^%w%-_%.~]", function(c)
    return string.format("%%%02X", c:byte())
  end))
end

local function query_string(params)
  local parts = {}
  for _, key in ipairs({ "query", "limit", "offset", "node_type", "title_only" }) do
    local value = params[key]
    if value ~= nil then
      parts[#parts + 1] = key .. "=" .. encode(value)
    end
  end
  return #parts > 0 and ("?" .. table.concat(parts, "&")) or ""
end

-- Calls the Pandora REST API. Returns the decoded body, or nil and a message.
-- Request bodies go to curl on stdin, so note text is never part of a shell string.
local function request(method, path, body)
  local base_url = require("notes").config.base_url
  local cmd = {
    "curl", "-sS", "--max-time", "5", "-X", method,
    "-H", "Content-Type: application/json",
    "-w", "\n%{http_code}",
  }
  local opts = { text = true }
  if body then
    vim.list_extend(cmd, { "--data-binary", "@-" })
    opts.stdin = vim.json.encode(body)
  end
  cmd[#cmd + 1] = base_url .. "/api/notes" .. path

  local res = vim.system(cmd, opts):wait()
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "request failed")
  end

  local payload, status = res.stdout:match("^(.*)\n(%d+)$")
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

-- One page of notes matching the query. Returns nil and a message on failure.
function M.search(query, opts)
  opts = opts or {}
  return request("GET", query_string({
    query = query or "",
    limit = opts.limit or PAGE_SIZE,
    title_only = opts.title_only and "true" or nil,
  }))
end

-- Every note, paged through the API.
function M.list_all()
  local notes = {}
  local offset = 0
  repeat
    local page, err = request("GET", query_string({ limit = PAGE_SIZE, offset = offset }))
    if not page then return nil, err end
    vim.list_extend(notes, page)
    offset = offset + PAGE_SIZE
  until #page < PAGE_SIZE
  return notes
end

function M.get(id)
  return request("GET", "/" .. id)
end

function M.create(fields)
  return request("POST", "", fields)
end

function M.update(id, fields)
  return request("PUT", "/" .. id, fields)
end

return M
