%ifndef LA_DESKTOP_KEYBOARD_ASM
%define LA_DESKTOP_KEYBOARD_ASM

kbd_flags_shift   dd 0
kbd_flags_ctrl    dd 0
kbd_flags_alt     dd 0
kbd_flags_caps    dd 0
kbd_last_scan     dd 0

keyboard_init:
    mov dword [kbd_flags_shift], 0
    mov dword [kbd_flags_ctrl], 0
    mov dword [kbd_flags_alt], 0
    mov dword [kbd_flags_caps], 0
    mov dword [kbd_last_scan], 0
    ret

keyboard_update:
    ; intenta extraer 1 scancode IRQ-enqueued
    call kbd_irq_pop_scancode
    cmp eax, 1
    jne .none
    movzx eax, al
    mov [kbd_last_scan], eax
    mov bl, al
    test bl, 0x80
    jnz .release
    cmp bl, 0x2A
    je .set_shift
    cmp bl, 0x36
    je .set_shift
    cmp bl, 0x1D
    je .set_ctrl
    cmp bl, 0x38
    je .set_alt
    cmp bl, 0x3A
    je .toggle_caps
    mov eax, EVENT_KEY_DOWN
    mov ebx, [kbd_last_scan]
    call evq_push
    ret
.release:
    and bl, 0x7F
    cmp bl, 0x2A
    je .clr_shift
    cmp bl, 0x36
    je .clr_shift
    cmp bl, 0x1D
    je .clr_ctrl
    cmp bl, 0x38
    je .clr_alt
    mov eax, EVENT_KEY_UP
    mov ebx, [kbd_last_scan]
    call evq_push
    ret
.set_shift: mov dword [kbd_flags_shift],1
    ret
.clr_shift: mov dword [kbd_flags_shift],0
    ret
.set_ctrl: mov dword [kbd_flags_ctrl],1
    ret
.clr_ctrl: mov dword [kbd_flags_ctrl],0
    ret
.set_alt: mov dword [kbd_flags_alt],1
    ret
.clr_alt: mov dword [kbd_flags_alt],0
    ret
.toggle_caps:
    xor dword [kbd_flags_caps],1
.none:
    ret

%endif
