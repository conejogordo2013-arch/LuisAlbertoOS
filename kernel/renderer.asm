%ifndef LA_RENDERER_ASM
%define LA_RENDERER_ASM

WALLPAPER_MODE_SOLID equ 0
WALLPAPER_MODE_RAW   equ 1
WALLPAPER_W          equ 320
WALLPAPER_H          equ 188
WALLPAPER_PIXELS     equ WALLPAPER_W*WALLPAPER_H

wallpaper_mode       dd WALLPAPER_MODE_SOLID
wallpaper_solid_color db 1
wallpaper_raw_ptr    dd 0

renderer_set_wallpaper_solid:
    ; AL=color
    mov [wallpaper_solid_color], al
    mov dword [wallpaper_mode], WALLPAPER_MODE_SOLID
    ret

renderer_set_wallpaper_raw:
    ; ESI=ptr buffer RAW 8bpp de 320x188
    mov [wallpaper_raw_ptr], esi
    mov dword [wallpaper_mode], WALLPAPER_MODE_RAW
    ret

renderer_draw_desktop_bg:
    cmp dword [wallpaper_mode], WALLPAPER_MODE_RAW
    jne .solid
    mov esi, [wallpaper_raw_ptr]
    test esi, esi
    jz .solid
    mov edi, GRAPH_BACKBUF
    mov ecx, WALLPAPER_PIXELS/4
    rep movsd
    jmp .icons
.solid:
    mov eax, 0
    mov ebx, 0
    mov ecx, 320
    mov edx, 188
    movzx esi, byte [wallpaper_solid_color]
    call graphics_fill_rect
.icons:
    ; iconos
    mov eax, 10
    mov ebx, 12
    mov ecx, 14
    mov edx, 14
    mov esi, 11
    call graphics_fill_rect
    mov eax, 28
    mov ebx, 12
    mov ecx, 14
    mov edx, 14
    mov esi, 10
    call graphics_fill_rect
    ret

%endif
