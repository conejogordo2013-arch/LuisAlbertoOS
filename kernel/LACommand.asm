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

cmd_buffer        times 64 db 0
arg_ptr           dd 0

current_path      times 128 db 0
path_root_init    db "C:/",0

BUFFER_EDITOR     times 512 db 0 

; Comandos Básicos
cmd_dir       db "dir",0
cmd_clear     db "clear",0
cmd_cd        db "cd",0
cmd_mkdir     db "mkdir",0
cmd_touch     db "touch",0
cmd_edit      db "edit",0
cmd_audio     db "audio",0
cmd_img       db "img",0
cmd_help      db "help",0
cmd_net       db "net",0
cmd_devices   db "devices",0
cmd_beep      db "beep",0
cmd_pwd       db "pwd",0
cmd_meminfo   db "meminfo",0
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
cmd_ring3     db "ring3",0

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

; Mensajes Básicos
msg_err_cmd       db 0x0A,"Error: comando no reconocido.",0
msg_created_dir   db 0x0A,"Carpeta creada en disco.",0
msg_created_file  db 0x0A,"Archivo creado en disco.",0
msg_edit_info     db 0x0A,"--- EDITOR (ESC para guardar y salir) ---",0x0A,0
msg_saved         db 0x0A,"Archivo guardado.",0
msg_dir_header    db 0x0A,"-- DIRECTORIO ACTUAL --",0x0A,0
msg_dir_type      db " <DIR>",0
msg_audio     db 0x0A,"Comando no implementado.",0
msg_err_img       db 0x0A,"Error: Archivo de imagen no encontrado o vacio.",0
msg_help          db 0x0A, "Comandos disponibles:",0x0A, \
                "dir    - Lista directorio",0x0A, \
                "clear  - Limpia pantalla",0x0A, \
                "cd     - Cambia directorio",0x0A, \
                "mkdir  - Crea carpeta",0x0A, \
                "touch  - Crea archivo",0x0A, \
                "edit   - Editor de archivos",0x0A, \
                "audio  - Reproducir WAV No implementado Aun",0x0A, \
                "img    - Visualizador de imagen",0x0A, \
                "net    - Subsistema de red (net help)",0x0A, \
                "help   - Muestra esta ayuda",0x0A, \
                "devices- Estado de drivers",0x0A, \
                "beep   - Prueba audio AC97",0x0A, \
                "pwd    - Muestra ruta actual",0x0A, \
                "meminfo- Estado memoria",0x0A, \
                "alloc  - Reserva 4KB",0x0A, \
                "free   - Libera ultimo frame",0x0A, \
                "rm     - Elimina entrada",0x0A, \
                "cat    - Muestra archivo",0x0A, \
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
                "vmunmap- Unmap page demo",0x0A, \
                "ring3  - Probar salto ring3",0

; Mensajes de Red
msg_net_usage     db 0x0A,"Uso: net <comando> [args]",0x0A,"Comandos: info, up, down, send, recv, listen, dump, stats, config, ping, scan, arp, reset, icmp, l4, proto",0
msg_net_up        db 0x0A,"Red inicializada (RTL8139 UP). RX/TX habilitados.",0
msg_net_down      db 0x0A,"Red deshabilitada (RTL8139 DOWN).",0
msg_net_info      db 0x0A,"Dispositivo: RTL8139",0x0A,"Estado: UP",0x0A,"MAC: Cargada",0
msg_net_config    db 0x0A,"IP: 192.168.1.100",0x0A,"Mascara: 255.255.255.0",0x0A,"Gateway: 192.168.1.1",0
msg_net_stats     db 0x0A,"-- Estadisticas de Red --",0x0A,"Enviados: ",0
msg_net_recv_msg  db 0x0A,"Paquetes Recibidos: ",0
msg_net_err       db 0x0A,"Errores: ",0
msg_net_ping_rep  db 0x0A,"Respuesta desde destino. Tiempo: <1ms",0
msg_net_scan      db 0x0A,"Escaneando red local... (Modo promiscuo)",0
msg_net_listen    db 0x0A,"Escuchando paquetes (ESC para salir)...",0
msg_net_send_err  db 0x0A,"Error: Formato Hexadecimal Invalido.",0
msg_net_send_ok   db 0x0A,"Paquete enviado correctamente.",0
msg_net_timeout   db 0x0A,"Tiempo de espera agotado.",0
msg_net_arp_tx    db 0x0A,"ARP request enviado (gateway).",0
msg_net_reset_ok  db 0x0A,"Driver de red reiniciado.",0
msg_net_icmp_none db 0x0A,"No ICMP echo request detectado.",0
msg_net_icmp_ok   db 0x0A,"ICMP echo request detectado.",0
msg_net_l4_none   db 0x0A,"L4: none/no ipv4",0
msg_net_l4_icmp   db 0x0A,"L4: ICMP",0
msg_net_l4_tcp    db 0x0A,"L4: TCP",0
msg_net_l4_udp    db 0x0A,"L4: UDP",0
msg_net_proto     db 0x0A,"Proto stack: ETH/ARP/IP/ICMP/TCP/UDP (parser base)",0
msg_fs_unavail    db 0x0A,"Error: almacenamiento ATA no disponible.",0
msg_net_unavail   db 0x0A,"Error: red RTL8139 no disponible.",0
msg_audio_unavail db 0x0A,"Error: audio AC97 no disponible.",0
msg_dev_status    db 0x0A,"Estado dispositivos:",0x0A,0
msg_dev_fs        db "ATA: ",0
msg_dev_net       db 0x0A,"RTL8139: ",0
msg_dev_audio     db 0x0A,"AC97: ",0
msg_dev_ok        db "OK",0
msg_dev_missing   db "NO DETECTADO",0
msg_mem_hdr       db 0x0A,"Memoria kernel:",0x0A,0
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
msg_block_ok      db 0x0A,"Task actual bloqueada.",0
msg_wake_ok       db 0x0A,"Task 0 despertada.",0
msg_journal_seq   db 0x0A,"FS journal seq: ",0
msg_tasks_hdr     db 0x0A,"Tasks (idx/state):",0x0A,0
msg_vmmap_ok      db 0x0A,"vm map ok",0
msg_vmmap_fail    db 0x0A,"vm map fail",0
msg_vmunmap_ok    db 0x0A,"vm unmap ok",0
msg_vmunmap_fail  db 0x0A,"vm unmap fail",0
msg_ring3_info    db 0x0A,"Saltando a user stub ring3...",0
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

