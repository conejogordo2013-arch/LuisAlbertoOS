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

    ; Inicializar almacenamiento. La terminal usa RAM FS por defecto para
    ; arrancar igual aunque no exista ATA/IDE. El driver ATA se sondea solo
    ; como dispositivo opcional y nunca bloquea comandos de archivos.
    call floppy_probe
    mov dword [fs_driver_available], 1
    mov esi, msg_fs_ram
    call api_print_string

    ; Nota de estabilidad: algunos equipos/emuladores reinician si se sondean
    ; dispositivos opcionales demasiado pronto durante el arranque.
    ; Dejamos los drivers opcionales en modo bajo demanda (comandos shell).
    mov dword [net_driver_available], 0
    mov dword [active_net_driver], 0
    mov dword [audio_driver_available], 0
    mov dword [active_audio_driver], 0
    mov esi, msg_optional_deferred
    call api_print_string

    call scheduler_register_kernel_main
    call shell_start
    ret

welcome_msg db "Welcome to LuisAlbertoOS Core v1.0 Compilation 1.2.57.796", 0
msg_fs_ram db 0x0A,"[OK] Filesystem RAM activo. ATA queda como dispositivo opcional.",0
msg_net_missing db 0x0A,"[WARN] RTL8139 no detectado. Comandos de red no disponibles.",0
msg_audio_missing db 0x0A,"[WARN] AC97 no detectado. Comandos de audio no disponibles.",0
msg_mem_ready db 0x0A,"[OK] Memoria/Interrupciones inicializadas.",0
msg_sched_ready db 0x0A,"[OK] Scheduler round-robin inicializado.",0
msg_optional_deferred db 0x0A,"[INFO] Drivers opcionales (red/audio/discos extra) diferidos para estabilidad de arranque.",0
