
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

function! s:HasInputOperator(source_code)
    if index(str2list(a:source_code), 44) >= 0
        return 1
    else
        return 0
    endif
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
    " TODO here
    " 这里的加减方法应该是位的加减，比如0 - 1 = 255
    " https://www.jianshu.com/p/a7e7f2b26125
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
        " todo 这里需要更多测试
        if self.array[self.ptr] >= 255
            let self.array[self.ptr] = 0
        endif
    endfunction

    function Buf.decrement()
        let self.array[self.ptr] -= 1
        " todo 这里需要更多测试
        if self.array[self.ptr] < 0
            let self.array[self.ptr] = 255
        endif
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

    function Buf.log()
        " call s:log("Buffer Length: " . len(self.array))

        let buf_msg = "Buffer Array:  "
        let i = 0
        while i < len(self.array)
            if i == self.ptr
                let buf_msg = buf_msg . "*"
            endif
            let buf_msg = buf_msg . string(self.array[i])
            let buf_msg = buf_msg . " "
            let i += 1
        endwhile
        call s:log(buf_msg)
    endfunction


    function Buf.input(inputstream)
        call self.store(a:inputstream.get_one_input())
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

    function Program.log()
        let program_msg = "Program:". join(repeat([" "], 7),"")
        let i = 0
        while i < len(self.program)
            if i == self.pos
                let program_msg = program_msg . "(" . self.program[i] . ")"
            else
                let program_msg = program_msg . self.program[i]
            endif
            let i += 1
        endwhile
        call s:log(program_msg)
    endfunction

    return Program
endfunction

function! s:InitInputStream(source_code)
    let InputStream = {}
    let InputStream.source_code = a:source_code
    let InputStream.array = []
    let InputStream.cursor = 0

    function InputStream.input()
        if !s:HasInputOperator(self.source_code)
            return
        endif

        let ipt = input("Input: ")
        let self.array = str2list(ipt)
    endfunction

    function InputStream.get_one_input()
        if len(self.array) >= 1
            let val = self.array[0]
            let self.array = self.array[1:]
            return val
        else
            call self.input()
            return self.get_one_input()
        endif
    endfunction

    return InputStream

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
    let Interpreter.inputstream = s:InitInputStream(a:source_code)

    call Interpreter.inputstream.input() " TODO 这里注释掉，逻辑上应该没啥问题，但实际上输入提示符不显示，不知为何

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
        call self.buffer.input(self.inputstream)
    endfunction

    function Interpreter.handle_jump_forward()
        if self.buffer.current == 0
            let cursor = 1
            while cursor > 0
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
                call self.program.advance(-1)
                if self.program.current() == self.JUMP_BACKWARD
                    let cursor += 1
                elseif self.program.current() == self.JUMP_FORWARD
                    let cursor -= 1
                endif
            endwhile
        endif
    endfunction

    function Interpreter.log()
        call s:warning('====== Interpreter State ======')
        call self.program.log()
        call self.buffer.log()
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
            " call self.log()
            call self.program.advance(1)
        endwhile

        call self.log()

        call s:warning('====== EOF ======')
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
    exec "echon \"\nBuffer Length: \t". len(a:a) ."\n\""
    exec "echon \"Buffer Array: \t\""
    for i in a:a
        if type(i) == type(0) || type(i) == type("")
            exec "echon \"". i . "\""
            exec "echon \" \""
        endif
    endfor
endfunction
