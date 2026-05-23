%ifndef LA_TASKBAR_ASM
%define LA_TASKBAR_ASM

tb_start_open dd 0
desktop_should_exit dd 0
txt_start db 'START',0
txt_cmd db 'CMD',0
txt_net_on db 'NET:ON',0
txt_net_off db 'NET:OFF',0
txt_aud_on db 'AUD:ON',0
txt_aud_off db 'AUD:OFF',0

taskbar_init:
    mov dword [tb_start_open], 0
    mov dword [desktop_should_exit], 0
    ret

taskbar_handle_mouse:
    ; eax=x ebx=y edx=click_edge
    cmp edx, 1
    jne .ret
    cmp ebx, 188
    jb .close
    cmp eax, 4
    jb .close
    cmp eax, 18
    jbe .open_terminal
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
.open_terminal:
    mov dword [desktop_should_exit], 1
    mov dword [tb_start_open],0
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
    ; boton terminal (verde)
    mov eax, 6
    mov ebx, 190
    mov ecx, 10
    mov edx, 8
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
    ; estado red/audio (indicadores)
    mov eax, 286
    mov ebx, 190
    mov ecx, 12
    mov edx, 8
    cmp dword [net_driver_available], 0
    je .net_off
    mov esi, 2
    jmp .net_draw
.net_off:
    mov esi, 4
.net_draw:
    call graphics_fill_rect
    mov eax, 302
    cmp dword [audio_driver_available], 0
    je .aud_off
    mov esi, 10
    jmp .aud_draw
.aud_off:
    mov esi, 12
.aud_draw:
    call graphics_fill_rect
    mov eax, 20
    mov ebx, 191
    mov esi, txt_start
    mov edi, 15
    call gui_draw_text
    mov eax, 6
    mov ebx, 191
    mov esi, txt_cmd
    mov edi, 0
    call gui_draw_text
    cmp dword [net_driver_available],0
    je .txt_net_off
    mov esi, txt_net_on
    jmp .txt_net_draw
.txt_net_off:
    mov esi, txt_net_off
.txt_net_draw:
    mov eax, 206
    mov ebx, 191
    mov edi, 15
    call gui_draw_text
    cmp dword [audio_driver_available],0
    je .txt_aud_off
    mov esi, txt_aud_on
    jmp .txt_aud_draw
.txt_aud_off:
    mov esi, txt_aud_off
.txt_aud_draw:
    mov eax, 254
    mov ebx, 191
    mov edi, 15
    call gui_draw_text
    ret

%endif
