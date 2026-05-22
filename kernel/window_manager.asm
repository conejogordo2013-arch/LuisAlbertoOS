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

wm_init:
    mov dword [wm_next_id], 1
    mov dword [wm_count], 0
    mov dword [wm_focus_id], 0
    mov dword [wm_drag_id], 0
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
.n: inc edi
    jmp .l2
.d: popad
    ret

%endif
