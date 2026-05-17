; Application Binary Interface (ABI)
; EBX points to this table when an app is launched. Hardware-backed services
; are kept as callable optional services, so simple apps can still run when
; storage or other devices are absent.

api_table:
    dd api_print_string     ; offset 0
    dd api_clear_screen     ; offset 4
    dd api_delay            ; offset 8
    dd kbd_read_char        ; offset 12
    dd print_char           ; offset 16
    dd fs_write_file        ; offset 20
    dd fs_read_file         ; offset 24
    dd 0x80                 ; offset 28: syscall vector marker
