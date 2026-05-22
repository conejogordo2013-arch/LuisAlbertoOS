%ifndef LA_RENDERER_ASM
%define LA_RENDERER_ASM

renderer_draw_desktop_bg:
    mov eax, 0
    mov ebx, 0
    mov ecx, 320
    mov edx, 188
    mov esi, 1
    call graphics_fill_rect
    ; iconos
    mov eax, 10
    mov ebx, 12
    mov ecx, 14
    mov edx, 14
    mov esi, 11
    call graphics_fill_rect
    mov eax, 28
    mov ebx, 12
    mov ecx, 14
    mov edx, 14
    mov esi, 10
    call graphics_fill_rect
    ret

%endif
