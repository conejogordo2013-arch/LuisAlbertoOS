%ifndef LA_ELF_LOADER_ASM
%define LA_ELF_LOADER_ASM

ELF_MAGIC           equ 0x464C457F
PT_LOAD             equ 1
ELF_LOAD_BASE       equ 0x00200000
ELF_STACK_TOP       equ 0x00280000

elf_load_result     dd 0

elf_load_image:
    ; ESI = ptr imagen ELF en memoria
    ; OUT EAX = entry point, 0 si error
    pushad
    mov dword [elf_load_result], 0
    cmp dword [esi], ELF_MAGIC
    jne .done
    movzx eax, word [esi+42]     ; e_phentsize
    cmp eax, 32
    jne .done
    movzx ecx, word [esi+44]     ; e_phnum
    cmp ecx, 0
    je .done
    mov ebx, [esi+28]            ; e_phoff
    add ebx, esi
.ph_loop:
    cmp dword [ebx], PT_LOAD
    jne .next
    push ecx
    mov edi, [ebx+8]             ; p_vaddr
    mov edx, [ebx+4]             ; p_offset
    add edx, esi
    mov ecx, [ebx+16]            ; p_filesz
    rep movsb
    pop ecx
.next:
    add ebx, 32
    dec ecx
    jnz .ph_loop
    mov eax, [esi+24]            ; e_entry
    mov [elf_load_result], eax
.done:
    popad
    mov eax, [elf_load_result]
    ret

elf_run_image:
    ; ESI = ptr ELF en RAM
    pushad
    call elf_load_image
    test eax, eax
    jz .exit
    mov esp, ELF_STACK_TOP
    call eax
.exit:
    popad
    ret

%endif
