[BITS 16]
[ORG 0x7C00]

KERNEL_LOAD_SEG  equ 0x0000
KERNEL_LOAD_OFF  equ 0x1000
KERNEL_SECTORS   equ 80
DEFAULT_SPT      equ 18
DEFAULT_HEADS    equ 2

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    ; Keep IRQs masked during early boot. BIOS INT calls still work with IF=0
    ; and this avoids random hardware IRQ handlers stomping our tiny stack.
    mov [boot_drive], dl
    mov byte [sectors_per_trk], DEFAULT_SPT
    mov byte [heads_count], DEFAULT_HEADS

    ; Query BIOS drive geometry so CHS stepping works for floppy and HDD.
    ; If the BIOS call fails we keep conservative floppy defaults.
    mov ah, 0x08
    mov dl, [boot_drive]
    int 0x13
    jc .geom_done
    and cl, 0x3F
    cmp cl, 1
    jb .geom_done
    mov [sectors_per_trk], cl
    inc dh
    cmp dh, 1
    jb .geom_done
    mov [heads_count], dh
.geom_done:

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
    mov al, [sectors_per_trk]
    inc al
    cmp byte [disk_sector], al
    jb .read_loop

    mov byte [disk_sector], 1
    inc byte [disk_head]
    mov al, [heads_count]
    cmp byte [disk_head], al
    jb .read_loop
    mov byte [disk_head], 0
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

boot_msg db 'LuisAlbertoOS Boot OK. Loading...', 13, 10, 0
disk_err_msg db 'Disk read error', 13, 10, 0
boot_drive db 0
disk_cylinder db 0
disk_head db 0
disk_sector db 0
sectors_left db 0
sectors_per_trk db DEFAULT_SPT
heads_count db DEFAULT_HEADS

times 510-($-$$) db 0
dw 0xAA55
