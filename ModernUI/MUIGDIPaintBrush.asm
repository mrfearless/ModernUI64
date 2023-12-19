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
includelib kernel32.lib
includelib gdi32.lib

include ModernUI.inc


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIPaintBrush - Fills a rectangle with a specific color
;
; lpBrushRect is a pointer to a RECT containing the bounding box to paint
; hBrushBitmap is an brush bitmap created from CreatePatternBrush to paint with
; qwBrushOrgX is x adjustment to start painting from in the source brush bitmap
; qwBrushOrgY is y adjustment to start painting from in the source brush bitmap
;------------------------------------------------------------------------------
MUIGDIPaintBrush PROC FRAME hdc:HDC, lpBrushRect:LPRECT, hBrushBitmap:HBITMAP, qwBrushOrgX:MUIVALUE, qwBrushOrgY:MUIVALUE
    LOCAL hBrushOld:QWORD
    LOCAL rect:RECT
    
    .IF hBrushBitmap == 0
        ret
    .ENDIF

    ; Adjust rect for FillRect call
    Invoke CopyRect, Addr rect, lpBrushRect
    inc rect.right
    inc rect.bottom
    Invoke SelectObject, hdc, hBrushBitmap
    mov hBrushOld, rax
    
    Invoke SetBrushOrgEx, hdc, dword ptr qwBrushOrgX, dword ptr qwBrushOrgY, 0   
    Invoke FillRect, hdc, Addr rect, hBrushBitmap
    Invoke SetBrushOrgEx, hdc, 0, 0, 0 ; reset the brush origin  

    .IF hBrushOld != 0
        Invoke SelectObject, hdc, hBrushOld
        Invoke DeleteObject, hBrushOld
    .ENDIF
   
    ret
MUIGDIPaintBrush ENDP


MODERNUI_LIBEND


