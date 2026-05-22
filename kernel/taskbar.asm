%ifndef LA_TASKBAR_ASM
%define LA_TASKBAR_ASM

tb_start_open dd 0

taskbar_init:
    mov dword [tb_start_open], 0
    ret

taskbar_handle_mouse:
    ; eax=x ebx=y edx=edge click
    cmp edx, 1
    jne .ret
    cmp ebx, 188
    jb .ret
    cmp eax, 4
    jb .close
    cmp eax, 52
    ja .close
    xor dword [tb_start_open], 1
    ret
.close:
    mov dword [tb_start_open], 0
.ret:
    ret

taskbar_draw:
    mov eax, 0
    mov ebx, 188
    mov ecx, 320
    mov edx, 12
    mov esi, 8
    call graphics_fill_rect
    mov eax, 4
    mov ebx, 189
    mov ecx, 48
    mov edx, 10
    mov esi, 2
    call graphics_fill_rect
    ret

%endif
