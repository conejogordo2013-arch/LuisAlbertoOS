%ifndef LA_DESKTOP_MOUSE_ASM
%define LA_DESKTOP_MOUSE_ASM

mouse_cursor_draw:
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    cmp eax, 1
    jb .ret
    cmp eax, 318
    ja .ret
    cmp ebx, 1
    jb .ret
    cmp ebx, 198
    ja .ret
    imul edx, ebx, 320
    add edx, eax
    mov byte [GRAPH_BACKBUF + edx], 15
.ret:
    ret

%endif
