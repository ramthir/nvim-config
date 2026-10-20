-- Run: nvim --headless -u NONE -i NONE -l tests/wikilinks.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local requests = {}
package.loaded['notes.pandora'] = {
  get_async = function(id, callback)
    requests[#requests + 1] = { id = id, callback = callback }
  end,
}
local links = require('notes.wikilinks')
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buf, 'pandora://notes/105')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '[[123]] [[456]]' })
local ns = vim.api.nvim_get_namespaces().NotesWikiLinks
local function text(index)
  links.refresh(buf)
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
  return marks[index][4].virt_text[1][1]
end
local function latest()
  local request = requests[#requests]
  assert(request.id == 123)
  return request.callback
end

links.refresh(buf)
local old = requests[1].callback
requests[2].callback({ title = 'Other note' })
links.set_title(123, 'New title')
old({ title = 'Stale title' })
assert(text(1) == 'New title', 'Old responses must not overwrite a directly supplied title')
assert(text(2) == 'Other note', 'Other note IDs must remain unaffected')

links.invalidate(123)
links.refresh(buf)
old = latest()
links.invalidate(123)
old({ title = 'Invalidated title' })
assert(text(1) == '123', 'Invalidated responses must not restore cached titles')
local current = latest()
local count = #requests
old(nil)
links.refresh(buf)
assert(#requests == count, 'Stale failures must not clear a newer in-flight request')
current({ title = 'Fresh title' })
assert(text(1) == 'Fresh title', 'The current response must still update the title')

links.invalidate(123)
links.refresh(buf)
old = latest()
links.invalidate(123)
links.refresh(buf)
current = latest()
current({ title = 'Newest title' })
old({ title = 'Late old title' })
assert(text(1) == 'Newest title', 'Out-of-order success must preserve the newest title')

links.invalidate(123)
links.refresh(buf)
latest()(nil)
count = #requests
assert(text(1) == '123')
assert(#requests == count, 'Current failures must retain the negative cache')
links.invalidate(123)
links.refresh(buf)
assert(#requests == count + 1, 'Invalidation must allow a retry after a failed lookup')
latest()({ title = 'Recovered title' })
assert(text(1) == 'Recovered title')

print('Wiki-link stale response regression checks passed')
vim.cmd('qa!')
