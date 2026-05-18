; ==================================================================  
; LACommand.asm - Shell REAL para LuisAlbertoOS
; ==================================================================  

[BITS 32]

%include "kernel/LAApi.asm"
%include "drivers/ata.lasys"
%include "kernel/fs.lasys"

; ==================================================================
; DATOS Y BÚFERES
; ==================================================================

shell_prompt      db "> ",0
msg_welcome       db 0x0A,"LuisAlbertoOS Shell REAL v3.1 (Net Enabled)",0x0A,0
msg_newline       db 0x0A,0

cmd_buffer        times 128 db 0
char_buffer       db 0,0
hex_buffer        times 9 db 0
entry_name_buffer times 17 db 0
arg_ptr           dd 0
arg2_ptr          dd 0

current_path      times 128 db 0
path_root_init    db "C:/",0

BUFFER_EDITOR     times FS_MAX_FILE_BYTES db 0

; Comandos Básicos
cmd_dir       db "dir",0
cmd_clear     db "clear",0
cmd_cd        db "cd",0
cmd_mkdir     db "mkdir",0
cmd_touch     db "touch",0
cmd_edit      db "edit",0
cmd_audio     db "audio",0
cmd_play      db "play",0
cmd_img       db "img",0
cmd_help      db "help",0
cmd_net       db "net",0
cmd_devices   db "devices",0
cmd_beep      db "beep",0
cmd_pwd       db "pwd",0
cmd_meminfo   db "meminfo",0
cmd_data      db "data",0
cmd_alloc     db "alloc",0
cmd_free      db "free",0
cmd_rm        db "rm",0
cmd_cat       db "cat",0
cmd_irq       db "irq",0
cmd_sched     db "sched",0
cmd_task      db "task",0
cmd_syscall   db "syscall",0
cmd_mktask    db "mktask",0
cmd_exc       db "exc",0
cmd_block     db "block",0
cmd_wake      db "wake",0
cmd_journal   db "journal",0
cmd_tasks     db "tasks",0
cmd_vmmap     db "vmmap",0
cmd_vmunmap   db "vmunmap",0
cmd_change    db "change",0
cmd_echo      db "echo",0
cmd_copy      db "copy",0
cmd_move      db "move",0
cmd_rename    db "rename",0
cmd_type      db "type",0
cmd_hexdump   db "hexdump",0
cmd_date      db "date",0
cmd_ver       db "ver",0
cmd_reboot    db "reboot",0
cmd_shutdown  db "shutdown",0
cmd_run       db "run",0
cmd_mount     db "mount",0
cmd_umount    db "umount",0
cmd_format    db "format",0
cmd_set       db "set",0

; Comandos de Red (Subcomandos)
net_sub_info      db "info",0
net_sub_up        db "up",0
net_sub_down      db "down",0
net_sub_send      db "send",0
net_sub_recv      db "recv",0
net_sub_listen    db "listen",0
net_sub_dump      db "dump",0
net_sub_stats     db "stats",0
net_sub_config    db "config",0
net_sub_ping      db "ping",0
net_sub_scan      db "scan",0
net_sub_arp       db "arp",0
net_sub_reset     db "reset",0
net_sub_icmp      db "icmp",0
net_sub_l4        db "l4",0
net_sub_proto     db "proto",0
net_sub_paginf    db "paginf",0

; Mensajes Básicos
msg_err_cmd       db 0x0A,"Error: comando no reconocido.",0
msg_usage_two     db 0x0A,"Uso: comando <origen> <destino>",0
msg_copy_ok       db 0x0A,"Archivo copiado.",0
msg_move_ok       db 0x0A,"Archivo movido/renombrado.",0
msg_op_fail       db 0x0A,"Operacion fallida.",0
msg_dump_hdr      db 0x0A,"Offset  Hex",0x0A,0
msg_date_text     db 0x0A,"Fecha: 2026-05-18 UTC",0
msg_ver_text      db 0x0A,"LuisAlbertoOS Shell REAL v3.2 multi-sector",0
msg_rebooting     db 0x0A,"Reiniciando...",0
msg_shutdown_text db 0x0A,"Sistema detenido. Puede cerrar el emulador.",0
msg_mount_ok      db 0x0A,"Montaje activo.",0
msg_umount_ok     db 0x0A,"Unidad desmontada (RAM FS sigue disponible).",0
msg_format_ok     db 0x0A,"Filesystem formateado.",0
msg_run_fail      db 0x0A,"App no encontrada. Usa sample1, taskmgr o textedit.",0
msg_hist_note     db 0x0A,"Historial/autocompletado: buffer preparado; flechas extendidas dependen del teclado.",0
msg_set_ok        db 0x0A,"Variable guardada.",0
msg_set_usage     db 0x0A,"Uso: set <nombre> <valor> ; echo $nombre",0
msg_arp_hdr       db 0x0A,"-- ARP table --",0x0A,0
msg_arp_empty     db "(vacia)",0x0A,0
msg_created_dir   db 0x0A,"Carpeta creada.",0
msg_created_file  db 0x0A,"Archivo creado.",0
msg_edit_info     db 0x0A,"--- EDITOR (ESC para guardar y salir) ---",0x0A,0
msg_saved         db 0x0A,"Archivo guardado.",0
msg_dir_header    db 0x0A,"-- DIRECTORIO ACTUAL --",0x0A,0
msg_dir_type      db " <DIR>",0
msg_audio     db 0x0A,"Audio: SB16 WAV PCM si esta disponible; AC97/PIT beep como fallback.",0
msg_play_usage db 0x0A,"Uso: play <archivo.wav> (PCM mono 8-bit)",0
msg_play_ok    db 0x0A,"Reproduciendo WAV PCM por SB16.",0
msg_play_fail  db 0x0A,"No se pudo reproducir: requiere SB16 y WAV PCM mono 8-bit.",0
msg_sb16_stat  db 0x0A,"SB16 DSP: ",0
msg_ac97_stat  db 0x0A,"AC97: ",0
msg_err_img       db 0x0A,"Error: Archivo de imagen no encontrado o vacio.",0
msg_help          db 0x0A, "Comandos disponibles:",0x0A, \
                "dir    - Lista directorio",0x0A, \
                "clear  - Limpia pantalla",0x0A, \
                "cd     - Cambia directorio",0x0A, \
                "mkdir  - Crea carpeta",0x0A, \
                "touch  - Crea archivo",0x0A, \
                "edit   - Editor de archivos",0x0A, \
                "audio  - Estado/prueba de audio",0x0A, \
                "play   - Reproduce WAV PCM SB16",0x0A, \
                "img    - Visualizador de imagen",0x0A, \
                "net    - Subsistema de red (net help)",0x0A, \
                "help   - Muestra esta ayuda",0x0A, \
                "devices- Estado de drivers",0x0A, \
                "beep   - Prueba audio AC97",0x0A, \
                "pwd    - Muestra ruta actual",0x0A, \
                "meminfo- Estado memoria",0x0A, \
                "data   - Diagnostico completo del sistema",0x0A, \
                "alloc  - Reserva 4KB",0x0A, \
                "free   - Libera ultimo frame",0x0A, \
                "rm     - Elimina entrada",0x0A, \
                "cat/type - Muestra archivo multi-sector",0x0A, \
                "copy/move/rename - Gestion de archivos",0x0A, \
                "hexdump- Volcado hexadecimal",0x0A, \
                "echo/set/date/ver/run/mount/umount/format",0x0A, \
                "irq    - Ver ticks IRQ0",0x0A, \
                "sched  - Ver ticks scheduler",0x0A, \
                "task   - Estado scheduler",0x0A, \
                "syscall- Prueba int80",0x0A, \
                "mktask - Crea task demo",0x0A, \
                "exc    - Estado excepciones",0x0A, \
                "block  - Bloquear task",0x0A, \
                "wake   - Despertar task0",0x0A, \
                "journal- Estado journal FS",0x0A, \
                "tasks  - Lista tasks",0x0A, \
                "vmmap  - Map page demo",0x0A, \
                "vmunmap- Unmap page demo",0

