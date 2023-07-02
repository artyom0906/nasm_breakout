%include "/mnt/d/code/c/asm/src/asm/renderContext.asm"


struc GameStruct
    .ball_x          resd 1 ; 0x00
    .ball_y          resd 1 ; 0x04
    .ball_dx         resd 1 ; 0x08
    .ball_dy         resd 1 ; 0x0b
    .ball_color      resd 1 ; 0x10
    .ball_size       resd 1 ; 0x14

    .platform_x      resd 1 ; 0x18
    .platform_y      resd 1 ; 0x1b
    .platform_w      resd 1 ; 0x20
    .platform_h      resd 1 ; 0x24
    .platform_color  resd 1 ; 0x28
    .platform_v      resd 1 ; 0x2b

    .block_w         resd 1;
    .block_h         resd 1;

    .currentLevel    resq 1 ;
    .levels          resq 1 ;
    .levelCount      resd 1 ;
    .currentLevelIdx resd 1 ;

endstruc
struc Level
    .mask           resq 4 ; 0x00
    .speed          resd 2
    .allign         resq 3
    .colors         resd 0x80 ; 0x10
endstruc


section  .text

    extern checkSquareCircleCollision

    extern drawRectangle
    extern drawCircle


    extern memset
    extern aligned_alloc

    extern XNextEvent
    extern XPending




    global keyboardHandler
    global update
    global draw
    global eventHandler

keyboardHandler:
	cmp    esi, 0x26
	je     .buttonD
	cmp    esi, 0x28
	je     .buttonA
	cmp    esi, 0x9
	je     .buttonESC
	ret
	.buttonA:
	movss  xmm0, [rdi+GameStruct.platform_x]
	addss  xmm0, [rdi+GameStruct.platform_v]
	jmp    .savePlatformPos
	.buttonD:
	movss  xmm0, [rdi+GameStruct.platform_x]
	subss  xmm0, [rdi+GameStruct.platform_v]
	.savePlatformPos:
	movss  [rdi+GameStruct.platform_x], xmm0
	ret
	.buttonESC:
	mov rax, 1
	xor rbx, rbx
	int 0x80

update:
    push   rbp
    push   rbx
    sub    rsp, 0x10
    mov    rbp, rsp

    movss  xmm0, [rdi+GameStruct.ball_x]
    movss  xmm1, [rdi+GameStruct.ball_y]
    movss  xmm2, [rdi+GameStruct.ball_dx]
    movss  xmm3, [rdi+GameStruct.ball_dy]
    addss  xmm0, xmm2
    addss  xmm1, xmm3
    movss  dword [rdi+GameStruct.ball_x], xmm0
    movss  dword [rdi+GameStruct.ball_y], xmm1

    mov    eax, dword [rdi+GameStruct.ball_size]
    cvtsi2ss xmm4, eax
    mov    eax, dword [rsi+RenderContext.width]
    cvtsi2ss xmm5, eax


    mov eax, 0x80000000
    movd xmm6, eax

    addss xmm0, xmm4
    ucomiss xmm0, xmm5
    jae .changeBallDX ;jae

    movss  xmm0, [rdi+GameStruct.ball_x]
    subss  xmm0, xmm4
    xorps  xmm7, xmm7
    ucomiss xmm7, xmm0
    jb .checkBallDY

    .changeBallDX:
    xorps xmm2, xmm6
    movss dword [rdi+GameStruct.ball_dx], xmm2

    .checkBallDY:
    mov    eax, dword [rsi+RenderContext.height]
    cvtsi2ss xmm0, eax

    addss xmm1, xmm4
    ucomiss xmm1, xmm0
    jae .changeBallDY

    movss  xmm1, [rdi+GameStruct.ball_y]
    subss  xmm1, xmm4
    ucomiss xmm7, xmm1
    jb .checkCollisionWithPlatform

    .changeBallDY:
    xorps xmm3, xmm6
    movss dword [rdi+GameStruct.ball_dy], xmm3

    .checkCollisionWithPlatform:
    mov rbx, rdi
    cvttss2si edi, [rbx+GameStruct.ball_x]
    cvttss2si esi, [rbx+GameStruct.ball_y]
    mov rdx, [rbx+GameStruct.ball_size]
    cvttss2si rcx, [rbx+GameStruct.platform_x]
    cvttss2si r8,  [rbx+GameStruct.platform_y]
    cvttss2si r9,  [rbx+GameStruct.platform_w]
    cvttss2si r10,  [rbx+GameStruct.platform_w]
    mov [rsp], r10
    call checkSquareCircleCollision
    test eax, eax

    je .level_complete_check
    movss xmm0, [rbx+GameStruct.ball_dy]
    xorps xmm0, xmm6
    movss [rbx+GameStruct.ball_dy], xmm0
    movss xmm0, [rbx+GameStruct.ball_y]
    mov eax, 0xc0400000 ; -3.f
    movd xmm1, eax
    addss xmm0, xmm1
    movss [rbx+GameStruct.ball_y], xmm0


    mov rcx, 4
    mov rdx, 0
    .level_complete_check:

    mov rax, [rbx+GameStruct.currentLevel]
    mov rax, [rax+rdx]
    test rax, rax

    jnz .game_continue

    inc rdx
    loop .level_complete_check

    ;next level
    mov rax, [rbx+GameStruct.currentLevel]
    add rax,  1088
    mov [rbx+GameStruct.currentLevel], rax

    ;mov rax, [rax + Level.speed]
    ;mov [rbx+GameStruct.ball_dx], rax
    ;todo change speed

    .game_continue:
    mov rdi, rbx
    call checkAndUpdateLevelBlockCollisions

    add    rsp, 0x10
    pop    rbx
	pop    rbp
	ret

