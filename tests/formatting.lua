-- Requires installed conform.nvim.
-- Run: nvim --headless -u NONE -i NONE -l tests/formatting.lua
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/conform.nvim')
local format = dofile('lua/plugins/formatting.lua')[1].opts.format_after_save
local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/src', 'p')
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(buf, root .. '/src/app.js')
vim.bo[buf].filetype = 'javascript'
local function fixture(name, content, enabled)
  local path = root .. '/' .. name
  vim.fn.writefile({ content }, path)
  assert((format(buf) ~= nil) == enabled, 'Unexpected formatting eligibility for ' .. name)
  vim.fn.delete(path)
end
assert(format(buf) == nil, 'Projects without configuration must skip automatic formatting')
fixture('package.json', '{"prettier":{"singleQuote":true}}', true)
fixture('package.json', '{"prettier":"@company/prettier-config"}', true)
fixture('package.json', '{"name":"no-format-config"}', false)
for _, name in ipairs({
  '.prettierrc', '.prettierrc.json', '.prettierrc.json5',
  '.prettierrc.yml', '.prettierrc.yaml', '.prettierrc.toml',
  '.prettierrc.js', '.prettierrc.cjs', '.prettierrc.mjs',
  '.prettierrc.ts', '.prettierrc.cts', '.prettierrc.mts',
  'prettier.config.js', 'prettier.config.cjs', 'prettier.config.mjs',
  'prettier.config.ts', 'prettier.config.cts', 'prettier.config.mts',
}) do
  fixture(name, '{}', true)
end
vim.fn.writefile({ '{}' }, root .. '/.prettierrc')
vim.fn.writefile({ '{"name":"nested-package"}' }, root .. '/src/package.json')
assert(format(buf) ~= nil, 'A nested package without a prettier key must not hide a parent config')
vim.fn.delete(root, 'rf')
local unnamed = vim.api.nvim_create_buf(true, false)
assert(format(unnamed) == nil, 'Unnamed buffers must skip config discovery')
print('Prettier configuration discovery regression checks passed')
vim.cmd('qa!')
