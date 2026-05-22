%ifndef LA_START_MENU_ASM
%define LA_START_MENU_ASM

start_menu_draw:
    cmp dword [tb_start_open], 1
    jne .ret
    mov eax, 4
    mov ebx, 118
    mov ecx, 152
    mov edx, 70
    mov esi, 8
    call graphics_fill_rect
.ret:
    ret

%endif
