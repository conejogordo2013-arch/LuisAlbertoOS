%ifndef LA_WINDOW_MANAGER_ASM
%define LA_WINDOW_MANAGER_ASM

WM_MAX_WINDOWS      equ 8
WM_TITLE_MAX        equ 24
WIN_FLAG_VISIBLE    equ 1
WIN_FLAG_MINIMIZED  equ 2
WIN_FLAG_DRAGGING   equ 4

wm_next_id          dd 1
wm_count            dd 0
wm_focus_id         dd 0
wm_drag_id          dd 0
wm_drag_dx          dd 0
wm_drag_dy          dd 0

wm_id               times WM_MAX_WINDOWS dd 0
wm_x                times WM_MAX_WINDOWS dd 0
wm_y                times WM_MAX_WINDOWS dd 0
wm_w                times WM_MAX_WINDOWS dd 0
wm_h                times WM_MAX_WINDOWS dd 0
wm_z                times WM_MAX_WINDOWS dd 0
wm_flags            times WM_MAX_WINDOWS dd 0
wm_title            times WM_MAX_WINDOWS*WM_TITLE_MAX db 0
wm_editor_cursor_x  dd 0

wm_init:
    mov dword [wm_next_id], 1
    mov dword [wm_count], 0
    mov dword [wm_focus_id], 0
    mov dword [wm_drag_id], 0
    mov dword [wm_editor_cursor_x], 0
    ret

window_create:
    ; esi=title eax=x ebx=y ecx=w edx=h -> eax=id / 0
    pushad
    mov edi, [wm_count]
    cmp edi, WM_MAX_WINDOWS
    jae .fail
    mov eax, [wm_next_id]
    mov [wm_id + edi*4], eax
    inc dword [wm_next_id]
    mov eax, [esp+28]
    mov [wm_x + edi*4], eax
    mov eax, [esp+16]
    mov [wm_y + edi*4], eax
    mov eax, [esp+24]
    mov [wm_w + edi*4], eax
    mov eax, [esp+20]
    mov [wm_h + edi*4], eax
    mov eax, edi
    mov [wm_z + edi*4], eax
    mov dword [wm_flags + edi*4], WIN_FLAG_VISIBLE
    ; copy title
    mov ebp, edi
    imul edi, edi, WM_TITLE_MAX
    add edi, wm_title
    mov ecx, WM_TITLE_MAX-1
.cp: lodsb
    test al, al
    jz .tend
    mov [edi], al
    inc edi
    loop .cp
.tend:
    mov byte [edi], 0
    inc dword [wm_count]
    mov eax, [wm_id + ebp*4]
    mov [wm_focus_id], eax
    mov [esp+28], eax
    popad
    ret
.fail:
    xor eax, eax
    mov [esp+28], eax
    popad
    ret

window_destroy:
    ; eax=id
    pushad
    call wm_find_index
    cmp eax, -1
    je .out
    mov esi, eax
.sh:
    mov edi, esi
    inc edi
    cmp edi, [wm_count]
    jae .dec
    mov eax,[wm_id+edi*4]      ; compact arrays
    mov [wm_id+esi*4],eax
    mov eax,[wm_x+edi*4]
    mov [wm_x+esi*4],eax
    mov eax,[wm_y+edi*4]
    mov [wm_y+esi*4],eax
    mov eax,[wm_w+edi*4]
    mov [wm_w+esi*4],eax
    mov eax,[wm_h+edi*4]
    mov [wm_h+esi*4],eax
    mov eax,[wm_z+edi*4]
    mov [wm_z+esi*4],eax
    mov eax,[wm_flags+edi*4]
    mov [wm_flags+esi*4],eax
    mov ebx, edi
    imul ebx, ebx, WM_TITLE_MAX
    add ebx, wm_title
    mov ecx, esi
    imul ecx, ecx, WM_TITLE_MAX
    add ecx, wm_title
    push esi
    mov esi,ebx
    mov edi,ecx
    mov ecx,WM_TITLE_MAX
    rep movsb
    pop esi
    inc esi
    jmp .sh
