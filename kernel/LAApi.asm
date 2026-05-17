%ifndef LAAPI_ASM
%define LAAPI_ASM

cursor_x dd 0
cursor_y dd 0

api_clear_screen:
    pusha
    cld
    mov edi, 0xB8000
    mov ecx, 80 * 25
    mov ax, 0x0720      ; 0x07 = Light gray on black, 0x20 = Space character
    rep stosw
    mov dword [cursor_x], 0
    mov dword [cursor_y], 0
    popa
    ret

api_scroll:
    pusha
    cld
    ; Move rows 1..24 to rows 0..23.
    mov esi, 0xB8000 + (80 * 2)
    mov edi, 0xB8000
    mov ecx, 80 * 24
    rep movsw

    ; Clear the last row.
    mov edi, 0xB8000 + (80 * 24 * 2)
    mov ecx, 80
    mov ax, 0x0720
    rep stosw
    mov dword [cursor_y], 24
    popa
    ret

api_newline:
    mov dword [cursor_x], 0
    inc dword [cursor_y]
    cmp dword [cursor_y], 25
    jl .done
    call api_scroll
.done:
    ret

api_print_string:
    pusha
.loop:
    lodsb
    cmp al, 0
    je .done
    cmp al, 0x0A        ; Handle Newline
    je .newline

    cmp dword [cursor_y], 25
    jl .position_ok
    call api_scroll
.position_ok:
    ; Calculate offset: (y * 80 + x) * 2
    mov eax, [cursor_y]
    imul eax, 80
    add eax, [cursor_x]
    imul eax, 2
    mov ebx, 0xB8000
    add ebx, eax

    mov al, [esi - 1]
    mov byte [ebx], al
    mov byte [ebx + 1], 0x0F ; White text

    inc dword [cursor_x]
    cmp dword [cursor_x], 80
    jl .loop
.newline:
    call api_newline
    jmp .loop
.done:
    popa
    ret


api_backspace:
    pusha
    cmp dword [cursor_x], 0
    jne .dec_x
    cmp dword [cursor_y], 0
    je .done
    dec dword [cursor_y]
    mov dword [cursor_x], 79
    jmp .erase
.dec_x:
    dec dword [cursor_x]
.erase:
    mov eax, [cursor_y]
    imul eax, 80
    add eax, [cursor_x]
    imul eax, 2
    mov ebx, 0xB8000
    add ebx, eax
    mov byte [ebx], 0x20
    mov byte [ebx + 1], 0x0F
.done:
    popa
    ret

api_delay:
    push ecx
    mov ecx, 0xFFFFF    ; Simple busy-wait loop
.delay_loop:
    nop
    loop .delay_loop
    pop ecx
    ret
%endif
