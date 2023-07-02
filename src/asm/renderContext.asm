struc RenderContext
    .display_ptr    resq 1;0x0
    .window         resq 1;0x8
    .gc             resq 1;0x10
    .front          resq 1;0x18
    .img            resq 1;0x20
    .screen_num     resd 1;0x28
    .width          resd 1;0x2c
    .height         resd 1;0x30
endstruc