net_driver_available dd 0
fs_driver_available  dd 0

oskrnl_main:
    call api_clear_screen
    
    mov esi, welcome_msg
    call api_print_string
    
    ; Inicializar drivers opcionales
    call floppy_probe
    mov [fs_driver_available], eax
    cmp eax, 0
    jne .fs_ok
    mov esi, msg_fs_missing
    call api_print_string
.fs_ok:

    call rtl8139_init
    mov [net_driver_available], eax
    cmp eax, 0
    jne .net_ok
    mov esi, msg_net_missing
    call api_print_string
.net_ok:

    call shell_start
    ret

welcome_msg db "Welcome to LuisAlbertoOS Core v1.0 Compilation 1.2026.3.25.5p.51", 0
msg_fs_missing db 0x0A,"[WARN] Dispositivo ATA no detectado. Comandos de archivos no disponibles.",0
msg_net_missing db 0x0A,"[WARN] RTL8139 no detectado. Comandos de red no disponibles.",0
