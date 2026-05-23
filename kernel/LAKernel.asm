[BITS 16]
[ORG 0x10000]

kernel_start:
kernel_entry:
    cli                     ; Disable interrupts (Crucial for PM switch)
    mov ax, cs              ; Kernel is loaded at 1000:0000; use CS for 16-bit data refs
    mov ds, ax
    
    ; Load Global Descriptor Table (GDT)
    lgdt [gdt_descriptor]
    
    ; Enable Protected Mode in CR0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    ; Far jump to flush instruction pipeline and set CS
    jmp dword 0x08:kernel_32

[BITS 32]
kernel_32:
    cld                     ; Ensure all string operations move forward
    ; Setup 32-bit segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000        ; Set up 32-bit stack safely away from code

    call oskrnl_main
    jmp $                   ; Infinite loop (safety net)

; --- GDT ---
gdt_start:
    dq 0x0                  ; Null descriptor
gdt_code:
    dw 0xFFFF, 0x0000       ; Base=0, Limit=4GB, Code, Exec/Read
    db 0x00, 10011010b, 11001111b, 0x00
gdt_data:
    dw 0xFFFF, 0x0000       ; Base=0, Limit=4GB, Data, Read/Write
    db 0x00, 10010010b, 11001111b, 0x00
gdt_user_code:
    dw 0xFFFF, 0x0000
    db 0x00, 11111010b, 11001111b, 0x00
gdt_user_data:
    dw 0xFFFF, 0x0000
    db 0x00, 11110010b, 11001111b, 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; Include subsystems (acts as static linking)
%include "kernel/LAoskrnl.asm"
%include "kernel/LAApi.asm"
%include "kernel/LAApiApplications.asm"
%include "drivers/keyboard.lasys"
%include "drivers/mouse_ps2.lasys"
%include "kernel/graphics.asm"
%include "kernel/gui_text.asm"
%include "kernel/event_queue.asm"
%include "kernel/mouse.asm"
%include "kernel/keyboard.asm"
%include "kernel/renderer.asm"
%include "kernel/gui_api.asm"
%include "kernel/elf_loader.asm"
%include "kernel/applications.asm"
%include "kernel/taskbar.asm"
%include "kernel/start_menu.asm"
%include "kernel/window_manager.asm"
%include "kernel/desktop.asm"
%include "kernel/LACommand.asm"
%include "drivers/ata.lasys"
%include "kernel/fs.lasys"
%include "drivers/vga_image.lasys"
%include "drivers/rtl8139.lasys"   ; <--- Añadir Driver de Red
%include "kernel/net.lasys"        ; <--- Añadir Pila de Red
%include "drivers/ac97.lasys"
%include "drivers/sb16.lasys"
%include "drivers/intelhda.lasys"
%include "drivers/e1000.lasys"
%include "drivers/rtl8169.lasys"
%include "drivers/pcnet.lasys"
%include "drivers/intel_pro1000_variants.lasys"
%include "drivers/rtl_net_variants.lasys"
%include "drivers/pcnet_variants.lasys"
%include "drivers/storage_extra.lasys"
%include "drivers/storage_bus_stubs.lasys"
%include "kernel/pci.lasys"

%include "kernel/interrupts.lasys"

%include "kernel/memory.lasys"

%include "kernel/scheduler.lasys"

user_entry_stub:
    mov ax, 0x23
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, 1
    mov ebx, user_msg
    int 0x80
.user_loop:
    mov eax, 4
    int 0x80
    jmp .user_loop

user_msg db 0x0A, "[RING3] User stub activo via int80.",0

kernel_end:
