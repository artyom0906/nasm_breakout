default rel
%include "/mnt/d/code/c/asm/src/asm/renderContext.asm"

section  .text

checkSquareCircleCollision:
     push rbp
     mov  rbp, rsp



     pop rbp
     ret



handleEvents:
	push rbp
	mov  rbp, rsp
	sub  rsp, 0xd0
;.loop:
;	mov  rdi,QWORD [renderContext.asm + RenderContext.display_ptr]
;	lea  rsi, [rbp-0xc0]
;	call XNextEvent
;	mov  [rbp-0xc4], eax
;	mov  edx,len
;    mov  ecx,msg
;    mov  ebx,1
;    mov  eax,4
;    int  0x80
;	jmp  .loop



section  .data
    msg db 'test', 0xa
    len equ $-msg
    err_msg db 'Failed to connect to the X server', 0xa
    len_err_msg equ $-err_msg
    ;renderContext.asm + RenderContext.display_ptr dq 0         ; renderContext.asm + RenderContext.display_ptr pointe
    ;window dd 0              ; X11 window ID
    x: dq 0                  ; x coordinate
    y: dq 0                  ; y coordinate
    width: dq 640            ; window width
    height: dq 480           ; window height
    border_width: dq 1       ; border width
    border: dq 0             ; border color
    background: dq 0         ; background color

section .bss
    ;renderContext.asm + RenderContext.screen_num resd 1

;    cmp QWORD [rbp-0x10], 0x0
;
;    jne not_null ; jump to not_null if eax is not null
;    ; eax is null, print error message
;    mov eax, 4 ; sys_write
;    mov ebx, 1 ; stdout
;    mov ecx, err_msg ; message to print
;    mov edx, len_err_msg ; message length
;    int 0x80 ; syscall
;    ; exit program with status code 1 (error)
;    mov eax, 1 ; sys_exit
;    xor ebx, ebx ; status code 0 (success)
;    int 0x80 ; syscall
;    ret