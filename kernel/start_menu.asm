%ifndef LA_START_MENU_ASM
%define LA_START_MENU_ASM

start_menu_handle_mouse:
    ; eax=x ebx=y edx=click
    cmp dword [tb_start_open],1
    jne .r
    cmp edx,1
    jne .r
    cmp eax,4
    jb .close
    cmp eax,156
    ja .close
    cmp ebx,118
    jb .close
    cmp ebx,186
    ja .close
    ; launch apps
    cmp ebx,138
    jbe .app0
    cmp ebx,150
    jbe .app1
    cmp ebx,174
    jbe .reboot
    jmp .shutdown
.app0: mov eax,0
    call applications_launch
    mov dword [tb_start_open],0
    ret
.app1: mov eax,1
    call applications_launch
    mov dword [tb_start_open],0
    ret
.reboot:
    mov al,0xFE
    out 0x64,al
    ret
.shutdown:
    cli
.h: hlt
    jmp .h
.close:
    mov dword [tb_start_open],0
.r: ret

start_menu_draw:
    cmp dword [tb_start_open], 1
    jne .ret
    mov eax, 4
    mov ebx, 118
    mov ecx, 152
    mov edx, 70
    mov esi, 8
    call graphics_fill_rect
.ret: ret

%endif
