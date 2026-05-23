%ifndef LA_GUI_API_ASM
%define LA_GUI_API_ASM

create_window:
    ; esi=title eax=x ebx=y ecx=w edx=h
    call window_create
    ret

draw_rect:
    ; eax=x ebx=y ecx=w edx=h esi=color
    call graphics_fill_rect
    ret

draw_pixel:
    ; eax=x ebx=y esi=color
    call graphics_draw_pixel
    ret

get_event:
    call evq_pop
    ret

%endif
