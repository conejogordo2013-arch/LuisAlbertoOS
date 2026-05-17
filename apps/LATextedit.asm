[BITS 32]
[ORG 0x4000]

; =========================
; API OFFSETS (ABI)
; =========================
API_PRINT_STRING equ 0
API_CLEAR        equ 4
API_DELAY        equ 8
API_KBD_READ     equ 12
API_PRINT_CHAR   equ 16
API_WRITE_FILE   equ 20
API_READ_FILE    equ 24

; =========================
; CONFIG
; =========================
FILE_BUFFER     equ 0x6000
MAX_FILE_SIZE   equ 511

start:
    ; EBX = API table, ESI = filename pointer (set by launcher/kernel)
    mov [api_ptr], ebx
    mov [filename_ptr], esi

    mov esi, msg_title
    call [ebx + API_PRINT_STRING]

    ; Inicializar buffer
    mov edi, FILE_BUFFER
    xor ecx, ecx

.edit_loop:
    mov ebx, [api_ptr]
    call [ebx + API_KBD_READ]

    cmp al, 0
    je .edit_loop

    ; CTRL+C -> guardar
    cmp al, 0x03
    je .save_exit

    ; CTRL+X -> salir sin guardar
    cmp al, 0x18
    je .abort_exit

    ; BACKSPACE
    cmp al, 0x08
    je .handle_backspace

    ; ENTER/line feed is already 0x0A in the kernel keyboard API
    jmp .insert_char

.handle_backspace:
    cmp ecx, 0
    je .edit_loop

    dec edi
    dec ecx
    mov byte [edi], 0

    ; borrar visual REAL
    mov ebx, [api_ptr]
    mov al, 0x08
    call [ebx + API_PRINT_CHAR]
    mov al, ' '
    call [ebx + API_PRINT_CHAR]
    mov al, 0x08
    call [ebx + API_PRINT_CHAR]

    jmp .edit_loop

.insert_char:
    cmp ecx, MAX_FILE_SIZE
    jge .edit_loop

    mov [edi], al
    inc edi
    inc ecx

    mov ebx, [api_ptr]
    call [ebx + API_PRINT_CHAR]
    jmp .edit_loop

.save_exit:
    ; terminar string correctamente
    mov byte [edi], 0x00
    inc ecx

    ; preparar llamada FS: ESI=filename, EBX=buffer, ECX=size
    mov esi, [filename_ptr]
    mov ebx, FILE_BUFFER
    mov edx, [api_ptr]
    call [edx + API_WRITE_FILE]

    mov ebx, [api_ptr]
    mov esi, msg_saved
    call [ebx + API_PRINT_STRING]
    ret

.abort_exit:
    mov ebx, [api_ptr]
    mov esi, msg_exit
    call [ebx + API_PRINT_STRING]
    ret

; =========================
; DATA
; =========================
api_ptr dd 0
filename_ptr dd 0

msg_title db 0x0A, "LATextEdit: Ctrl+C guarda, Ctrl+X sale.", 0x0A, 0
msg_saved db 0x0A, "[Saved]", 0x0A, 0
msg_exit  db 0x0A, "[Exit]", 0x0A, 0
