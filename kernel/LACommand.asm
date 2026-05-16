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
                "help   - Muestra esta ayuda",0

; Mensajes de Red
msg_net_usage     db 0x0A,"Uso: net <comando> [args]",0x0A,"Comandos: info, up, down, send, recv, listen, dump, stats, config, ping, scan",0
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
msg_fs_unavail    db 0x0A,"Error: almacenamiento ATA no disponible.",0
msg_net_unavail   db 0x0A,"Error: red RTL8139 no disponible.",0
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
    mov esi, msg_net_recv_msg
    call api_print_string
    mov esi, msg_net_err
    call api_print_string
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