%ifndef LA_APPLICATIONS_ASM
%define LA_APPLICATIONS_ASM

APP_HELLO_ELF_LBA equ 136
APP_HELLO_ELF_SECTORS equ 4

app_count dd 4
app0_name db 'Explorer',0
app1_name db 'TaskMgr',0
app2_name db 'hello.elf',0
app3_name db 'TextEdit',0

applications_init:
    ret

applications_launch:
    ; eax=app id
    cmp eax, 0
    jne .task
    mov esi, app0_name
    mov eax, 26
    mov ebx, 24
    mov ecx, 180
    mov edx, 120
    call create_window
    ret
.task:
    cmp eax, 1
    jne .hello_elf
    mov esi, app1_name
    mov eax, 50
    mov ebx, 38
    mov ecx, 160
    mov edx, 110
    call create_window
    ret
.hello_elf:
    cmp eax, 2
    jne .textedit
    ; Carga ELF por sectores contiguos y ejecuta entry point.
    mov eax, APP_HELLO_ELF_LBA
    mov edi, ELF_LOAD_BASE
    mov ecx, APP_HELLO_ELF_SECTORS
.read_loop:
    push eax
    push ecx
    call floppy_read_sector
    pop ecx
    pop eax
    inc eax
    add edi, 512
    dec ecx
    jnz .read_loop
    mov esi, ELF_LOAD_BASE
    call elf_run_image
    ret
.textedit:
    cmp eax, 3
    jne .ret0
    mov esi, app3_name
    mov eax, 20
    mov ebx, 16
    mov ecx, 270
    mov edx, 160
    call create_window
    ret
.ret0:
    ret

%endif
