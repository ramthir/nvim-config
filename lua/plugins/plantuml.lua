return {
  {
    'aklt/plantuml-syntax',
    -- Eager, not ft-triggered: g:markdown_fenced_languages needs
    -- syntax/plantuml.vim on the runtimepath *before* any markdown buffer's
    -- FileType event fires (see treesitter.lua, which routes markdown
    -- through the legacy :syntax engine specifically to support this).
    -- ft = { 'plantuml', 'markdown' } raced that same FileType event -
    -- when this plugin's lazy-load autocmd ran after treesitter.lua's,
    -- core markdown.vim's `syntax include syntax/plantuml.vim` fired before
    -- the plugin was on rtp, throwing E484.
    lazy = false,
    config = function()
      vim.filetype.add({
        extension = {
          puml = 'plantuml',
          plantuml = 'plantuml',
        },
      })
    end,
  },
}
