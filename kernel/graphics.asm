%ifndef LA_GRAPHICS_ASM
%define LA_GRAPHICS_ASM

GRAPH_VRAM       equ 0xA0000
GRAPH_WIDTH      equ 320
GRAPH_HEIGHT     equ 200
GRAPH_PIXELS     equ GRAPH_WIDTH*GRAPH_HEIGHT

GRAPH_BACKBUF    equ 0x80000
gfx_dirty_all    dd 1
gfx_color_tmp    db 0

graphics_init:
    mov dword [gfx_dirty_all], 1
    ret

graphics_clear_backbuffer:
    ; AL = color
    push edi
    push ecx
    mov edi, GRAPH_BACKBUF
    mov ecx, GRAPH_PIXELS
    rep stosb
    pop ecx
    pop edi
    ret

graphics_fill_rect:
    ; eax=x ebx=y ecx=w edx=h esi=color
    pushad
    cmp ecx, 0
    jle .done
    cmp edx, 0
    jle .done
    cmp eax, 0
    jl .done
    cmp ebx, 0
    jl .done
    mov edi, ebx
    imul edi, GRAPH_WIDTH
    add edi, eax
    add edi, GRAPH_BACKBUF
    mov eax, esi
    mov [gfx_color_tmp], al
    mov ebp, edx
.row:
    push ebp
    mov al, [gfx_color_tmp]
    mov ebp, ecx
.col:
    mov [edi], al
    inc edi
    dec ebp
    jnz .col
    mov ebp, GRAPH_WIDTH
    sub ebp, ecx
    add edi, ebp
    pop ebp
    dec ebp
    jnz .row
.done:
    popad
    ret

graphics_draw_pixel:
    ; eax=x ebx=y esi=color
    pushad
    cmp eax, 0
    jl .done
    cmp ebx, 0
    jl .done
    cmp eax, GRAPH_WIDTH
    jge .done
    cmp ebx, GRAPH_HEIGHT
    jge .done
    mov eax, esi
    mov [gfx_color_tmp], al
    mov edi, ebx
    imul edi, GRAPH_WIDTH
    add edi, eax
    add edi, GRAPH_BACKBUF
    mov al, byte [gfx_color_tmp]
    mov [edi], al
.done:
    popad
    ret

graphics_present:
    ; Copia completa al VRAM (doble buffer simple y estable)
    pushad
    call vga_wait_vsync
    mov esi, GRAPH_BACKBUF
    mov edi, GRAPH_VRAM
    mov ecx, GRAPH_PIXELS/4
    rep movsd
    popad
    ret

%endif
