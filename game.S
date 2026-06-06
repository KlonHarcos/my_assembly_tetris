.global game_run


.equ C_EMPTY, 0
.equ C_RED, 1
.equ C_GREEN, 2
.equ C_YELLOW, 3
.equ C_BLUE, 4
.equ C_PURPLE, 5
.equ C_TEAL, 6
.equ C_WHITE, 7
.equ C_FALLING, 10
.equ C_LEFT_GUARD, 8
.equ C_RIGHT_GUARD, 9
.equ real_line_len, 12

.equ up_arrow, 0x103
.equ down_arrow, 0x102
.equ left_arrow, 0x104
.equ right_arrow, 0x105



.equ GRID_SIZE, 288
.equ HIDDEN_GRID_SIZE, 48

.equ line_clear_bonus, 40
.equ drop_bonus, 1
.equ tetris_size_mul, 2




############ TWEAK ME ########
.equ MAX_SPEED,        800000
.equ SPEED_INCREMENT,   30000
.equ BASE_GAME_SPEED, 2000000
.equ COYOTE_TIME,     1000000
##############################

.bss
# [unitialized static variables]
ghost_grid:
    .skip GRID_SIZE
kernel_pointer:
    .skip 8
falling_holder:
    .skip 32
tick_counter:
    .skip 8
game_speed:
    .skip 8
high_score:
    .skip 8
current_score:
    .skip 8

.data
################ TWEAK ME #################
    tick_speed: .quad 0, 500              #
    anim_delay: .quad 0, 50000000         #
  

    









    grid:
        .rept 24          
        .byte 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9   # The sequence to repeat
        .endr            # End of the repeat block
    O:  .long 0x00000000, 0x00000000, 0x000a0a00, 0x000a0a00
    I:  .long 0x00000a00, 0x00000a00, 0x00000a00, 0x00000a00
    Z:  .long 0x00000000, 0x00000000, 0x00000a0a, 0x000a0a00
    S:  .long 0x00000000, 0x00000000, 0x0a0a0000, 0x000a0a00
    J:  .long 0x00000000, 0x000a0000, 0x000a0000, 0x000a0a00
    L:  .long 0x00000000, 0x00000a00, 0x00000a00, 0x000a0a00
    T:  .long 0x00000000, 0x00000000, 0x000a0a0a, 0x00000a00
    falling_color: .byte 2
    store_bool: .byte 0
    tile_storage: .byte -1
    game_state: .byte 1
    storage_space:  .rept 4         
                    .byte 8, 0, 0, 0, 0, 9   # The sequence to repeat
                    .endr
.text

    print_string:
        .asciz "  "
    endl_string:
        .asciz "|\n"
    begin_line_string:
        .asciz "|"
    point_string:
        .asciz "OO"
    dummy_print_string:
        .asciz "%c"
    dummy_endl_string:
        .asciz "%c\n"
    game_over_text:
        .asciz "GAME OVER press R to try again"
    paused_text:
        .asciz "GAME PAUSED press q to exit"
    bottom_line_text:
        .asciz "======================\n"
    score_string:
        .ascii "SCORE: %ld       BEST: %ld\n"
        .ascii "CONTROLS: \n"
        .asciz "Q: pause C: change UP: rotate\n"
    
    


game_run:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    call game_setup

   
    loop:

    cmpb $2, game_state(%rip)
    je pause_state
    cmpb $0, game_state(%rip)
    je game_over_screen


    leaq tick_speed(%rip), %rax
    movq 8(%rax), %rax
    addq %rax, tick_counter(%rip)

    call game_loop
    


    # sleep for tick_speed time
    leaq tick_speed(%rip), %rdi 
    mov   $35, %eax  
    xor   %esi, %esi
    syscall

    movq game_speed(%rip), %rax
    cmpq tick_counter(%rip), %rax
    jg loop
        call drop_tile
        movq $0, tick_counter(%rip)
    jmp loop
    loop_exit:

    
    ############# GAME PAUSED ###############
    pause_state:
    movq stdscr(%rip), %rdi
    movq $0, %rsi
    call nodelay

    movq stdscr(%rip), %rdi
    leaq paused_text(%rip), %rsi
    xorq %rax, %rax
    call wprintw
    call refresh

    call getch

    cmpq $'q', %rax
    je game_run_ep

    movq stdscr(%rip), %rdi
    movq $1, %rsi
    call nodelay

    movb $1, game_state(%rip)
    jmp loop



    ############# GAME OVER ###############
    game_over_screen:
    movq stdscr(%rip), %rdi
    movq $0, %rsi
    call nodelay

    movq current_score(%rip), %rax
    cmpq high_score(%rip), %rax
    jng print_game_over

        movq %rax, high_score(%rip)

    print_game_over:
    movq stdscr(%rip), %rdi
    leaq game_over_text(%rip), %rsi
    xorq %rax, %rax
    call wprintw
    call refresh

    get_input_again:
    call getch
    cmpq $'r', %rax
    jne get_input_again

    call game_setup
    jmp loop



    


    game_run_ep:
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