.dec:
    dec dword [wm_count]
    cmp dword [wm_count], 0
    jne .out
    mov dword [wm_focus_id], 0
.out: popad
    ret

window_move: ; eax=id ebx=x ecx=y
    pushad
    call wm_find_index
    cmp eax,-1
    je .o
    mov [wm_x+eax*4], ebx
    mov [wm_y+eax*4], ecx
.o: popad
    ret
window_resize: ; eax=id ebx=w ecx=h
    pushad
    call wm_find_index
    cmp eax,-1
    je .o2
    mov [wm_w+eax*4], ebx
    mov [wm_h+eax*4], ecx
.o2: popad
    ret
window_focus: ; eax=id
    mov [wm_focus_id], eax
    ret

wm_find_index:
    ; in eax=id out eax=index or -1
    push ecx
    xor ecx, ecx
.l: cmp ecx, [wm_count]
    jae .nf
    cmp [wm_id+ecx*4], eax
    je .f
    inc ecx
    jmp .l
.f: mov eax, ecx
    pop ecx
    ret
.nf: mov eax, -1
    pop ecx
    ret

wm_draw:
    pushad
    xor edi,edi
.l2: cmp edi,[wm_count]
    jae .d
    mov eax,[wm_flags+edi*4]
    test eax,WIN_FLAG_VISIBLE
    jz .n
    test eax,WIN_FLAG_MINIMIZED
    jnz .n
    mov eax,[wm_x+edi*4]
    mov ebx,[wm_y+edi*4]
    mov ecx,[wm_w+edi*4]
    mov edx,[wm_h+edi*4]
    mov esi,7
    call graphics_fill_rect
    mov edx,12
    mov esi,4
    call graphics_fill_rect
    mov eax,[wm_x+edi*4]
    add eax,3
    mov ebx,[wm_y+edi*4]
    add ebx,2
    push edi
    mov esi, edi
    imul esi, esi, WM_TITLE_MAX
    add esi, wm_title
    mov edi, 15
    call gui_draw_text
    pop edi
    mov eax,[wm_x+edi*4]
    add eax,[wm_w+edi*4]
    sub eax,9
    mov ebx,[wm_y+edi*4]
    add ebx,2
    mov ecx,7
    mov edx,7
    mov esi,12
    call graphics_fill_rect
    call wm_draw_content
.n: inc edi
    jmp .l2
.d: popad
    ret

wm_handle_mouse:
    ; eax=mouse_x ebx=mouse_y ecx=left_down(0/1)
    pushad
    cmp ecx, 1
    jne .mouse_up

    mov edx, [wm_drag_id]
    test edx, edx
    jnz .drag_move

    ; buscar ventana top-most bajo el cursor (barra de título: alto 12)
    mov esi, [wm_count]
    dec esi
.scan:
    cmp esi, -1
    je .done
    mov edx, [wm_flags + esi*4]
    test edx, WIN_FLAG_VISIBLE
    jz .next
    test edx, WIN_FLAG_MINIMIZED
    jnz .next

    mov edx, [wm_x + esi*4]
    cmp eax, edx
    jl .next
    mov edi, [wm_w + esi*4]
    add edi, edx
    cmp eax, edi
    jge .next

    mov edx, [wm_y + esi*4]
    cmp ebx, edx
    jl .next
    mov edi, edx
    add edi, 12
    cmp ebx, edi
    jge .next

    mov edi, [wm_w + esi*4]
    add edi, [wm_x + esi*4]
    sub edi, 10
    cmp eax, edi
    jl .start_drag
    mov eax, [wm_id + esi*4]
    call window_destroy
    mov dword [wm_drag_id], 0
    jmp .done