draw:
	push   r10
	push   rbx
	mov    rbx, rsi
	mov    r10, rdi
	mov    rdi, [rdi+RenderContext.front]
	mov    edx, 0x271000; 800*800*4 clear the buffer
	xor    esi,esi
	call   memset

	cvttss2si esi, [rbx+GameStruct.platform_x]
	cvttss2si edx, [rbx+GameStruct.platform_y]
	cvttss2si ecx, [rbx+GameStruct.platform_w]
	cvttss2si r8d, [rbx+GameStruct.platform_h]
	mov       r9d, [rbx+GameStruct.platform_color]
	mov       rdi, r10
	call   drawRectangle

    mov rdi, r10
	mov rsi, rbx
	call drawLevel

	cvttss2si esi, [rbx+GameStruct.ball_x]
    cvttss2si edx, [rbx+GameStruct.ball_y]
    mov       ecx, [rbx+GameStruct.ball_size]
    mov       r8d, [rbx+GameStruct.ball_color]
    mov       rdi, r10
    call   drawCircle


	pop    rbx
	pop    r10
	ret


global loadLevels
loadLevels:
    push   rbp
    sub    rsp, 0x100
    mov    rbp, rsp

    mov [rbp-0x8], rdi

    mov eax, 2                      ; Системный вызов open
    mov edi, filename               ; Указатель на имя файла
    mov esi, 0                      ; Режим открытия файла
    syscall                         ; Вызов системного прерывания
    mov [rbp-0x10], eax


    mov edi, eax                   ; Дескриптор файла
    mov eax, 0x5                   ; Системный вызов fstat
    lea rsi, [rbp-0xa0]            ; Указатель на структуру stat
    syscall                        ; Вызов системного прерывания


    mov rsi, [rbp-0x08]           ; Буфер для чтения данных
    mov rsi, [rsi+GameStruct.levels]
    mov edi, [rbp-0x10]           ; Дескриптор файла
    mov edx, [rbp-0xa0+48]        ; Размер буфера
    mov eax, 0                    ; Системный вызов read
    syscall

    mov rax, [rbp-0xa8]

    ; Закрываем файл
    ;mov eax, 6                      ; Системный вызов close
    ;mov ebx, [rbp-0x8]              ; Дескриптор файла
    ;int 0x80                        ; Вызов системного прерывания

    add    rsp, 0x100
    pop    rbp
    ret


