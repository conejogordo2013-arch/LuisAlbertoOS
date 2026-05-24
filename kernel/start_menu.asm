%ifndef LA_START_MENU_ASM
%define LA_START_MENU_ASM

sm_newfile_name db 'n.txt',0
sm_l0 db 'CMD.ELF',0
sm_l1 db 'NOTEPAD',0
sm_l2 db 'DEMO.ELF',0
sm_l3 db 'TXTEDIT',0
sm_l4 db 'FILES',0
sm_l5 db 'NOTES',0
sm_l6 db 'CMD',0
sm_l7 db 'NEWFILE',0
sm_l8 db 'REBOOT',0
sm_l9 db 'OFF',0

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
    cmp ebx,210
    ja .close
    ; launch apps
    cmp ebx,128
    jbe .app0
    cmp ebx,140
    jbe .app1
    cmp ebx,152
    jbe .app2
    cmp ebx,164
    jbe .app3
    cmp ebx,176
    jbe .app4
    cmp ebx,188
    jbe .app5
    cmp ebx,198
    jbe .app6
    cmp ebx,204
    jbe .mkfile
    cmp ebx,210
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
.app2: mov eax,2
    call applications_launch
    mov dword [tb_start_open],0
    ret
.app3: mov eax,3
    call applications_launch
    mov dword [tb_start_open],0
    ret
.app4: mov eax,4
    call applications_launch
    mov dword [tb_start_open],0
    ret
.app5: mov eax,5
    call applications_launch
    mov dword [tb_start_open],0
    ret
.app6: mov eax,6
    call applications_launch
    mov dword [tb_start_open],0
    ret
.mkfile:
    call start_menu_create_file
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
    mov edx, 98
    mov esi, 8
    call graphics_fill_rect
    mov eax, 10
    mov ebx, 122
    mov esi, sm_l0
    mov edi, 15
    call gui_draw_text
    mov ebx, 134
    mov esi, sm_l1
    call gui_draw_text
    mov ebx, 146
    mov esi, sm_l2
    call gui_draw_text
    mov ebx, 158
    mov esi, sm_l3
    call gui_draw_text
    mov ebx, 170
    mov esi, sm_l4
    call gui_draw_text
    mov ebx, 182
    mov esi, sm_l5
    call gui_draw_text
    mov ebx, 194
    mov esi, sm_l6
    call gui_draw_text
    mov ebx, 202
    mov esi, sm_l7
    call gui_draw_text
    mov eax, 86
    mov ebx, 208
    mov esi, sm_l8
    call gui_draw_text
    mov eax, 128
    mov esi, sm_l9
    call gui_draw_text
.ret: ret

start_menu_create_file:
    ; crea/asegura archivo new.txt en FS actual
    mov esi, sm_newfile_name
    mov al, 1
    call fs_create_file
    ret

%endif