; ==================================================================
; INICIO DEL SHELL
; ==================================================================

shell_start:
    cmp byte [current_path], 0
    jne skip_init
    mov esi, path_root_init
    mov edi, current_path
    call strcpy
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
    xor ecx, ecx
read_key:
    call kbd_read_char
    cmp al, 0
    je read_key
    cmp al, 0x0A
    je parse_command
    cmp al, 0x08
    je handle_backspace

    cmp ecx, 62
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

    mov edi, cmd_ring3
    call strcmp
    cmp eax, 0
    je do_ring3

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
    mov edi, esi
    push esi
    push ecx
    call api_print_string
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
    add esi, 24          
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
    mov ecx, 512
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
    cmp ecx, 511         
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
    jmp .edit_loop
.save_file:
    mov byte [edi], 0
    mov esi, [arg_ptr]     
    mov ebx, BUFFER_EDITOR 
    mov ecx, 512           
    call fs_write_file
    mov esi, msg_saved
    call api_print_string
    jmp shell_loop

do_audio:
    mov esi, msg_audio
    call api_print_string
    jmp shell_loop

do_img:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
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
    mov esi, msg_dev_ok
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
    mov esi, msg_mem_total
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
    mov byte [APP_POINTER+511], 0
    mov esi, msg_cat_hdr
    call api_print_string
    mov esi, APP_POINTER
    call api_print_string
    jmp shell_loop
.cat_fail:
    mov esi, msg_cat_fail
    call api_print_string
    jmp shell_loop


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
    call scheduler_block_current
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

do_ring3:
    mov esi, msg_ring3_info
    call api_print_string
    ; construir iret frame a CPL3
    cli
    mov ax, 0x23
    mov ds, ax
    mov es, ax
    push dword 0x23
    push dword 0x8D000
    pushfd
    pop eax
    or eax, 0x200
    push eax
    push dword 0x1B
    push dword user_entry_stub
    iretd

do_help:
    mov esi, msg_help
    call api_print_string
    jmp shell_loop

; ==================================================================
; SUBSISTEMA DE RED (NET)
; ==================================================================

do_net:
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
    mov esi, msg_net_up
    call api_print_string
    jmp shell_loop

net_cmd_down:
    ; Simula apagado
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
    jmp shell_loop

net_cmd_config:
    mov esi, msg_net_config
    call api_print_string
    jmp shell_loop

net_cmd_ping:
    call api_delay
    mov esi, msg_net_ping_rep
    call api_print_string
    inc dword [net_pkts_sent]
    inc dword [net_pkts_recv]
    jmp shell_loop


net_cmd_arp:
    call net_build_arp_request
    call rtl8139_transmit
    inc dword [net_pkts_sent]
    mov esi, msg_net_arp_tx
    call api_print_string
    jmp shell_loop

net_cmd_reset:
    call rtl8139_init
    mov esi, msg_net_reset_ok
    call api_print_string
    jmp shell_loop

net_cmd_icmp:
    call rtl8139_receive
    cmp ecx, 0
    je .icmp_none
    mov esi, RTL8139_RX_BUF
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
    mov esi, RTL8139_RX_BUF
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

net_cmd_scan:
    mov esi, msg_net_scan
    call api_print_string
    call api_delay
    mov esi, msg_net_timeout
    call api_print_string
    jmp shell_loop


; ==================================================================
; UTILIDADES BÁSICAS Y RED
; ==================================================================
print_char:
    pusha
    mov byte [cmd_buffer+60], al
    mov byte [cmd_buffer+61], 0
    mov esi, cmd_buffer+60
    call api_print_string
    popa
    ret

print_hex32:
    pusha
    mov edi, cmd_buffer+40
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
    mov esi, cmd_buffer+40
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

print_packet_dump:
    mov esi, msg_net_len
    call api_print_string
    mov esi, msg_net_hex
    call api_print_string
    mov esi, msg_net_ascii
    call api_print_string
    ret
task_demo_entry:
    mov esi, msg_newline
    call api_print_string
    mov esi, msg_welcome
    call api_print_string
    jmp task_demo_entry
