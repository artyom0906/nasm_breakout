
section .data
    ALIGN 64
    offsets  dd 0x0000, 0x0010, 0x0020, 0x0030, 0x0040, 0x0050, 0x0060, 0x0070    ; Адреса смещений
             dd 0x0080, 0x0090, 0x00a0, 0x00b0, 0x00c0, 0x00d0, 0x00e0, 0x00f0
    ALIGN 64
    dataVals dd 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16   ; значения


section  .text
global test1
test1:
   push rbp               ; save previous base pointer
   mov  rbp, rsp          ; set up new base pointer
   sub  rsp, 0x40


   vmovdqa64 zmm0, [offsets]
   vmovdqa64 zmm1, [dataVals]

    mov ax, 0b0101010101010101
    kmovq k1, rax
	;kmovq  k1, k0

   ;mov rdi, result

   ;vpxor zmm0, zmm0, zmm0
   vpscatterdd [rdi+zmm0*1]{k1}, zmm1,


   add rsp, 0x40
   pop rbp
   ret