%ifndef LA_DESKTOP_ASM
%define LA_DESKTOP_ASM

desktop_prev_left dd 0
desktop_click_edge dd 0
desktop_wallpaper_inited dd 0
DESKTOP_WALLPAPER_BUF equ 0x00300000
DESKTOP_ICON_COUNT equ 7

desktop_drag_icon_id dd -1
desktop_drag_dx dd 0
desktop_drag_dy dd 0
desktop_drag_moved dd 0
desktop_icon_x dd 12, 12, 12, 12, 12, 12, 12
desktop_icon_y dd 18, 46, 74, 102, 130, 158, 170
desktop_icon_label0 db 'CMD.ELF',0
desktop_icon_label1 db 'NOTEPAD',0
desktop_icon_label2 db 'DEMO.ELF',0
desktop_icon_label3 db 'TXTEDIT',0
desktop_icon_label4 db 'FILES',0
desktop_icon_label5 db 'NOTES',0
desktop_icon_label6 db 'CMD',0
desktop_icon_labels dd desktop_icon_label0,desktop_icon_label1,desktop_icon_label2,desktop_icon_label3,desktop_icon_label4,desktop_icon_label5,desktop_icon_label6

desktop_launch:
    ; Garantizar IRQs activas al entrar al entorno gráfico.
    sti
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
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    mov ecx, [mouse_buttons]
    and ecx, 1
    mov edx, [desktop_click_edge]
    call desktop_icons_handle_mouse

    mov al, 1
    call graphics_clear_backbuffer
    call renderer_draw_desktop_bg
    call desktop_icons_draw
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
    cmp dword [desktop_should_exit], 1
    je .exit
    jmp .loop
.exit:
    mov esi, vga_regs_3h
    call vga_write_regs
    ret

desktop_icons_handle_mouse:
    ; eax=x ebx=y ecx=down edx=edge
    pushad
    cmp ecx, 1
    jne .release
    cmp dword [desktop_drag_icon_id], -1
    jne .drag
    cmp edx, 1
    jne .done
    call desktop_icons_find_hit
    cmp eax, -1
    je .done
    mov [desktop_drag_icon_id], eax
    mov dword [desktop_drag_moved], 0
    mov esi, eax
    mov edi, [desktop_icon_x+esi*4]
    mov ebp, [desktop_icon_y+esi*4]
    mov edx, [esp+28]
    sub edx, edi
    mov [desktop_drag_dx], edx
    mov edx, [esp+16]
    sub edx, ebp
    mov [desktop_drag_dy], edx
    jmp .done
.drag:
    mov esi, [desktop_drag_icon_id]
    mov edx, [esp+28]
    sub edx, [desktop_drag_dx]
    cmp edx, 2
    jge .dx_ok
    mov edx, 2
.dx_ok:
    cmp edx, 250
    jle .dx_ok2
    mov edx, 250
.dx_ok2:
    mov [desktop_icon_x+esi*4], edx
    mov edx, [esp+16]
    sub edx, [desktop_drag_dy]
    cmp edx, 2
    jge .dy_ok
    mov edx, 2
.dy_ok:
    cmp edx, 168
    jle .dy_ok2
    mov edx, 168
.dy_ok2:
    mov [desktop_icon_y+esi*4], edx
    mov dword [desktop_drag_moved], 1
    jmp .done
.release:
    cmp dword [desktop_drag_icon_id], -1
    je .done
    cmp edx, 1
    jne .clear
    cmp dword [desktop_drag_moved], 1
    je .clear
    mov eax, [desktop_drag_icon_id]
    call applications_launch
.clear:
    mov dword [desktop_drag_icon_id], -1
.done:
    popad
    ret

desktop_icons_find_hit:
    ; in eax=x ebx=y out eax=id/-1
    push ebx
    push ecx
    mov ecx, ebx
    mov ebx, eax
    xor eax, eax
.scan:
    cmp eax, DESKTOP_ICON_COUNT
    jae .miss
    mov edx, [desktop_icon_x+eax*4]
    cmp ebx, edx
    jl .n
    mov esi, edx
    add esi, 56
    cmp ebx, esi
    jg .n
    mov edx, [desktop_icon_y+eax*4]
    cmp ecx, edx
    jl .n
    mov esi, edx
    add esi, 22
    cmp ecx, esi
    jg .n
    jmp .out
.n: inc eax
    jmp .scan
.miss: mov eax, -1
.out:
    pop ecx
    pop ebx
    ret

desktop_icons_draw:
    pushad
    xor ebp, ebp
.l:
    cmp ebp, DESKTOP_ICON_COUNT
    jae .out
    mov eax, [desktop_icon_x+ebp*4]
    mov ebx, [desktop_icon_y+ebp*4]
    mov ecx, 12
    mov edx, 10
    mov edi, ebp
    cmp edi, 2
    je .elf
    cmp edi, 4
    je .file
    mov edi, 11
    jmp .draw_icon
.elf: mov edi, 12
    jmp .draw_icon
.file: mov edi, 14
.draw_icon:
    push ebp
    mov esi, edi
    call graphics_fill_rect
    pop ebp
    push ebp
    mov eax, [desktop_icon_x+ebp*4]
    add eax, 1
    mov ebx, [desktop_icon_y+ebp*4]
    add ebx, 2
    mov ecx, 4
    mov edx, 6
    mov esi, 15
    call graphics_fill_rect
    pop ebp
    push ebp
    mov eax, [desktop_icon_x+ebp*4]
    add eax, 6
    mov ebx, [desktop_icon_y+ebp*4]
    add ebx, 2
    mov ecx, 4
    mov edx, 6
    mov esi, 1
    call graphics_fill_rect
    pop ebp
    mov ecx, 54
    mov edx, 9
    mov esi, 1
    call graphics_fill_rect
    mov edi, [desktop_icon_labels+ebp*4]
    mov eax, [desktop_icon_x+ebp*4]
    add eax, 2
    mov ebx, [desktop_icon_y+ebp*4]
    add ebx, 12
    mov esi, edi
    mov edi, 15
    call gui_draw_text
    inc ebp
    jmp .l
.out:
    popad
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
