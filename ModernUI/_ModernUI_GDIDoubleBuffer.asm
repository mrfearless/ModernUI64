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


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIDoubleBufferStart - Starts double buffering. Used in a WM_PAINT event. 
; Place after BeginPaint call
;------------------------------------------------------------------------------
MUIGDIDoubleBufferStart PROC FRAME USES RBX hWin:QWORD, hdcSource:QWORD, lpHDCBuffer:QWORD, lpClientRect:QWORD, lpBufferBitmap:QWORD, lpPreBufferBitamp:QWORD
    LOCAL hdcBuffer:QWORD
    LOCAL hBitmap:QWORD

    .IF lpHDCBuffer == 0 || lpClientRect == 0 || lpBufferBitmap == 0 || lpPreBufferBitamp == 0
        mov rax, FALSE
        ret
    .ENDIF
    Invoke GetClientRect, hWin, lpClientRect
    Invoke CreateCompatibleDC, hdcSource
    mov hdcBuffer, rax
    mov rbx, lpHDCBuffer
    mov [rbx], rax
    mov rbx, lpClientRect
    Invoke CreateCompatibleBitmap, hdcSource, [rbx].RECT.right, [rbx].RECT.bottom
    mov hBitmap, rax
    mov rbx, lpBufferBitmap
    mov [rbx], rax
    Invoke SelectObject, hdcBuffer, hBitmap
    mov rbx, lpPreBufferBitamp
    mov [rbx], rax
    mov rax, TRUE
    ret
MUIGDIDoubleBufferStart ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIDoubleBufferFinish - Finishes double buffering - cleans up afterwards.
; Used in a WM_PAINT event. Place before EndPaint call and after all Blt calls
;------------------------------------------------------------------------------
MUIGDIDoubleBufferFinish PROC FRAME hdcBuffer:QWORD, hBufferBitmap:QWORD, hPreBufferBitamp:QWORD
    .IF hBufferBitmap != 0
        Invoke SelectObject, hdcBuffer, hBufferBitmap
        Invoke DeleteObject, hBufferBitmap
    .ENDIF
    .IF hPreBufferBitamp != 0
        Invoke SelectObject, hdcBuffer, hPreBufferBitamp
        Invoke DeleteObject, hPreBufferBitamp
    .ENDIF
    .IF hdcBuffer != 0
        Invoke DeleteDC, hdcBuffer
    .ENDIF
    ret
MUIGDIDoubleBufferFinish ENDP


MODERNUI_LIBEND



