[BITS 64]
default rel

global window64_create
global window64_close
global window64_redraw_all
global window64_handle_mouse
global window64_handle_keyboard

extern fb64_rect
extern draw_string64
extern keyboard_get_ascii
extern mouse_x
extern mouse_y
extern mouse_buttons

%define MAX_WINS 8
%define W_SZ 56
%define W_X 0
%define W_Y 4
%define W_W 8
%define W_H 12
%define W_TITLE 16
%define W_Z 24
%define W_FLAGS 28

section .bss
wins: resb MAX_WINS*W_SZ
focus_id: resd 1
drag_id: resd 1
drag_dx: resd 1
drag_dy: resd 1

section .text
window64_create:
    ; eax=x ebx=y ecx=w edx=h rsi=title* -> eax=id/-1
    xor r8d, r8d
.f:
    cmp r8d, MAX_WINS
    jae .fail
    mov r9, r8
    imul r9, W_SZ
    add r9, wins
    cmp dword [r9+W_FLAGS], 0
    je .use
    inc r8d
    jmp .f
.use:
    mov [r9+W_X], eax
    mov [r9+W_Y], ebx
    mov [r9+W_W], ecx
    mov [r9+W_H], edx
    mov [r9+W_TITLE], rsi
    mov dword [r9+W_Z], r8d
    mov dword [r9+W_FLAGS], 1
    mov eax, r8d
    mov [focus_id], eax
    ret
.fail:
    mov eax, -1
    ret

window64_close:
    ; eax=id
    mov r8, rax
    imul r8, W_SZ
    add r8, wins
    mov dword [r8+W_FLAGS], 0
    ret

window64_redraw_all:
    xor r8d, r8d
.l:
    cmp r8d, MAX_WINS
    jae .done
    mov r9, r8
    imul r9, W_SZ
    add r9, wins
    cmp dword [r9+W_FLAGS], 1
    jne .n
    mov eax, [r9+W_X]
    mov ebx, [r9+W_Y]
    mov ecx, [r9+W_W]
    mov edx, [r9+W_H]
    mov edi, 0x00404040
    call fb64_rect
    mov eax, [r9+W_X]
    mov ebx, [r9+W_Y]
    mov ecx, [r9+W_W]
    mov edx, 14
    mov edi, 0x006060A0
    call fb64_rect
.n:
    inc r8d
    jmp .l
.done:
    ret

window64_handle_mouse:
    ret
window64_handle_keyboard:
    ret