.start_drag:
    mov edx, [wm_id + esi*4]
    mov [wm_drag_id], edx
    mov [wm_focus_id], edx
    mov edi, [wm_x + esi*4]
    mov edx, eax
    sub edx, edi
    mov [wm_drag_dx], edx
    mov edi, [wm_y + esi*4]
    mov edx, ebx
    sub edx, edi
    mov [wm_drag_dy], edx
    jmp .done
.next:
    dec esi
    jmp .scan

.drag_move:
    mov eax, [wm_drag_id]
    call wm_find_index
    cmp eax, -1
    je .done
    mov esi, eax
    mov edx, [esp+28]            ; original mouse_x
    sub edx, [wm_drag_dx]
    cmp edx, 0
    jge .x_ok0
    xor edx, edx
.x_ok0:
    mov edi, 320
    sub edi, [wm_w + esi*4]
    cmp edx, edi
    jle .x_ok1
    mov edx, edi
.x_ok1:
    mov [wm_x + esi*4], edx
    mov edx, [esp+16]            ; original mouse_y
    sub edx, [wm_drag_dy]
    cmp edx, 0
    jge .y_ok0
    xor edx, edx
.y_ok0:
    mov edi, 200
    sub edi, [wm_h + esi*4]
    cmp edx, edi
    jle .y_ok1
    mov edx, edi
.y_ok1:
    mov [wm_y + esi*4], edx
    jmp .done

.mouse_up:
    mov dword [wm_drag_id], 0
.done:
    popad
    ret

wm_draw_content:
    ; usa EDI=index ventana actual
    pushad
    mov eax,[wm_x+edi*4]
    add eax,3
    mov ebx,[wm_y+edi*4]
    add ebx,16
    mov ecx,[wm_w+edi*4]
    sub ecx,6
    mov edx,[wm_h+edi*4]
    sub edx,19
    cmp ecx,8
    jbe .out
    cmp edx,8
    jbe .out

    mov esi,9
    call graphics_fill_rect

    ; selector por primera letra del título
    mov eax, edi
    imul eax, eax, WM_TITLE_MAX
    add eax, wm_title
    mov al, [eax]
    cmp al, 'T'
    je .textedit
    cmp al, 'F'
    je .files
    cmp al, 'N'
    je .notes
    cmp al, 'E'
    je .explr
    cmp al, 'C'
    je .cmd
    jmp .driver_mgr

.textedit:
    mov eax,[wm_x+edi*4]
    add eax,6
    mov ebx,[wm_y+edi*4]
    add ebx,20
    mov ecx,[wm_w+edi*4]
    sub ecx,12
    mov edx,[wm_h+edi*4]
    sub edx,26
    mov esi,15
    call graphics_fill_rect
    mov eax,[wm_x+edi*4]
    add eax,8
    mov ebx,[wm_y+edi*4]
    add ebx,22
    mov esi, wm_txt_editor
    mov edi, 0
    call gui_draw_text
    mov eax,[wm_editor_cursor_x]
    inc eax
    and eax,31
    mov [wm_editor_cursor_x],eax
    mov eax,[wm_x+edi*4]
    add eax,12
    add eax,[wm_editor_cursor_x]
    mov ebx,[wm_y+edi*4]
    add ebx,24
    mov ecx,2
    mov edx,10
    mov esi,0
    call graphics_fill_rect
    jmp .out
.files:
    mov eax,[wm_x+edi*4]
    add eax,8
    mov ebx,[wm_y+edi*4]
    add ebx,22
    mov ecx,[wm_w+edi*4]
    sub ecx,16
    mov edx,8
    mov esi,1
    call graphics_fill_rect
    mov eax,[wm_x+edi*4]
    add eax,10
    mov ebx,[wm_y+edi*4]
    add ebx,23
    mov esi, wm_txt_files
    mov edi, 15
    call gui_draw_text
    add ebx,14
    mov esi,3
    call graphics_fill_rect
    add ebx,14
    mov esi,11
    call graphics_fill_rect
    jmp .out
