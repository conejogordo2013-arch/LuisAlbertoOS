%ifndef LA_EVENT_QUEUE_ASM
%define LA_EVENT_QUEUE_ASM

evq_head       dd 0
evq_tail       dd 0
evq_size       equ 64
evq_mask       equ evq_size-1
evq_entries    times evq_size*2 dd 0 ; type, payload

ev_mouse_move  equ 1
ev_mouse_btn   equ 2
ev_key         equ 3

evq_init:
    mov dword [evq_head], 0
    mov dword [evq_tail], 0
    ret

evq_push:
    ; eax=type ebx=payload, CF=1 si llena
    push edx
    push ecx
    mov edx, [evq_tail]
    mov ecx, edx
    inc ecx
    and ecx, evq_mask
    cmp ecx, [evq_head]
    je .full
    shl edx, 3
    mov [evq_entries + edx], eax
    mov [evq_entries + edx + 4], ebx
    mov [evq_tail], ecx
    clc
    jmp .out
.full:
    stc
.out:
    pop ecx
    pop edx
    ret

evq_pop:
    ; out eax=type ebx=payload, ZF=1 vacia
    push edx
    mov edx, [evq_head]
    cmp edx, [evq_tail]
    je .empty
    shl edx, 3
    mov eax, [evq_entries + edx]
    mov ebx, [evq_entries + edx + 4]
    mov edx, [evq_head]
    inc edx
    and edx, evq_mask
    mov [evq_head], edx
    test eax, eax
    jmp .out
.empty:
    xor eax, eax
    xor ebx, ebx
    or eax, eax
.out:
    pop edx
    ret

%endif
