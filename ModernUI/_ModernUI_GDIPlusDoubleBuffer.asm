;==============================================================================
;
; ModernUI Library x64
;
; Copyright (c) 2023 by fearless
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
includelib gdi32.lib

include ModernUI.inc


IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Start Double Buffering for GDI+
;------------------------------------------------------------------------------
MUIGDIPlusDoubleBufferStart PROC FRAME USES RBX hWin:MUIWND, pGraphics:GPGRAPHICS, lpBitmapHandle:LPGPIMAGE, lpGraphicsBuffer:LPGPGRAPHICS
    LOCAL rect:RECT
    LOCAL pBuffer:QWORD
    LOCAL pBitmap:QWORD
    
    Invoke GetClientRect, hWin, Addr rect
    Invoke GdipCreateBitmapFromGraphics, rect.right, rect.bottom, pGraphics, Addr pBitmap
    Invoke GdipGetImageGraphicsContext, pBitmap, Addr pBuffer

    ; Save our created bitmap and buffer back to pGraphicsBuffer
    .IF lpGraphicsBuffer != NULL
        mov rbx, lpGraphicsBuffer
        mov rax, pBuffer
        mov [rbx], rax
    .ENDIF
    .IF lpBitmapHandle != NULL
        mov rbx, lpBitmapHandle
        mov rax, pBitmap
        mov [rbx], rax
    .ENDIF
    
    xor eax, eax
    ret
MUIGDIPlusDoubleBufferStart ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Finish Double Buffering for GDI+ & copy finished pGraphicsBuffer to pGraphics (HDC)
;------------------------------------------------------------------------------
MUIGDIPlusDoubleBufferFinish PROC FRAME hWin:MUIWND, pGraphics:GPGRAPHICS, pBitmap:GPIMAGE, pGraphicsBuffer:GPGRAPHICS
    LOCAL rect:RECT
    
    Invoke GetClientRect, hWin, Addr rect
    Invoke GdipDrawImageRectI, pGraphics, pBitmap, 0, 0, rect.right, rect.bottom
    Invoke GdipDeleteGraphics, pGraphicsBuffer   
    invoke GdipDisposeImage, pBitmap
    xor eax, eax
    ret
MUIGDIPlusDoubleBufferFinish ENDP


ENDIF


MODERNUI_LIBEND