; Mensajes de Red
msg_net_usage     db 0x0A,"Uso: net <comando> [args]",0x0A,"Comandos: info, up, down, send, recv, listen, dump, stats, config, ping, scan, arp, reset, icmp, l4, proto, paginf",0
msg_net_up        db 0x0A,"Red inicializada (RTL8139 UP). RX/TX habilitados.",0
msg_net_down      db 0x0A,"Red deshabilitada (RTL8139 DOWN).",0
msg_net_info      db 0x0A,"Dispositivo: RTL8139",0x0A,"Estado: UP",0x0A,"MAC: Cargada",0
msg_net_config    db 0x0A,"IP: 192.168.1.100",0x0A,"Mascara: 255.255.255.0",0x0A,"Gateway: 192.168.1.1",0
msg_net_ip_lbl    db 0x0A,"IP: ",0
msg_net_msk_lbl   db 0x0A,"Mascara: 255.255.255.0",0
msg_net_gw_lbl    db 0x0A,"Gateway: ",0
msg_net_dns_lbl   db 0x0A,"DNS: ",0
msg_net_stats     db 0x0A,"-- Estadisticas de Red --",0x0A,"Enviados: ",0
msg_net_recv_msg  db 0x0A,"Paquetes Recibidos: ",0
msg_net_err       db 0x0A,"Errores: ",0
msg_net_ping_rep  db 0x0A,"Ping real iniciado: ARP enviado; espera respuesta real con net recv/listen.",0
msg_net_scan      db 0x0A,"Scan real: ARP broadcast enviado; escucha respuestas con net listen.",0
msg_net_listen    db 0x0A,"Escuchando paquetes (ESC para salir)...",0
msg_net_send_err  db 0x0A,"Error: Formato Hexadecimal Invalido.",0
msg_net_send_ok   db 0x0A,"Paquete enviado correctamente.",0
msg_net_timeout   db 0x0A,"No se inventan hosts: solo se reportan paquetes reales recibidos.",0
msg_net_arp_tx    db 0x0A,"ARP request enviado (gateway).",0
msg_net_reset_ok  db 0x0A,"Driver de red reiniciado.",0
msg_net_icmp_none db 0x0A,"No ICMP echo request detectado.",0
msg_net_icmp_ok   db 0x0A,"ICMP echo request detectado.",0
msg_net_l4_none   db 0x0A,"L4: none/no ipv4",0
msg_net_l4_icmp   db 0x0A,"L4: ICMP",0
msg_net_l4_tcp    db 0x0A,"L4: TCP",0
msg_net_l4_udp    db 0x0A,"L4: UDP",0
msg_net_proto     db 0x0A,"Proto stack real: ETH/ARP/IP/ICMP/TCP/UDP + DNS preparado (sin respuestas falsas)",0
msg_net_paginf_use db 0x0A,"Uso: net paginf <host>",0
msg_net_paginf_host db 0x0A,"Host: ",0
msg_net_paginf_start db 0x0A,"PAGINF real: resolviendo gateway por ARP para DNS/ICMP...",0
msg_net_paginf_wait db 0x0A,"Sin simular: usa net listen/recv para capturar ARP/DNS/ICMP reales; IP/puerto/ping se muestran cuando haya respuesta.",0
msg_rtl_stats     db 0x0A,"-- RTL8139 driver --",0x0A,"TX ok: ",0
msg_rtl_rx_ok     db "RX ok: ",0
msg_rtl_tx_err    db "TX err: ",0
msg_rtl_rx_err    db "RX err: ",0
msg_rtl_last_len  db "Last RX len: ",0
msg_rtl_last_isr  db "Last ISR: ",0
msg_fs_unavail    db 0x0A,"Error: filesystem no disponible.",0
msg_net_unavail   db 0x0A,"Error: red RTL8139 no disponible.",0
msg_audio_unavail db 0x0A,"Error: audio AC97 no disponible.",0
msg_dev_status    db 0x0A,"Estado dispositivos:",0x0A,0
msg_dev_fs        db "FS: ",0
msg_dev_net       db 0x0A,"RTL8139: ",0
msg_dev_audio     db 0x0A,"AC97: ",0
msg_dev_ok        db "OK",0
msg_dev_ram       db "RAM FS",0
msg_dev_missing   db "NO DETECTADO",0
msg_mem_hdr       db 0x0A,"Memoria kernel:",0x0A,0
msg_data_hdr      db 0x0A,"== LuisAlbertoOS DATA ==",0x0A,0
msg_data_boot     db 0x0A,"Bootloader:",0x0A,0
msg_data_bootaddr db "Bootloader physical address: ",0
msg_data_loadoff  db "Kernel load offset: ",0
msg_data_total    db "Total Memory: ",0
msg_data_kpa      db "Kernel physical address: ",0
msg_data_kva      db "Kernel virtual address: ",0
msg_data_kstart   db "KERNEL START: ",0
msg_data_kend     db "KERNEL END: ",0
msg_data_ksectors db "Kernel load sectors: ",0
msg_data_malloc   db 0x0A,"Malloced Addresses:",0x0A,0
msg_data_freed    db 0x0A,"Freed Addresses:",0x0A,0
msg_data_heap     db "Heap ptr/end: ",0
msg_data_last     db "Last/count: ",0
msg_data_devices  db 0x0A,"Devices:",0x0A,0
msg_data_tasks    db 0x0A,"TASKS:",0x0A,0
msg_data_dump     db 0x0A,"Memory Dump:",0x0A,0
msg_data_errors   db 0x0A,"Memory Errors Addresses:",0x0A,0
msg_data_fs       db "FS mode/journal: ",0
msg_data_irq      db "IRQ/syscalls: ",0
msg_mem_total     db "Total bytes: ",0
msg_mem_used      db 0x0A,"Usado bytes: ",0
msg_mem_free      db 0x0A,"Libre bytes: ",0
msg_int_state     db 0x0A,"Interrupciones: ",0
msg_pg_state      db 0x0A,"Paging: ",0
msg_alloc_ok      db 0x0A,"Heap alloc ok @0x",0
msg_alloc_fail    db 0x0A,"Alloc fallo.",0
msg_frame_ok      db 0x0A,"Frame alloc ok @0x",0
msg_frame_fail    db 0x0A,"Frame alloc fallo.",0
msg_frame_free_ok db 0x0A,"Ultimo frame liberado.",0
msg_frame_free_no db 0x0A,"No hay frame para liberar.",0
msg_num_nl        db 0x0A,0
msg_rm_ok         db 0x0A,"Entrada eliminada.",0
msg_rm_fail       db 0x0A,"No se pudo eliminar (no existe).",0
msg_cat_hdr       db 0x0A,"Contenido:",0x0A,0
msg_cat_fail      db 0x0A,"No se pudo leer archivo.",0
msg_irq_ticks     db 0x0A,"IRQ0 ticks: ",0
msg_sched_ticks   db 0x0A,"Scheduler ticks: ",0
msg_sched_switch  db 0x0A,"Switches: ",0
msg_irq1_keys     db 0x0A,"IRQ1 keys: ",0
msg_syscall_ticks db 0x0A,"int80 ticks: ",0
msg_syscall_pid   db 0x0A,"int80 pid: ",0
msg_syscall_count db 0x0A,"int80 count: ",0
msg_syscall_t0    db 0x0A,"int80 task0 state: ",0
msg_mktask_ok     db 0x0A,"Task kernel registrada.",0
msg_mktask_fail   db 0x0A,"No se pudo registrar task.",0
msg_exc_count     db 0x0A,"Exceptions: ",0
msg_exc_last      db 0x0A,"Last exception: ",0
msg_block_ok      db 0x0A,"Protegido: la shell principal no se bloquea.",0
msg_wake_ok       db 0x0A,"Task 0 despertada.",0
msg_journal_seq   db 0x0A,"FS journal seq: ",0
msg_tasks_hdr     db 0x0A,"Tasks (idx/state):",0x0A,0
msg_vmmap_ok      db 0x0A,"vm map ok",0
msg_vmmap_fail    db 0x0A,"vm map fail",0
msg_vmunmap_ok    db 0x0A,"vm unmap ok",0
msg_vmunmap_fail  db 0x0A,"vm unmap fail",0
msg_change_usage  db 0x0A,"Uso: change <ram|ata|a:|c:|d:>",0
msg_change_ram_ok db 0x0A,"Cambiado a Ram Correctamente.",0
msg_change_ata_ok db 0x0A,"Cambiado a ata Correctamente.",0
msg_change_ata_no db 0x0A,"No se encontro disco.",0
msg_change_fdd_ok db 0x0A,"Dispositivo activo: Floppy A:.",0
msg_change_hdd_ok db 0x0A,"Dispositivo activo: Disco duro C:.",0
msg_change_cd_ok  db 0x0A,"Dispositivo activo: CDROM D:.",0
msg_change_dev_no db 0x0A,"Dispositivo no disponible.",0
arg_ram           db "ram",0
arg_ata           db "ata",0
arg_a             db "a:",0
arg_c             db "c:",0
arg_d             db "d:",0
dot_char          db ".",0
colon_char        db ":",0
space_char        db " ",0
msg_sw_from       db 0x0A,"Last from: ",0
msg_sw_to         db 0x0A,"Last to: ",0
msg_sched_on      db 0x0A,"Scheduler: ",0
msg_tasks_count   db 0x0A,"Tasks: ",0
msg_task_curr     db 0x0A,"Current: ",0
msg_net_len       db 0x0A,"LEN: ",0
msg_net_hex       db 0x0A,"HEX:",0x0A,0
msg_net_ascii     db 0x0A,"ASCII:",0x0A,0

