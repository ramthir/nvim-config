local M = {}

local MONTH_MAP = {
  january = 0, jan = 0,
  february = 1, feb = 1,
  march = 2, mar = 2,
  april = 3, apr = 3,
  may = 4,
  june = 5, jun = 5,
  july = 6, jul = 6,
  august = 7, aug = 7,
  september = 8, sep = 8,
  october = 9, oct = 9,
  november = 10, nov = 10,
  december = 11, dec = 11,
}

local MONTH_NAMES = {
  "january","february","march","april","may","june",
  "july","august","september","october","november","december",
}

local WEEKDAYS = { "sunday","monday","tuesday","wednesday","thursday","friday","saturday" }

local function is_tag_line(line)
  if line:match("^%s*$") then return false end
  return line:gsub("#[%a][%w%-]*", ""):gsub("%s+", "") == ""
end

local function extract_tags(content)
  local lines = vim.split(content, "\n")
  local tags = {}
  local i = #lines
  while i >= 1 and lines[i]:match("^%s*$") do i = i - 1 end
  while i >= 1 do
    local line = lines[i]:match("^%s*(.-)%s*$")
    if line == "" or not is_tag_line(line) then break end
    for tag in line:gmatch("#([%a][%w%-]*)") do
      table.insert(tags, 1, tag:lower())
    end
    i = i - 1
  end
  return tags
end

local function parse_scheduled_time(tag)
  local h, m, ampm = tag:match("^at%-(%d%d?)[-_]?(%d?%d?)(a?p?m?)$")
  if not h then return nil end
  h, m = tonumber(h), tonumber(m) or 0
  if h < 0 or h > 23 or m < 0 or m > 59 then return nil end
  if ampm == "pm" and h < 12 then h = h + 12 end
  if ampm == "am" and h == 12 then h = 0 end
  return { hours = h, minutes = m }
end

local function parse_holiday_date(tag)
  local stripped = tag
    :gsub("^birthday%-", "")
    :gsub("^holiday%-", "")
    :gsub("^anniversary%-", "")
    :gsub("^aniversary%-", "")
  local month_str, day = stripped:match("^([%a]+)[-_]?(%d%d?)$")
  if not month_str then return nil end
  day = tonumber(day)
  local month = MONTH_MAP[month_str:lower()]
  if month == nil or day < 1 or day > 31 then return nil end
  return { month = month, day = day }
end

local function is_upcoming_meeting(tags_set)
  for tag in pairs(tags_set) do
    local t = parse_scheduled_time(tag)
    if t then
      local now = os.date("*t")
      if t.hours > now.hour then return true end
      if t.hours == now.hour and t.minutes > now.min then return true end
      return false
    end
  end
  return true
end

local function is_current_month_note(tags_set, title)
  if not tags_set["month"] then return false end
  local now = os.date("*t")
  local exact = MONTH_NAMES[now.month] .. ", " .. tostring(now.year)
  local haystack = title:lower()
  return haystack:find(exact, 1, true) ~= nil
end

local function get_priority(tags, title)
  local tags_set = {}
  for _, t in ipairs(tags) do tags_set[t] = true end

  if is_current_month_note(tags_set, title) then return 0 end

  local now = os.date("*t")
  local today = WEEKDAYS[now.wday]
  local is_daily = tags_set["daily"] or tags_set["everyday"]
  if tags_set["meeting"] and (tags_set[today] or is_daily) then
    return is_upcoming_meeting(tags_set) and 1.0 or 1.5
  end

  if tags_set["inprogress"] or tags_set["in-progress"] then return 3 end

  local has_special = tags_set["holiday"] or tags_set["birthday"] or
    tags_set["anniversary"] or tags_set["aniversary"]
  if not has_special then
    for t in pairs(tags_set) do
      if t:match("^birthday") or t:match("^anniversary") or t:match("^aniversary") then
        has_special = true
        break
      end
    end
  end
  if has_special then
    -- os month is 1-based; MONTH_MAP is 0-based
    local cur_month = now.month - 1
    for t in pairs(tags_set) do
      local d = parse_holiday_date(t)
      if d and d.month == cur_month and d.day == now.day then return 4.1 end
    end
    for t in pairs(tags_set) do
      local d = parse_holiday_date(t)
      if d and d.month == cur_month then return 4.5 end
    end
  end

  if tags_set["pin"] then return 4.8 end

  return 5
end

M.tags = extract_tags

function M.sort(entries)
  for _, entry in ipairs(entries) do
    entry.priority = get_priority(entry.tags, entry.title)
  end
  table.sort(entries, function(a, b)
    if a.priority ~= b.priority then return a.priority < b.priority end
    -- updated_at is an ISO timestamp, so string order is time order
    if a.updated_at ~= b.updated_at then return a.updated_at > b.updated_at end
    return a.title:lower() < b.title:lower()
  end)
  return entries
end

return M
