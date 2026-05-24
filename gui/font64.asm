[BITS 64]
default rel

global draw_char64
global draw_string64
extern fb64_putpixel
extern font8x16

section .text
draw_char64:
    ; eax=x ebx=y cl=char edi=color
    movzx edx, cl
    shl edx, 4
    lea r8, [font8x16 + rdx]
    xor r9d, r9d
.row:
    cmp r9d, 16
    jae .done
    mov dl, [r8+r9]
    xor r10d, r10d
.col:
    cmp r10d, 8
    jae .next
    test dl, 0x80
    jz .skip
    mov ecx, eax
    add ecx, r10d
    mov edx, ebx
    add edx, r9d
    call fb64_putpixel
.skip:
    shl dl, 1
    inc r10d
    jmp .col
.next:
    inc r9d
    jmp .row
.done:
    ret

draw_string64:
    ; eax=x ebx=y rsi=str edi=color
.n:
    mov cl, [rsi]
    test cl, cl
    jz .d
    call draw_char64
    add eax, 8
    inc rsi
    jmp .n
.d: ret
