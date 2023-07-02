section  .text
    global checkSquareCircleCollision

checkSquareCircleCollision:
    ; circleX:      => RDI
    ; circleY:      => RSI
    ; radius:       => RDX
    ; squareX:      => RCX
    ; squareY:      => R8
    ; squareWidth:  => R9
    ; squareHeight  => rsp+0x8

    add    r9d, ecx                 ; squareX+squareWidth
    cmp    r9d, edi                 ; if circleX > squareX+squareWidth
    cmovg  r9d, edi                 ; r9 = circleX
    cmp    edi, ecx                 ; if cx<squareX
    cmovl  r9d, ecx                 ; r9 = squareX      (r9 is closest point X)

    mov    ecx, dword [rsp+0x8]     ; ecx = squareHeight
    add    ecx, r8d                 ; squareHeight + squareY
    cmp    ecx, esi                 ; if squareHeight + squareY > circleY
    cmovg  ecx, esi                 ; ecx = circleY
    cmp    esi, r8d                 ; if circleY < squareY
    cmovl  ecx, r8d                 ; ecx = squareY     (ecx is closest point Y)

    sub    r9d, edi                 ; distanceX = r9d-circleX
    sub    ecx, esi                 ; distanceY = ecx-circleY
    imul   r9d, r9d                 ; distanceX^2
    imul   ecx, ecx                 ; distanceY^2
    add    ecx, r9d                 ; distanceX^2 + distanceY^2
    imul   edx, edx                 ; radius^2
    xor    eax, eax
    cmp    ecx, edx                 ;  distanceX^2 + distanceY^2 <= radius^2
    setbe  al
    ret
