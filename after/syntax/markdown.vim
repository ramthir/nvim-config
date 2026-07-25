" Core markdown.vim has no table support, so pipes and separator rows
" render as plain text. Gray them out to match the other delimiter styling
" in lua/core/autocmds.lua.
syn match markdownTablePipe "|"
syn match markdownTableRule "^\s*|\?\s*:\?-\+:\?\s*\(|\s*:\?-\+:\?\s*\)*|\?\s*$"

" Header row: any line directly followed by a separator row. Uses a
" zero-width lookahead so the separator line itself stays unconsumed and
" still matches markdownTableRule above.
syn match markdownTableHeader "^.\+|.*\%(\n\s*|\?\s*:\?-\+:\?\s*\%(|\s*:\?-\+:\?\s*\)*|\?\s*$\)\@=" contains=markdownTablePipe,markdownCode,markdownBold,markdownItalic

hi def link markdownTablePipe markdownTableDelimiter
hi def link markdownTableRule markdownTableDelimiter
