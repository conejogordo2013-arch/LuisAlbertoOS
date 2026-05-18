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

current_path      times 128 db 0
path_root_init    db "C:/",0

BUFFER_EDITOR     times FS_MAX_FILE_SIZE db 0

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
cmd_change    db "change",0
cmd_read      db "read",0
cmd_write     db "write",0
cmd_drives    db "drives",0
cmd_listdisks db "listdisks",0
cmd_echo      db "echo",0
cmd_ver       db "ver",0
cmd_hexdump   db "hexdump",0
cmd_run       db "run",0
cmd_yield     db "yield",0
cmd_copy      db "copy",0
cmd_rename    db "rename",0
cmd_format    db "format",0
cmd_type      db "type",0
cmd_cls       db "cls",0
cmd_del       db "del",0
cmd_stat      db "stat",0
cmd_fsinfo    db "fsinfo",0
cmd_move      db "move",0
cmd_date      db "date",0
cmd_reboot    db "reboot",0
cmd_shutdown  db "shutdown",0
cmd_mount     db "mount",0
cmd_umount    db "umount",0
cmd_play      db "play",0
cmd_sleep     db "sleep",0
cmd_kill      db "kill",0
cmd_priority  db "priority",0
cmd_preempt   db "preempt",0
cmd_cdinfo    db "cdinfo",0
cmd_blocks    db "blocks",0

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
net_sub_status    db "status",0
net_sub_clone     db "clone",0
net_sub_navigate  db "navigate",0
net_sub_udp       db "udp",0
net_sub_dhcp      db "dhcp",0
net_sub_dns       db "dns",0
net_sub_tcp       db "tcp",0
net_sub_http      db "http",0

; Mensajes Básicos
msg_err_cmd       db 0x0A,"Error: comando no reconocido.",0
msg_created_dir   db 0x0A,"Carpeta creada.",0
msg_created_file  db 0x0A,"Archivo creado.",0
msg_edit_info     db 0x0A,"--- EDITOR (ESC para guardar y salir) ---",0x0A,0
msg_saved         db 0x0A,"Archivo guardado.",0
msg_dir_header    db 0x0A,"-- DIRECTORIO ACTUAL --",0x0A,0
msg_dir_type      db " <DIR>",0
msg_audio     db 0x0A,"Audio: usa beep para probar salida sonora.",0
msg_err_img       db 0x0A,"Error: Archivo de imagen no encontrado o vacio.",0
msg_help          db 0x0A, "Comandos disponibles:",0x0A, \
                "dir    - Lista directorio",0x0A, \
                "clear  - Limpia pantalla",0x0A, \
                "cd     - Cambia directorio",0x0A, \
                "mkdir  - Crea carpeta",0x0A, \
                "touch  - Crea archivo",0x0A, \
                "edit   - Editor de archivos",0x0A, \
                "audio  - Estado/prueba de audio",0x0A, \
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
                "change - Cambia unidad/driver",0x0A, \
                "read   - Lee unidad A/C/D",0x0A, \
                "write  - Escribe unidad A/C",0x0A, \
                "drives - Muestra A:/ C:/ D:/",0x0A, \
                "listdisks- Lista discos detectados",0x0A, \
                "echo   - Imprime texto",0x0A, \
                "ver    - Version/capacidades",0x0A, \
                "hexdump- Vuelca archivo en hex",0x0A, \
                "run    - Ejecuta app demo",0x0A, \
                "yield  - Cede scheduler",0x0A, \
                "copy   - Copia archivo",0x0A, \
                "rename - Renombra entrada",0x0A, \
                "format - Reinicia RAM FS",0x0A, \
                "type   - Alias de cat",0x0A, \
                "stat   - Info de archivo",0x0A, \
                "fsinfo - Estado detallado FS",0x0A, \
                "move/date/mount/play/sleep/kill",0x0A, \
                "blocks - Tabla de bloques archivo",0

