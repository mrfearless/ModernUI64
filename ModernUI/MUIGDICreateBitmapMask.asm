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
; MUIGDICreateBitmapMask - Create a mask from an existing bitmap using the 
; specified color as the mask transparency: 
; http://www.winprog.org/tutorial/transparency.html
;------------------------------------------------------------------------------
MUIGDICreateBitmapMask PROC FRAME hBitmap:HBITMAP, TransparentColor:MUICOLORRGB
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hdcMem2:HDC
    LOCAL hdcMask:HDC
    LOCAL hbmMask:HBITMAP
    LOCAL hbmMaskOld:QWORD
    LOCAL hBitmapMask:QWORD
    LOCAL hBitmapMaskOld:QWORD
    LOCAL hBitmapOld:QWORD
    LOCAL bm:BITMAP

	Invoke GetDC, 0
	mov hdc, rax

    ; Create monochrome (1 bit) mask bitmap.  
    Invoke RtlZeroMemory, Addr bm, SIZEOF BITMAP
    Invoke GetObject, hBitmap, SIZEOF BITMAP, Addr bm
    Invoke CreateBitmap, bm.bmWidth, bm.bmHeight, 1, 1, NULL
    mov hbmMask, rax
    
    Invoke CreateCompatibleBitmap, hdc, bm.bmWidth, bm.bmHeight
    mov hBitmapMask, rax

    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    Invoke CreateCompatibleDC, hdc
    mov hdcMem2, rax
    Invoke CreateCompatibleDC, hdc
    mov hdcMask, rax

    Invoke SelectObject, hdcMem, hBitmap
    mov hBitmapOld, rax
    Invoke SelectObject, hdcMem2, hbmMask
    mov hbmMaskOld, rax
    Invoke SelectObject, hdcMask, hBitmapMask
    mov hBitmapMaskOld, rax
    
    Invoke SetBkColor, hdcMem, dword ptr TransparentColor

    Invoke BitBlt, hdcMem2, 0, 0, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY
    Invoke BitBlt, hdcMask, 0, 0, bm.bmWidth, bm.bmHeight, hdcMem2, 0, 0, SRCINVERT

    ; Clean up.
    Invoke SelectObject, hdcMem, hBitmapOld
    Invoke DeleteObject, hBitmapOld
    
    Invoke SelectObject, hdcMem2, hbmMaskOld
    Invoke DeleteObject, hbmMaskOld
    Invoke DeleteObject, hbmMask
    
    Invoke SelectObject, hdcMask, hBitmapMaskOld
    Invoke DeleteObject, hBitmapMaskOld
    
    Invoke DeleteDC, hdcMem
    Invoke DeleteDC, hdcMem2
    Invoke DeleteDC, hdcMask
    
    Invoke ReleaseDC, 0, hdc
    
    mov rax, hBitmapMask
    ret
MUIGDICreateBitmapMask ENDP



MODERNUI_LIBEND