; Buffers y Variables de Red
hex_arg_ptr       dd 0
net_pkts_sent     dd 0
net_pkts_recv     dd 0
net_errors        dd 0
dump_size         dd 0
shell_var_name    times 16 db 0
shell_var_value   times 64 db 0

; ==================================================================
; INICIO DEL SHELL
; ==================================================================

shell_start:
    cmp byte [current_path], 0
    jne skip_init
    mov esi, path_root_init
    mov edi, current_path
    call strcpy
    cmp dword [fs_driver_available], 0
    je skip_init
    call fs_init
skip_init:
    mov esi, msg_welcome
    call api_print_string

shell_loop:
    mov esi, msg_newline
    call api_print_string
    mov esi, current_path
    call api_print_string
    mov esi, shell_prompt
    call api_print_string

    mov edi, cmd_buffer
    mov ecx, 128
    xor eax, eax
    rep stosb
    mov edi, cmd_buffer
    xor ecx, ecx
read_key:
    call kbd_read_char
    cmp al, 0
    je read_key
    cmp al, 0x0A
    je parse_command
    cmp al, 0x08
    je handle_backspace

    cmp ecx, 126
    jge read_key

    mov [edi], al
    inc edi
    inc ecx
    push eax
    call print_char
    pop eax
    jmp read_key

handle_backspace:
    cmp ecx, 0
    je read_key
    dec edi
    mov byte [edi], 0
    dec ecx
    call api_backspace
    jmp read_key

parse_command:
    mov byte [edi], 0
    mov esi, cmd_buffer
    mov dword [arg_ptr], 0
    mov dword [arg2_ptr], 0
find_space:
    cmp byte [esi], 0
    je execute
    cmp byte [esi], ' '
    je split
    inc esi
    jmp find_space
split:
    mov byte [esi], 0
    inc esi
    mov dword [arg_ptr], esi
find_space2:
    cmp byte [esi], 0
    je execute
    cmp byte [esi], ' '
    je split2
    inc esi
    jmp find_space2
split2:
    mov byte [esi], 0
    inc esi
    mov dword [arg2_ptr], esi

execute:
    mov esi, cmd_buffer
    cmp byte [esi], 0
    je shell_loop

    ; --- RUTINAS DE COMANDOS BÁSICOS ---
    mov edi, cmd_dir
    call strcmp
    cmp eax, 0
    je do_dir

    mov edi, cmd_clear
    call strcmp
    cmp eax, 0
    je do_clear

    mov edi, cmd_cd
    call strcmp
    cmp eax, 0
    je do_cd

    mov edi, cmd_mkdir
    call strcmp
    cmp eax, 0
    je do_mkdir

    mov edi, cmd_touch
    call strcmp
    cmp eax, 0
    je do_touch

    mov edi, cmd_edit
    call strcmp
    cmp eax, 0
    je do_edit
    
    mov edi, cmd_audio
    call strcmp
    cmp eax, 0
    je do_audio

    mov edi, cmd_play
    call strcmp
    cmp eax, 0
    je do_play
    
    mov edi, cmd_img
    call strcmp
    cmp eax, 0
    je do_img

    mov edi, cmd_help
    call strcmp
    cmp eax, 0
    je do_help

    mov edi, cmd_devices
    call strcmp
    cmp eax, 0
    je do_devices

    mov edi, cmd_beep
    call strcmp
    cmp eax, 0
    je do_beep

    mov edi, cmd_pwd
    call strcmp
    cmp eax, 0
    je do_pwd

    mov edi, cmd_meminfo
    call strcmp
    cmp eax, 0
    je do_meminfo

    mov edi, cmd_data
    call strcmp
    cmp eax, 0
    je do_data

    mov edi, cmd_alloc
    call strcmp
    cmp eax, 0
    je do_alloc

    mov edi, cmd_free
    call strcmp
    cmp eax, 0
    je do_free

    mov edi, cmd_rm
    call strcmp
    cmp eax, 0
    je do_rm

    mov edi, cmd_cat
    call strcmp
    cmp eax, 0
    je do_cat

    mov edi, cmd_irq
    call strcmp
    cmp eax, 0
    je do_irq

    mov edi, cmd_sched
    call strcmp
    cmp eax, 0
    je do_sched

    mov edi, cmd_task
    call strcmp
    cmp eax, 0
    je do_task

    mov edi, cmd_syscall
    call strcmp
    cmp eax, 0
    je do_syscall

    mov edi, cmd_mktask
    call strcmp
    cmp eax, 0
    je do_mktask

    mov edi, cmd_exc
    call strcmp
    cmp eax, 0
    je do_exc

    mov edi, cmd_block
    call strcmp
    cmp eax, 0
    je do_block

    mov edi, cmd_wake
    call strcmp
    cmp eax, 0
    je do_wake

    mov edi, cmd_journal
    call strcmp
    cmp eax, 0
    je do_journal

    mov edi, cmd_tasks
    call strcmp
    cmp eax, 0
    je do_tasks

    mov edi, cmd_vmmap
    call strcmp
    cmp eax, 0
    je do_vmmap

    mov edi, cmd_vmunmap
    call strcmp
    cmp eax, 0
    je do_vmunmap

    mov edi, cmd_change
    call strcmp
    cmp eax, 0
    je do_change



    mov edi, cmd_echo
    call strcmp
    cmp eax, 0
    je do_echo

    mov edi, cmd_copy
    call strcmp
    cmp eax, 0
    je do_copy

    mov edi, cmd_move
    call strcmp
    cmp eax, 0
    je do_move

    mov edi, cmd_rename
    call strcmp
    cmp eax, 0
    je do_rename

    mov edi, cmd_type
    call strcmp
    cmp eax, 0
    je do_cat

    mov edi, cmd_hexdump
    call strcmp
    cmp eax, 0
    je do_hexdump

    mov edi, cmd_date
    call strcmp
    cmp eax, 0
    je do_date

    mov edi, cmd_ver
    call strcmp
    cmp eax, 0
    je do_ver

    mov edi, cmd_reboot
    call strcmp
    cmp eax, 0
    je do_reboot

    mov edi, cmd_shutdown
    call strcmp
    cmp eax, 0
    je do_shutdown

    mov edi, cmd_run
    call strcmp
    cmp eax, 0
    je do_run

    mov edi, cmd_mount
    call strcmp
    cmp eax, 0
    je do_mount

    mov edi, cmd_umount
    call strcmp
    cmp eax, 0
    je do_umount

    mov edi, cmd_format
    call strcmp
    cmp eax, 0
    je do_format

    mov edi, cmd_set
    call strcmp
    cmp eax, 0
    je do_set

    ; --- INTEGRACIÓN DEL SUBSISTEMA DE RED ---
    mov edi, cmd_net
    call strcmp
    cmp eax, 0
    je do_net

    mov esi, msg_err_cmd
    call api_print_string
    jmp shell_loop