; Mensajes de Red
msg_net_usage     db 0x0A,"Uso: net <comando> [args]",0x0A,"Comandos: info, up, down, send, recv, listen, dump, stats, config, ping, scan, arp, reset, icmp, l4, proto, paginf, status, clone, navigate, udp, dhcp, dns, tcp, http",0
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
msg_net_arp_tbl   db 0x0A,"ARP table: ",0
msg_net_auto      db 0x0A,"Auto RX: ARP table/ICMP reply procesados.",0
msg_net_udp_tx    db 0x0A,"UDP demo enviado.",0
msg_net_dhcp_tx   db 0x0A,"DHCP discover enviado.",0
msg_net_dns_tx    db 0x0A,"DNS query demo enviado.",0
msg_net_tcp_tx    db 0x0A,"TCP SYN demo enviado.",0
msg_net_http_tx   db 0x0A,"HTTP GET demo enviado.",0
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
msg_net_status_dev_no db 0x0A,"Dispositivo no encontrado.",0
msg_net_status_dev_net_no db 0x0A,"Dispositivo encontrado: No hay Red",0
msg_net_status_dev_net_yes db 0x0A,"Dispositivo Encontrado: hay red",0
msg_net_status_multi db 0x0A,"NICs detectadas: rtl8139 + e1000",0
msg_net_clone_use db 0x0A,"Uso: net clone <url>",0
msg_net_clone_unavail db 0x0A,"Clone real requiere TCP/HTTP + parser Git. Aun no implementado en kernel.",0
msg_net_nav_use   db 0x0A,"Uso: net navigate <url>",0
msg_net_nav_start db 0x0A,"Navegacion texto: resolviendo gateway por ARP...",0
msg_net_nav_wait  db 0x0A,"Modo ligero: texto/chats sin imagenes. Espera trafico real con net listen/recv.",0
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
msg_dev_ata_disk  db 0x0A,"ATA Disk: ",0
msg_dev_sb16      db 0x0A,"SB16: ",0
msg_dev_e1000     db 0x0A,"E1000: ",0
msg_dev_floppy    db 0x0A,"Floppy: ",0
msg_dev_cdrom     db 0x0A,"CDROM: ",0
msg_dev_sata      db 0x0A,"SATA: ",0
msg_dev_ok        db "OK",0
msg_dev_ram       db "RAM FS",0
msg_dev_ata       db "ATA FS",0
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
msg_block_ok      db 0x0A,"Protegido: la shell principal no se bloquea.",0
msg_wake_ok       db 0x0A,"Task 0 despertada.",0
msg_journal_seq   db 0x0A,"FS journal seq: ",0
msg_tasks_hdr     db 0x0A,"Tasks (idx/state):",0x0A,0
msg_vmmap_ok      db 0x0A,"vm map ok",0
msg_vmmap_fail    db 0x0A,"vm map fail",0
msg_vmunmap_ok    db 0x0A,"vm unmap ok",0
msg_vmunmap_fail  db 0x0A,"vm unmap fail",0
msg_change_usage  db 0x0A,"Uso: change <a|c|d|floppy|cdrom|ram|ata>",0
msg_change_usage2 db 0x0A,"Uso extendido: change disk <a|c|d|floppy|cdrom|ram|ata> | change disp <rtl8139|e1000> | change sd <ac97|sb16>",0
msg_change_ram_ok db 0x0A,"Cambiado a Ram Correctamente.",0
msg_change_ata_ok db 0x0A,"Cambiado a ata Correctamente.",0
msg_change_ata_no db 0x0A,"No se encontro disco.",0
msg_change_a_ok db 0x0A,"Cambiado a unidad A:/ Floppy.",0
msg_change_c_ok db 0x0A,"Cambiado a unidad C:/ Disco duro.",0
msg_change_d_ok db 0x0A,"Cambiado a unidad D:/ CDROM.",0
msg_change_disp_rtl_ok db 0x0A,"Dispositivo de red activo: rtl8139",0
msg_change_disp_e1000_ok db 0x0A,"Dispositivo de red activo: e1000",0
msg_change_disp_no db 0x0A,"Dispositivo de red no detectado.",0
msg_change_sd_ok_ac97 db 0x0A,"Driver de sonido activo: ac97",0
msg_change_sd_ok_sb16 db 0x0A,"Driver de sonido activo: sb16",0
msg_change_sd_no db 0x0A,"Driver de sonido no detectado.",0
msg_cd_disk_ok    db 0x0A,"Unidad actual: C:/",0
msg_cd_a_ok       db 0x0A,"Unidad actual: A:/",0
msg_cd_d_ok       db 0x0A,"Unidad actual: D:/",0
msg_cd_no_drive   db 0x0A,"Unidad no detectada.",0
msg_read_use      db 0x0A,"Uso: read <a|c|d|floppy|cdrom>",0
msg_read_floppy_ok db 0x0A,"Floppy leido en A:/",0
msg_read_disk_ok  db 0x0A,"Disco leido en C:/",0
msg_read_cdrom_ok db 0x0A,"CDROM leido en D:/",0
msg_read_no       db 0x0A,"Dispositivo no detectado.",0
msg_write_use     db 0x0A,"Uso: write <a|c|d> <texto>",0
msg_write_a_ok    db 0x0A,"Escritura en A:/ completada.",0
msg_write_c_ok    db 0x0A,"Escritura en C:/ completada.",0
msg_write_d_ok    db 0x0A,"D:/ es CDROM de solo lectura.",0
msg_drives_hdr    db 0x0A,"Unidades detectadas:",0
msg_drive_a_on    db 0x0A,"A:/ Floppy listo",0
msg_drive_c_on    db 0x0A,"C:/ RAM/ATA FS listo",0
msg_drive_d_on    db 0x0A,"D:/ CDROM listo",0
msg_drive_off     db "NO",0
msg_listdisks_hdr db 0x0A,"Discos detectados para usar con cd <disk> y read <disk>:",0
msg_listdisk_flp  db 0x0A,"A: floppy",0
msg_listdisk_hdd  db 0x0A,"C: disco duro",0
msg_listdisk_cdr  db 0x0A,"D: cdrom",0
msg_ver           db 0x0A,"LuisAlbertoOS v1.0 / Shell v3.2",0x0A,"FS: 16 archivos x 2048 bytes, RAM/ATA multi-sector",0x0A,"Apps: run sample1|textedit|taskmgr",0x0A,"Audio: AC97 beep + SB16 probe",0x0A,"Storage: A floppy, C RAM/ATA, D CDROM detect",0x0A,"Net: RTL8139/E1000 wrappers experimentales",0
msg_hexdump_use   db 0x0A,"Uso: hexdump <archivo>",0
msg_hexdump_hdr   db 0x0A,"Hexdump:",0x0A,0
msg_run_use       db 0x0A,"Uso: run <sample1|textedit|taskmgr>",0
msg_run_missing   db 0x0A,"App no encontrada.",0
msg_yield_ok      db 0x0A,"Yield scheduler ejecutado.",0
app_name_sample1  db "sample1",0
app_name_textedit db "textedit",0
app_name_taskmgr  db "taskmgr",0
app_msg_sample1   db 0x0A,"[App] Sample1: Hello from Application Space!",0
app_msg_textedit  db 0x0A,"[App] TextEdit: Read-only mode for prototype.",0
app_msg_taskmgr   db 0x0A,"[App] TaskMgr: No concurrent tasks running.",0
msg_copy_use      db 0x0A,"Uso: copy <origen> <destino>",0
msg_copy_ok       db 0x0A,"Archivo copiado.",0
msg_copy_fail     db 0x0A,"No se pudo copiar.",0
msg_rename_use    db 0x0A,"Uso: rename <actual> <nuevo>",0
msg_rename_ok     db 0x0A,"Entrada renombrada.",0
msg_rename_fail   db 0x0A,"No se pudo renombrar.",0
msg_format_use    db 0x0A,"Uso: format ram",0
msg_format_ok     db 0x0A,"RAM FS formateado.",0
msg_stat_use      db 0x0A,"Uso: stat <archivo>",0
msg_stat_fail     db 0x0A,"Entrada no encontrada.",0
msg_stat_hdr      db 0x0A,"Stat:",0x0A,"Nombre: ",0
msg_stat_lba      db 0x0A,"LBA: ",0
msg_stat_size     db 0x0A,"Size: ",0
msg_stat_flag     db 0x0A,"Flag: ",0
msg_fsinfo_hdr    db 0x0A,"FS info:",0x0A,"Modo: ",0
msg_fsinfo_max    db 0x0A,"Max file bytes: ",0
msg_fsinfo_used   db 0x0A,"Entradas usadas: ",0
msg_date          db 0x0A,"Fecha CMOS/Build: 2026-05-18",0
msg_reboot        db 0x0A,"Reiniciando...",0
msg_shutdown      db 0x0A,"Apagando/HALT...",0
msg_mount_use     db 0x0A,"Uso: mount <a|c|d|ram|ata>",0
msg_mount_ok      db 0x0A,"Unidad montada/cambiada.",0
msg_umount_ok     db 0x0A,"Unidad desmontada logicamente.",0
msg_play_use      db 0x0A,"Uso: play <wav>",0
msg_play_ok       db 0x0A,"WAV/PCM enviado a ruta SB16 demo.",0
msg_sleep_ok      db 0x0A,"Sleep terminado.",0
msg_kill_use      db 0x0A,"Uso: kill <0|1>",0
msg_kill_ok       db 0x0A,"Task marcada zombie.",0
msg_priority_use  db 0x0A,"Uso: priority <tid> <nivel> (registrado demo)",0
msg_preempt_on    db 0x0A,"Preemptive scheduler ON.",0
msg_preempt_off   db 0x0A,"Preemptive scheduler OFF.",0
msg_cdinfo_hdr    db 0x0A,"CDROM capacity/PVD:",0
msg_blocks_use    db 0x0A,"Uso: blocks <archivo>",0
msg_blocks_hdr    db 0x0A,"Bloques/LBA:",0x0A,0
msg_iso_hdr       db 0x0A,"D:/ ISO9660 PVD sector:",0x0A,0
write_file_name   db "write.txt",0
arg_ram           db "ram",0
arg_ata           db "ata",0
arg_disk          db "disk",0
arg_disp          db "disp",0
arg_rtl8139       db "rtl8139",0
arg_e1000         db "e1000",0
arg_sd            db "sd",0
arg_ac97          db "ac97",0
arg_sb16          db "sb16",0
arg_floppy        db "floppy",0
arg_cdrom         db "cdrom",0
arg_a             db "a",0
arg_c             db "c",0
arg_d             db "d",0
arg_a_colon       db "a:",0
arg_c_colon       db "c:",0
arg_d_colon       db "d:",0
dot_char          db ".",0
path_a_init       db "A:/",0
path_d_init       db "D:/",0
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
floppy_present    dd 0
e1000_present     dd 0
sb16_present      dd 0
cdrom_present     dd 0
sata_present      dd 0
active_net_driver dd 0 ; 1=rtl8139,2=e1000
active_audio_driver dd 0 ; 1=ac97,2=sb16
e1000_link_up     dd 0
e1000_tx_packets  dd 0
e1000_tx_errors   dd 0

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

    mov edi, cmd_cls
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

    mov edi, cmd_del
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

    mov edi, cmd_read
    call strcmp
    cmp eax, 0
    je do_read

    mov edi, cmd_write
    call strcmp
    cmp eax, 0
    je do_write

    mov edi, cmd_drives
    call strcmp
    cmp eax, 0
    je do_drives

    mov edi, cmd_listdisks
    call strcmp
    cmp eax, 0
    je do_listdisks

    mov edi, cmd_echo
    call strcmp
    cmp eax, 0
    je do_echo

    mov edi, cmd_ver
    call strcmp
    cmp eax, 0
    je do_ver

    mov edi, cmd_hexdump
    call strcmp
    cmp eax, 0
    je do_hexdump

    mov edi, cmd_run
    call strcmp
    cmp eax, 0
    je do_run

    mov edi, cmd_yield
    call strcmp
    cmp eax, 0
    je do_yield

    mov edi, cmd_copy
    call strcmp
    cmp eax, 0
    je do_copy

    mov edi, cmd_rename
    call strcmp
    cmp eax, 0
    je do_rename

    mov edi, cmd_format
    call strcmp
    cmp eax, 0
    je do_format

    mov edi, cmd_type
    call strcmp
    cmp eax, 0
    je do_cat

    mov edi, cmd_stat
    call strcmp
    cmp eax, 0
    je do_stat

    mov edi, cmd_fsinfo
    call strcmp
    cmp eax, 0
    je do_fsinfo

    mov edi, cmd_move
    call strcmp
    cmp eax, 0
    je do_rename

    mov edi, cmd_date
    call strcmp
    cmp eax, 0
    je do_date

    mov edi, cmd_reboot
    call strcmp
    cmp eax, 0
    je do_reboot

    mov edi, cmd_shutdown
    call strcmp
    cmp eax, 0
    je do_shutdown

    mov edi, cmd_mount
    call strcmp
    cmp eax, 0
    je do_mount

    mov edi, cmd_umount
    call strcmp
    cmp eax, 0
    je do_umount

    mov edi, cmd_play
    call strcmp
    cmp eax, 0
    je do_play

    mov edi, cmd_sleep
    call strcmp
    cmp eax, 0
    je do_sleep

    mov edi, cmd_kill
    call strcmp
    cmp eax, 0
    je do_kill

    mov edi, cmd_priority
    call strcmp
    cmp eax, 0
    je do_priority

    mov edi, cmd_preempt
    call strcmp
    cmp eax, 0
    je do_preempt

    mov edi, cmd_cdinfo
    call strcmp
    cmp eax, 0
    je do_cdinfo

    mov edi, cmd_blocks
    call strcmp
    cmp eax, 0
    je do_blocks

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
    cmp byte [current_path], 'D'
    je do_dir_cdrom
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
    add esi, DIR_ENTRY_SIZE
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
    mov edi, arg_c_colon
    call strcmp
    cmp eax, 0
    je .to_c
    mov esi, [arg_ptr]
    mov edi, arg_a_colon
    call strcmp
    cmp eax, 0
    je .to_a
    mov esi, [arg_ptr]
    mov edi, arg_d_colon
    call strcmp
    cmp eax, 0
    je .to_d
    jne .normal_cd
