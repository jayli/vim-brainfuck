
" File:         autoload/easydebugger.vim
" Author:       @jayli <http://jayli.github.io>
" Description:  Event handler and plugin starting up
"
" brainfuck


function! brainfuck#exec()
    call s:log("bf ok")
    let Interpreter = s:InitInterpreter(s:get_sourcecode())
    call Interpreter.execute()
endfunction

" A more robust trim function {{{
function! brainfuck#trim(str)
    if !empty(a:str)
        let a1 = substitute(a:str, "^\\s\\+\\(.\\{\-}\\)$","\\1","g")
        let a1 = substitute(a:str, "^\\(.\\{\-}\\)\\s\\+$","\\1","g")
        return a1
    endif
    return ""
endfunction "}}}

function! s:get_sourcecode()
    let sourcecode_list= []
    let lines = getbufline(bufnr(''), 1 ,"$")
    for line in lines
        if brainfuck#trim(line) == ""
            continue
        endif
        call add(sourcecode_list, brainfuck#trim(split(line,'//')[0]))
    endfor
    return join(sourcecode_list, "")
endfunction

function! s:InitBuf()
    let Buf = {}
    let Buf.array = [0]
    let Buf.ptr = 0

    function Buf.move(n)
        let n = empty(a:n) ? a:n : 0
        let self.ptr += n
    endfunction

    function Buf.increment()
        let self.array[self.ptr] += 1
    endfunction

    function Buf.decrement()
        let self.array[self.ptr] -= 1
    endfunction

    function Buf.current()
        return self.array[self.ptr]
    endfunction

    function Buf.store(val)
        let self.array[self.ptr] = val
    endfunction

    function Buf.dump(start, end)
        let start = empty(a:start) ? self.ptr : a:start
        let end = empty(a:end) ? 1 : a:end
        if start > self.ptr
            call s:warning('数组越界')
        endif
        return self.array[start:end]
    endfunction

    function Buf.str()
        return "ptr: " . self.ptr . " , value:" . self.current()
    endfunction

    function Buf.input()
        let ipt = input("")
        if ipt == "" || len(ipt) > 1
            call s:warning("输入为空或者大于一个字符")
            finish
        endif
        call self.store(ipt)
    endfunction

    return Buf
endfunction

function! s:InitProgram(source_code)
    let Program = {}
    let Program.program = a:source_code
    let Program.pos = 0

    function! Program.advance(n)
        let self.pos += a:n
    endfunction

    function Program.current()
        return self.program[self.pos]
    endfunction

    function Program.eof()
        call s:log(56)
        return self.pos == len(self.program)
    endfunction

    function Program.str()
        return "pos: " . self.pos . " , op:" . self.current()
    endfunction

    return Program
endfunction

function! brainfuck#interpreter(source_code)
    return s:InitInterpreter(a:source_code)
endfunction


function! s:InitInterpreter(source_code)

    let Interpreter = {
        \   "INC_PTR"        : ">",
        \   "DEC_PTR"        : "<",
        \   "INC_BYTE"       : "+",
        \   "DEC_BYTE"       : "-",
        \   "OUTPUT_BYTE"    : ".",
        \   "INPUT_BYTE"     : ",",
        \   "JUMP_FORWARD"   : "[",
        \   "JUMP_BACKWARD"  : "]"
        \ }

    let Interpreter.buffer = s:InitBuf()
    let Interpreter.program = s:InitProgram(a:source_code)


    function Interpreter.handle_inc_ptr()
        call self.buffer.move(1)
    endfunction

    function Interpreter.handle_dec_ptr()
        call self.buffer.move(-1)
    endfunction

    function Interpreter.handle_inc_byte()
        call self.buffer.increment()
    endfunction

    function Interpreter.handle_dec_byte()
        call self.buffer.decrement()
    endfunction

    function Interpreter.handle_output_byte()
        call execute("echon \"" . self.buffer.dump() ."\"")
    endfunction

    function Interpreter.handle_input_byte()
        " todo
    endfunction

    function Interpreter.handle_jump_forward()
        if self.buffer.current == 0
            let count = 1
            while count > 0
                call self.__dump_state("__handle_jump_forward: (count : ". count .")")
                call self.program.advance(1)
                if self.program.current() == self.JUMP_FORWARD
                    let count += 1
                elseif self.program.current() == self.JUMP_BACKWARD
                    let count -= 1
                endif
            endwhile
        endif
    endfunction

    function Interpreter.handle_jump_backward()
        if self.buffer.current() ！= 0
            let count = 1
            while count != 0
                call self.__dump_state("__handle_jump_backward: (count : ". count .")")
                call self.program.advance(-1)
                if self.program.current() == self.JUMP_BACKWARD
                    let count += 1
                elseif self.program.current() == self.JUMP_FORWARD
                    let count -= 1
                endif
            endwhile
        endif
    endfunction

    function Interpreter.__dump_state(msg)
        call s:log(string(self.buffer.dump(0,10)))
        " echon a:msg
    endfunction

    function Interpreter.execute()
        let op_handler = {}
        let op_handler[self.INC_PTR]       = self.handle_inc_ptr
        let op_handler[self.DEC_PTR]       = self.handle_dec_ptr
        let op_handler[self.INC_BYTE]      = self.handle_inc_byte
        let op_handler[self.DEC_BYTE]      = self.handle_dec_byte
        let op_handler[self.OUTPUT_BYTE]   = self.handle_output_byte
        let op_handler[self.INPUT_BYTE]    = self.handle_input_byte
        let op_handler[self.JUMP_FORWARD]  = self.handle_jump_forward
        let op_handler[self.JUMP_BACKWARD] = self.handle_jump_backward
        
        let g:kk = self

        while !self.program.eof()
            " call self.__dump_state("execute:")

            let Handler = get(op_handler, self.program.current())
            call Handler()
            call self.program.advance(1)
            call s:log(self.program.pos)
        endwhile
    endfunction

    call s:log(a:source_code)
    return Interpreter
endfunction


function! s:log(msg)
    call s:msg(a:msg, "Question")
endfunction

" print warning msg {{{
function! s:waring(msg)
    return s:msg(a:msg, "WarningMsg")
endfunction "}}}

" EchoMsg {{{
function! s:msg(msg, style_group)
    exec "echohl " . a:style_group
    echom '>>> '. a:msg
    echohl NONE
    return a:msg
endfunction " }}}