game_setup:

    pushq %rbp
    movq %rsp, %rbp


    ## turn delay off ##### 
    movq stdscr(%rip), %rdi
    movq $1, %rsi
    call nodelay

    movq $0, current_score(%rip)

    movb $1, game_state(%rip)
    movq $0, tick_counter(%rip)

    movq $BASE_GAME_SPEED, game_speed(%rip)

    call init_rand

    call clear_grid
    
    
    //xorq %rdi, %rdi
    movq $7, %rdi
    call load_tile

    
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


game_loop:

    pushq %rbp
    movq %rsp, %rbp
    
    call handle_input
    

    call print_grid
    
    call print_storage

    call print_score

    //call debug_print

    call refresh

    
    

    
    
    game_loop_epilogue:
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

print_grid:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp

    call erase

    
    ## uncomment to hide buffer rows:
    movq $HIDDEN_GRID_SIZE, -16(%rbp)
    incq -16(%rbp)
    print_loop:
        cmpq $GRID_SIZE, -16(%rbp)
        je print_loop_exit

        
        
        ###############load base color print begining line###############
        movq stdscr(%rip), %rdi
        movq $0x0100, %rsi
        xorq %rax, %rax
        call wattron
        movq stdscr(%rip), %rdi
        leaq begin_line_string(%rip), %rsi
        xorq %rax, %rax
        call wprintw

        print_loop_inner:
            leaq grid(%rip), %rsi
            xorq %rdi, %rdi
            movq -16(%rbp), %rcx
            movb (%rsi, %rcx), %dil

            cmpb $C_RIGHT_GUARD, %dil
            je print_loop_inner_exit

            cmpb $C_LEFT_GUARD, %dil
            je print_loop_guard_next

            cmpb $C_FALLING, %dil
            jne assign_as_is
                movb falling_color(%rip), %dil
            
            assign_as_is:
            movq %rdi, %rsi


            #### TURNS COLOR ON ####
            incq %rsi
            shl $8, %rsi
            movq stdscr(%rip), %rdi
            call wattron

            #### PRINTS COLORED STRING ###
            ###DEBUG CODE###################
            //leaq grid(%rip), %rsi           #
            //xorq %rdi, %rdi                 #
            //movq -16(%rbp), %rcx            #
            //leaq (%rsi, %rcx), %rax         #
            //cmpq kernel_pointer(%rip), %rax #
            //movq stdscr(%rip), %rdi
            //leaq point_string(%rip), %rsi
            //je debug_jmp                    #
            ################################
             
            movq stdscr(%rip), %rdi
            leaq print_string(%rip), %rsi
            debug_jmp:
            xorq %rax, %rax
            call wprintw

            print_loop_guard_next:
            
            incq -16(%rbp)
            jmp print_loop_inner
        print_loop_inner_exit:

        
        movq stdscr(%rip), %rdi
        movq $0x0100, %rsi
        xorq %rax, %rax
        call wattron
        incq -16(%rbp)
        movq stdscr(%rip), %rdi
        leaq endl_string(%rip), %rsi
        xorq %rax, %rax
        call wprintw

        jmp print_loop
    print_loop_exit:


    movq stdscr(%rip), %rdi
    leaq bottom_line_text(%rip), %rsi
    xorq %rax, %rax
    call wprintw
    
    
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret



    

drop_tile:
    pushq %rbp
    movq %rsp, %rbp

   

    #### check for falling pieces in the bottom row ####
    call check_sticky

    leaq grid(%rip), %r9
    addq $GRID_SIZE, %r9
    decq %r9

    leaq grid(%rip), %rdx
    addq $9, %rdx # dont check in first row
    drop_loop:
    cmpq %r9, %rdx
    je drop_loop_bake

    cmpb $C_EMPTY, (%r9)
    jne non_empty_field
    cmpb $C_FALLING, -real_line_len(%r9)
    jne next_drop_loop
        movb $C_FALLING, (%r9)
        movb $C_EMPTY, -real_line_len(%r9)
        jmp next_drop_loop
    non_empty_field:
    
    
    next_drop_loop:
    decq %r9
    jmp drop_loop
    drop_loop_bake:
    //call bake_ghost
    drop_loop_no_bake:

    leaq grid(%rip), %rdx
    movb $C_EMPTY, 1(%rdx)
    movb $C_EMPTY, 2(%rdx)
    movb $C_EMPTY, 3(%rdx)
    movb $C_EMPTY, 4(%rdx)
    movb $C_EMPTY, 5(%rdx)
    movb $C_EMPTY, 6(%rdx)
    movb $C_EMPTY, 7(%rdx)
    movb $C_EMPTY, 8(%rdx)
    movb $C_EMPTY, 9(%rdx)
    movb $C_EMPTY, 10(%rdx)

    addq $real_line_len, kernel_pointer(%rip)
    

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

