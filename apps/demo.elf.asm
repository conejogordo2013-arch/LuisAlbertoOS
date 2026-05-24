[BITS 32]
[ORG 0x00214000]

ehdr:
    db 0x7F, "ELF"
    db 1,1,1,0
    times 8 db 0
    dw 2
    dw 3
    dd 1
    dd _start
    dd phdr - $$
    dd 0
    dd 0
    dw 52
    dw 32
    dw 1
    dw 0
    dw 0
    dw 0

phdr:
    dd 1
    dd 0
    dd $$ + 0x00214000
    dd $$ + 0x00214000
    dd file_end - $$
    dd file_end - $$
    dd 5
    dd 0x1000

_start:
    mov eax, 1
    mov ebx, msg
    int 0x80

    mov eax, 11
    mov ebx, 30
    mov ecx, 30
    mov edx, 120
    mov esi, 60
    mov edi, 10
    int 0x80

    mov eax, 6
    int 0x80
.h: jmp .h

msg db 0x0A, "[demo.elf] draw rect syscall",0
file_end:
