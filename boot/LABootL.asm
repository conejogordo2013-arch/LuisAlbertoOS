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
    ; First try EDD/LBA reads (INT 13h AH=42h). This is the most robust path
    ; on modern BIOSes and avoids CHS geometry mismatches.
    call load_kernel_lba
    jc .fallback_chs
    jmp boot_kernel

.fallback_chs:
    ; BIOS reads must not cross track boundaries on many machines.
    ; CHS fallback: load one sector at a time from 0/0/2 into 0000:1000.
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

load_kernel_lba:
    pusha
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    mov bx, KERNEL_LOAD_OFF
    mov dword [dap_lba_low], 1
    mov dword [dap_lba_high], 0
    mov byte [sectors_left], KERNEL_SECTORS
.lba_loop:
    cmp byte [sectors_left], 0
    je .ok
    mov word [dap_buffer_off], bx
    mov word [dap_buffer_seg], es
    mov si, disk_address_packet
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc .err
    add bx, 512
    inc dword [dap_lba_low]
    dec byte [sectors_left]
    jmp .lba_loop
.ok:
    popa
    clc
    ret
.err:
    popa
    stc
    ret

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

; Disk Address Packet (EDD INT13h AH=42h)
disk_address_packet:
dap_size db 0x10
dap_reserved db 0
dap_count dw 1
dap_buffer_off dw 0
dap_buffer_seg dw 0
dap_lba_low dd 0
dap_lba_high dd 0

times 510-($-$$) db 0
dw 0xAA55