; ==================================================================
; LÓGICA DE COMANDOS (Sistema de Archivos y Utilidades)
; ==================================================================
do_clear:
    call api_clear_screen
    jmp shell_loop

do_dir:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, msg_dir_header
    call api_print_string
    mov esi, DIR_BUFFER  
    mov ecx, 16          
.dir_loop:
    cmp byte [esi], 0    
    je .next_entry
    push esi
    push ecx
    call print_entry_name
    pop ecx
    pop esi
    cmp byte [esi+24], 2 
    jne .print_nl
    push esi
    push ecx
    mov esi, msg_dir_type
    call api_print_string
    pop ecx
    pop esi
.print_nl:
    push esi
    push ecx
    mov esi, msg_newline
    call api_print_string
    pop ecx
    pop esi
.next_entry:
    add esi, 26
    dec ecx
    jnz .dir_loop
    jmp shell_loop
do_mkdir:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    mov al, 2            
    call fs_create_file  
    mov esi, msg_created_dir
    call api_print_string
    jmp shell_loop

do_touch:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    mov al, 1            
    call fs_create_file
    mov esi, msg_created_file
    call api_print_string
    jmp shell_loop

do_cd:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    call fs_change_dir   
    jmp shell_loop

do_edit:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    mov esi, msg_edit_info
    call api_print_string
    mov edi, BUFFER_EDITOR
    mov ecx, FS_MAX_FILE_BYTES
    mov al, 0
    rep stosb
    mov edi, BUFFER_EDITOR
    xor ecx, ecx         
.edit_loop:
    call kbd_read_char
    cmp al, 0x1B         
    je .save_file
    cmp al, 0
    je .edit_loop
    cmp al, 0x08         
    je .edit_backspace
    cmp ecx, FS_MAX_FILE_BYTES-1
    jge .edit_loop
    mov [edi], al
    inc edi
    inc ecx
    push eax
    call print_char      
    pop eax
    jmp .edit_loop
.edit_backspace:
    cmp ecx, 0
    je .edit_loop
    dec edi
    mov byte [edi], 0
    dec ecx
    call api_backspace
    jmp .edit_loop
.save_file:
    mov byte [edi], 0
    inc ecx                ; include null terminator in stored size
    mov esi, [arg_ptr]
    mov ebx, BUFFER_EDITOR
    call fs_write_file
    mov esi, msg_saved
    call api_print_string
    jmp shell_loop

do_audio:
    cmp dword [audio_driver_available], 0
    je .audio_no
    mov esi, msg_audio
    call api_print_string
    mov esi, msg_sb16_stat
    call api_print_string
    mov eax, [sb16_driver_available]
    call print_hex32
    cmp dword [sb16_driver_available], 1
    jne .beep_fallback
    movzx eax, byte [sb16_dsp_major]
    call print_hex32
    movzx eax, byte [sb16_dsp_minor]
    call print_hex32
    jmp shell_loop
.beep_fallback:
    call ac97_beep
    mov esi, msg_ac97_stat
    call api_print_string
    mov eax, [ac97_driver_available]
    call print_hex32
    jmp shell_loop
.audio_no:
    mov esi, msg_audio_unavail
    call api_print_string
    jmp shell_loop

do_play:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .usage
    cmp dword [sb16_driver_available], 1
    jne .fail
    call fs_read_file
    cmp eax, 0
    je .fail
    mov esi, APP_POINTER
    call sb16_play_wav
    cmp eax, 0
    je .fail
    mov esi, msg_play_ok
    call api_print_string
    jmp shell_loop
.usage:
    mov esi, msg_play_usage
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_play_fail
    call api_print_string
    jmp shell_loop

do_img:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .no_arg
    cmp byte [esi], 0
    je .no_arg
    call fs_read_file
    cmp eax, 0
    je .img_not_found
    cmp ecx, 0
    je .img_not_found
    pusha                  
    call vga_image_view    
    popa                   
    call api_clear_screen  
    jmp shell_loop
.no_arg:
.img_not_found:
    mov esi, msg_err_img
    call api_print_string
    jmp shell_loop

fs_missing_cmd:
    mov esi, msg_fs_unavail
    call api_print_string
    jmp shell_loop


do_pwd:
    mov esi, msg_newline
    call api_print_string
    mov esi, current_path
    call api_print_string
    jmp shell_loop

do_devices:
    mov esi, msg_dev_status
    call api_print_string
    mov esi, msg_dev_fs
    call api_print_string
    cmp dword [fs_driver_available], 0
    je .fs_no
    mov esi, msg_dev_ram
    jmp .fs_out
.fs_no:
    mov esi, msg_dev_missing
.fs_out:
    call api_print_string

    mov esi, msg_dev_net
    call api_print_string
    cmp dword [net_driver_available], 0
    je .net_no
    mov esi, msg_dev_ok
    jmp .net_out
.net_no:
    mov esi, msg_dev_missing
.net_out:
    call api_print_string

    mov esi, msg_dev_audio
    call api_print_string
    cmp dword [audio_driver_available], 0
    je .aud_no
    mov esi, msg_dev_ok
    jmp .aud_out
.aud_no:
    mov esi, msg_dev_missing
.aud_out:
    call api_print_string
    jmp shell_loop

do_beep:
    cmp dword [audio_driver_available], 0
    je .beep_no
    call ac97_beep
    jmp shell_loop
.beep_no:
    mov esi, msg_audio_unavail
    call api_print_string
    jmp shell_loop


do_meminfo:
    mov esi, msg_mem_hdr
    call api_print_string
    mov esi, msg_data_total
    call api_print_string
    mov eax, [mem_total_bytes]
    call print_hex32
    mov esi, msg_mem_used
    call api_print_string
    mov eax, [mem_used_bytes]
    call print_hex32
    mov esi, msg_mem_free
    call api_print_string
    mov eax, [mem_total_bytes]
    sub eax, [mem_used_bytes]
    call print_hex32
    mov esi, msg_int_state
    call api_print_string
    mov eax, [interrupts_ready]
    call print_hex32
    mov esi, msg_pg_state
    call api_print_string
    mov eax, [paging_enabled]
    call print_hex32
    jmp shell_loop


