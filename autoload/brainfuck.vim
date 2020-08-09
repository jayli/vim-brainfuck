
" File:         autoload/easydebugger.vim
" Author:       @jayli <http://jayli.github.io>
" Description:  Event handler and plugin starting up
"
" brainfuck

function! brainfuck#exec()
    let Interpreter = s:InitInterpreter(s:GetSourceCode())
    call Interpreter.execute()
endfunction

function! s:ClearComment(line)
    let line = substitute(a:line,"\\(\/\/\\|\\w\\|\\#\\|\\*\\).\\+", "", "g")
    let line = substitute(line, "[^><+-.,\\[\\]]", "", "g")
    let line = trim(line)
    return line
endfunction

function! s:GetSourceCode()
    let sourcecode_list= []
    let lines = getbufline(bufnr(''), 1 ,"$")
    for line in lines
        if trim(line) == ""
            continue
        endif
        call add(sourcecode_list, substitute(s:ClearComment(line)," ","","g"))
    endfor
    return join(sourcecode_list, "")
endfunction

function! s:InitBuf()
    let Buf = {}
    let Buf.array = [0]
    let Buf.ptr = 0

    function Buf.move(n)
        let self.ptr += a:n
        call self.fullfill()
    endfunction

    function Buf.fullfill()
        if self.ptr >= len(self.array)
            let cursor = len(self.array)
            while cursor <= self.ptr
                call add(self.array, 0)
                let cursor += 1
            endwhile
        endif
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
        let self.array[self.ptr] = a:val
    endfunction

    function Buf.dump()
        return self.array[self.ptr]
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
        exec "echon \"" . nr2char(self.buffer.dump()) . "\""
    endfunction

    function Interpreter.handle_input_byte()
        " todo
        call self.buffer.input()
    endfunction

    function Interpreter.handle_jump_forward()
        if self.buffer.current == 0
            let cursor = 1
            while cursor > 0
                " call self.__dump_state()
                call self.program.advance(1)
                if self.program.current() == self.JUMP_FORWARD
                    let cursor += 1
                elseif self.program.current() == self.JUMP_BACKWARD
                    let cursor -= 1
                endif
            endwhile
        endif
    endfunction

    function Interpreter.handle_jump_backward()
        if self.buffer.current() != 0
            let cursor = 1
            while cursor != 0
                " call self.__dump_state()
                call self.program.advance(-1)
                if self.program.current() == self.JUMP_BACKWARD
                    let cursor += 1
                elseif self.program.current() == self.JUMP_FORWARD
                    let cursor -= 1
                endif
            endwhile
        endif
    endfunction

    function Interpreter.__dump_state()
        let t_array = deepcopy(self.buffer.array)
        let t_ptr = self.buffer.ptr
        let t_array[t_ptr] = "*" . string(t_array[t_ptr])
        call s:print_array(t_array)
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
            let current_opt = self.program.current()
            let Handler = get(op_handler, current_opt)
            call Handler()
            call self.program.advance(1)
        endwhile

        call self.__dump_state()
    endfunction

    return Interpreter
endfunction

function! s:log(msg)
    call s:msg(a:msg, "Question")
endfunction

" print warning msg {{{
function! s:warning(msg)
    return s:msg(a:msg, "WarningMsg")
endfunction "}}}

" EchoMsg {{{
function! s:msg(msg, style_group)
    exec "echohl " . a:style_group
    echom '>>> '. a:msg
    echohl NONE
    return a:msg
endfunction " }}}

function! s:print_array(a)
    exec "echon \"Buffer Length: \t". len(a:a) ."\n\""
    exec "echon \"Buffer Array: \t\""
    for i in a:a
        if type(i) == type(0) || type(i) == type("")
            exec "echon \"". i . "\""
            exec "echon \" \""
        endif
    endfor
endfunction
