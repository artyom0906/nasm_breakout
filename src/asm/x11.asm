%include "/mnt/d/code/c/asm/src/asm/renderContext.asm"

section  .text

    global openWindow
    global handleEvents
    global createCanvas
    global drawFB
    global initContext
    global mainLoop

    extern XOpenDisplay
    extern DefaultScreen
    extern XCreateSimpleWindow
    extern XMapWindow
    extern XFlush
    extern XSelectInput
    extern XGetWindowAttributes
    extern XCreateGC
    extern XCreateImage
    extern XPutImage

    extern clock
    extern usleep

    extern memset
    extern malloc
    extern aligned_alloc

getRootWindow:
    push   rbp
    mov    rbp, rsp
    mov    rax, [rdi + RenderContext.display_ptr]
    mov    rax, [rax+0xe8]
    movsxd rcx, [rdi+RenderContext.screen_num]
    shl    rcx, 0x7
    add    rax, rcx
    mov    rax, [rax+0x10]
    pop    rbp
    ret

openWindow:
    push rbp               ; save previous base pointer
    mov  rbp, rsp          ; set up new base pointer
    sub  rsp, 0x40
    xor eax, eax
    mov ecx, eax

    mov [rbp-0x8], rdi     ; put rdi(context*) on stack
    mov rdi, rcx           ; put 0 as first argument
    call XOpenDisplay
    ; Save the display_ptr pointer

    mov rcx, [rbp-0x8]
    mov qword [rcx + RenderContext.display_ptr], rax

    mov rax, [rcx + RenderContext.display_ptr]
    mov edx, dword [rax+0xe0]; get screen number from display_ptr
    mov [rcx + RenderContext.screen_num], edx

    mov rdi, rcx

    call getRootWindow
    mov rsi, rax
    mov rcx, [rbp-0x8]

    mov rdi, qword [rcx + RenderContext.display_ptr]

    mov r8, [rcx + RenderContext.width]
    mov r9, [rcx + RenderContext.height]

    mov rdx, 0x64
    mov rcx, 0x64

    mov dword [rsp],      1
    mov qword [rsp+0x8],  0
    mov qword [rsp+0x10], 0xffffff
    call XCreateSimpleWindow

    mov rcx, [rbp-0x8]
    mov [rcx + RenderContext.window], rax

    mov rdi, QWORD [rcx + RenderContext.display_ptr]
    mov rsi, qword [rcx + RenderContext.window]
    mov rdx, 1
    call XSelectInput
    mov rcx, [rbp-0x8]
    mov rdi, QWORD [rcx + RenderContext.display_ptr]
    mov rsi, qword [rcx + RenderContext.window]
    call XMapWindow
    mov rcx, [rbp-0x8]
    mov rdi, QWORD [rcx + RenderContext.display_ptr]
    ;mov dword [rbp-0xc], eax
    call XFlush
    mov rcx, [rbp-0x8]
    mov rdi, QWORD [rcx + RenderContext.display_ptr]
    mov rsi, qword [rcx + RenderContext.window]
    mov rdx, 0
    mov rcx, 0
    call XCreateGC
    mov rcx, [rbp-0x8]
    mov qword [rcx + RenderContext.gc], rax

    add rsp, 0x40
    pop rbp

    ret

