A BrainFuck Compiler Plugin for VIM

Brainfuck is an eight-instruction turing-complete programming language. I emplement a small Brainfuck interpreter in pure VIM script. It's based on VIM 8.1 and offers you a really simple playground for brainfuck language.

Install with Pathogen, execute the following commands:

    cd ~/.vim/bundle/
    git clone https://github.com/jayli/vim-brainfuck

Useage:

    :BrainFuck

For example, Copy this program to your vim editor and exec ":BrainFuck"

    ++++++++++[>+++++++>++++++++++>+++>+<<<<-]
    >++.>+.+++++++..+++.>++.<<+++++++++++++++.
    >.+++.------.--------.>+.>.

It will output "Hello World!".

More info about BrainFuck: <http://en.wikipedia.org/wiki/Brainfuck>
Other esoteric programming languages: <https://esolangs.org/wiki/Language_list>

(C) Jayli 2020
This programm is licensed under the terms of the
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE.