do_data:
    mov esi, msg_data_hdr
    call api_print_string

    mov esi, msg_data_boot
    call api_print_string
    mov esi, msg_data_bootaddr
    call api_print_string
    mov eax, 0x7C00
    call print_hex32
    mov esi, msg_data_loadoff
    call api_print_string
    mov eax, 0x1000
    call print_hex32
    mov esi, msg_data_ksectors
    call api_print_string
    mov eax, 60
    call print_hex32
    mov esi, msg_data_kpa
    call api_print_string
    mov eax, kernel_image_start
    call print_hex32
    mov esi, msg_data_kva
    call api_print_string
    mov eax, kernel_image_start
    call print_hex32
    mov esi, msg_data_kstart
    call api_print_string
    mov eax, kernel_image_start
    call print_hex32
    mov esi, msg_data_kend
    call api_print_string
    mov eax, kernel_image_end
    call print_hex32

    mov esi, msg_data_total
    call api_print_string
    mov eax, [mem_total_bytes]
    call print_hex32
    mov esi, msg_mem_used
    call api_print_string
    mov eax, [mem_used_bytes]
    call print_hex32
    mov esi, msg_mem_free
    call api_print_string
    mov eax, [mem_total_bytes]
    sub eax, [mem_used_bytes]
    call print_hex32

    mov esi, msg_data_malloc
    call api_print_string
    mov esi, msg_data_heap
    call api_print_string
    mov eax, [heap_ptr]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [heap_end]
    call print_hex32
    mov esi, msg_data_last
    call api_print_string
    mov eax, [last_kmalloc_addr]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [last_kmalloc_size]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [kmalloc_count]
    call print_hex32

    mov esi, msg_data_freed
    call api_print_string
    mov esi, msg_data_last
    call api_print_string
    mov eax, [last_frame_free]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [frame_free_count]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [last_kfree_addr]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [kfree_count]
    call print_hex32

    mov esi, msg_data_devices
    call api_print_string
    mov esi, msg_dev_fs
    call api_print_string
    mov eax, [fs_driver_available]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov esi, msg_dev_net
    call api_print_string
    mov eax, [net_driver_available]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov esi, msg_dev_audio
    call api_print_string
    mov eax, [audio_driver_available]
    call print_hex32
    mov esi, msg_data_fs
    call api_print_string
    mov eax, [fs_storage_mode]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [fs_journal_seq]
    call print_hex32

    mov esi, msg_data_tasks
    call api_print_string
    mov esi, msg_sched_on
    call api_print_string
    mov eax, [sched_enabled]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [sched_preemptive]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [sched_task_count]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [sched_current]
    call print_hex32

    mov esi, msg_data_irq
    call api_print_string
    mov eax, [irq_ticks]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [irq1_keys]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [syscall_count]
    call print_hex32

    mov esi, msg_data_errors
    call api_print_string
    mov eax, [memory_error_addr]
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [memory_error_code]
    call print_hex32

    mov esi, msg_data_dump
    call api_print_string
    mov esi, kernel_image_start
    mov ecx, 8
    call print_dword_dump
    mov esi, FRAME_BITMAP
    mov ecx, 4
    call print_dword_dump
    jmp shell_loop

do_change:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .usage
    mov edi, arg_ram
    call strcmp
    cmp eax, 0
    je .to_ram
    mov esi, [arg_ptr]
    mov edi, arg_ata
    call strcmp
    cmp eax, 0
    je .to_ata
    mov esi, [arg_ptr]
    mov edi, arg_a
    call strcmp
    cmp eax, 0
    je .to_fdd
    mov esi, [arg_ptr]
    mov edi, arg_c
    call strcmp
    cmp eax, 0
    je .to_hdd
    mov esi, [arg_ptr]
    mov edi, arg_d
    call strcmp
    cmp eax, 0
    je .to_cd
.usage:
    mov esi, msg_change_usage
    call api_print_string
    jmp shell_loop
.to_ram:
    call fs_init_ram
    mov dword [fs_driver_available], 1
    mov esi, msg_change_ram_ok
    call api_print_string
    jmp shell_loop
.to_ata:
    cmp dword [ata_present], 1
    jne .ata_missing
    call fs_init_ata
    mov dword [fs_driver_available], 1
    mov esi, msg_change_ata_ok
    call api_print_string
    jmp shell_loop
.ata_missing:
    mov esi, msg_change_ata_no
    call api_print_string
    jmp shell_loop
.to_fdd:
    mov al, 'A'
    call storage_select_by_letter
    cmp eax, 0
    je .dev_missing
    call fs_init_ram
    mov dword [fs_driver_available], 1
    mov esi, msg_change_fdd_ok
    call api_print_string
    jmp shell_loop
.to_hdd:
    mov al, 'C'
    call storage_select_by_letter
    cmp eax, 0
    je .dev_missing
    call fs_init_ata
    mov dword [fs_driver_available], 1
    mov esi, msg_change_hdd_ok
    call api_print_string
    jmp shell_loop
.to_cd:
    mov al, 'D'
    call storage_select_by_letter
    cmp eax, 0
    je .dev_missing
    ; CDROM read-only backend pending, keep RAM backend to avoid writes failing.
    call fs_init_ram
    mov dword [fs_driver_available], 1
    mov esi, msg_change_cd_ok
    call api_print_string
    jmp shell_loop
.dev_missing:
    mov esi, msg_change_dev_no
    call api_print_string
    jmp shell_loop

do_alloc:
    mov ecx, 4096
    call kmalloc
    cmp eax, 0
    je .alloc_fail
    mov esi, msg_alloc_ok
    call api_print_string
    call print_hex32
    call frame_alloc
    cmp eax, 0
    je .frame_fail
    mov esi, msg_frame_ok
    call api_print_string
    call print_hex32
    jmp shell_loop
.alloc_fail:
    mov esi, msg_alloc_fail
    call api_print_string
    jmp shell_loop
.frame_fail:
    mov esi, msg_frame_fail
    call api_print_string
    jmp shell_loop

do_free:
    mov eax, [last_frame_alloc]
    cmp eax, 0
    je .free_none
    call frame_free
    mov dword [last_frame_alloc], 0
    mov esi, msg_frame_free_ok
    call api_print_string
    jmp shell_loop
.free_none:
    mov esi, msg_frame_free_no
    call api_print_string
    jmp shell_loop


do_rm:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    call fs_delete_entry
    cmp eax, 0
    je .rm_fail
    mov esi, msg_rm_ok
    call api_print_string
    jmp shell_loop
.rm_fail:
    mov esi, msg_rm_fail
    call api_print_string
    jmp shell_loop

do_cat:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    call fs_read_file
    cmp eax, 0
    je .cat_fail
    mov esi, msg_cat_hdr
    call api_print_string
    mov esi, APP_POINTER
    call api_print_string
    jmp shell_loop
.cat_fail:
    mov esi, msg_cat_fail
    call api_print_string
    jmp shell_loop



do_echo:
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    cmp byte [esi], '$'
    jne .literal
    cmp byte [shell_var_name], 0
    je .literal
    inc esi
    mov edi, shell_var_name
    call strcmp
    cmp eax, 0
    jne .literal_from_arg
    mov esi, msg_newline
    call api_print_string
    mov esi, shell_var_value
    call api_print_string
    jmp shell_loop
.literal_from_arg:
    mov esi, [arg_ptr]
.literal:
    mov esi, msg_newline
    call api_print_string
    mov esi, [arg_ptr]
    call api_print_string
    jmp shell_loop

do_set:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .usage
    mov ebx, [arg2_ptr]
    cmp ebx, 0
    je .usage
    mov edi, shell_var_name
    mov ecx, 15
.copy_name:
    lodsb
    cmp al, 0
    je .name_done
    stosb
    loop .copy_name
.name_done:
    mov byte [edi], 0
    mov esi, [arg2_ptr]
    mov edi, shell_var_value
    mov ecx, 63
.copy_value:
    lodsb
    cmp al, 0
    je .value_done
    stosb
    loop .copy_value
.value_done:
    mov byte [edi], 0
    mov esi, msg_set_ok
    call api_print_string
    jmp shell_loop
.usage:
    mov esi, msg_set_usage
    call api_print_string
    jmp shell_loop

do_copy:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .usage
    cmp dword [arg2_ptr], 0
    je .usage
    call fs_read_file
    cmp eax, 0
    je .fail
    mov esi, [arg2_ptr]
    mov ebx, APP_POINTER
    call fs_write_file
    cmp eax, 0
    je .fail
    mov esi, msg_copy_ok
    call api_print_string
    jmp shell_loop
.usage:
    mov esi, msg_usage_two
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_op_fail
    call api_print_string
    jmp shell_loop

do_move:
do_rename:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .usage
    mov edi, [arg2_ptr]
    cmp edi, 0
    je .usage
    call fs_rename_entry
    cmp eax, 0
    je .fail
    mov esi, msg_move_ok
    call api_print_string
    jmp shell_loop
.usage:
    mov esi, msg_usage_two
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_op_fail
    call api_print_string
    jmp shell_loop

