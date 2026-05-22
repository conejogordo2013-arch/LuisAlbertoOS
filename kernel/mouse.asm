%ifndef LA_DESKTOP_MOUSE_ASM
%define LA_DESKTOP_MOUSE_ASM

mouse_init_gui:
    call mouse_init
    ret

mouse_irq_handler:
    ; wrapper: ISR real already calls mouse_irq_handle_byte in interrupts
    ret

mouse_update:
    ; state already updated in IRQ path
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
    imul edx, ebx, 320
    add edx, eax
    mov byte [GRAPH_BACKBUF + edx], 15
.ret:
    ret

%endif
