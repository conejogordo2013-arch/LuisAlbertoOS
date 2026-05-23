%ifndef LA_DESKTOP_ASM
%define LA_DESKTOP_ASM

desktop_prev_left dd 0
desktop_click_edge dd 0
desktop_wallpaper_inited dd 0
DESKTOP_WALLPAPER_BUF equ 0x00300000

desktop_launch:
    mov esi, vga_regs_13h
    call vga_write_regs
    call graphics_init
    call evq_init
    call keyboard_init
    call mouse_init_gui
    call wm_init
    call desktop_wallpaper_init
    call taskbar_init
    call applications_init
    mov esi, desktop_title
    mov eax, 40
    mov ebx, 26
    mov ecx, 190
    mov edx, 120
    call window_create
.loop:
    call mouse_update
    call keyboard_update

    mov dword [desktop_click_edge], 0
    mov eax, [mouse_buttons]
    and eax, 1
    mov ebx, [desktop_prev_left]
    mov [desktop_prev_left], eax
    xor edx, edx
    cmp eax, ebx
    je .noedge
    cmp eax, 1
    jne .up
    mov eax, EVENT_MOUSE_DOWN
    jmp .pushm
.up: mov eax, EVENT_MOUSE_UP
.pushm:
    mov ecx, [mouse_y]
    shl ecx, 16
    mov ebx, [mouse_x]
    and ebx, 0xFFFF
    or ebx, ecx
    call evq_push
    mov edx, 1
    mov dword [desktop_click_edge], 1
.noedge:
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    mov ecx, [mouse_buttons]
    and ecx, 1
    call wm_handle_mouse
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    mov edx, [desktop_click_edge]
    call taskbar_handle_mouse
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    mov edx, [desktop_click_edge]
    call start_menu_handle_mouse

    mov al, 1
    call graphics_clear_backbuffer
    call renderer_draw_desktop_bg
    call wm_draw
    call taskbar_draw
    call start_menu_draw
    call mouse_cursor_draw
    call graphics_present

    in al, 0x64
    test al, 1
    jz .w
    test al, 0x20
    jnz .w
    in al, 0x60
    cmp al, 0x01
    je .exit
.w: hlt
    jmp .loop
.exit:
    mov esi, vga_regs_3h
    call vga_write_regs
    ret

desktop_title db 'Desktop',0

desktop_wallpaper_init:
    cmp dword [desktop_wallpaper_inited], 1
    je .done
    mov edi, DESKTOP_WALLPAPER_BUF
    xor ebx, ebx                    ; y
.row:
    cmp ebx, 188
    jge .set
    xor eax, eax                    ; x
.col:
    cmp eax, 320
    jge .next_row
    mov edx, eax
    shr edx, 4
    mov ecx, ebx
    shr ecx, 4
    xor edx, ecx
    and edx, 1
    cmp edx, 0
    jne .c2
    mov dl, 1
    jmp .st
.c2:
    mov dl, 3
.st:
    mov [edi], dl
    inc edi
    inc eax
    jmp .col
.next_row:
    inc ebx
    jmp .row
.set:
    mov esi, DESKTOP_WALLPAPER_BUF
    call renderer_set_wallpaper_raw
    mov dword [desktop_wallpaper_inited], 1
.done:
    ret
%endif