.to_c:
    mov esi, path_root_init
    mov edi, current_path
    call strcpy
    mov esi, msg_cd_disk_ok
    call api_print_string
    jmp shell_loop
.to_a:
    cmp dword [floppy_present], 0
    je .drive_missing
    mov esi, path_a_init
    mov edi, current_path
    call strcpy
    mov esi, msg_cd_a_ok
    call api_print_string
    jmp shell_loop
.to_d:
    cmp dword [cdrom_present], 0
    je .drive_missing
    mov esi, path_d_init
    mov edi, current_path
    call strcpy
    mov esi, msg_cd_d_ok
    call api_print_string
    jmp shell_loop
.drive_missing:
    mov esi, msg_cd_no_drive
    call api_print_string
    jmp shell_loop
.normal_cd:
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
    mov ecx, FS_MAX_FILE_SIZE
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
    cmp ecx, FS_MAX_FILE_SIZE-1
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
    cmp dword [active_audio_driver], 2
    je .sb16
    cmp dword [audio_driver_available], 0
    je .audio_no
    call ac97_beep
    mov esi, msg_audio
    call api_print_string
    jmp shell_loop
.sb16:
    cmp dword [sb16_present], 1
    jne .audio_no
    call sb16_beep
    mov esi, msg_audio
    call api_print_string
    jmp shell_loop
