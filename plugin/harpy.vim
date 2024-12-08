if !has('vim9script') || v:version < 900
    finish
endif

vim9script

if get(g:, 'loaded_harpy', false)
  finish
endif
g:loaded_harpy = true

import autoload "../autoload/harpy.vim"

command! Harpy harpy.Run()
command! -nargs=? HarpyAdd harpy.Add(<f-args>)
