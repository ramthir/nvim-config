" Core markdown.vim has no table support, so pipes and separator rows
" render as plain text. Gray them out to match the other delimiter styling
" in lua/core/autocmds.lua.
syn match markdownTablePipe "|"
syn match markdownTableRule "^\s*|\?\s*:\?-\+:\?\s*\(|\s*:\?-\+:\?\s*\)*|\?\s*$"

hi def link markdownTablePipe markdownTableDelimiter
hi def link markdownTableRule markdownTableDelimiter