.audio_no:
    mov esi, msg_audio_unavail
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
    cmp dword [fs_storage_mode], FS_MODE_ATA
    je .fs_ata
    mov esi, msg_dev_ram
    jmp .fs_out
.fs_ata:
    mov esi, msg_dev_ata
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

    mov esi, msg_dev_ata_disk
    call api_print_string
    cmp dword [ata_present], 0
    je .ata_no
    mov esi, msg_dev_ok
    jmp .ata_out
.ata_no:
    mov esi, msg_dev_missing
.ata_out:
    call api_print_string

    mov esi, msg_dev_floppy
    call api_print_string
    cmp dword [floppy_present], 0
    je .flp_no
    mov esi, msg_dev_ok
    jmp .flp_out
.flp_no:
    mov esi, msg_dev_missing
.flp_out:
    call api_print_string

    mov esi, msg_dev_cdrom
    call api_print_string
    cmp dword [cdrom_present], 0
    je .cd_no
    mov esi, msg_dev_ok
    jmp .cd_out
.cd_no:
    mov esi, msg_dev_missing
.cd_out:
    call api_print_string

    mov esi, msg_dev_sata
    call api_print_string
    cmp dword [sata_present], 0
    je .sata_no
    mov esi, msg_dev_ok
    jmp .sata_out
.sata_no:
    mov esi, msg_dev_missing
.sata_out:
    call api_print_string

    mov esi, msg_dev_sb16
    call api_print_string
    cmp dword [sb16_present], 0
    je .sb16_no
    mov esi, msg_dev_ok
    jmp .sb16_out
.sb16_no:
    mov esi, msg_dev_missing
.sb16_out:
    call api_print_string

    mov esi, msg_dev_e1000
    call api_print_string
    cmp dword [e1000_present], 0
    je .e1000_no
    mov esi, msg_dev_ok
    jmp .e1000_out
.e1000_no:
    mov esi, msg_dev_missing
.e1000_out:
    call api_print_string
    jmp shell_loop

do_beep:
    cmp dword [active_audio_driver], 2
    je .beep_sb16
    cmp dword [audio_driver_available], 0
    je .beep_no
    call ac97_beep
    jmp shell_loop
.beep_sb16:
    cmp dword [sb16_present], 1
    je .beep_sb16_ok
    jmp .beep_no
.beep_sb16_ok:
    call sb16_beep
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

do_change:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .usage
    mov edi, esi
.find_change_space:
    cmp byte [edi], 0
    je .legacy_one
    cmp byte [edi], ' '
    je .split
    inc edi
    jmp .find_change_space
.split:
    mov byte [edi], 0
    inc edi
    mov ebx, edi
    mov edi, arg_disk
    call strcmp
    cmp eax, 0
    je .from_disk
    mov esi, [arg_ptr]
    mov edi, arg_disp
    call strcmp
    cmp eax, 0
    je .from_disp
    mov esi, [arg_ptr]
    mov edi, arg_sd
    call strcmp
    cmp eax, 0
    je .from_sd
    jmp .usage
.from_disk:
    mov esi, ebx
    jmp .legacy
.from_disp:
    mov esi, ebx
    mov edi, arg_rtl8139
    call strcmp
    cmp eax, 0
    je .to_rtl
    mov esi, ebx
    mov edi, arg_e1000
    call strcmp
    cmp eax, 0
    je .to_e1000
    jmp .usage
.to_rtl:
    cmp dword [rtl8139_present], 1
    jne .disp_no
    mov dword [active_net_driver], 1
    mov dword [net_driver_available], 1
    mov esi, msg_change_disp_rtl_ok
    call api_print_string
    jmp shell_loop
.to_e1000:
    cmp dword [e1000_present], 1
    jne .disp_no
    mov dword [active_net_driver], 2
    mov dword [net_driver_available], 1
    call e1000_init
    mov esi, msg_change_disp_e1000_ok
    call api_print_string
    jmp shell_loop
.disp_no:
    mov esi, msg_change_disp_no
    call api_print_string
    jmp shell_loop
.from_sd:
    mov esi, ebx
    mov edi, arg_ac97
    call strcmp
    cmp eax, 0
    je .to_ac97
    mov esi, ebx
    mov edi, arg_sb16
    call strcmp
    cmp eax, 0
    je .to_sb16
    jmp .usage
.to_ac97:
    cmp dword [audio_driver_available], 1
    jne .sd_no
    mov dword [active_audio_driver], 1
    mov esi, msg_change_sd_ok_ac97
    call api_print_string
    jmp shell_loop
.to_sb16:
    cmp dword [sb16_present], 1
    jne .sd_no
    mov dword [active_audio_driver], 2
    mov esi, msg_change_sd_ok_sb16
    call api_print_string
    jmp shell_loop
.sd_no:
    mov esi, msg_change_sd_no
    call api_print_string
    jmp shell_loop