global checkAndUpdateLevelBlockCollisions
checkAndUpdateLevelBlockCollisions:
   push rbp               ; save previous base pointer
   push r11
   push rbx
   push r10
   push r12
   push r13
   mov  rbp, rsp          ; set up new base pointer
   sub  rsp, 0x100

   ;rdi GameStruct ptr
   ;r11 layers counter



    mov r11, 15
   .loop_layers:

    vmovdqa64 zmm0, [offsets_1]
    mov r9d, [rdi + GameStruct.block_w]
    vpbroadcastd zmm3, r9d
    vpmulld  zmm0, zmm0, zmm3; blocks X cords
    vmovupd zmm15, zmm0
    dec r9
    vpbroadcastd zmm1, r9d   ; blocks width

    cvttss2si eax, dword [rdi + GameStruct.ball_x]
    vpbroadcastd zmm2, eax ; ball x
    cvttss2si edx, dword [rdi + GameStruct.ball_y]
    vpbroadcastd zmm3, edx ; ball y
    mov ecx, dword [rdi + GameStruct.ball_size]
    vpbroadcastd zmm4, ecx ; ball r
    vpmulld      zmm4, zmm4, zmm4

   mov rbx, [rdi + GameStruct.currentLevel]
   lea rbx, [rbx + Level.mask+r11*2]
   mov rbx, [rbx]


   vpaddd  zmm5, zmm0, zmm1   ; block X + block width
   vpminsd zmm5, zmm5, zmm2   ; min(ball_x, block X + block width)
   vpmaxsd zmm5, zmm5, zmm0   ; max(blockX, min)

   mov r10, r11
   imul r10, [rdi + GameStruct.block_h]
   add r10, r11; X
   mov r12, r10
   add r12, [rdi + GameStruct.block_h];X+width

   vpbroadcastd zmm6, r10d
   vpbroadcastd zmm7, r12d

   vpminsd zmm8, zmm7, zmm3 ; min(ball_y{zmm3}, blockY+blockHeigh
   vpmaxsd zmm8, zmm6, zmm8 ; max(BlockY, min)

   vpsubd zmm8, zmm3, zmm8
   vpsubd zmm5, zmm2, zmm5

   vpmulld zmm5, zmm5, zmm5
   vpmulld zmm8, zmm8, zmm8

   vpaddd zmm5, zmm8, zmm5

   vpcmpgtd k2, zmm4, zmm5

   kmovw eax, k2
   and eax, ebx
   cmp eax, 0
   je .next
   movups xmm0, [rdi + GameStruct.ball_x]

   xor rbx, rbx
   tzcnt ebx, eax
   imul ebx, 4

   mov rax, rbp
   and rax, 63
   mov rcx, 64
   sub rcx, rax
   sub rbp, rcx

   vmovups [rbp], zmm15
   mov eax, dword [rbp + rbx]
   vmovups [rbp], zmm6
   mov ecx, dword [rbp + rbx]
   cvtsi2ss xmm1, eax
   cvtsi2ss xmm2, ecx
   vbroadcastss xmm2, xmm2
   vmovss xmm2, xmm1

   vmovdqu xmm1, [rdi + GameStruct.block_w]
   psrld xmm1, 1
   cvtdq2ps xmm1, xmm1

    ; xmm2 - {blockX, blockY}
    ; xmm1 - {blockW, blockH}/2
    ; xmm0 - {circleX, circleY}

   vaddps xmm3, xmm2, xmm1
   vsubps xmm4, xmm0, xmm3

   movaps xmm5, xmm4
   vmulps xmm5, xmm5, xmm5
   movaps xmm6, xmm5
   haddps xmm6, xmm6
   sqrtss xmm6, xmm6
   vbroadcastss xmm6, xmm6
   divps  xmm4, xmm6

   mov eax, [rdi + GameStruct.ball_size]
   cvtsi2ss xmm7, eax
   vbroadcastss xmm7, xmm7
   vaddps xmm7, xmm7, xmm1
   vmulps xmm7, xmm4, xmm7
   vaddps xmm7, xmm7, xmm3
   ;todo write to memory (convert to int, remove trash, save)
    movq    rax, xmm7
    mov     [rdi + GameStruct.ball_x], rax

   vmovups xmm10, [rdi + GameStruct.ball_dx]
   vmovups xmm8, xmm10
   vmulps  xmm8, xmm4
   haddps  xmm8, xmm8
   vbroadcastss xmm8, xmm8
   vmulps  xmm8, xmm4
   mov eax, 2
   cvtsi2ss xmm9, eax
   vbroadcastss xmm9, xmm9
   vmulps  xmm8, xmm9
   vsubps  xmm10, xmm8
   movq    rax, xmm10
   mov     [rdi + GameStruct.ball_dx], rax



   mov rbx, [rdi + GameStruct.currentLevel]
   lea rbx, [rbx + Level.mask+r11*2]
   kmovd k1, [rbx]
   knotd k2, k2
   kandd k3, k2, k1

   kmovd [rbx], k3
   .next:
   dec r11
   cmp r11, -1
   jne .loop_layers

   add rsp, 0x100
   pop r13
   pop r12
   pop r10
   pop rbx
   pop r11
   pop rbp
   ret

global drawLevel
drawLevel:
   push rbp               ; save previous base pointer
   push r10
   push rbx
   push r11
   push r12
   mov  rbp, rsp          ; set up new base pointer
   sub  rsp, 0x10



   vmovdqa64 zmm0, [offsets]
   mov r9d, [rsi + GameStruct.block_w]
   vpbroadcastd zmm3, r9d
   vpmulld  zmm0, zmm0, zmm3
   dec r9
   mov r11, 15; 16-1



   .loop_layers:

   mov r12, [rsi + GameStruct.currentLevel]
   lea r12, [r12 + Level.colors]
   shl r11, 6
   lea r12, [r12 + r11]
   shr r11, 6

   vmovdqa64 zmm1, [r12]

   mov ecx, [rsi + GameStruct.block_h]

   imul rcx, r9
   dec rcx
   mov rbx, [rsi + GameStruct.currentLevel]
   lea rbx, [rbx + Level.mask+r11*2]
   mov rbx, [rbx]

   .loop:
   cqo
   mov rax, rcx
   idiv r9
   ; edx x
   ; eax y

   mov r10, r11
   imul r10, [rsi + GameStruct.block_h]
   add r10, r11


   add rax, r10
   imul eax, [rdi+RenderContext.width]
   add eax, edx
   ;add rax, rcx
   imul rax, 4
   vpbroadcastd zmm2, eax

   vpaddd zmm4, zmm0, zmm2

   mov rax, [rdi+RenderContext.front]

   ;vpxor zmm0, zmm0, zmm0

    ;mov ax, 0b1001100110011001
   ;mov rbx, 0xFFFFFFFF;[ebx + Level.mask]
   kmovw k1, ebx

   vpscatterdd [rax+zmm4*1]{k1}, zmm1

   dec ecx
   cmp ecx, -1
   jne .loop

   dec r11
   cmp r11, -1
   jne .loop_layers


   add rsp, 0x10
   pop r12
   pop r11
   pop rbx
   pop r10
   pop rbp
   ret

eventHandler:
    push r14
    push rbx
    sub rsp, 0xc8

    mov r14, rsi
    mov rbx, rdi

    mov rdi, [rdi+RenderContext.display_ptr]
    call XPending
    test eax, eax
    je .render

    mov qword rdi, [rbx+RenderContext.display_ptr]
    lea rsi, [rsp+0x8]
    call XNextEvent
    cmp dword [rsp+0x8], 0x2 ; KeyPress code
    jne .render
    mov esi, [rsp+0x5c] ; event.xkey.keycode
    mov qword rdi, r14
    call keyboardHandler

    .render:
    mov rdi, r14
    mov rsi, rbx
    call update
    mov rdi, rbx
    mov rsi, r14
    call draw

    add rsp, 0xc8
    pop rbx
    pop r14
    ret

section .data

    ; Данные
    filename  db '../levels.dat', 0
    mode      dd 0
    ALIGN 64
    offsets   dd 0x00, 0x04, 0x08, 0x0c, 0x10, 0x14, 0x18, 0x1c
              dd 0x20, 0x24, 0x28, 0x2c, 0x30, 0x34, 0x38, 0x3c
    ALIGN 64
    offsets_1 dd 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
              dd 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
    ;offsets  dd 000, 050, 100, 150, 200, 250, 300, 350    ; Адреса смещений
    ;         dd 400, 450, 500, 550, 600, 650, 700, 750