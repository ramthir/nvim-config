-- Run: nvim --headless -u NONE -i NONE -l tests/plantuml_syntax.lua
vim.opt.rtp:prepend(vim.fn.expand('~/.local/share/nvim/lazy/plantuml-syntax'))
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.getcwd() .. '/after')
vim.o.termguicolors = true
vim.cmd('syntax on')
vim.cmd('filetype plugin on')

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = 'plantuml'

vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  '@startuml DomainModel',
  'hide circle',
  'hide methods',
  '',
  'class User <<Aggregate Root>> {',
  '  _id: ObjectId',
  '  email: string',
  '  roles: UserRole[]',
  '  deleted_at: datetime?',
  '}',
  '',
  'class Address <<Value Object>> {',
  '  city: string',
  '}',
  '',
  'enum UserStatus <<Enum>> {',
  '  ACTIVE',
  '  INACTIVE',
  '}',
  '',
  'interface Authenticatable <<Interface>> {',
  '}',
  '@enduml',
})

local function group_at(line, col)
  local id = vim.fn.synID(line, col, 1)
  return vim.fn.synIDattr(id, 'name')
end

local function trans_at(line, col)
  local id = vim.fn.synID(line, col, 1)
  return vim.fn.synIDattr(vim.fn.synIDtrans(id), 'name')
end

local function fg(name)
  return vim.fn.synIDattr(vim.fn.hlID(name), 'fg#')
end

-- 1. Stereotypes
assert(group_at(5, 15) == 'plantumlStereoAggregateRoot', '<<Aggregate Root>> must match plantumlStereoAggregateRoot')
assert(fg('plantumlStereoAggregateRoot') == '#fc9867', 'Aggregate Root must use Monokai Pro orange (#fc9867)')

assert(group_at(12, 18) == 'plantumlStereoValueObject', '<<Value Object>> must match plantumlStereoValueObject')
assert(fg('plantumlStereoValueObject') == '#a9dc76', 'Value Object must use Monokai Pro green (#a9dc76)')

assert(group_at(16, 18) == 'plantumlStereoEnum', '<<Enum>> must match plantumlStereoEnum')
assert(fg('plantumlStereoEnum') == '#ab9df2', 'Enum must use Monokai Pro purple (#ab9df2)')

assert(group_at(21, 28) == 'plantumlStereoInterface', '<<Interface>> must match plantumlStereoInterface')
assert(fg('plantumlStereoInterface') == '#ff61ae', 'Interface must use Monokai Pro pink (#ff61ae)')

-- 2. Domain Class Attributes and Types
-- _id: ObjectId
assert(group_at(6, 3) == 'plantumlDomainAttribute', 'Attribute name _id must match plantumlDomainAttribute')
assert(trans_at(6, 3) == 'Identifier', 'Attribute name must link to Identifier')
assert(group_at(6, 6) == 'plantumlDomainColon', 'Colon must match plantumlDomainColon')
assert(group_at(6, 8) == 'plantumlDomainType', 'ObjectId must match plantumlDomainType')
assert(trans_at(6, 8) == 'Type', 'Attribute type must link to Type')

-- email: string
assert(group_at(7, 3) == 'plantumlDomainAttribute', 'Attribute name email must match plantumlDomainAttribute')
assert(group_at(7, 10) == 'plantumlDomainType', 'string must match plantumlDomainType')

-- roles: UserRole[] (array type)
assert(group_at(8, 3) == 'plantumlDomainAttribute', 'Attribute name roles must match plantumlDomainAttribute')
assert(group_at(8, 11) == 'plantumlDomainType', 'UserRole[] must match plantumlDomainType')
assert(group_at(8, 19) == 'plantumlDomainType', 'Array brackets must be included in plantumlDomainType')

-- deleted_at: datetime? (optional type)
assert(group_at(9, 3) == 'plantumlDomainAttribute', 'Attribute name deleted_at must match plantumlDomainAttribute')
assert(group_at(9, 15) == 'plantumlDomainType', 'datetime? must match plantumlDomainType')
assert(group_at(9, 23) == 'plantumlDomainType', 'Question mark must be included in plantumlDomainType')

-- 3. Enum Blocks and Members
assert(group_at(16, 26) == 'plantumlEnum', 'Enum opening brace must match plantumlEnum')
assert(group_at(17, 4) == 'plantumlEnumMember', 'Enum member ACTIVE must match plantumlEnumMember')
assert(trans_at(17, 4) == 'Constant', 'Enum member must link to Constant')
assert(group_at(18, 4) == 'plantumlEnumMember', 'Enum member INACTIVE must match plantumlEnumMember')
assert(group_at(19, 1) == 'plantumlEnum', 'Enum closing brace must match plantumlEnum')

print('All plantuml domain model syntax checks passed successfully')
vim.cmd('qa!')
