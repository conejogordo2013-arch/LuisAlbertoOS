%ifndef LA_DESKTOP_ASM
%define LA_DESKTOP_ASM

desktop_prev_left dd 0

desktop_launch:
    mov esi, vga_regs_13h
    call vga_write_regs
    call graphics_init
    call evq_init
    call wm_init
    call taskbar_init
.loop:
    ; eventos mouse
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    shl ebx, 16
    and eax, 0xFFFF
    or ebx, eax
    mov eax, ev_mouse_move
    call evq_push

    mov eax, [mouse_buttons]
    and eax, 1
    mov ebx, [desktop_prev_left]
    mov [desktop_prev_left], eax
    xor edx, edx
    cmp eax, 1
    jne .btn
    cmp ebx, 0
    jne .btn
    mov edx, 1
.btn:
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    mov ecx, [mouse_buttons]
    and ecx, 1
    push edx
    call taskbar_handle_mouse
    pop edx
    call wm_handle_mouse

    mov al, 1
    call graphics_clear_backbuffer
    call taskbar_draw
    call start_menu_draw
    call wm_draw
    call mouse_cursor_draw
    call graphics_present

    ; salida ESC sin consumir AUX
    in al, 0x64
    test al, 1
    jz .wait
    test al, 0x20
    jnz .wait
    in al, 0x60
    cmp al, 0x01
    je .exit
.wait:
    hlt
    jmp .loop
.exit:
    mov esi, vga_regs_3h
    call vga_write_regs
    ret

%endif
