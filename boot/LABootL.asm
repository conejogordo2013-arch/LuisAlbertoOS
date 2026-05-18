[BITS 16]
[ORG 0x7C00]

KERNEL_LOAD_SEG  equ 0x0000
KERNEL_LOAD_OFF  equ 0x1000
KERNEL_SECTORS   equ 80
SECTORS_PER_TRK  equ 18

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    ; Keep IRQs disabled in stage-1 loader for deterministic disk reads.
    mov [boot_drive], dl

    ; Print Boot Message
    mov si, boot_msg
print_loop:
    lodsb
    or al, al
    jz load_kernel
    mov ah, 0x0E
    int 0x10
    jmp print_loop

load_kernel:
    call enable_a20
    ; BIOS reads must not cross track boundaries on many machines.
    ; Load one sector at a time from CHS 0/0/2 into 0000:1000.
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    mov bx, KERNEL_LOAD_OFF
    mov byte [disk_cylinder], 0
    mov byte [disk_head], 0
    mov byte [disk_sector], 2
    mov byte [sectors_left], KERNEL_SECTORS

.read_loop:
    cmp byte [sectors_left], 0
    je boot_kernel

    mov ah, 0x02        ; BIOS read sectors
    mov al, 1           ; Read exactly one sector
    mov ch, [disk_cylinder]
    mov cl, [disk_sector]
    mov dh, [disk_head]
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    add bx, 512
    dec byte [sectors_left]
    inc byte [disk_sector]
    cmp byte [disk_sector], SECTORS_PER_TRK + 1
    jb .read_loop

    mov byte [disk_sector], 1
    xor byte [disk_head], 1
    cmp byte [disk_head], 1
    je .read_loop
    inc byte [disk_cylinder]
    jmp .read_loop

boot_kernel:
    ; Jump to Kernel entry point
    jmp KERNEL_LOAD_SEG:KERNEL_LOAD_OFF

disk_error:
    xor ax, ax
    int 0x13            ; reset disk system, then show a clear failure
    mov si, disk_err_msg
.err_print:
    lodsb
    or al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .err_print
.halt:
    cli
    hlt
    jmp .halt


; Enable A20 so accesses above 1MiB (heap/page structures) do not wrap.
enable_a20:
    in al, 0x92
    test al, 0x02
    jnz .done
    or al, 0x02
    and al, 0xFE
    out 0x92, al
.done:
    ret

boot_msg db 'LuisAlbertoOS Boot OK. Loading...', 13, 10, 0
disk_err_msg db 'Disk read error', 13, 10, 0
boot_drive db 0
disk_cylinder db 0
disk_head db 0
disk_sector db 0
sectors_left db 0

times 510-($-$$) db 0
dw 0xAA55
