%ifndef LA_WINDOW_MANAGER_ASM
%define LA_WINDOW_MANAGER_ASM

wm_count          dd 1
wm_focused        dd 0
wm0_x             dd 40
wm0_y             dd 28
wm0_w             dd 200
wm0_h             dd 120
wm0_min           dd 0
wm0_drag          dd 0
wm_drag_off_x     dd 0
wm_drag_off_y     dd 0

wm_init:
    mov dword [wm_count], 1
    mov dword [wm_focused], 0
    mov dword [wm0_min], 0
    mov dword [wm0_drag], 0
    ret

wm_handle_mouse:
    ; eax=x ebx=y ecx=left_down edge in edx (1 click)
    cmp edx, 1
    jne .drag
    ; focus/title hit
    cmp eax, [wm0_x]
    jb .drag
    mov esi, [wm0_x]
    add esi, [wm0_w]
    cmp eax, esi
    ja .drag
    cmp ebx, [wm0_y]
    jb .drag
    mov esi, [wm0_y]
    add esi, 12
    cmp ebx, esi
    ja .check_min
    mov dword [wm_focused], 0
    mov dword [wm0_drag], 1
    mov esi, [wm0_x]
    mov [wm_drag_off_x], esi
    mov esi, [wm0_y]
    mov [wm_drag_off_y], esi
.check_min:
    ; minimizar
    mov esi, [wm0_x]
    add esi, [wm0_w]
    sub esi, 24
    cmp eax, esi
    jb .drag
    add esi, 10
    cmp eax, esi
    ja .check_close
    mov esi, [wm0_y]
    add esi, 2
    cmp ebx, esi
    jb .drag
    add esi, 8
    cmp ebx, esi
    ja .drag
    xor dword [wm0_min], 1
    ret
.check_close:
    ; cerrar
    mov esi, [wm0_x]
    add esi, [wm0_w]
    sub esi, 12
    cmp eax, esi
    jb .drag
    add esi, 10
    cmp eax, esi
    ja .drag
    mov dword [wm0_min], 1
.drag:
    cmp ecx, 1
    je .do_drag
    mov dword [wm0_drag], 0
    ret
.do_drag:
    cmp dword [wm0_drag], 1
    jne .ret
    mov esi, eax
    sub esi, 80
    cmp esi, 2
    jge .okx
    mov esi, 2
.okx:
    cmp esi, 118
    jle .setx
    mov esi, 118
.setx:
    mov [wm0_x], esi
    mov esi, ebx
    sub esi, 6
    cmp esi, 2
    jge .oky
    mov esi, 2
.oky:
    cmp esi, 140
    jle .sety
    mov esi, 140
.sety:
    mov [wm0_y], esi
.ret:
    ret

wm_draw:
    cmp dword [wm0_min], 1
    je .done
    mov eax, [wm0_x]
    mov ebx, [wm0_y]
    mov ecx, [wm0_w]
    mov edx, [wm0_h]
    mov esi, 7
    call graphics_fill_rect
    mov eax, [wm0_x]
    mov ebx, [wm0_y]
    mov ecx, [wm0_w]
    mov edx, 12
    mov esi, 4
    call graphics_fill_rect
.done:
    ret

%endif
