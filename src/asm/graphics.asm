%include "/mnt/d/code/c/asm/src/asm/renderContext.asm"

section  .text
   ;global _start
   global drawLine
   global drawCircle
   global drawRectangle

drawRectangle:
    push rbp
    mov  rbp, rsp
    push r10
    push r11
    push r12
    sub rsp, 0x40
    mov  [rbp-0x08], rdi    ;rdi RenderContext* ; rbp-0x8
    mov  [rbp-0x10], rsi    ;rsi X              ; rbp-0x10
    mov  [rbp-0x18], rdx    ;rdx Y              ; rbp-0x18
    mov  [rbp-0x20], rcx    ;rcx width          ; rbp-0x20
    mov  [rbp-0x28], r8     ;r8  height         ; rbp-0x28
    mov  [rbp-0x30], r9     ;r9  color          ; rbp-0x28\

    mov r11, r9

    cmp esi, 0
    jl .exit
    mov r10,  rdx
    cmp edx, 0
    jl .exit
    lea rax, [rcx+rsi]
    cmp eax, dword [rdi+RenderContext.width]
    jg .exit
    lea rax, [r8+r10]
    cmp eax, dword [rdi+RenderContext.height]
    jg .exit

    mov r9, rcx
    mov r11d, dword [rdi+RenderContext.width]
    imul rcx, r8
    dec rcx
    .loop:
    cqo
    mov rax, rcx
    idiv r9
    ; edx x
    ; eax y
    add rdx, rsi         ; x += X
    add rax, [rbp-0x18]  ; y += Y

    imul rax, r11 ; y *= RenderContext.width
    add rax, rdx  ; y += x
    shl rax, 0x2  ; y *= 4
    add rax, [rdi + RenderContext.front]
    mov r12, [rbp-0x30]
    mov dword [rax], r12d

    ;mov rcx, -1
    loop .loop

    sub rax, 4
    mov dword [rax], r12d


    .exit:
    add rsp, 0x40
    pop r12
    pop r11
    pop r10
    pop rbp
    ret

drawCircle:
    push rbp
    mov  rbp, rsp
    push r10
    push r11
    push r12
    sub rsp, 0x40

    mov  [rbp-0x08], rdi  ;rdi RenderContext* ; rbp-0x8
    mov  [rbp-0x10], rsi  ;rsi centerX        ; rbp-0x10
    mov  [rbp-0x18], rdx  ;rdx centerY        ; rbp-0x18
    mov  [rbp-0x20], rcx  ;rcx radius         ; rbp-0x20
    mov  [rbp-0x28], r8   ;r8  color          ; rbp-0x28
    xor r9, r9
    mov r10, r9
    mov r11, r9
    mov r12, r9

    sub  rsi, rcx; startX
    cmp rsi, 0
    cmovle rsi, r9

    sub  rdx, rcx; startY
    cmp rdx, 0
    cmovle rdx, r9

    mov [rbp-0x30], rsi ;startX
    mov [rbp-0x38], rdx ;startY

    mov  r9, rcx
    imul rcx, 2  ;diameter
    mov  r8, rcx
    imul r9, r9 ;r^2

    imul rcx, rcx
    xor  rax, rax
    .loop_start:
    mov rdi, [rbp-0x8]
    xor rdx, rdx
    mov rax, rcx
    div r8 ;edx - c%diameter - x eax - c/diameter - y

    add edx, [rbp-0x30]; x + StartX
    add eax, [rbp-0x38]; y + StartY

    cmp rdx, 0
    jl .end
    cmp rdx, [rdi+RenderContext.width]
    jge .end
    cmp rax, 0
    jl .end
    cmp rax, [rdi+RenderContext.height]
    jge .end

    ;currentX  - edx
    ;currentY  - eax
    mov r11, rdx
    mov r12, rax

    sub rdx, [rbp-0x10] ;dx = current - centerX
    sub rax, [rbp-0x18] ;dy = current - centerY

    mov  r10, rdx
    imul r10, rdx
    imul rax, rax
    add  r10, rax
    ;distanceSquared = dx * dx + dy * dy
    cmp r10, r9
    jg .end

    mov  eax,dword [rdi+RenderContext.width]
    imul r12, rax
    add  r12, r11
    imul r12, 4
    mov rax, [rdi+RenderContext.front]
    add rax, r12
    mov rdi, [rbp-0x28]
    mov dword [rax], edi


    .end:
    loop .loop_start

    add rsp, 0x40
    pop r12
    pop r11
    pop r10
    pop rbp
    ret


drawLine:
    push rbp
    mov  rbp, rsp
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    sub rsp, 0x40
    xor r10, r10
    mov r11, r10    ;dx
    mov r12, r10    ;dy
    mov r13, 1      ;sx
    mov r14, 1      ;sy
    mov r15, r10    ;err

    ;rdi RenderContext* ; rbp-0x8
    ;rsi x1             ; rbp-0x10
    ;rdx y1             ; rbp-0x18
    ;rcx x2             ; rbp-0x20
    ;r8  y2             ; rbp-0x28
    ;r9  color          ; rbp-0x30

    mov  [rbp-0x08], rdi
    mov  [rbp-0x10], rsi
    mov  [rbp-0x18], rdx
    mov  [rbp-0x20], rcx
    mov  [rbp-0x28], r8
    mov  [rbp-0x30], r9

    ;r11 - dx
    mov r11, rcx
    sub r11, rsi
    cmp r11, 0
    jns .dx_end
    neg r11
    mov r13, -1
    add r11, 1
    .dx_end:
    ;r12 - dy
    mov r12, r8
    sub r12, rdx
    cmp r12, 0
    jns .dy_end
    neg r12
    mov r14, -1
    add r12, 1
    .dy_end:

    cmp r11, r12
    cmovb r15, r11
    cmovle r15, r12
    jnle .err_end
    neg r15
    .err_end:
    sar r15, 1


    .loop:
        mov rdi, [rbp-0x08]
        mov r10d, dword[rdi + RenderContext.width]
        imul rdx, r10 ; width * y1
        add  rdx, rsi ; width * y1 + x1
        shl  rdx, 2   ; (width * y1 + x1)*4 - address of pixel with x1 y1 coordinates
        mov  r10, [rdi + RenderContext.front]
        add  r10, rdx

        mov  rax, r9
        mov  rdi, r10
        stosd

        mov rcx, [rbp-0x20]
        cmp rsi, rcx
        je .end
        mov  rdx, [rbp-0x18]
        cmp rdx, r10
        je .end

        mov rax, r15
        neg r11
        cmp rax, r11
        neg r11
        jnb .err_cmp1_end

        sub r15, r12
        add rsi, r13

        .err_cmp1_end:
        cmp rax, r12
        jnl .err_cmp2_end

        add r15, r11
        add rdx, r14
        mov [rbp-0x18], rdx

        .err_cmp2_end:
        loop .loop
    .end:
    add rsp, 0x40
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop rbp
    ret

