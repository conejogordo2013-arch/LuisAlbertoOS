net_driver_available dd 0
fs_driver_available  dd 0
audio_driver_available dd 0

oskrnl_main:
    call api_clear_screen
    
    mov esi, welcome_msg
    call api_print_string
    
    ; Inicializar subsistemas núcleo. El IDT/PIC/PIT se configura, pero las
    ; IRQs quedan deshabilitadas durante el arranque: el shell lee teclado por
    ; polling y algunas BIOS/emuladores reinician con IRQ0 activa demasiado
    ; pronto. interrupts_enable queda disponible para activar timer luego.
    call interrupts_init
    call mem_init
    call paging_init
    call scheduler_init
    call interrupts_enable

    mov esi, msg_mem_ready
    call api_print_string
    mov esi, msg_sched_ready
    call api_print_string

    ; Arranque seguro: el filesystem RAM permite llegar siempre al shell.
    ; No sondeamos hardware opcional aquí porque varias VMs/BIOS reinician al
    ; tocar puertos de dispositivos ausentes. Los comandos del shell pueden
    ; activar/probar drivers bajo demanda (por ejemplo net up/reset).
    mov dword [ata_present], 0
    mov dword [fs_driver_available], 1
    call floppy_probe_legacy
    mov esi, msg_fs_ram
    call api_print_string

    mov dword [net_driver_available], 0
    mov dword [active_net_driver], 0
    mov dword [rtl8139_present], 0
    mov dword [e1000_present], 0
    mov dword [e1000_link_up], 0
    mov esi, msg_net_missing
    call api_print_string

    mov dword [audio_driver_available], 0
    mov dword [active_audio_driver], 0
    mov dword [ac97_present], 0
    mov dword [sb16_present], 0
    mov esi, msg_audio_missing
    call api_print_string

    mov dword [cdrom_present], 0
    mov dword [sata_present], 0

    call scheduler_register_kernel_main
    ; Flujo principal: GUI primero (como pidió el proyecto).
    ; Si el usuario sale del desktop, vuelve a shell estable.
    call desktop_launch
    call shell_start
    ret

welcome_msg db "Welcome to LuisAlbertoOS Core v1.0 Compilation 1.2.57.796", 0
msg_fs_ram db 0x0A,"[OK] Filesystem RAM activo. ATA queda como dispositivo opcional.",0
msg_net_missing db 0x0A,"[WARN] RTL8139 no detectado. Comandos de red no disponibles.",0
msg_audio_missing db 0x0A,"[WARN] AC97 no detectado. Comandos de audio no disponibles.",0
msg_mem_ready db 0x0A,"[OK] Memoria/Interrupciones inicializadas.",0
msg_sched_ready db 0x0A,"[OK] Scheduler round-robin inicializado.",0
