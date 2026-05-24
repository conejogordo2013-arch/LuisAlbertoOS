[BITS 64]
[ORG 0x400000]
_start:
    mov rax, 1
    mov rbx, msg
    int 0x80
    mov rax, 6
    int 0x80
.h: jmp .h
msg db '[cmd.elf64] hello',0