check_sticky:
    pushq %rbp
    movq %rsp, %rbp


    leaq grid(%rip), %rdx
    addq $GRID_SIZE, %rdx # load last element
    decq %rdx

    cmpb $C_FALLING, -1(%rdx)
    je stick_falling
    cmpb $C_FALLING, -2(%rdx)
    je stick_falling
    cmpb $C_FALLING, -3(%rdx)
    je stick_falling
    cmpb $C_FALLING, -4(%rdx)
    je stick_falling
    cmpb $C_FALLING, -5(%rdx)
    je stick_falling
    cmpb $C_FALLING, -6(%rdx)
    je stick_falling
    cmpb $C_FALLING, -7(%rdx)
    je stick_falling
    cmpb $C_FALLING, -8(%rdx)
    je stick_falling
    cmpb $C_FALLING, -9(%rdx)
    je stick_falling
    cmpb $C_FALLING, -10(%rdx)
    je stick_falling
    
    leaq grid(%rip), %rdx
    movq $0, %r9
    movq $GRID_SIZE, %r8
    subq $real_line_len, %r8 #dont check last row as it reaches beyond boundary
    l0:
        cmpq $GRID_SIZE, %r9
        je stick_ep

        cmpb $C_FALLING, (%rdx, %r9)
        jne l0_next

            cmpb $C_EMPTY, real_line_len(%rdx, %r9)
            je l0_next
            cmpb $C_FALLING, real_line_len(%rdx, %r9)
            je l0_next

                jmp stick_falling


        l0_next:
        incq %r9
        jmp l0


    stick_falling:
        leaq grid(%rip), %r8
        movq $0, %r9
        l1:
            cmpq $GRID_SIZE, %r9
            je l1_out

            cmpb $C_FALLING, (%r8, %r9)
            jne l1_next
                movb falling_color(%rip), %al
                movb %al, (%r8, %r9)

            l1_next:
            incq %r9
            jmp l1
        l1_out:
        call tetris
        movb $0, store_bool(%rip)
        call game_over_check
        xorq %rdi, %rdi
        call load_tile

            call increase_speed
        

    stick_ep:
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

handle_input:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    call getch
    movq %rax, -8(%rbp)

    
    cmpq $left_arrow, %rax
    je shift_left
    
    cmpq $right_arrow, %rax
    je shift_right
    
    cmpq $down_arrow, %rax
    je drop
    
    cmpq $up_arrow, %rax
    je turn_tile
    
    cmpq $'q', %rax
    je quit
    
    cmpq $'Q', %rax
    je quit

    cmpq $'c', %rax
    je store

    cmpq $'C', %rax
    je store

    movb $0, %al
    jmp input_handler_ep

    shift_left:
        call shift_left_func
        call coyote_time_handler
    jmp input_handler_ep
    shift_right:
        call shift_right_func
        call coyote_time_handler
    jmp input_handler_ep
    drop:
        call drop_tile
        addq $drop_bonus, current_score(%rip)
    jmp input_handler_ep
    turn_tile:
        call rotate_tile_func
        call coyote_time_handler
    jmp input_handler_ep
    quit:
        movb $2, game_state(%rip)
    jmp input_handler_ep
    store:
        call store_tile
    jmp input_handler_ep
    
        

    jmp input_handler_ep

    input_handler_ep:
    movq %rbp, %rsp
    popq %rbp
ret

coyote_time_handler:
    pushq %rbp
    movq %rsp, %rbp

    
    subq $COYOTE_TIME, tick_counter(%rip)

    cmpq $0, tick_counter(%rip)
    jg coyote_ep

        movq $0, tick_counter(%rip)

    coyote_ep:
    movq %rbp, %rsp
    popq %rbp
ret

shift_left_func:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    
    call init_ghost
    
    leaq ghost_grid(%rip), %r8
    movq $0, %r9
    loop_left:
    cmpq $GRID_SIZE, %r9
    je loop_left_bake

    #check if the bit to the left should be shifted (meaning it is fallin if not go next loop)
    movb 1(%r8, %r9), %dil
    cmpb $C_FALLING, %dil
    jne loop_left_next

    movb (%r8, %r9), %sil
    cmpb $C_EMPTY, %sil
    jne loop_left_no_bake
    
    movb $C_FALLING, (%r8, %r9)
    movb $C_EMPTY, 1(%r8, %r9)

    
    loop_left_next:
    incq %r9
    jmp loop_left
    loop_left_bake:
    call bake_ghost
    subq $1, kernel_pointer(%rip)
    loop_left_no_bake:

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