do_hexdump:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    call fs_read_file
    cmp eax, 0
    je .fail
    mov esi, msg_dump_hdr
    call api_print_string
    mov [dump_size], ecx
    xor ebx, ebx
.dump_loop:
    cmp ebx, [dump_size]
    jae shell_loop
    mov eax, ebx
    call print_hex32_no_nl
    mov al, ' '
    call print_char
    mov esi, APP_POINTER
    add esi, ebx
    movzx eax, byte [esi]
    call print_hex8
    mov esi, msg_newline
    call api_print_string
    inc ebx
    jmp .dump_loop
.fail:
    mov esi, msg_cat_fail
    call api_print_string
    jmp shell_loop

do_date:
    mov esi, msg_date_text
    call api_print_string
    jmp shell_loop

do_ver:
    mov esi, msg_ver_text
    call api_print_string
    mov esi, msg_hist_note
    call api_print_string
    jmp shell_loop

do_reboot:
    mov esi, msg_rebooting
    call api_print_string
    mov al, 0xFE
    out 0x64, al
.hang:
    hlt
    jmp .hang

do_shutdown:
    mov esi, msg_shutdown_text
    call api_print_string
    cli
.halt:
    hlt
    jmp .halt

do_mount:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .ram
    mov al, [esi]
    cmp al, 'a'
    jb .sel
    cmp al, 'z'
    ja .sel
    sub al, 32
.sel:
    call storage_select_by_letter
    cmp eax, 0
    je .fail
.ram:
    call fs_init_ram
    mov esi, msg_mount_ok
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_change_dev_no
    call api_print_string
    jmp shell_loop

do_umount:
    mov esi, msg_umount_ok
    call api_print_string
    jmp shell_loop

do_format:
    call fs_format
    mov esi, msg_format_ok
    call api_print_string
    jmp shell_loop

do_run:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .fail
    mov edi, app_sample1_name
    call strcmp
    cmp eax, 0
    je .sample1
    mov esi, [arg_ptr]
    mov edi, app_taskmgr_name
    call strcmp
    cmp eax, 0
    je .taskmgr
    mov esi, [arg_ptr]
    mov edi, app_textedit_name
    call strcmp
    cmp eax, 0
    je .textedit
.fail:
    mov esi, msg_run_fail
    call api_print_string
    jmp shell_loop
.sample1:
    mov eax, 64
    mov ebx, 0x80000
    call floppy_read_sector
    mov ebx, api_table
    call 0x80000
    jmp shell_loop
.textedit:
    mov eax, 66
    mov ebx, 0x81000
    call floppy_read_sector
    mov ebx, api_table
    call 0x81000
    jmp shell_loop
.taskmgr:
    mov eax, 68
    mov ebx, 0x82000
    call floppy_read_sector
    mov ebx, api_table
    call 0x82000
    jmp shell_loop

app_sample1_name db "sample1",0
app_taskmgr_name db "taskmgr",0
app_textedit_name db "textedit",0

do_irq:
    mov esi, msg_irq_ticks
    call api_print_string
    mov eax, [irq_ticks]
    call print_hex32
    jmp shell_loop

do_sched:
    mov esi, msg_sched_ticks
    call api_print_string
    mov eax, [scheduler_ticks]
    call print_hex32
    mov esi, msg_sched_switch
    call api_print_string
    mov eax, [sched_switch_count]
    call print_hex32
    jmp shell_loop

do_task:
    mov esi, msg_sched_on
    call api_print_string
    mov eax, [sched_enabled]
    call print_hex32
    mov esi, msg_tasks_count
    call api_print_string
    mov eax, [sched_task_count]
    call print_hex32
    mov esi, msg_task_curr
    call api_print_string
    mov eax, [sched_current]
    call print_hex32
    mov esi, msg_sched_switch
    call api_print_string
    mov eax, [sched_switch_count]
    call print_hex32
    mov esi, msg_irq1_keys
    call api_print_string
    mov eax, [irq1_keys]
    call print_hex32
    jmp shell_loop

do_syscall:
    mov eax, 2
    int 0x80
    mov esi, msg_syscall_ticks
    call api_print_string
    call print_hex32
    mov eax, 5
    int 0x80
    mov esi, msg_syscall_pid
    call api_print_string
    call print_hex32
    mov esi, msg_syscall_count
    call api_print_string
    mov eax, [syscall_count]
    call print_hex32
    mov eax, 7
    xor ebx, ebx
    int 0x80
    mov esi, msg_syscall_t0
    call api_print_string
    call print_hex32
    jmp shell_loop

do_mktask:
    mov eax, task_demo_entry
    mov ebx, 0x8E000
    call scheduler_add_kthread
    cmp eax, 0
    je .mk_fail
    mov esi, msg_mktask_ok
    call api_print_string
    jmp shell_loop
.mk_fail:
    mov esi, msg_mktask_fail
    call api_print_string
    jmp shell_loop

do_exc:
    mov esi, msg_exc_count
    call api_print_string
    mov eax, [exception_count]
    call print_hex32
    mov esi, msg_exc_last
    call api_print_string
    mov eax, [last_exception]
    call print_hex32
    jmp shell_loop

do_block:
    ; No bloquear task0: es la terminal. Mantener el comando seguro.
    mov esi, msg_block_ok
    call api_print_string
    jmp shell_loop

do_wake:
    xor eax, eax
    call scheduler_wake_task
    mov esi, msg_wake_ok
    call api_print_string
    jmp shell_loop

do_journal:
    mov esi, msg_journal_seq
    call api_print_string
    mov eax, [fs_journal_seq]
    call print_hex32
    jmp shell_loop

do_tasks:
    mov esi, msg_tasks_hdr
    call api_print_string
    xor ebx, ebx
.loop_t:
    cmp ebx, [sched_task_count]
    jae .done_t
    mov eax, ebx
    call print_hex32
    mov edi, sched_tcbs
    imul ecx, ebx, TCB_SIZE
    add edi, ecx
    mov eax, [edi+36]
    call print_hex32
    inc ebx
    jmp .loop_t
.done_t:
    mov esi, msg_sw_from
    call api_print_string
    mov eax, [sched_last_switch_from]
    call print_hex32
    mov esi, msg_sw_to
    call api_print_string
    mov eax, [sched_last_switch_to]
    call print_hex32
    jmp shell_loop

do_vmmap:
    mov eax, 0x003FF000
    mov ebx, 0x003FF000
    mov edx, 0x003
    call map_page
    cmp eax, 0
    je .f
    mov esi, msg_vmmap_ok
    call api_print_string
    jmp shell_loop
.f:
    mov esi, msg_vmmap_fail
    call api_print_string
    jmp shell_loop

do_vmunmap:
    mov eax, 0x003FF000
    call unmap_page
    cmp eax, 0
    je .f2
    mov esi, msg_vmunmap_ok
    call api_print_string
    jmp shell_loop
.f2:
    mov esi, msg_vmunmap_fail
    call api_print_string
    jmp shell_loop

do_help:
    mov esi, msg_help
    call api_print_string
    jmp shell_loop

; ==================================================================
; SUBSISTEMA DE RED (NET)
; ==================================================================

do_net:
    mov dword [hex_arg_ptr], 0
    cmp dword [net_driver_available], 0
    je .net_missing
    mov esi, [arg_ptr]
    cmp esi, 0
    je .show_usage

    mov edi, esi
.find_space_net:
    cmp byte [edi], 0
    je .parse_subcmd
    cmp byte [edi], ' '
    je .split_net
    inc edi
    jmp .find_space_net
.split_net:
    mov byte [edi], 0
    inc edi
    mov dword [hex_arg_ptr], edi 

