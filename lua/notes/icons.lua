local M = {}

local RULES = {
  { icon = "󰐃", hl = "NotesIconPin",      match = function(t) return t["pin"] end },
  { icon = "󰄬", hl = "NotesIconDone",     match = function(t) return t["done"] or t["complete"] end },
  { icon = "󰔛", hl = "NotesIconOngoing",  match = function(t) return t["inprogress"] or t["in-progress"] or t["ongoing"] end },
  { icon = "󰄱", hl = "NotesIconTodo",     match = function(t) return t["todo"] or t["task"] end },
  { icon = "󰙅", hl = "NotesIconMeeting",  match = function(t) return t["meeting"] or t["event"] end },
  { icon = "󰃭", hl = "NotesIconCalendar", match = function(t) return t["month"] end },
  { icon = "󰄰", hl = "NotesIconCalendar", match = function(t) return t["week"] end },
  { icon = "󰔟", hl = "NotesIconCalendar", match = function(t) return t["day"] end },
  { icon = "󰀄", hl = "NotesIconContact",  match = function(t) return t["contact"] end },
  { icon = "󰋖", hl = "NotesIconFamily",   match = function(t) return t["kids"] or t["family"] or t["wife"] or t["son"] or t["daughter"] end },
  { icon = "󰹄", hl = "NotesIconGift",     match = function(t, raw)
      if t["birthday"] or t["anniversary"] or t["aniversary"] then return true end
      for _, tag in ipairs(raw) do
        if tag:match("^birthday") or tag:match("^anniversary") or tag:match("^aniversary") then
          return true
        end
      end
      return false
    end },
  { icon = "󱒋", hl = "NotesIconWork",     match = function(t) return t["company"] end },
  { icon = "󰉻", hl = "NotesIconWork",     match = function(t) return t["team"] or t["organization"] or t["organisation"] or t["org"] end },
  { icon = "󰉋", hl = "NotesIconProject",  match = function(t) return t["project"] end },
  { icon = "󱒊", hl = "NotesIconDefault",  match = function(t) return t["uml"] or t["plantuml"] or t["plant-uml"] end },
  { icon = "󰆼", hl = "NotesIconDefault",  match = function(t) return t["db"] or t["database"] or t["schema"] or t["sql"] or t["table"] or t["er"] end },
  { icon = "󰃀", hl = "NotesIconDefault",  match = function(t) return t["clipping"] or t["clip"] end },
  { icon = "󰭻", hl = "NotesIconDefault",  match = function(t) return t["prompt"] end },
  { icon = "󰺕", hl = "NotesIconCalendar", match = function(t) return t["poya"] end },
  { icon = "󰓎", hl = "NotesIconHoliday",  match = function(t) return t["holiday"] end },
  { icon = "󰋞", hl = "NotesIconDefault",  match = function(t) return t["location"] or t["city"] end },
  { icon = "󰙓", hl = "NotesIconDefault",  match = function(t) return t["movie"] end },
  { icon = "󰂺", hl = "NotesIconDefault",  match = function(t) return t["book"] or t["spec"] end },
  { icon = "󰬚", hl = "NotesIconDefault",  match = function(t) return t["word"] or t["world"] end },
  { icon = "󱠂", hl = "NotesIconIdea",     match = function(t) return t["idea"] end },
  { icon = "󰇮", hl = "NotesIconDefault",  match = function(t) return t["mail"] or t["email"] end },
}

local DEFAULT = { icon = "󰈙", hl = "NotesIconDefault" }

-- Used when no tag rule matches, so Pandora notes without tags still get an icon.
local NODE_TYPE_ICONS = {
  task            = { icon = "󰄱", hl = "NotesIconTodo" },
  meeting         = { icon = "󰙅", hl = "NotesIconMeeting" },
  meeting_minutes = { icon = "󰙅", hl = "NotesIconMeeting" },
  project         = { icon = "󰉋", hl = "NotesIconProject" },
  specification   = { icon = "󰂺", hl = "NotesIconDefault" },
  contact         = { icon = "󰀄", hl = "NotesIconContact" },
  company         = { icon = "󱒋", hl = "NotesIconWork" },
  team            = { icon = "󰉻", hl = "NotesIconWork" },
  week            = { icon = "󰄰", hl = "NotesIconCalendar" },
  month           = { icon = "󰃭", hl = "NotesIconCalendar" },
  year            = { icon = "󰃭", hl = "NotesIconCalendar" },
}

function M.get(tags, node_type)
  local tags_set = {}
  for _, t in ipairs(tags) do tags_set[t] = true end
  for _, rule in ipairs(RULES) do
    if rule.match(tags_set, tags) then
      return rule.icon, rule.hl
    end
  end
  local by_type = NODE_TYPE_ICONS[node_type]
  if by_type then
    return by_type.icon, by_type.hl
  end
  return DEFAULT.icon, DEFAULT.hl
end

return M