shift_right_func:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    
    call init_ghost
    
    leaq ghost_grid(%rip), %r8
    movq $GRID_SIZE, %r9
    loop_right:
    cmpq $0, %r9
    je loop_right_bake

    #check if the bit to the left should be shifted (meaning it is fallin if not go next loop)
    movb -1(%r8, %r9), %dil
    cmpb $C_FALLING, %dil
    jne loop_right_next

    movb (%r8, %r9), %sil
    cmpb $C_EMPTY, %sil
    jne loop_right_no_bake
    
    movb $C_FALLING, (%r8, %r9)
    movb $C_EMPTY, -1(%r8, %r9)

    
    loop_right_next:
    decq %r9
    jmp loop_right
    loop_right_bake:
    call bake_ghost
    addq $1, kernel_pointer(%rip)
    loop_right_no_bake:



    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


init_ghost:
    pushq %rbp
    movq %rsp, %rbp


    leaq ghost_grid(%rip), %r8
    leaq grid(%rip), %r9
    xorq %rcx, %rcx
    i_ghost_loop:
    cmpq $GRID_SIZE, %rcx
    je i_ghost_loop_exit
    movb (%r9, %rcx), %al
    movb %al, (%r8, %rcx)
    incq %rcx
    jmp i_ghost_loop
    i_ghost_loop_exit:



    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


bake_ghost:
    pushq %rbp
    movq %rsp, %rbp

    leaq ghost_grid(%rip), %r9
    leaq grid(%rip), %r8
    xorq %rcx, %rcx
    b_ghost_loop:
    cmpq $GRID_SIZE, %rcx
    je b_ghost_loop_exit
    movb (%r9, %rcx), %al
    movb %al, (%r8, %rcx)
    incq %rcx
    jmp b_ghost_loop
    b_ghost_loop_exit:

    movq %rbp, %rsp
    popq %rbp
ret


tetris:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp

    movq $0, -32(%rbp)
    movq $0, -24(%rbp)

    leaq grid(%rip), %r8
    movq %r8, -8(%rbp)
    movq %r8, %r9
    addq $GRID_SIZE, %r9
    movq %r9, -16(%rbp)
    l3:
    movq -8(%rbp), %r8
    movq -16(%rbp), %r9
    cmpq %r8, %r9
    jle l3_exit
    
    
    movq %r8, %rdi
    call is_full_row
    testq %rax, %rax
    jz l3_next 

        movq %r8, %rdi
        call clear_row

        addq $line_clear_bonus, -24(%rbp)
        addq $tetris_size_mul, -32(%rbp)


        call anim
        call collapse_board
        call anim

        //call increase_speed
    l3_next:
    addq $real_line_len, -8(%rbp)
    jmp l3
    l3_exit:

    ############ add score ########
    movq -24(%rbp), %rax
    imulq -32(%rbp), %rax
    addq %rax, current_score(%rip)
    #################################

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

collapse_board:
    pushq %rbp
    movq %rsp, %rbp

    leaq grid(%rip), %r8
    addq $GRID_SIZE, %r8
    subq $real_line_len, %r8
    l4:
    leaq grid(%rip), %rax
    cmpq %rax, %r8
    jle l4_exit
    
    ### check if row is empty go to next row if it is not
    movq %r8, %rdi
    call is_empty_row
    testq %rax, %rax
    je full_false

        
        ### move all rows one down
        movq %r8, %rcx
        l5:
            leaq grid(%rip), %rax
            cmpq %rcx, %rax
            je l5_exit
            
            movq %rcx, %rsi
            movq %rcx, %rdi
            subq $real_line_len, %rdi
            call copy_row

            subq $real_line_len, %rcx
            jmp l5
        l5_exit:

        leaq grid(%rip), %rdi
        call clear_row
    full_false:
    subq $real_line_len, %r8
    jmp l4
    l4_exit:

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

clear_grid:
    pushq %rbp
    movq %rsp, %rbp


    leaq grid(%rip), %rdi

    movq $0, %rcx
    l11:
    cmpq $GRID_SIZE, %rcx
    je l11_exit
    
    cmpb $C_LEFT_GUARD, (%rdi, %rcx)
    je l11_next
    cmpb $C_RIGHT_GUARD, (%rdi, %rcx)
    je l11_next

        movb $C_EMPTY, (%rdi, %rcx)
    l11_next:
    incq  %rcx
    jmp l11
    l11_exit:
    
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


