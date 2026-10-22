" Custom PlantUML syntax augmentations for domain models and Pandora diagrams.

" Stereotypes with colors matching Pandora's Monokai Pro theme:
" $orange: #fc9867 (Aggregate Root)
" $green:  #a9dc76 (Value Object)
" $purple: #ab9df2 (Enum)
" $pink:   #ff61ae (Interface)
" $muted:  #939293 (Relationship link label, colons, attribute types)
syntax match plantumlStereoAggregateRoot /<<\s*Aggregate Root\s*>>/
syntax match plantumlStereoValueObject  /<<\s*Value Object\s*>>/
syntax match plantumlStereoEnum         /<<\s*Enum\s*>>/
syntax match plantumlStereoInterface    /<<\s*Interface\s*>>/

function! s:apply_plantuml_colors() abort
  if &background ==# 'light'
    highlight plantumlStereoAggregateRoot guifg=#e16032 gui=bold ctermfg=166 cterm=bold
    highlight plantumlStereoValueObject  guifg=#269d69 gui=bold ctermfg=29  cterm=bold
    highlight plantumlStereoEnum         guifg=#7058be gui=bold ctermfg=98  cterm=bold
    highlight plantumlStereoInterface    guifg=#e14775 gui=bold ctermfg=168 cterm=bold
    highlight plantumlDomainType         guifg=#706b6e ctermfg=243
    highlight plantumlDomainColon        guifg=#706b6e ctermfg=243
    highlight plantumlRelationshipLabel  guifg=#706b6e ctermfg=243
  else
    highlight plantumlStereoAggregateRoot guifg=#fc9867 gui=bold ctermfg=209 cterm=bold
    highlight plantumlStereoValueObject  guifg=#a9dc76 gui=bold ctermfg=149 cterm=bold
    highlight plantumlStereoEnum         guifg=#ab9df2 gui=bold ctermfg=141 cterm=bold
    highlight plantumlStereoInterface    guifg=#ff61ae gui=bold ctermfg=205 cterm=bold
    highlight plantumlDomainType         guifg=#939293 ctermfg=246
    highlight plantumlDomainColon        guifg=#939293 ctermfg=246
    highlight plantumlRelationshipLabel  guifg=#939293 ctermfg=246
  endif
endfunction

call s:apply_plantuml_colors()

augroup PlantUMLColors
  autocmd!
  autocmd ColorScheme * call s:apply_plantuml_colors()
augroup END

" Domain model class attributes: name: type
syntax match plantumlDomainAttribute /^\s*\zs[A-Za-z_][A-Za-z0-9_]*\ze\s*:/ contained containedin=plantumlClass
syntax match plantumlDomainColon     /:/ contained containedin=plantumlClass
syntax match plantumlDomainType      /\(:\s*\)\@<=[A-Za-z0-9_?\[\]]\+/ contained containedin=plantumlClass

highlight default link plantumlDomainAttribute Identifier
highlight default link plantumlDomainColon     Delimiter
highlight default link plantumlDomainType      Comment

" Relationship link labels (e.g. : sources, : index versions)
syntax match plantumlRelationshipLabel /\S\@<=\s*\zs:\s*.\+$/
highlight default link plantumlRelationshipLabel Comment

" Domain model enum blocks and enum members
syntax region plantumlEnum
      \ start=/\%(enum\s[^{]\+\)\@<=\zs{/
      \ end=/^\s*}/
      \ contains=plantumlEnumMember,
      \          plantumlComment

syntax match plantumlEnumMember /^\s*\zs[A-Za-z0-9_]\+\ze\s*$/ contained
highlight default link plantumlEnumMember Identifier
