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
; MUIGDIPaintFill - Fills a rectangle with a specific color
;
; lpFillRect is a pointer to a RECT containing the bounding box to fill
; FillColor is an RGBCOLOR to paint fill the rectangle with
;------------------------------------------------------------------------------
MUIGDIPaintFill PROC FRAME hdc:HDC, lpFillRect:LPRECT, FillColor:MUICOLORRGB
    LOCAL hBrush:QWORD
    LOCAL hBrushOld:QWORD
    LOCAL rect:RECT
    
    ; Adjust rect for FillRect call
    Invoke CopyRect, Addr rect, lpFillRect
    inc rect.right
    inc rect.bottom
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdc, rax
    mov hBrushOld, rax
    Invoke SetDCBrushColor, hdc, dword ptr FillColor
    Invoke FillRect, hdc, Addr rect, hBrush
    .IF hBrushOld != 0
        Invoke SelectObject, hdc, hBrushOld
        Invoke DeleteObject, hBrushOld
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF      
    ret
MUIGDIPaintFill ENDP


MODERNUI_LIBEND

