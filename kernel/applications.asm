%ifndef LA_APPLICATIONS_ASM
%define LA_APPLICATIONS_ASM

app_count dd 2
app0_name db 'Explorer',0
app1_name db 'TaskMgr',0

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
    mov esi, app1_name
    mov eax, 50
    mov ebx, 38
    mov ecx, 160
    mov edx, 110
    call create_window
    ret

%endif