.parse_subcmd:
    mov edi, net_sub_info
    call strcmp
    cmp eax, 0
    je net_cmd_info

    mov edi, net_sub_up
    call strcmp
    cmp eax, 0
    je net_cmd_up

    mov edi, net_sub_down
    call strcmp
    cmp eax, 0
    je net_cmd_down

    mov edi, net_sub_send
    call strcmp
    cmp eax, 0
    je net_cmd_send

    mov edi, net_sub_recv
    call strcmp
    cmp eax, 0
    je net_cmd_recv

    mov edi, net_sub_listen
    call strcmp
    cmp eax, 0
    je net_cmd_listen

    mov edi, net_sub_dump
    call strcmp
    cmp eax, 0
    je net_cmd_dump

    mov edi, net_sub_stats
    call strcmp
    cmp eax, 0
    je net_cmd_stats

    mov edi, net_sub_config
    call strcmp
    cmp eax, 0
    je net_cmd_config

    mov edi, net_sub_ping
    call strcmp
    cmp eax, 0
    je net_cmd_ping

    mov edi, net_sub_scan
    call strcmp
    cmp eax, 0
    je net_cmd_scan

    mov edi, net_sub_arp
    call strcmp
    cmp eax, 0
    je net_cmd_arp

    mov edi, net_sub_reset
    call strcmp
    cmp eax, 0
    je net_cmd_reset

    mov edi, net_sub_icmp
    call strcmp
    cmp eax, 0
    je net_cmd_icmp

    mov edi, net_sub_l4
    call strcmp
    cmp eax, 0
    je net_cmd_l4

    mov edi, net_sub_proto
    call strcmp
    cmp eax, 0
    je net_cmd_proto

    mov edi, net_sub_paginf
    call strcmp
    cmp eax, 0
    je net_cmd_paginf

.net_missing:
    mov esi, msg_net_unavail
    call api_print_string
    jmp shell_loop

.show_usage:
    mov esi, msg_net_usage
    call api_print_string
    jmp shell_loop

; --- SUBCOMANDOS NET ---

net_cmd_info:
    mov esi, msg_net_info
    call api_print_string
    jmp shell_loop

net_cmd_up:
    call rtl8139_init
    cmp eax, 0
    je do_net.net_missing
    mov dword [net_driver_available], 1
    mov esi, msg_net_up
    call api_print_string
    jmp shell_loop

net_cmd_down:
    call rtl8139_shutdown
    mov esi, msg_net_down
    call api_print_string
    jmp shell_loop

net_cmd_send:
    mov esi, [hex_arg_ptr]
    cmp esi, 0
    je do_net.show_usage

    mov edi, RTL8139_TX_BUF
    xor ecx, ecx         

.hex_parse_loop:
    mov al, [esi]
    cmp al, 0
    je .hex_parse_done
    call char_to_hex
    cmp ah, 1            
    je .send_err
    shl al, 4            
    mov bl, al
    inc esi
    mov al, [esi]
    cmp al, 0
    je .send_err         
    call char_to_hex
    cmp ah, 1
    je .send_err
    or al, bl
    cmp ecx, 1518
    jae .send_err         ; Evitar desbordar el buffer TX
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    jmp .hex_parse_loop

.hex_parse_done:
    ; Llama al driver con la longitud en ECX
    call rtl8139_transmit
    inc dword [net_pkts_sent]
    mov esi, msg_net_send_ok
    call api_print_string
    jmp shell_loop

.send_err:
    mov esi, msg_net_send_err
    call api_print_string
    inc dword [net_errors]
    jmp shell_loop

net_cmd_recv:
    call rtl8139_receive
    cmp ecx, 0
    je shell_loop
    inc dword [net_pkts_recv]
    call net_update_arp_from_last
    call print_packet_dump
    jmp shell_loop

net_cmd_listen:
    mov esi, msg_net_listen
    call api_print_string
.listen_loop:
    call kbd_read_char
    cmp al, 0x1B         ; ESC
    je shell_loop
    call rtl8139_receive
    cmp ecx, 0
    je .continue_listen
    inc dword [net_pkts_recv]
    call net_update_arp_from_last
    call print_packet_dump
.continue_listen:
    call api_delay
    jmp .listen_loop

net_cmd_dump:
    call print_packet_dump
    jmp shell_loop

net_cmd_stats:
    mov esi, msg_net_stats
    call api_print_string
    mov eax, [net_pkts_sent]
    call print_hex32
    mov esi, msg_net_recv_msg
    call api_print_string
    mov eax, [net_pkts_recv]
    call print_hex32
    mov esi, msg_net_err
    call api_print_string
    mov eax, [net_errors]
    call print_hex32
    mov esi, msg_rtl_stats
    call api_print_string
    mov eax, [rtl_tx_packets]
    call print_hex32
    mov esi, msg_rtl_rx_ok
    call api_print_string
    mov eax, [rtl_rx_packets]
    call print_hex32
    mov esi, msg_rtl_tx_err
    call api_print_string
    mov eax, [rtl_tx_errors]
    call print_hex32
    mov esi, msg_rtl_rx_err
    call api_print_string
    mov eax, [rtl_rx_errors]
    call print_hex32
    mov esi, msg_rtl_last_len
    call api_print_string
    mov eax, [rtl_last_rx_len]
    call print_hex32
    mov esi, msg_rtl_last_isr
    call api_print_string
    movzx eax, word [rtl_last_isr]
    call print_hex32
    jmp shell_loop

net_cmd_config:
    mov esi, msg_net_ip_lbl
    call api_print_string
    mov esi, net_local_ip
    call print_ip4
    mov esi, msg_net_msk_lbl
    call api_print_string
    mov esi, msg_net_gw_lbl
    call api_print_string
    mov esi, net_gw_ip
    call print_ip4
    mov esi, msg_net_dns_lbl
    call api_print_string
    mov esi, net_dns_ip
    call print_ip4
    jmp shell_loop

net_cmd_ping:
    call net_build_arp_request
    call rtl8139_transmit
    cmp eax, 0
    je .ping_fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_ping_rep
    call api_print_string
    jmp shell_loop
.ping_fail:
    inc dword [net_errors]
    mov esi, msg_net_unavail
    call api_print_string
    jmp shell_loop


net_cmd_arp:
    call print_arp_table
    call net_build_arp_request
    call rtl8139_transmit
    inc dword [net_pkts_sent]
    mov esi, msg_net_arp_tx
    call api_print_string
    jmp shell_loop

net_cmd_reset:
    call rtl8139_init
    cmp eax, 0
    je do_net.net_missing
    mov dword [net_driver_available], 1
    mov esi, msg_net_reset_ok
    call api_print_string
    jmp shell_loop

net_cmd_icmp:
    call rtl8139_receive
    cmp ecx, 0
    je .icmp_none
    call net_update_arp_from_last
    mov esi, RTL8139_LAST_RX_BUF
    call net_parse_icmp_echo
    cmp eax, 1
    jne .icmp_none
    mov esi, msg_net_icmp_ok
    call api_print_string
    jmp shell_loop
.icmp_none:
    mov esi, msg_net_icmp_none
    call api_print_string
    jmp shell_loop

net_cmd_l4:
    call rtl8139_receive
    cmp ecx, 0
    je .none
    call net_update_arp_from_last
    mov esi, RTL8139_LAST_RX_BUF
    call net_parse_l4
    cmp eax,1
    je .icmp
    cmp eax,2
    je .tcp
    cmp eax,3
    je .udp
.none:
    mov esi, msg_net_l4_none
    call api_print_string
    jmp shell_loop
.icmp:
    mov esi, msg_net_l4_icmp
    call api_print_string
    jmp shell_loop
.tcp:
    mov esi, msg_net_l4_tcp
    call api_print_string
    jmp shell_loop
.udp:
    mov esi, msg_net_l4_udp
    call api_print_string
    jmp shell_loop

net_cmd_proto:
    mov esi, msg_net_proto
    call api_print_string
    jmp shell_loop

net_cmd_paginf:
    mov esi, [hex_arg_ptr]
    cmp esi, 0
    je .usage
    cmp byte [esi], 0
    je .usage
    mov esi, msg_net_paginf_host
    call api_print_string
    mov esi, [hex_arg_ptr]
    call api_print_string
    mov esi, msg_net_paginf_start
    call api_print_string
    call net_build_dns_arp_request
    call rtl8139_transmit
    cmp eax, 0
    je .fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_paginf_wait
    call api_print_string
    jmp shell_loop