createCanvas:
    push   rbp
	mov    rbp,rsp
	push   rbx
	sub    rsp, 0xc8
	xor    esi, esi
	mov    [rbp-0x10], rdi
	lea    rax, [rbp-0x98]
	mov    rcx,rax
	mov    rdi,rcx
	mov    edx, 0x88
	mov    [rbp-0xa0],rax
	call   memset
	mov    rax, [rbp-0x10]
	mov    rdi, [rax + RenderContext.display_ptr]
	mov    rsi, [rax + RenderContext.window]
	mov    rdx, [rbp-0xa0]
	call   XGetWindowAttributes
	xor    r8d, r8d
	mov    rcx, [rbp-0x10]
	mov    rdi, [rcx + RenderContext.display_ptr]
	mov    rsi, [rbp-0x80] ;window_attributes.visual
	mov    edx, [rbp-0x84] ;window_attributes.depth
	mov    r9,  [rcx+RenderContext.front]
	mov    r10d,[rcx+RenderContext.width]
	mov    r11d,[rcx+RenderContext.height]
	mov    ebx, [rcx+RenderContext.width]
	mov    ecx, ebx
	shl    rcx, 0x2
	mov    ebx, 0x2
	mov    [rbp-0xa4], ecx
	mov    ecx, ebx
	mov    [rsp], r10d
	mov    [rsp+0x8], r11d
	mov    dword [rsp+0x10], 0x20
	mov    r10d, [rbp-0xa4]
	mov    [rsp+0x18], r10d
	mov    [rbp-0xa8], eax
	call XCreateImage
	xor    r8d, r8d
	mov    rcx, [rbp-0x10]
	mov    [rcx+RenderContext.img], rax

	add    rsp, 0xc8
	pop    rbx
	pop    rbp
	ret

initContext:
	push   rbp
	mov    rbp,rsp
	sub    rsp, 0x10
	mov    edi, 0x38         ; sizeof struct
	call   malloc            ; <malloc@plt>
	mov    [rbp-0x8], rax
	mov    dword [rax+RenderContext.width], 0x320
	mov    dword [rax+RenderContext.height], 0x320
	mov    edi, [rax+RenderContext.width]
	imul   edi, [rax+RenderContext.height]
	imul   edi, 4
	mov    esi, edi
	mov    edi, 64
	call   aligned_alloc            ; <malloc@plt>
	mov    rcx, [rbp-0x8]
	mov    [rcx + RenderContext.front], rax
	mov    rax, [rbp-0x8]
	add    rsp, 0x10
	pop    rbp
	ret

drawFB:
    push rbp
    mov  rbp, rsp
    sub  rsp, 0x20
    xor  eax, eax
    mov  [rbp-0x8], rdi
    mov  rax, rdi
    mov  rdi, [rax+RenderContext.display_ptr]
    mov  rsi, [rax+RenderContext.window]
    mov  rdx, [rax+RenderContext.gc]
    mov  rcx, [rax+RenderContext.img]
    mov  r8d, 0
    mov  r9d, 0
    mov  dword [rsp], 0
    mov  dword [rsp+0x08], 0
    mov r10d, [rax+RenderContext.width]
    mov  dword [rsp+0x10], r10d
    mov r10d, [rax+RenderContext.height]
    mov  dword [rsp+0x18], r10d
    call XPutImage
    add rsp, 0x20
    pop rbp
    ret

mainLoop:
    push rbp
    mov  rbp, rsp
    sub  rsp, 0x40

    mov [rbp-0x08], rdi
    mov [rbp-0x10], rsi
    mov [rbp-0x38], rdx
    mov dword [rbp-0x14], 0x8
  .loop:
    call clock
    mov [rbp-0x20], rax
    sub rax, [rbp-0x28]
    imul rax, 0x3e8 ; 1000
    cqo
    mov ecx, 0xf4240 ; CLOCKS_PER_SEC
    idiv rcx
    mov [rbp-0x2c], eax
    cmp eax, [rbp-0x14]
    jl .end
    mov rax, [rbp-0x20]
    mov [rbp-0x20], rax
    mov al, 0x0
    mov rdi, [rbp-0x8]
    mov rsi, [rbp-0x38]
    call [rbp-0x10]
    mov rdi, [rbp-0x8]
    call drawFB
    mov ecx, [rbp-0x14]
    sub ecx, [rbp-0x2c]
    mov [rbp-0x30], ecx
    cmp dword ecx, 0
    jle .end
    imul edi, [rbp-0x30], 0x3e8; 1000
    call usleep
    .end:
    jmp .loop