.notes:
    mov eax,[wm_x+edi*4]
    add eax,8
    mov ebx,[wm_y+edi*4]
    add ebx,22
    mov ecx,[wm_w+edi*4]
    sub ecx,20
    mov edx,6
    mov esi,14
    call graphics_fill_rect
    mov eax,[wm_x+edi*4]
    add eax,10
    mov ebx,[wm_y+edi*4]
    add ebx,23
    mov esi, wm_txt_notes
    mov edi, 0
    call gui_draw_text
    add ebx,10
    call graphics_fill_rect
    add ebx,10
    call graphics_fill_rect
    jmp .out
.explr:
    mov eax,[wm_x+edi*4]
    add eax,10
    mov ebx,[wm_y+edi*4]
    add ebx,24
    mov ecx,10
    mov edx,10
    mov esi,12
    call graphics_fill_rect
    mov eax,[wm_x+edi*4]
    add eax,10
    mov ebx,[wm_y+edi*4]
    add ebx,36
    mov esi, wm_txt_explr
    mov edi, 15
    call gui_draw_text
    add eax,16
    mov ecx,16
    mov edx,18
    mov esi,10
    call graphics_fill_rect
    add eax,22
    mov ecx,20
    mov edx,26
    mov esi,2
    call graphics_fill_rect
    jmp .out

.cmd:
    mov eax,[wm_x+edi*4]
    add eax,6
    mov ebx,[wm_y+edi*4]
    add ebx,20
    mov ecx,[wm_w+edi*4]
    sub ecx,12
    mov edx,[wm_h+edi*4]
    sub edx,26
    mov esi,0
    call graphics_fill_rect
    mov eax,[wm_x+edi*4]
    add eax,8
    mov ebx,[wm_y+edi*4]
    add ebx,22
    mov esi, wm_txt_cmd0
    mov edi, 15
    call gui_draw_text
    add ebx,10
    mov esi, wm_txt_cmd1
    call gui_draw_text
    add ebx,10
    mov esi, wm_txt_cmd2
    call gui_draw_text
    add ebx,10
    mov esi, wm_txt_cmd3
    call gui_draw_text
    add ebx,10
    mov esi, wm_txt_cmd4
    call gui_draw_text
    jmp .out
.driver_mgr:
    mov eax,[wm_x+edi*4]
    add eax,8
    mov ebx,[wm_y+edi*4]
    add ebx,22
    mov ecx,[wm_w+edi*4]
    sub ecx,16
    mov edx,8
    cmp dword [fs_driver_available],0
    je .d0
    mov esi,2
    jmp .d0d
.d0: mov esi,4
.d0d: call graphics_fill_rect
    add ebx,12
    cmp dword [net_driver_available],0
    je .d1
    mov esi,2
    jmp .d1d
.d1: mov esi,4
.d1d: call graphics_fill_rect
    add ebx,12
    cmp dword [audio_driver_available],0
    je .d2
    mov esi,2
    jmp .d2d
.d2: mov esi,4
.d2d: call graphics_fill_rect
    mov eax,[wm_x+edi*4]
    add eax,10
    mov ebx,[wm_y+edi*4]
    add ebx,23
    mov esi, wm_txt_drv
    mov edi, 15
    call gui_draw_text
.out:
    popad
    ret
wm_txt_editor db 'EDITOR',0
wm_txt_files db 'FILES',0
wm_txt_notes db 'NOTES',0
wm_txt_explr db 'EXPLORER',0
wm_txt_drv db 'DRIVERS',0
wm_txt_cmd0 db 'GUI CMD',0
wm_txt_cmd1 db 'desktop=activo',0
wm_txt_cmd2 db 'apps: HELLO TXT FILES',0
wm_txt_cmd3 db 'power: REBOOT/OFF',0
wm_txt_cmd4 db 'shell legacy removida',0
%endif