.legacy_one:
    mov ebx, esi
.legacy:
    mov edi, arg_ram
    call strcmp
    cmp eax, 0
    je do_change_to_ram
    mov esi, ebx
    mov edi, arg_ata
    call strcmp
    cmp eax, 0
    je do_change_to_ata
    mov esi, ebx
    mov edi, arg_a
    call strcmp
    cmp eax, 0
    je do_change_to_a
    mov esi, ebx
    mov edi, arg_a_colon
    call strcmp
    cmp eax, 0
    je do_change_to_a
    mov esi, ebx
    mov edi, arg_floppy
    call strcmp
    cmp eax, 0
    je do_change_to_a
    mov esi, ebx
    mov edi, arg_c
    call strcmp
    cmp eax, 0
    je do_change_to_c
    mov esi, ebx
    mov edi, arg_c_colon
    call strcmp
    cmp eax, 0
    je do_change_to_c
    mov esi, ebx
    mov edi, arg_d
    call strcmp
    cmp eax, 0
    je do_change_to_d
    mov esi, ebx
    mov edi, arg_d_colon
    call strcmp
    cmp eax, 0
    je do_change_to_d
    mov esi, ebx
    mov edi, arg_cdrom
    call strcmp
    cmp eax, 0
    je do_change_to_d
.usage:
    mov esi, msg_change_usage
    call api_print_string
    mov esi, msg_change_usage2
    call api_print_string
    jmp shell_loop

do_read:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, arg_floppy
    call strcmp
    cmp eax, 0
    je .floppy
    mov esi, [arg_ptr]
    mov edi, arg_cdrom
    call strcmp
    cmp eax, 0
    je .cdrom
    mov esi, [arg_ptr]
    mov edi, arg_a
    call strcmp
    cmp eax, 0
    je .floppy
    mov esi, [arg_ptr]
    mov edi, arg_c
    call strcmp
    cmp eax, 0
    je .diskfs
    mov esi, [arg_ptr]
    mov edi, arg_d
    call strcmp
    cmp eax, 0
    je .cdrom
.use:
    mov esi, msg_read_use
    call api_print_string
    jmp shell_loop
.floppy:
    cmp dword [floppy_present], 0
    je .no
    mov esi, msg_read_floppy_ok
    call api_print_string
    jmp shell_loop
.cdrom:
    cmp dword [cdrom_present], 0
    je .no
    xor eax, eax
    mov ebx, FILE_BUFFER
    call cdrom_read_sector
    cmp eax, 1
    jne .no
    mov esi, msg_read_cdrom_ok
    call api_print_string
    jmp shell_loop
.diskfs:
    cmp dword [fs_driver_available], 0
    je .no
    mov esi, msg_read_disk_ok
    call api_print_string
    jmp shell_loop
.no:
    mov esi, msg_read_no
    call api_print_string
    jmp shell_loop

do_write:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, esi
.findw:
    cmp byte [edi], 0
    je .use
    cmp byte [edi], ' '
    je .split
    inc edi
    jmp .findw
.split:
    mov byte [edi], 0
    inc edi
    mov ebx, edi
    mov edi, arg_a
    call strcmp
    cmp eax, 0
    je .wa
    mov esi, [arg_ptr]
    mov edi, arg_c
    call strcmp
    cmp eax, 0
    je .wc
    mov esi, [arg_ptr]
    mov edi, arg_d
    call strcmp
    cmp eax, 0
    je .wd
    jmp .use
.wa:
    cmp dword [floppy_present], 0
    je .no
    mov esi, msg_write_a_ok
    call api_print_string
    jmp shell_loop
.wc:
    cmp dword [fs_driver_available], 0
    je .no
    cmp ebx, 0
    je .no
    mov esi, ebx
    mov edi, BUFFER_EDITOR
    xor ecx, ecx
.copy_text_c:
    cmp ecx, FS_MAX_FILE_SIZE-1
    jae .finish_text_c
    lodsb
    stosb
    inc ecx
    cmp al, 0
    jne .copy_text_c
    jmp .save_text_c
.finish_text_c:
    mov byte [edi], 0
.save_text_c:
    mov esi, write_file_name
    mov ebx, BUFFER_EDITOR
    call fs_write_file
    mov esi, msg_write_c_ok
    call api_print_string
    jmp shell_loop
.wd:
    cmp dword [cdrom_present], 0
    je .no
    mov esi, msg_write_d_ok
    call api_print_string
    jmp shell_loop
.no:
    mov esi, msg_read_no
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_write_use
    call api_print_string
    jmp shell_loop

do_drives:
    mov esi, msg_drives_hdr
    call api_print_string
    cmp dword [floppy_present], 0
    je .a_no
    mov esi, msg_drive_a_on
    call api_print_string
.a_no:
    cmp dword [fs_driver_available], 0
    je .c_no
    mov esi, msg_drive_c_on
    call api_print_string
.c_no:
    cmp dword [cdrom_present], 0
    je .d_no
    mov esi, msg_drive_d_on
    call api_print_string
.d_no:
    jmp shell_loop

do_listdisks:
    mov esi, msg_listdisks_hdr
    call api_print_string
    cmp dword [floppy_present], 0
    je .skip_a
    mov esi, msg_listdisk_flp
    call api_print_string
.skip_a:
    cmp dword [fs_driver_available], 0
    je .skip_c
    mov esi, msg_listdisk_hdd
    call api_print_string
.skip_c:
    cmp dword [cdrom_present], 0
    je .skip_d
    mov esi, msg_listdisk_cdr
    call api_print_string
.skip_d:
    jmp shell_loop
do_echo:
    mov esi, msg_newline
    call api_print_string
    mov esi, [arg_ptr]
    cmp esi, 0
    je shell_loop
    call api_print_string
    jmp shell_loop

do_ver:
    mov esi, msg_ver
    call api_print_string
    jmp shell_loop

do_hexdump:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    call fs_read_file
    cmp eax, 0
    je .fail
    mov esi, msg_hexdump_hdr
    call api_print_string
    mov esi, APP_POINTER
    xor edx, edx
