%ifndef LA_EVENT_QUEUE_ASM
%define LA_EVENT_QUEUE_ASM

EVENT_MOUSE_MOVE    equ 1
EVENT_MOUSE_DOWN    equ 2
EVENT_MOUSE_UP      equ 3
EVENT_KEY_DOWN      equ 4
EVENT_KEY_UP        equ 5
EVENT_WINDOW_CLOSE  equ 6
EVENT_WINDOW_FOCUS  equ 7
EVENT_WINDOW_MOVE   equ 8
EVENT_WINDOW_RESIZE equ 9

evq_head       dd 0
evq_tail       dd 0
evq_size       equ 64
evq_mask       equ evq_size-1
evq_entries    times evq_size*3 dd 0 ; ts,type,data

evq_init:
    mov dword [evq_head], 0
    mov dword [evq_tail], 0
    ret

evq_push:
    ; eax=type ebx=data
    push ecx
    push edx
    mov edx, [evq_tail]
    mov ecx, edx
    inc ecx
    and ecx, evq_mask
    cmp ecx, [evq_head]
    je .full
    imul edx, edx, 12
    mov dword [evq_entries + edx], 0
    mov ecx, [irq_ticks]
    mov [evq_entries + edx], ecx
    mov [evq_entries + edx + 4], eax
    mov [evq_entries + edx + 8], ebx
    mov ecx, [evq_tail]
    inc ecx
    and ecx, evq_mask
    mov [evq_tail], ecx
.full:
    pop edx
    pop ecx
    ret

evq_pop:
    ; out eax=type ebx=data ecx=timestamp, eax=0 if empty
    push edx
    mov edx, [evq_head]
    cmp edx, [evq_tail]
    je .e
    imul edx, edx, 12
    mov ecx, [evq_entries + edx]
    mov eax, [evq_entries + edx + 4]
    mov ebx, [evq_entries + edx + 8]
    mov edx, [evq_head]
    inc edx
    and edx, evq_mask
    mov [evq_head], edx
    pop edx
    ret
.e:
    xor eax,eax
    xor ebx,ebx
    xor ecx,ecx
    pop edx
    ret

%endif