.usage:
    mov esi, msg_net_paginf_use
    call api_print_string
    jmp shell_loop
.fail:
    inc dword [net_errors]
    mov esi, msg_net_unavail
    call api_print_string
    jmp shell_loop

net_cmd_scan:
    call net_build_arp_request
    call rtl8139_transmit
    cmp eax, 0
    je .scan_fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_scan
    call api_print_string
    mov esi, msg_net_timeout
    call api_print_string
    jmp shell_loop
.scan_fail:
    inc dword [net_errors]
    mov esi, msg_net_unavail
    call api_print_string
    jmp shell_loop


; ==================================================================
; UTILIDADES BÁSICAS Y RED
; ==================================================================
print_entry_name:
    ; ESI = entrada de directorio. Copia nombre de 16 bytes a un
    ; buffer terminado en cero para no imprimir LBA/tamaño como texto.
    pusha
    mov edi, entry_name_buffer
    mov ecx, 16
.copy:
    lodsb
    cmp al, 0
    je .zero_rest
    stosb
    loop .copy
    jmp .done_copy
.zero_rest:
    mov byte [edi], 0
    jmp .print
.done_copy:
    mov byte [edi], 0
.print:
    mov esi, entry_name_buffer
    call api_print_string
    popa
    ret

print_char:
    pusha
    mov [char_buffer], al
    mov byte [char_buffer+1], 0
    mov esi, char_buffer
    call api_print_string
    popa
    ret


print_hex32_no_nl:
    pusha
    mov edi, hex_buffer
    mov ecx, 8
.hex_loop:
    rol eax, 4
    mov bl, al
    and bl, 0x0F
    cmp bl, 9
    jle .digit
    add bl, 55
    jmp .store
.digit:
    add bl, 48
.store:
    mov [edi], bl
    inc edi
    loop .hex_loop
    mov byte [edi], 0
    mov esi, hex_buffer
    call api_print_string
    popa
    ret

print_hex8:
    pusha
    mov ah, al
    shr al, 4
    call .nibble
    mov al, ah
    and al, 0x0F
    call .nibble
    popa
    ret
.nibble:
    cmp al, 9
    jle .dig
    add al, 55
    jmp print_char
.dig:
    add al, 48
    jmp print_char

print_hex32:
    pusha
    mov edi, hex_buffer
    mov ecx, 8
.hex_loop:
    rol eax, 4
    mov bl, al
    and bl, 0x0F
    cmp bl, 9
    jle .digit
    add bl, 55
    jmp .store
.digit:
    add bl, 48
.store:
    mov [edi], bl
    inc edi
    loop .hex_loop
    mov byte [edi], 0
    mov esi, hex_buffer
    call api_print_string
    mov esi, msg_num_nl
    call api_print_string
    popa
    ret

strcpy:
.loop:
    mov al, [esi]
    mov [edi], al
    cmp al, 0
    je .done
    inc esi
    inc edi
    jmp .loop
.done:
    ret

strcmp:
    push esi
    push edi
.loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .diff
    cmp al, 0
    je .same
    inc esi
    inc edi
    jmp .loop
.diff:
    mov eax, 1
    pop edi
    pop esi
    ret
.same:
    xor eax, eax
    pop edi
    pop esi
    ret

char_to_hex:
    mov ah, 0
    cmp al, '0'
    jl .invalid
    cmp al, '9'
    jle .is_num
    cmp al, 'A'
    jl .invalid
    cmp al, 'F'
    jle .is_upper
    cmp al, 'a'
    jl .invalid
    cmp al, 'f'
    jle .is_lower
.invalid:
    mov ah, 1
    ret
.is_num:
    sub al, '0'
    ret
.is_upper:
    sub al, 'A'
    add al, 10
    ret
.is_lower:
    sub al, 'a'
    add al, 10
    ret

print_mac:
    ; ESI = 6-byte MAC
    pusha
    mov edi, esi
    mov ecx, 6
.mac_loop:
    movzx eax, byte [edi]
    call print_hex8
    inc edi
    dec ecx
    jz .done
    mov esi, colon_char
    call api_print_string
    jmp .mac_loop
.done:
    popa
    ret

print_arp_table:
    pusha
    mov esi, msg_arp_hdr
    call api_print_string
    mov edi, net_arp_table
    mov ebx, 0
    mov ecx, 4
.row:
    cmp dword [edi], 0
    je .next
    inc ebx
    mov esi, edi
    call print_ip4_inline
    mov esi, space_char
    call api_print_string
    lea esi, [edi + 4]
    call print_mac
    mov esi, msg_newline
    call api_print_string
.next:
    add edi, 10
    loop .row
    cmp ebx, 0
    jne .done
    mov esi, msg_arp_empty
    call api_print_string
.done:
    popa
    ret


print_dword_dump:
    ; ESI = address, ECX = dword count
    pusha
    mov edi, esi
    mov ebx, ecx
.dump_loop:
    cmp ebx, 0
    je .done
    mov eax, edi
    call print_hex32_no_nl
    mov esi, space_char
    call api_print_string
    mov eax, [edi]
    call print_hex32
    add edi, 4
    dec ebx
    jmp .dump_loop
.done:
    popa
    ret

print_packet_dump:
    pusha
    mov esi, msg_net_len
    call api_print_string
    mov eax, [rtl_last_rx_len]
    call print_hex32
    mov esi, msg_net_hex
    call api_print_string
    mov ebx, 0
.dump_hex:
    cmp ebx, [rtl_last_rx_len]
    jae .ascii
    cmp ebx, 64
    jae .ascii
    mov esi, RTL8139_LAST_RX_BUF
    add esi, ebx
    movzx eax, byte [esi]
    call print_hex8
    mov al, ' '
    call print_char
    inc ebx
    jmp .dump_hex
.ascii:
    mov esi, msg_net_ascii
    call api_print_string
    mov ebx, 0
.dump_ascii:
    cmp ebx, [rtl_last_rx_len]
    jae .done
    cmp ebx, 64
    jae .done
    mov esi, RTL8139_LAST_RX_BUF
    add esi, ebx
    mov al, [esi]
    cmp al, 32
    jb .dot
    cmp al, 126
    jbe .emit
.dot:
    mov al, '.'
.emit:
    call print_char
    inc ebx
    jmp .dump_ascii
.done:
    popa
    ret

print_ip4_inline:
    pusha
    mov edi, esi
    mov ecx, 4
.octet:
    movzx eax, byte [edi]
    call print_dec_u8
    inc edi
    dec ecx
    jz .done
    mov esi, dot_char
    call api_print_string
    jmp .octet
.done:
    popa
    ret

print_ip4:
    pusha
    mov edi, esi
    mov ecx, 4
.octet:
    movzx eax, byte [edi]
    call print_dec_u8
    inc edi
    dec ecx
    jz .done
    mov esi, dot_char
    call api_print_string
    jmp .octet
.done:
    mov esi, msg_num_nl
    call api_print_string
    popa
    ret

print_dec_u8:
    pusha
    xor esi, esi            ; printed flag
    xor edx, edx
    mov ebx, 100
    div ebx
    cmp eax, 0
    je .skip_hundreds
    add al, '0'
    call print_char
    mov esi, 1
.skip_hundreds:
    mov eax, edx
    xor edx, edx
    mov ebx, 10
    div ebx
    cmp eax, 0
    jne .print_tens
    cmp esi, 0
    je .ones
.print_tens:
    add al, '0'
    call print_char
    mov esi, 1
.ones:
    add dl, '0'
    mov al, dl
    call print_char
    popa
    ret
task_demo_entry:
    mov esi, msg_newline
    call api_print_string
    mov esi, msg_welcome
    call api_print_string
    jmp task_demo_entry