.dump_loop:
    cmp ecx, 0
    je shell_loop
    lodsb
    call print_hex8
    inc edx
    dec ecx
    test edx, 0x0F
    jnz .dump_loop
    push esi
    mov esi, msg_newline
    call api_print_string
    pop esi
    jmp .dump_loop
.use:
    mov esi, msg_hexdump_use
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_cat_fail
    call api_print_string
    jmp shell_loop

do_run:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, app_name_sample1
    call strcmp
    cmp eax, 0
    je .sample1
    mov esi, [arg_ptr]
    mov edi, app_name_textedit
    call strcmp
    cmp eax, 0
    je .textedit
    mov esi, [arg_ptr]
    mov edi, app_name_taskmgr
    call strcmp
    cmp eax, 0
    je .taskmgr
    mov esi, msg_run_missing
    call api_print_string
    jmp shell_loop
.sample1:
    mov ebx, api_table
    mov esi, app_msg_sample1
    call [ebx + 0]
    jmp shell_loop
.textedit:
    mov ebx, api_table
    mov esi, app_msg_textedit
    call [ebx + 0]
    jmp shell_loop
.taskmgr:
    mov ebx, api_table
    mov esi, app_msg_taskmgr
    call [ebx + 0]
    jmp shell_loop
.use:
    mov esi, msg_run_use
    call api_print_string
    jmp shell_loop

do_yield:
    call scheduler_yield
    mov esi, msg_yield_ok
    call api_print_string
    jmp shell_loop

do_copy:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, esi
.find_space_copy:
    cmp byte [edi], 0
    je .use
    cmp byte [edi], ' '
    je .split_copy
    inc edi
    jmp .find_space_copy
.split_copy:
    mov byte [edi], 0
    inc edi
    push edi
    mov esi, [arg_ptr]
    call fs_read_file
    pop edi
    cmp eax, 0
    je .fail
    mov esi, edi
    mov ebx, APP_POINTER
    call fs_write_file
    mov esi, msg_copy_ok
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_copy_use
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_copy_fail
    call api_print_string
    jmp shell_loop

do_rename:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, esi
.find_space_ren:
    cmp byte [edi], 0
    je .use
    cmp byte [edi], ' '
    je .split_ren
    inc edi
    jmp .find_space_ren
.split_ren:
    mov byte [edi], 0
    inc edi
    mov ebx, edi
    mov esi, [arg_ptr]
    call fs_rename_entry
    cmp eax, 0
    je .fail
    mov esi, msg_rename_ok
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_rename_use
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_rename_fail
    call api_print_string
    jmp shell_loop

do_format:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, arg_ram
    call strcmp
    cmp eax, 0
    jne .use
    call fs_init_ram
    mov dword [fs_driver_available], 1
    mov esi, msg_format_ok
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_format_use
    call api_print_string
    jmp shell_loop

do_stat:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, DIR_BUFFER
    mov ecx, 16
.find_stat:
    cmp byte [edi], 0
    je .next_stat
    push edi
    push esi
    mov edx, 16
.compare_stat:
    mov al, [esi]
    cmp al, [edi]
    jne .no_stat
    cmp al, 0
    je .match_stat
    inc esi
    inc edi
    dec edx
    jnz .compare_stat
.match_stat:
    pop esi
    pop edi
    mov esi, msg_stat_hdr
    call api_print_string
    mov esi, edi
    call print_entry_name
    mov esi, msg_stat_lba
    call api_print_string
    mov eax, [edi+16]
    call print_hex32
    mov esi, msg_stat_size
    call api_print_string
    mov eax, [edi+20]
    call print_hex32
    mov esi, msg_stat_flag
    call api_print_string
    movzx eax, byte [edi+24]
    call print_hex32
    jmp shell_loop
.no_stat:
    pop esi
    pop edi
.next_stat:
    add edi, DIR_ENTRY_SIZE
    dec ecx
    jnz .find_stat
    mov esi, msg_stat_fail
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_stat_use
    call api_print_string
    jmp shell_loop

do_fsinfo:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, msg_fsinfo_hdr
    call api_print_string
    cmp dword [fs_storage_mode], FS_MODE_ATA
    je .mode_ata
    mov esi, msg_dev_ram
    jmp .mode_out
.mode_ata:
    mov esi, msg_dev_ata
.mode_out:
    call api_print_string
    mov esi, msg_fsinfo_max
    call api_print_string
    mov eax, FS_MAX_FILE_SIZE
    call print_hex32
    mov esi, msg_journal_seq
    call api_print_string
    mov eax, [fs_journal_seq]
    call print_hex32
    mov esi, msg_fsinfo_used
    call api_print_string
    xor eax, eax
    mov esi, DIR_BUFFER
    mov ecx, 16
.count_loop:
    cmp byte [esi], 0
    je .count_next
    inc eax
.count_next:
    add esi, DIR_ENTRY_SIZE
    dec ecx
    jnz .count_loop
    call print_hex32
    jmp shell_loop

do_dir_cdrom:
    cmp dword [cdrom_present], 1
    jne do_drives
    mov esi, msg_iso_hdr
    call api_print_string
    mov eax, 16
    mov ebx, FILE_BUFFER
    call cdrom_read_sector
    cmp eax, 1
    jne shell_loop
    mov byte [FILE_BUFFER+128], 0
    mov esi, FILE_BUFFER+1
    call api_print_string
    jmp shell_loop

do_cat_cdrom:
    mov eax, 16
    mov ebx, FILE_BUFFER
    call cdrom_read_sector
    cmp eax, 1
    jne .fail
    mov byte [FILE_BUFFER+255], 0
    mov esi, msg_cat_hdr
    call api_print_string
    mov esi, FILE_BUFFER
    call api_print_string
    jmp shell_loop
.fail:
    mov esi, msg_cat_fail
    call api_print_string
    jmp shell_loop

do_date:
    mov esi, msg_date
    call api_print_string
    jmp shell_loop

do_reboot:
    mov esi, msg_reboot
    call api_print_string
    mov al, 0xFE
    out 0x64, al
    jmp $

do_shutdown:
    mov esi, msg_shutdown
    call api_print_string
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    cli
    hlt
    jmp $

do_mount:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov dword [arg_ptr], esi
    call do_change
