##### THIS PROJECT IS BASED ON NCURSE, BASED ON THE FOLLOWING SOURCES #######
# 
# little explaination on ncurse
# https://hackaday.com/2025/06/17/a-gentle-introduction-to-ncurses-for-the-terminally-impatient/
#
# C program using ncurse to make snake
# https://github.com/kwsp/Snake
#
#################################################################################





.global main

.equ up_arrow, 0x103
.equ down_arrow, 0x102
.equ left_arrow, 0x104
.equ right_arrow, 0x105


.bss
# [unitialized static variables]

x: .skip 8

y: .skip 8


.data
# [initialized static variables]
    //tick_speed: .quad $0, $500 
.text
   
    hw:
      .asciz "hello world\n"


main:

pushq %rbp
movq %rsp, %rbp
subq $16, %rsp

	call initscr           // init screen
	call start_color        // enable colours
	call noecho             // don't display keypresses
	call cbreak

	movq stdscr(%rip), %rdi
	movq $1, %rsi
	call nodelay

	movq stdscr(%rip), %rdi
	movq $1, %rsi
	call keypad

	movq $0, %rdi
	call curs_set

call refresh


# curses colors:
# https://www.linuxjournal.com/content/about-ncurses-colors-0

call start_color
movq $1, %rdi
movq $7, %rsi
movq $0, %rdx
call init_pair
movq $2, %rdi
movq $1, %rsi
movq $1, %rdx
call init_pair
movq $3, %rdi
movq $2, %rsi
movq $2, %rdx
call init_pair
movq $4, %rdi
movq $3, %rsi
movq $3, %rdx
call init_pair
movq $5, %rdi
movq $4, %rsi
movq $4, %rdx
call init_pair
movq $6, %rdi
movq $5, %rsi
movq $5, %rdx
call init_pair
movq $7, %rdi
movq $6, %rsi
movq $6, %rdx
call init_pair
movq $8, %rdi
movq $7, %rsi
movq $7, %rdx
call init_pair




call game_run

/*
loopy:
call getch
push %rax
movq %rax, %rbx
call erase
pop  %rdi
call echochar
call refresh
jmp loopy
*/
call endwin
xorq %rax, %rax
movq %rbp, %rsp
popq %rbp
ret





