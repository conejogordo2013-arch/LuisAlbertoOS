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
    ; Drena SOLO bytes AUX (mouse). No mezclar con teclado:
    ; mezclar bytes de teclado aquí desincroniza paquetes y provoca
    ; movimiento/drag fantasma al presionar teclas.
.poll:
    in al, 0x64
    test al, 1
    jz .done
    test al, 0x20
    jz .done
    in al, 0x60
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