.use:
    mov esi, msg_mount_use
    call api_print_string
    jmp shell_loop

do_umount:
    mov esi, path_root_init
    mov edi, current_path
    call strcpy
    mov esi, msg_umount_ok
    call api_print_string
    jmp shell_loop

do_play:
    cmp dword [sb16_present], 1
    jne .use
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    call fs_read_file
    cmp eax, 0
    je .use
    call sb16_beep
    mov esi, msg_play_ok
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_play_use
    call api_print_string
    jmp shell_loop

do_sleep:
    mov ecx, 3
.sleep_loop:
    call api_delay
    loop .sleep_loop
    mov esi, msg_sleep_ok
    call api_print_string
    jmp shell_loop

do_kill:
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    cmp byte [esi], '0'
    je .tid0
    cmp byte [esi], '1'
    je .tid1
    jmp .use
.tid0:
    mov dword [sched_tcbs+36], TASK_ZOMBIE
    jmp .ok
.tid1:
    mov dword [sched_tcbs+TCB_SIZE+36], TASK_ZOMBIE
.ok:
    mov esi, msg_kill_ok
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_kill_use
    call api_print_string
    jmp shell_loop

do_priority:
    mov esi, msg_priority_use
    call api_print_string
    jmp shell_loop

do_preempt:
    cmp dword [sched_preemptive], 1
    je .off
    mov dword [sched_preemptive], 1
    mov esi, msg_preempt_on
    call api_print_string
    jmp shell_loop
.off:
    mov dword [sched_preemptive], 0
    mov esi, msg_preempt_off
    call api_print_string
    jmp shell_loop

do_cdinfo:
    mov esi, msg_cdinfo_hdr
    call api_print_string
    call cdrom_capacity
    cmp eax, 1
    jne shell_loop
    mov eax, [FILE_BUFFER]
    call print_hex32
    mov eax, [FILE_BUFFER+4]
    call print_hex32
    jmp shell_loop

do_blocks:
    cmp dword [fs_driver_available], 0
    je fs_missing_cmd
    mov esi, [arg_ptr]
    cmp esi, 0
    je .use
    mov edi, DIR_BUFFER
    mov ecx, 16
.find_blk:
    cmp byte [edi], 0
    je .next_blk
    push edi
    push esi
    mov edx, 16
.compare_blk:
    mov al, [esi]
    cmp al, [edi]
    jne .no_blk
    cmp al, 0
    je .match_blk
    inc esi
    inc edi
    dec edx
    jnz .compare_blk
.match_blk:
    pop esi
    pop edi
    mov esi, msg_blocks_hdr
    call api_print_string
    mov eax, edi
    sub eax, DIR_BUFFER
    mov ebx, DIR_ENTRY_SIZE
    xor edx, edx
    div ebx
    imul eax, FS_FILE_SECTORS*4
    add eax, fs_block_table
    mov esi, eax
    mov ecx, FS_FILE_SECTORS
.print_blk:
    mov eax, [esi]
    call print_hex32
    add esi, 4
    loop .print_blk
    jmp shell_loop
.no_blk:
    pop esi
    pop edi
.next_blk:
    add edi, DIR_ENTRY_SIZE
    dec ecx
    jnz .find_blk
    mov esi, msg_stat_fail
    call api_print_string
    jmp shell_loop
.use:
    mov esi, msg_blocks_use
    call api_print_string
    jmp shell_loop

do_change_to_a:
    cmp dword [floppy_present], 0
    je do_change_ata_missing
    mov esi, path_a_init
    mov edi, current_path
    call strcpy
    mov esi, msg_change_a_ok
    call api_print_string
    jmp shell_loop
do_change_to_c:
    cmp dword [fs_driver_available], 0
    je do_change_ata_missing
    mov esi, path_root_init
    mov edi, current_path
    call strcpy
    mov esi, msg_change_c_ok
    call api_print_string
    jmp shell_loop
do_change_to_d:
    cmp dword [cdrom_present], 0
    je do_change_ata_missing
    mov esi, path_d_init
    mov edi, current_path
    call strcpy
    mov esi, msg_change_d_ok
    call api_print_string
    jmp shell_loop
do_change_to_ram:
    call fs_init_ram
    mov dword [fs_driver_available], 1
    mov esi, msg_change_ram_ok
    call api_print_string
    jmp shell_loop
do_change_to_ata:
    call fs_init_ata
    cmp eax, 1
    jne do_change_ata_missing
    mov dword [fs_driver_available], 1
    mov esi, msg_change_ata_ok
    call api_print_string
    jmp shell_loop
do_change_ata_missing:
    mov esi, msg_change_ata_no
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
    cmp byte [esi], 'd'
    je do_cat_cdrom
    cmp byte [esi], 'D'
    je do_cat_cdrom
    call fs_read_file
    cmp eax, 0
    je .cat_fail
    mov byte [APP_POINTER+FS_MAX_FILE_SIZE-1], 0
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

    mov edi, net_sub_status
    call strcmp
    cmp eax, 0
    je net_cmd_status

    mov edi, net_sub_clone
    call strcmp
    cmp eax, 0
    je net_cmd_clone

    mov edi, net_sub_navigate
    call strcmp
    cmp eax, 0
    je net_cmd_navigate

    mov edi, net_sub_udp
    call strcmp
    cmp eax, 0
    je net_cmd_udp

    mov edi, net_sub_dhcp
    call strcmp
    cmp eax, 0
    je net_cmd_dhcp

    mov edi, net_sub_dns
    call strcmp
    cmp eax, 0
    je net_cmd_dns

    mov edi, net_sub_tcp
    call strcmp
    cmp eax, 0
    je net_cmd_tcp

    mov edi, net_sub_http
    call strcmp
    cmp eax, 0
    je net_cmd_http

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
    call net_driver_init
    cmp eax, 0
    je do_net.net_missing
    mov dword [net_driver_available], 1
    mov esi, msg_net_up
    call api_print_string
    jmp shell_loop

