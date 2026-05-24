%ifndef LA_APPLICATIONS_ASM
%define LA_APPLICATIONS_ASM

APP_CMD_ELF_LBA equ 168
APP_CMD_ELF_SECTORS equ 8
APP_NOTEPAD_ELF_LBA equ 176
APP_NOTEPAD_ELF_SECTORS equ 8
APP_DEMO_ELF_LBA equ 184
APP_DEMO_ELF_SECTORS equ 8

app_count dd 7
app0_name db 'CMD.ELF',0
app1_name db 'NOTEPAD',0
app2_name db 'DEMO.ELF',0
app3_name db 'TxtEdit',0
app4_name db 'Files',0
app5_name db 'Notes',0
app6_name db 'CMD',0

applications_init:
    ret

applications_launch:
    ; eax=app id
    cmp eax, 0
    jne .notepad
    mov eax, APP_CMD_ELF_LBA
    mov ecx, APP_CMD_ELF_SECTORS
    call applications_run_elf
    ret
.notepad:
    cmp eax, 1
    jne .demo
    mov eax, APP_NOTEPAD_ELF_LBA
    mov ecx, APP_NOTEPAD_ELF_SECTORS
    call applications_run_elf
    ret
.demo:
    cmp eax, 2
    jne .textedit
    mov eax, APP_DEMO_ELF_LBA
    mov ecx, APP_DEMO_ELF_SECTORS
    call applications_run_elf
    ret
.textedit:
    cmp eax, 3
    jne .files
    mov esi, app3_name
    mov eax, 20
    mov ebx, 16
    mov ecx, 270
    mov edx, 160
    call create_window
    ret
.files:
    cmp eax, 4
    jne .notes
    mov esi, app4_name
    mov eax, 40
    mov ebx, 20
    mov ecx, 230
    mov edx, 150
    call create_window
    ret
.notes:
    cmp eax, 5
    jne .cmd
    mov esi, app5_name
    mov eax, 58
    mov ebx, 40
    mov ecx, 200
    mov edx, 120
    call create_window
    ret
.cmd:
    cmp eax, 6
    jne .ret0
    mov esi, app6_name
    mov eax, 24
    mov ebx, 18
    mov ecx, 274
    mov edx, 160
    call create_window
    ret
.ret0:
    ret

applications_run_elf:
    ; eax=lba ecx=sectors
    mov edi, ELF_LOAD_BASE
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

%endif
