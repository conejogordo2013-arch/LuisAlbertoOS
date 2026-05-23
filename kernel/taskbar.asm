%ifndef LA_TASKBAR_ASM
%define LA_TASKBAR_ASM

tb_start_open dd 0

taskbar_init:
    mov dword [tb_start_open], 0
    ret

taskbar_handle_mouse:
    ; eax=x ebx=y edx=click_edge
    cmp edx, 1
    jne .ret
    cmp ebx, 188
    jb .close
    cmp eax, 4
    jb .close
    cmp eax, 52
    jbe .toggle
    cmp eax, 64
    jb .close
    cmp eax, 78
    jbe .open_hello
    cmp eax, 82
    jb .close
    cmp eax, 96
    jbe .open_text
    cmp eax, 100
    jb .close
    cmp eax, 114
    jbe .open_files
    jmp .close
.toggle:
    xor dword [tb_start_open],1
    ret
.open_hello:
    mov eax, 2
    call applications_launch
    mov dword [tb_start_open],0
    ret
.open_text:
    mov eax, 3
    call applications_launch
    mov dword [tb_start_open],0
    ret
.open_files:
    mov eax, 4
    call applications_launch
    mov dword [tb_start_open],0
    ret
.close:
    mov dword [tb_start_open], 0
.ret: ret

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
    ; accesos rápidos
    mov eax, 64
    mov ebx, 189
    mov ecx, 14
    mov edx, 10
    mov esi, 11
    call graphics_fill_rect
    mov eax, 82
    mov esi, 10
    call graphics_fill_rect
    mov eax, 100
    mov esi, 3
    call graphics_fill_rect
    ret

%endif