net_cmd_down:
    call net_driver_shutdown
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
    call net_driver_transmit
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
    call net_driver_receive
    cmp ecx, 0
    je shell_loop
    inc dword [net_pkts_recv]
    push ecx
    call net_handle_rx
    mov esi, msg_net_auto
    call api_print_string
    pop ecx
    call print_packet_dump
    jmp shell_loop

net_cmd_listen:
    mov esi, msg_net_listen
    call api_print_string
.listen_loop:
    call kbd_read_char
    cmp al, 0x1B         ; ESC
    je shell_loop
    call net_driver_receive
    cmp ecx, 0
    je .continue_listen
    inc dword [net_pkts_recv]
    push ecx
    call net_handle_rx
    pop ecx
    call print_packet_dump
.continue_listen:
    call api_delay
    jmp .listen_loop

net_cmd_dump:
    mov ecx, [rtl_last_rx_len]
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
    cmp dword [net_arp_valid], 1
    jne .need_arp
    call net_build_icmp_echo_request
    jmp .send_ping
.need_arp:
    call net_build_arp_request
.send_ping:
    call net_driver_transmit
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
    mov esi, msg_net_arp_tbl
    call api_print_string
    cmp dword [net_arp_valid], 1
    jne .send_req
    mov esi, net_arp_ip
    call print_ip4
    mov eax, [net_arp_mac]
    call print_hex32
.send_req:
    call net_build_arp_request
    call net_driver_transmit
    inc dword [net_pkts_sent]
    mov esi, msg_net_arp_tx
    call api_print_string
    jmp shell_loop

net_cmd_reset:
    call net_driver_init
    cmp eax, 0
    je do_net.net_missing
    mov dword [net_driver_available], 1
    mov esi, msg_net_reset_ok
    call api_print_string
    jmp shell_loop

net_cmd_icmp:
    call net_driver_receive
    cmp ecx, 0
    je .icmp_none
    mov esi, 0x128000
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
    call net_driver_receive
    cmp ecx, 0
    je .none
    mov esi, 0x128000
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
    call net_build_dns_query
    call net_driver_transmit
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
    call net_driver_transmit
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

net_cmd_status:
    cmp dword [rtl8139_present], 1
    jne .single_check
    cmp dword [e1000_present], 1
    jne .single_check
    mov esi, msg_net_status_multi
    call api_print_string
.single_check:
    cmp dword [active_net_driver], 2
    je .check_e1000
.check_rtl:
    cmp dword [rtl8139_present], 1
    jne .dev_no
    cmp dword [rtl8139_link_up], 1
    jne .net_no
    mov esi, msg_net_status_dev_net_yes
    call api_print_string
    jmp shell_loop
.check_e1000:
    cmp dword [e1000_present], 1
    jne .dev_no
    cmp dword [e1000_link_up], 1
    jne .net_no
    mov esi, msg_net_status_dev_net_yes
    call api_print_string
    jmp shell_loop
.net_no:
    mov esi, msg_net_status_dev_net_no
    call api_print_string
    jmp shell_loop
.dev_no:
    mov esi, msg_net_status_dev_no
    call api_print_string
    jmp shell_loop

net_cmd_clone:
    mov esi, [hex_arg_ptr]
    cmp esi, 0
    je .usage
    cmp byte [esi], 0
    je .usage
    mov esi, msg_net_clone_unavail
    call api_print_string
    jmp shell_loop
.usage:
    mov esi, msg_net_clone_use
    call api_print_string
    jmp shell_loop

net_cmd_navigate:
    mov esi, [hex_arg_ptr]
    cmp esi, 0
    je .usage
    cmp byte [esi], 0
    je .usage
    mov esi, msg_net_nav_start
    call api_print_string
    call net_build_http_get
    call net_driver_transmit
    cmp eax, 0
    je .fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_nav_wait
    call api_print_string
    jmp shell_loop
.usage:
    mov esi, msg_net_nav_use
    call api_print_string
    jmp shell_loop
.fail:
    inc dword [net_errors]
    mov esi, msg_net_unavail
    call api_print_string
    jmp shell_loop

net_cmd_udp:
    call net_build_udp_demo
    call net_driver_transmit
    cmp eax, 0
    je .fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_udp_tx
    call api_print_string
    jmp shell_loop
.fail:
    inc dword [net_errors]
    mov esi, msg_net_unavail
    call api_print_string
    jmp shell_loop

net_cmd_dhcp:
    call net_build_dhcp_discover
    call net_driver_transmit
    cmp eax, 0
    je net_cmd_udp.fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_dhcp_tx
    call api_print_string
    jmp shell_loop

net_cmd_dns:
    call net_build_dns_query
    call net_driver_transmit
    cmp eax, 0
    je net_cmd_udp.fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_dns_tx
    call api_print_string
    jmp shell_loop

net_cmd_tcp:
    call net_build_tcp_syn
    call net_driver_transmit
    cmp eax, 0
    je net_cmd_udp.fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_tcp_tx
    call api_print_string
    jmp shell_loop

net_cmd_http:
    call net_build_http_get
    call net_driver_transmit
    cmp eax, 0
    je net_cmd_udp.fail
    inc dword [net_pkts_sent]
    mov esi, msg_net_http_tx
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

print_hex8:
    pusha
    mov bl, al
    shr al, 4
    call print_hex_nibble
    mov al, bl
    and al, 0x0F
    call print_hex_nibble
    mov al, ' '
    call print_char
    popa
    ret

print_hex_nibble:
    cmp al, 9
    jle .digit
    add al, 55
    jmp .out
.digit:
    add al, 48
.out:
    call print_char
    ret

print_packet_dump:
    push ecx
    mov esi, msg_net_len
    call api_print_string
    mov eax, ecx
    call print_hex32
    mov esi, msg_net_hex
    call api_print_string
    pop ecx
    cmp ecx, 256
    jbe .len_ok
    mov ecx, 256
.len_ok:
    mov esi, 0x128000
    xor edx, edx
.dump_loop:
    cmp ecx, 0
    je .done
    lodsb
    call print_hex8
    inc edx
    dec ecx
    test edx, 0x0F
    jnz .dump_loop
    push esi
    mov esi, msg_newline
    call api_print_string
    pop esi
    jmp .dump_loop
.done:
    mov esi, msg_net_ascii
    call api_print_string
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
