;==============================================================================
;
; ModernUI Library x64
;
; Copyright (c) 2019 by fearless
;
; All Rights Reserved
;
; http://github.com/mrfearless/ModernUI64
;
;==============================================================================
.686
.MMX
.XMM
.x64

option casemap : none
option win64 : 11
option frame : auto
option stackbase : rsp

_WIN64 EQU 1
WINVER equ 0501h

include windows.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

include ModernUI.inc

IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib
ENDIF


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGetImageSizeEx - Similar to MUIGetImageSize, but also returns centering
; x and y co-ord information based on rectangle of hWin
;------------------------------------------------------------------------------
MUIGetImageSizeEx PROC FRAME USES RBX hWin:MUIWND, hImage:MUIIMAGE, ImageHandleType:MUIIT, lpImageWidth:LPMUIVALUE, lpImageHeight:LPMUIVALUE, lpImageX:LPMUIVALUE, lpImageY:LPMUIVALUE
    LOCAL rect:RECT
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    LOCAL qwXPos:QWORD
    LOCAL qwYPos:QWORD
    LOCAL RetVal:QWORD

    Invoke MUIGetImageSize, hImage, ImageHandleType, Addr qwImageWidth, Addr qwImageHeight
    .IF rax == FALSE
        mov qwImageWidth, 0
        mov qwImageHeight, 0
        mov qwXPos, 0
        mov qwYPos, 0
        mov RetVal, FALSE
    .ELSE
        Invoke GetClientRect, hWin, Addr rect
        xor rax, rax
        mov eax, rect.right
        sub eax, rect.left
        sub rax, qwImageWidth
        shr rax, 1 ; div by 2
        .IF sqword ptr rax < 0
            mov rax, 0
        .ENDIF
        mov qwXPos, rax
        xor rax, rax
        mov eax, rect.bottom
        sub eax, rect.top
        sub rax, qwImageHeight
        shr rax, 1 ; div by 2
        .IF sqword ptr rax < 0
            mov rax, 0
        .ENDIF        
        mov qwYPos, rax
        mov RetVal, TRUE
    .ENDIF

    .IF lpImageWidth != 0
        mov rbx, lpImageWidth
        mov rax, qwImageWidth
        mov [rbx], rax
    .ENDIF
    .IF lpImageHeight != 0
        mov rbx, lpImageHeight
        mov rax, qwImageHeight
        mov [rbx], rax
    .ENDIF
    .IF lpImageX != 0
        mov rbx, lpImageX
        mov rax, qwXPos
        mov [rbx], rax
    .ENDIF
    .IF lpImageY != 0
        mov rbx, lpImageY
        mov rax, qwYPos
        mov [rbx], rax
    .ENDIF    

    mov rax, RetVal
    ret
MUIGetImageSizeEx ENDP



MODERNUI_LIBEND