" File:         easydebugger.vim
" Author:       @jayli <http://jayli.github.io>
" Description:  init file
"
"               more infomation: <https://github.com/jayli/vim-easydebugger>
"
" ╦  ╦┬┌┬┐  ╔═╗┌─┐┌─┐┬ ┬╔╦╗┌─┐┌┐ ┬ ┬┌─┐┌─┐┌─┐┬─┐
" ╚╗╔╝││││  ║╣ ├─┤└─┐└┬┘ ║║├┤ ├┴┐│ ││ ┬│ ┬├┤ ├┬┘
"  ╚╝ ┴┴ ┴  ╚═╝┴ ┴└─┘ ┴ ═╩╝└─┘└─┘└─┘└─┘└─┘└─┘┴└─

let g:brainfuck_init = 1

if version < 800
    finish
endif

if has( 'vim_starting' )
    command! -nargs=0 -complete=command BrainFuck call brainfuck#exec()
    autocmd BufRead,BufNewFile *.bf set filetype=text
endif
