%ifndef LA_DESKTOP_MOUSE_ASM
%define LA_DESKTOP_MOUSE_ASM

mouse_poll_idle_frames dd 0

mouse_init_gui:
    call mouse_init
    mov dword [mouse_poll_idle_frames], 0
    ret

mouse_irq_handler:
    ; wrapper: ISR real already calls mouse_irq_handle_byte in interrupts
    ret

mouse_update:
    ; Fallback robusto: drena bytes pendientes por polling en cada frame.
    ; Algunos emuladores no marcan siempre AUX(bit5) aunque sí entregan bytes
    ; válidos de mouse; aceptamos ambos caminos para no “congelar” el cursor.
.poll:
    in al, 0x64
    test al, 1
    jz .done
    mov ah, al
    in al, 0x60
    test ah, 0x20
    jnz .feed
    ; Si AUX no está marcado, aún así intentamos sincronizar paquete PS/2:
    ; sólo tratamos como primer byte si trae bit3=1.
    mov ebx, [mouse_byte_index]
    cmp ebx, 0
    jne .feed
    test al, 0x08
    jz .done
.feed:
    call mouse_irq_handle_byte
    jmp .poll
.done:
    ; Si el init de mouse falla (mouse_ready=0), reintentar periódicamente.
    cmp dword [mouse_ready], 0
    jne .ret_done
    inc dword [mouse_poll_idle_frames]
    cmp dword [mouse_poll_idle_frames], 180
    jb .ret_done
    call mouse_init
    mov dword [mouse_poll_idle_frames], 0
.ret_done:
    ret

mouse_cursor_draw:
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    cmp eax, 0
    jl .ret
    cmp eax, 319
    jg .ret
    cmp ebx, 0
    jl .ret
    cmp ebx, 199
    jg .ret
    ; cursor tipo cruz para mejor visibilidad
    imul edx, ebx, 320
    add edx, eax
    mov byte [GRAPH_BACKBUF + edx], 15
    cmp eax, 1
    jl .ret
    cmp eax, 318
    jg .ret
    cmp ebx, 1
    jl .ret
    cmp ebx, 198
    jg .ret
    mov edi, edx
    dec edi
    mov byte [GRAPH_BACKBUF + edi], 15
    mov edi, edx
    inc edi
    mov byte [GRAPH_BACKBUF + edi], 15
    mov edi, edx
    sub edi, 320
    mov byte [GRAPH_BACKBUF + edi], 15
    mov edi, edx
    add edi, 320
    mov byte [GRAPH_BACKBUF + edi], 15
.ret:
    ret

%endif
