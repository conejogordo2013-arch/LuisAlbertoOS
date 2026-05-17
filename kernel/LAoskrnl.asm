net_driver_available dd 0
fs_driver_available  dd 0
audio_driver_available dd 0

oskrnl_main:
    call api_clear_screen
    
    mov esi, welcome_msg
    call api_print_string
    
    ; Inicializar subsistemas núcleo
    call interrupts_init
    call mem_init
    call paging_init
    call scheduler_init

    mov esi, msg_mem_ready
    call api_print_string
    mov esi, msg_sched_ready
    call api_print_string

    ; Inicializar drivers opcionales
    call floppy_probe
    cmp eax, 0
    jne .fs_ata
    ; ATA is optional. Fall back to an in-memory filesystem so shell
    ; file commands still work when booted as a floppy image or in QEMU
    ; without an emulated IDE disk.
    mov dword [fs_driver_available], 1
    mov esi, msg_fs_ram
    call api_print_string
    jmp .fs_ok
.fs_ata:
    mov dword [fs_driver_available], 1
.fs_ok:

    call rtl8139_init
    mov [net_driver_available], eax
    cmp eax, 0
    jne .net_ok
    mov esi, msg_net_missing
    call api_print_string
.net_ok:

    call ac97_init
    mov [audio_driver_available], eax
    cmp eax, 0
    jne .audio_ok
    mov esi, msg_audio_missing
    call api_print_string
    jmp .audio_done
.audio_ok:
    call ac97_beep
.audio_done:

    call scheduler_register_kernel_main
    call shell_start
    ret

welcome_msg db "Welcome to LuisAlbertoOS Core v1.0 Compilation 1.2026.3.25.5p.51", 0
msg_fs_ram db 0x0A,"[WARN] ATA no detectado. Usando filesystem RAM opcional.",0
msg_net_missing db 0x0A,"[WARN] RTL8139 no detectado. Comandos de red no disponibles.",0
msg_audio_missing db 0x0A,"[WARN] AC97 no detectado. Comandos de audio no disponibles.",0
msg_mem_ready db 0x0A,"[OK] Memoria/Interrupciones inicializadas.",0
msg_sched_ready db 0x0A,"[OK] Scheduler round-robin inicializado.",0
