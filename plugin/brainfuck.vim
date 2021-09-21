" File:         brainfuck.vim
" Author:       @jayli <http://jayli.github.io>
" Description:  init file

if version < 800
  finish
endif

if has( 'vim_starting' )
  command! -nargs=? BrainFuck call brainfuck#exec()
  autocmd BufRead,BufNewFile *.bf set filetype=css
endif
