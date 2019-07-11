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
includelib gdi32.lib

include ModernUI.inc

IFNDEF BITMAPINFOHEADER
BITMAPINFOHEADER	STRUCT 8
biSize	            DWORD	?
biWidth	            SDWORD	?
biHeight	        SDWORD	?
biPlanes	        WORD	?
biBitCount	        WORD	?
biCompression	    DWORD	?
biSizeImage	        DWORD	?
biXPelsPerMeter	    SDWORD	?
biYPelsPerMeter	    SDWORD	?
biClrUsed	        DWORD	?
biClrImportant	    DWORD	?
BITMAPINFOHEADER	ENDS
ENDIF

IFNDEF BITMAPFILEHEADER
BITMAPFILEHEADER	STRUCT 8
bfType	            WORD	?
bfSize	            DWORD	?
bfReserved1	        WORD	?
bfReserved2	        WORD	?
bfOffBits	        DWORD	?
BITMAPFILEHEADER	ENDS
ENDIF

.DATA
szMUIBitmapFromMemoryDisplayDC DB 'DISPLAY',0


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICreateBitmapFromMemory
;
; http://www.masmforum.com/board/index.php?topic=16267.msg134453#msg134453
;------------------------------------------------------------------------------
MUICreateBitmapFromMemory PROC FRAME USES RCX RDX pBitmapData:POINTER
    LOCAL hDC:QWORD
    LOCAL hBmp:QWORD
    LOCAL lpInfoHeader:QWORD
    LOCAL lpInitBits:QWORD

    ;Invoke GetDC,hWnd
    Invoke CreateDC, Addr szMUIBitmapFromMemoryDisplayDC, NULL, NULL, NULL
    test    rax,rax
    jz      @f
    mov     hDC,rax
    mov     rdx,pBitmapData
    lea     rcx,[rdx + SIZEOF BITMAPFILEHEADER]  ; start of the BITMAPINFOHEADER header
    mov lpInfoHeader, rcx
    xor rax, rax
    mov     eax, dword ptr BITMAPFILEHEADER.bfOffBits[rdx]
    add     rdx,rax
    mov lpInitBits, rdx
    Invoke  CreateDIBitmap, hDC, lpInfoHeader, CBM_INIT, lpInitBits, lpInfoHeader, DIB_RGB_COLORS
    mov     hBmp,rax
    ;Invoke  ReleaseDC,hWnd,hDC
    Invoke DeleteDC, hDC
    mov     rax,hBmp
@@:
    ret
MUICreateBitmapFromMemory ENDP


MODERNUI_LIBEND