clear_row:
    pushq %rbp
    movq %rsp, %rbp


    movb $C_EMPTY, 1(%rdi)
    movb $C_EMPTY, 2(%rdi)
    movb $C_EMPTY, 3(%rdi)
    movb $C_EMPTY, 4(%rdi)
    movb $C_EMPTY, 5(%rdi)
    movb $C_EMPTY, 6(%rdi)
    movb $C_EMPTY, 7(%rdi)
    movb $C_EMPTY, 8(%rdi)
    movb $C_EMPTY, 9(%rdi)
    movb $C_EMPTY, 10(%rdi)
    
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

is_empty_row:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax

    cmpb $C_EMPTY, 1(%rdi)
    jne is_empty_ep
    movb 1(%rdi), %al
    cmpb $C_EMPTY, 2(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 3(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 4(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 5(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 6(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 7(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 8(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 9(%rdi)
    jne is_empty_ep
    cmpb $C_EMPTY, 10(%rdi)
    jne is_empty_ep

    movq $1, %rax

    is_empty_ep:
    movq %rbp, %rsp
    popq %rbp
ret

is_full_row:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax

    cmpb $C_EMPTY, 1(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 2(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 3(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 4(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 5(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 6(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 7(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 8(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 9(%rdi)
    je is_full_ep
    cmpb $C_EMPTY, 10(%rdi)
    je is_full_ep

    movq $1, %rax

    is_full_ep:
    movq %rbp, %rsp
    popq %rbp
ret

# from row rdi to rsi
copy_row:
    pushq %rbp
    movq %rsp, %rbp

    movb 1(%rdi), %al
    movb %al, 1(%rsi)
    movb 2(%rdi), %al
    movb %al, 2(%rsi)
    movb 3(%rdi), %al
    movb %al, 3(%rsi)
    movb 4(%rdi), %al
    movb %al, 4(%rsi)
    movb 5(%rdi), %al
    movb %al, 5(%rsi)
    movb 6(%rdi), %al
    movb %al, 6(%rsi)
    movb 7(%rdi), %al
    movb %al, 7(%rsi)
    movb 8(%rdi), %al
    movb %al, 8(%rsi)
    movb 9(%rdi), %al
    movb %al, 9(%rsi)
    movb 10(%rdi), %al
    movb %al, 10(%rsi)
    
    
    
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


anim:
    pushq %rbp
    movq %rsp, %rbp

    # sleep for tick_speed time
    leaq anim_delay(%rip), %rdi    #the time structure we just pushed
    mov   $35, %eax  
    xor   %esi, %esi
    syscall

    call print_grid
    
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


load_tile:
    pushq %rbp
    movq %rsp, %rbp

    cmpb $0, %dil
    je get_rand

    movb %dil, falling_color(%rip)
    jmp color_loaded

    get_rand:
    call get_rand_tile
    movb %al, falling_color(%rip)
    jmp color_loaded

    color_loaded:
    cmpb $C_RED, falling_color(%rip)
    je load_Z
    cmpb $C_YELLOW, falling_color(%rip)
    je load_O
    cmpb $C_BLUE, falling_color(%rip)
    je load_J
    cmpb $C_GREEN, falling_color(%rip)
    je load_S
    cmpb $C_WHITE, falling_color(%rip)
    je load_I
    cmpb $C_TEAL, falling_color(%rip)
    je load_L
    cmpb $C_PURPLE, falling_color(%rip)
    je load_T


    load_Z:
    leaq Z(%rip), %rax
    jmp load_set
    load_O:
    leaq O(%rip), %rax
    jmp load_set
    load_J:
    leaq J(%rip), %rax
    jmp load_set
    load_S:
    leaq S(%rip), %rax
    jmp load_set
    load_I:
    leaq I(%rip), %rax
    jmp load_set
    load_L:
    leaq L(%rip), %rax
    jmp load_set
    load_T:
    leaq T(%rip), %rax
    jmp load_set


    load_set:
    leaq grid(%rip), %rcx

    movq %rcx, kernel_pointer(%rip)
    addq $29, kernel_pointer(%rip)

    movl (%rax), %edi
    movl %edi, 4(%rcx)
    
    movl 4(%rax), %edi
    movl %edi, 16(%rcx)
    
    movl 8(%rax), %edi
    movl %edi, 28(%rcx)
    
    movl 12(%rax), %edi
    movl %edi, 40(%rcx)
    

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


init_rand:
    pushq %rbp
    movq %rsp, %rbp
    
    
    movq $0, %rdi
    call time
    movq %rax, %rdi
    call srand

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

get_rand_tile:
    pushq %rbp
    movq %rsp, %rbp

    call rand
    xorq %rdx, %rdx
    movq $7, %rcx
    idivq %rcx
    movq %rdx, %rax
    incq %rax

    movq %rbp, %rsp
    popq %rbp
ret


rotate_tile_func:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    ### CHECK IF ITS O BLOCK ###
    cmpb $C_YELLOW, falling_color(%rip)
    je rotate_tile_ep


    movq kernel_pointer(%rip), %rax
    #### FIND FALLING BLOCKS 
    leaq -25(%rax), %r8 # load first kernel position into the 
    movq $0, %r9
    leaq falling_holder(%rip), %r10 #pointer to falling holder
    # fill holder with bad values to catch errors
    movq $65793, (%r10)
    movq $65793, 8(%r10)
    movq $65793, 16(%r10)
    movq $65793, 24(%r10)
    l6:
    cmpq $40, %r9 # between -25 and +14 theres 39 numbers
    je l6_exit
    
    cmpb $C_FALLING, (%r8, %r9)
    jne l6_next
        leaq (%r8, %r9), %rcx
        subq kernel_pointer(%rip), %rcx

        cmpq $-25, %rcx
        je case_n25
        cmpq $-24, %rcx
        je case_n24
        cmpq $-23, %rcx
        je case_n23
        cmpq $-22, %rcx
        je case_n22
        cmpq $-13, %rcx
        je case_n13
        cmpq $-12, %rcx
        je case_n12
        cmpq $-11, %rcx
        je case_n11
        cmpq $-10, %rcx
        je case_n10
        cmpq $-1, %rcx
        je case_n1
        cmpq $0, %rcx
        je case_0
        cmpq $1, %rcx
        je case_1
        cmpq $2, %rcx
        je case_2
        cmpq $11, %rcx
        je case_11
        cmpq $12, %rcx
        je case_12
        cmpq $13, %rcx
        je case_13
        cmpq $14, %rcx
        je case_14
        
        xorq %rax, %rax

        case_n25:
        movq $-22, (%r10)
        jmp case_added
        case_n24:
        movq $-10, (%r10)
        jmp case_added
        case_n23:
        movq $2, (%r10)
        jmp case_added
        case_n22:
        movq $14, (%r10)
        jmp case_added
        case_n13:
        movq $-23, (%r10)
        jmp case_added
        case_n12:
        movq $-11, (%r10)
        jmp case_added
        case_n11:
        movq $1, (%r10)
        jmp case_added
        case_n10:
        movq $13, (%r10)
        jmp case_added
        case_n1:
        movq $-24, (%r10)
        jmp case_added
        case_0:
        movq $-12, (%r10)
        jmp case_added
        case_1:
        movq $0, (%r10)
        jmp case_added
        case_2:
        movq $12, (%r10)
        jmp case_added
        case_11:
        movq $-25, (%r10)
        jmp case_added
        case_12:
        movq $-13, (%r10)
        jmp case_added
        case_13:
        movq $-1, (%r10)
        jmp case_added
        case_14:
        movq $11, (%r10)
        jmp case_added
        
        case_added:
        addq $8, %r10
    l6_next:
    incq %r9
    jmp l6
    l6_exit:


    call init_ghost



    ############ CLEAR FALLING FROM GHOST #####################
    leaq ghost_grid(%rip), %rdi                               #
    call clear_falling                                        #
    ###########################################################




    #### calculate kernel pointer at ghost
    movq kernel_pointer(%rip), %rax
    leaq grid(%rip), %rdx
    subq %rdx, %rax
    leaq ghost_grid(%rip), %r8
    addq %rax, %r8 # r8 = ghost grid kernel pointer
    movq %r8, -8(%rbp)
    #############



    
    movq -8(%rbp), %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success

    
    movq -8(%rbp), %rdi
    incq %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success

    movq -8(%rbp), %rdi
    incq %rdi
    incq %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success
    
    movq -8(%rbp), %rdi
    decq %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success

    movq -8(%rbp), %rdi
    decq %rdi
    decq %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success


    
    movq -8(%rbp), %rax
    subq $real_line_len, %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success

    movq -8(%rbp), %rdi
    subq $real_line_len, %rdi
    decq %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success

    movq -8(%rbp), %rdi
    subq $real_line_len, %rdi
    incq %rdi
    pushq %rdi
    call check_for_fit
    testq %rax, %rax
    jnz placement_success
    

    jmp rotate_tile_ep

    placement_success:
        leaq falling_holder(%rip), %rcx

        /*
        movq (%rcx), %r11
        movq 8(%rcx), %r12
        movq 16(%rcx), %r13
        movq 24(%rcx), %rbx
        */
        popq %rax
        
        #shift kernel pointer to new position
        movq %rax, %rdx
        
        leaq ghost_grid(%rip), %r8
        subq %r8, %rdx
        
        leaq grid(%rip), %r8
        addq %r8, %rdx
        movq %rdx, kernel_pointer(%rip)
        
        //movq -8(%rbp), %r11
        movq %rax, -8(%rbp)

        movq (%rcx), %rax
        addq -8(%rbp), %rax
        movb $C_FALLING, (%rax)
        movq 8(%rcx), %rax
        addq -8(%rbp), %rax
        movb $C_FALLING, (%rax)
        movq 16(%rcx), %rax
        addq -8(%rbp), %rax
        movb $C_FALLING, (%rax)
        movq 24(%rcx), %rax
        addq -8(%rbp), %rax
        movb $C_FALLING, (%rax)



        call bake_ghost



    rotate_tile_ep:
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


check_for_fit:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    movq %rdi, -8(%rbp)

    leaq ghost_grid(%rip), %rax
    

    leaq falling_holder(%rip), %rcx
    l8:
        leaq falling_holder(%rip), %rax
        addq $32, %rax
        cmpq %rcx, %rax
        je fit_true



        movq -8(%rbp), %rax
        addq (%rcx), %rax

        leaq ghost_grid(%rip), %rdx
        addq $GRID_SIZE, %rdx
        cmpq %rax, %rdx
        jle fit_false

        cmpb $C_EMPTY, (%rax)
        je l8_next
             

            jmp fit_false

    l8_next:
    addq $8, %rcx
    jmp l8

    fit_false:
    movq $0, %rax
    jmp fit_ep
    fit_true:
    movq $1, %rax
    fit_ep:
    movq %rbp, %rsp
    popq %rbp
ret

store_tile:
    pushq %rbp
    movq %rsp, %rbp

    cmpb $1, store_bool(%rip)
    je store_tile_ep


    leaq grid(%rip), %rdi
    call clear_falling

    

    cmpb $-1, tile_storage(%rip)
    je tile_storage_empty

        jmp tile_storage_non_empty


    
    tile_storage_empty:
        movb falling_color(%rip), %cl
        movb %cl, tile_storage(%rip)

        
        xorq %rdi, %rdi
        call load_tile
    jmp store_tile_ep


    tile_storage_non_empty:
        xorq %rdi, %rdi
        movb tile_storage(%rip), %dil

        movb falling_color(%rip), %cl
        movb %cl, tile_storage(%rip)


        call load_tile

    jmp store_tile_ep



    
    

    store_tile_ep:

    movb $1, store_bool(%rip)
    
    
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


debug_print:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp

    //call erase

    movq $0, -16(%rbp)
    debug_print_loop:
        cmpq $GRID_SIZE, -16(%rbp)
        movq -16(%rbp), %rax
        je debug_print_loop_exit

        debug_print_loop_inner:
            leaq grid(%rip), %rsi
            xorq %rdi, %rdi
            movq -16(%rbp), %rcx
            movb (%rsi, %rcx), %dil

            cmpb $C_RIGHT_GUARD, %dil
            je debug_print_loop_inner_exit

            //cmpb $C_LEFT_GUARD, %dil
            //je debug_print_loop_guard_next

            cmpb $C_FALLING, %dil
            jne debug_assign_as_is
                movb falling_color(%rip), %dil
            
            debug_assign_as_is:
            movq %rdi, %rsi
            movq %rdi, %rdx
            addq $0x30, %rdx

            movq stdscr(%rip), %rdi
            leaq dummy_print_string(%rip), %rsi

            debug_debug_jmp:
            xorq %rax, %rax
            call wprintw

            debug_print_loop_guard_next:
            incq -16(%rbp)
            jmp debug_print_loop_inner
        debug_print_loop_inner_exit:
        incq -16(%rbp)
        movq stdscr(%rip), %rdi
        leaq dummy_endl_string(%rip), %rsi
        movq $57, %rdx
        xorq %rax, %rax
        call wprintw

        jmp debug_print_loop
    debug_print_loop_exit:
    
    call refresh

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


clear_falling:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    movq %rdi, -8(%rbp)

    movq $0, %rcx
    l9:
    cmpq $GRID_SIZE, %rcx
    je l9_exit

    cmpb $C_FALLING, (%rdi, %rcx)
    jne l9_next

        movb $C_EMPTY, (%rdi, %rcx)

    l9_next:
    incq %rcx
    jmp l9
    l9_exit:


    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret

game_over_check:
    pushq %rbp
    movq %rsp, %rbp

    leaq grid(%rip), %rax
    movq $0, %rcx
    l7:
    cmpq $HIDDEN_GRID_SIZE, %rcx
    je game_over_ep

        cmpb $C_EMPTY, (%rax, %rcx)
        je l7_next

        cmpb $C_FALLING, (%rax, %rcx)
        je l7_next

        cmpb $C_LEFT_GUARD, (%rax, %rcx)
        je l7_next

        cmpb $C_RIGHT_GUARD, (%rax, %rcx)
        je l7_next

            jmp game_over_true

    l7_next:
    incq %rcx
    jmp l7

    game_over_true:
    movb $0, game_state(%rip)

    game_over_ep:
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


print_storage:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp

    cmpb $-1, tile_storage(%rip)
    je s_load_EMPTY
    cmpb $C_RED, tile_storage(%rip)
    je s_load_Z
    cmpb $C_YELLOW, tile_storage(%rip)
    je s_load_O
    cmpb $C_BLUE, tile_storage(%rip)
    je s_load_J
    cmpb $C_GREEN, tile_storage(%rip)
    je s_load_S
    cmpb $C_WHITE, tile_storage(%rip)
    je s_load_I
    cmpb $C_TEAL, tile_storage(%rip)
    je s_load_L
    cmpb $C_PURPLE, tile_storage(%rip)
    je s_load_T


    s_load_Z:
    leaq Z(%rip), %rax
    jmp s_load_set
    s_load_O:
    leaq O(%rip), %rax
    jmp s_load_set
    s_load_J:
    leaq J(%rip), %rax
    jmp s_load_set
    s_load_S:
    leaq S(%rip), %rax
    jmp s_load_set
    s_load_I:
    leaq I(%rip), %rax
    jmp s_load_set
    s_load_L:
    leaq L(%rip), %rax
    jmp s_load_set
    s_load_T:
    leaq T(%rip), %rax
    jmp s_load_set
    
    


    s_load_set:
    leaq storage_space(%rip), %rcx


    movl (%rax), %edi
    movl %edi, 1(%rcx)
    
    movl 4(%rax), %edi
    movl %edi, 7(%rcx)
    
    movl 8(%rax), %edi
    movl %edi, 13(%rcx)
    
    movl 12(%rax), %edi
    movl %edi, 19(%rcx)

    jmp s_loop_setup

    s_load_EMPTY:
    leaq storage_space(%rip), %rcx

    movl $0, 1(%rcx)
    
    movl $0, 7(%rcx)

    movl $0, 13(%rcx)

    movl $0, 19(%rcx)


    s_loop_setup:
   
    movq $0, -16(%rbp) 
    storage_print_loop:
        cmpq $24, -16(%rbp)
        je storage_print_loop_exit

        storage_print_loop_inner:
            leaq storage_space(%rip), %rsi
            xorq %rdi, %rdi
            movq -16(%rbp), %rcx
            movb (%rsi, %rcx), %dil

            cmpb $C_RIGHT_GUARD, %dil
            je storage_print_loop_inner_exit

            cmpb $C_LEFT_GUARD, %dil
            je storage_print_loop_guard_next

            movq %rdi, %rsi

            cmpb $C_FALLING, %sil
            jne s_turn_color_on

                movb tile_storage(%rip), %sil

            s_turn_color_on:
            #### TURNS COLOR ON ####
            incq %rsi
            shl $8, %rsi
            movq stdscr(%rip), %rdi
            call wattron
            #### PRINTS COLORED STRING ###
            movq stdscr(%rip), %rdi
            leaq print_string(%rip), %rsi
            xorq %rax, %rax
            call wprintw

            storage_print_loop_guard_next:
            incq -16(%rbp)
            jmp storage_print_loop_inner
        storage_print_loop_inner_exit:
        
        
        
        movq stdscr(%rip), %rdi
        movq $0x0100, %rsi
        xorq %rax, %rax
        call wattron
        
        
        incq -16(%rbp)
        movq stdscr(%rip), %rdi
        leaq endl_string(%rip), %rsi
        xorq %rax, %rax
        call wprintw

        jmp storage_print_loop
    storage_print_loop_exit:

    print_storage_ep:
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


print_score:
    pushq %rbp
    movq %rsp, %rbp

    
    movq stdscr(%rip), %rdi
    leaq score_string(%rip), %rsi
    movq current_score(%rip), %rdx
    movq high_score(%rip), %rcx
    xorq %rax, %rax
    call wprintw

    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret


increase_speed:
    pushq %rbp
    movq %rsp, %rbp

    cmpq $MAX_SPEED, game_speed(%rip)
    jle inc_speed_ep

        subq $SPEED_INCREMENT, game_speed(%rip)


    inc_speed_ep:
    xorq %rax, %rax
    movq %rbp, %rsp
    popq %rbp
ret