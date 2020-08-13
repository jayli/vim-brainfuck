" File:         autoload/brainfuck.vim
" Author:       @jayli <http://jayli.github.io>
" Description:  A Brainfuck Compiler for Vim

function! brainfuck#exec()
    let Interpreter = s:InitInterpreter()
    call Interpreter.execute()
endfunction

function! s:ClearComment(line)
    let line = trim(substitute(a:line,"\\(\/\/\\|\\w\\|\\#\\|\\*\\).\\+", "", "g"))
    return line
endfunction

function! s:GetSourceMapLine(line)
    let line = trim(substitute(a:line, "[^><+-.,\\[\\]$|]", "", "g"))
    return line
endfunction

function! s:HasInputOperator(source_code)
    return index(str2list(a:source_code), 44) >= 0 ? 1 : 0
endfunction

function! s:GetSourceMapCode()
    let sourcecode_list= []
    let lines = getbufline(bufnr(''), 1 ,"$")
    for line in lines
        if trim(line) == ""
            continue
        endif
        call add(sourcecode_list, substitute(s:GetSourceMapLine(s:ClearComment(line))," ","","g"))
    endfor
    return join(sourcecode_list, "")
endfunction

function! s:InitBuf()
    let Buf = {}
    let Buf.array = [0]
    let Buf.ptr = 0

    " ASCII   255
    " Unicode 65535
    let Buf.bit = 255

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
        if self.array[self.ptr] >= self.bit
            let self.array[self.ptr] = 0
        endif
    endfunction

    function Buf.decrement()
        let self.array[self.ptr] -= 1
        if self.array[self.ptr] < 0
            let self.array[self.ptr] = self.bit
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

" exclude: 排除干扰的字符
" include: 要记录的字符
" return:  返回要记录的字符位置的数组
function! s:GetMarkPositions(source_map_code, exclude, include)
    let t_source = substitute(a:source_map_code, a:exclude, "", "g")
    let cursor = 0
    let positions = []
    while cursor < len(t_source)
        if t_source[cursor] == a:include
            let positions += [cursor - len(positions)]
        endif
        let cursor += 1
    endwhile
    return positions
endfunction

function! s:GetDollorPositions(source_map_code)
    return s:GetMarkPositions(a:source_map_code, "|", "$")
endfunction

function! s:GetPipePositions(source_map_code)
    return s:GetMarkPositions(a:source_map_code, "$", "|")
endfunction

function! s:InitProgram(source_map_code)
    let Program = {}
    let Program.program_source_map = a:source_map_code
    let Program.program = substitute(a:source_map_code, "\\(\\$\\||\\)", "", "g")
    let Program.pos = 0

    function! Program.advance(n)
        let self.pos += a:n
        if self.pos < 0
            call s:waring("Buffer 回退越界: Program.pos < 0")
        endif
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

function! s:InitInputStream(source_map_code)
    let InputStream = {}
    let InputStream.source_code = substitute(a:source_map_code, "\\(\\$\\||\\)", "", "g")
    let InputStream.source_map_code = a:source_map_code
    let InputStream.array = []

    function InputStream.input()
        if !s:HasInputOperator(self.source_code)
            return
        endif

        let ipt = input("Input: ")
        let self.array = str2list(ipt)
        redraw
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

function! s:InitInterpreter()
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

    let source_map_code = s:GetSourceMapCode()
    let Interpreter.buffer = s:InitBuf()
    let Interpreter.program = s:InitProgram(source_map_code)
    let Interpreter.inputstream = s:InitInputStream(source_map_code)
    let Interpreter.dollor_positions = s:GetDollorPositions(source_map_code)
    let Interpreter.pipe_positions = s:GetPipePositions(source_map_code)

    function Interpreter.meet_dollor()
        return index(self.dollor_positions, self.program.pos + 1) > -1
    endfunction

    function Interpreter.meet_pipe()
        return index(self.pipe_positions, self.program.pos + 1) > -1
    endfunction

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
        echon "" . nr2char(self.buffer.dump())
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

        let g:kk = self.pipe_positions

        while !self.program.eof()
            let current_opt = self.program.current()
            let Handler = get(op_handler, current_opt)
            call Handler()
            if self.meet_dollor()
                call self.log()
                call s:debug('------ Meet Dollor: Stop ------')
                return
            endif
            if self.meet_pipe()
                call self.log()
                call s:debug('------  Meet Pipe: Log  ------')
            endif
            call self.program.advance(1)
        endwhile
    endfunction

    return Interpreter
endfunction

" Print logs
function! s:log(msg)
    call s:msg(a:msg, "Question")
endfunction

function! s:debug(msg)
    call s:msg(a:msg, "Title")
endfunction

function! s:warning(msg)
    return s:msg(a:msg, "WarningMsg")
endfunction

function! s:msg(msg, style_group)
    exec "echohl " . a:style_group
    echom '>>> '. a:msg
    echohl NONE
    return a:msg
endfunction
