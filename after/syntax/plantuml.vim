" Custom PlantUML syntax augmentations for domain models and Pandora diagrams.

" Stereotypes with colors matching Pandora's Monokai Pro theme:
" $orange: #fc9867 (Aggregate Root)
" $green:  #a9dc76 (Value Object)
" $purple: #ab9df2 (Enum)
" $pink:   #ff61ae (Interface)
syntax match plantumlStereoAggregateRoot /<<\s*Aggregate Root\s*>>/
syntax match plantumlStereoValueObject  /<<\s*Value Object\s*>>/
syntax match plantumlStereoEnum         /<<\s*Enum\s*>>/
syntax match plantumlStereoInterface    /<<\s*Interface\s*>>/

function! s:apply_plantuml_colors() abort
  if &background ==# 'light'
    highlight default plantumlStereoAggregateRoot guifg=#e16032 gui=bold ctermfg=166 cterm=bold
    highlight default plantumlStereoValueObject  guifg=#269d69 gui=bold ctermfg=29  cterm=bold
    highlight default plantumlStereoEnum         guifg=#7058be gui=bold ctermfg=98  cterm=bold
    highlight default plantumlStereoInterface    guifg=#e14775 gui=bold ctermfg=168 cterm=bold
  else
    highlight default plantumlStereoAggregateRoot guifg=#fc9867 gui=bold ctermfg=209 cterm=bold
    highlight default plantumlStereoValueObject  guifg=#a9dc76 gui=bold ctermfg=149 cterm=bold
    highlight default plantumlStereoEnum         guifg=#ab9df2 gui=bold ctermfg=141 cterm=bold
    highlight default plantumlStereoInterface    guifg=#ff61ae gui=bold ctermfg=205 cterm=bold
  endif
endfunction

call s:apply_plantuml_colors()

augroup PlantUMLColors
  autocmd!
  autocmd ColorScheme * call s:apply_plantuml_colors()
augroup END

" Domain model class attributes: name: type
syntax match plantumlDomainAttribute /^\s*\zs[A-Za-z_][A-Za-z0-9_]*\ze\s*:/ containedin=plantumlClass
syntax match plantumlDomainColon     /:/ containedin=plantumlClass
syntax match plantumlDomainType      /\(:\s*\)\@<=[A-Za-z0-9_?\[\]]\+/ containedin=plantumlClass

highlight default link plantumlDomainAttribute Identifier
highlight default link plantumlDomainColon     Delimiter
highlight default link plantumlDomainType      Type

" Domain model enum blocks and enum members
syntax region plantumlEnum
      \ start=/\%(enum\s[^{]\+\)\@<=\zs{/
      \ end=/^\s*}/
      \ contains=plantumlEnumMember,
      \          plantumlComment

syntax match plantumlEnumMember /^\s*\zs[A-Za-z0-9_]\+\ze\s*$/ contained
highlight default link plantumlEnumMember Constant
