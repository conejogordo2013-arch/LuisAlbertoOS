[BITS 64]

global desktop64_init
global desktop64_loop
global fb64_clear
global fb64_putpixel
global fb64_rect

default rel

extern fb_base
extern fb_width
extern fb_height
extern mouse_x
extern mouse_y
extern mouse_buttons
extern keyboard_get_ascii
extern window64_redraw_all
extern window64_handle_mouse
extern window64_handle_keyboard

section .data
bg_color dd 0x00303048
taskbar_color dd 0x00202020

section .text
desktop64_init:
    ret

desktop64_loop:
.loop:
    mov edi, [bg_color]
    call fb64_clear

    ; taskbar
    mov eax, 0
    mov ebx, [fb_height]
    sub ebx, 22
    mov ecx, [fb_width]
    mov edx, 22
    mov edi, [taskbar_color]
    call fb64_rect

    call window64_handle_mouse
    call window64_handle_keyboard
    call window64_redraw_all
    jmp .loop

fb64_clear:
    ; edi=color
    xor eax, eax
    mov r8d, [fb_width]
    mov r9d, [fb_height]
.y:
    cmp eax, r9d
    jae .done
    xor ebx, ebx
.x:
    cmp ebx, r8d
    jae .ny
    mov ecx, ebx
    mov edx, eax
    call fb64_putpixel
    inc ebx
    jmp .x
.ny:
    inc eax
    jmp .y
.done:
    ret

fb64_putpixel:
    ; ecx=x edx=y edi=color
    mov eax, [fb_width]
    imul edx, eax
    add edx, ecx
    shl edx, 2
    mov rax, [fb_base]
    add rax, rdx
    mov [rax], edi
    ret

fb64_rect:
    ; eax=x ebx=y ecx=w edx=h edi=color
    mov r8d, eax
    mov r9d, ebx
    mov r10d, ecx
    mov r11d, edx
    xor esi, esi
.ry:
    cmp esi, r11d
    jae .rdone
    xor ebp, ebp
.rx:
    cmp ebp, r10d
    jae .rnext
    mov ecx, r8d
    add ecx, ebp
    mov edx, r9d
    add edx, esi
    call fb64_putpixel
    inc ebp
    jmp .rx
.rnext:
    inc esi
    jmp .ry
.rdone:
    ret
