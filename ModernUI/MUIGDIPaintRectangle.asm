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
; MUIGDIPaintRectangle - Draws a draws a rectangle. The rectangle is outlined 
; by using the specified outline color and filled by using the specified fill 
; color.
; 
; lpRect is a pointer to a RECT containing the bounding box of the frame
; FrameColor is an RGBCOLOR to paint the frame edges. If FrameColor is -1 
; then no outline painting occurs, just fill painting.
;------------------------------------------------------------------------------
MUIGDIPaintRectangle PROC FRAME hdc:HDC, lpRect:LPRECT, FrameColor:MUICOLORRGB, FillColor:MUICOLORRGB
    LOCAL hBrush:QWORD
    LOCAL hBrushOld:QWORD
    LOCAL hPen:QWORD
    LOCAL hPenOld:QWORD
    LOCAL rect:RECT
    LOCAL pt:POINT
    
    .IF FrameColor == -1 && FillColor == -1
        ret
    .ENDIF
    
    .IF FrameColor != -1
        
        .IF FillColor != -1
            ;--------------------------------------------------------------
            ; Paint Frame and Fill
            ;--------------------------------------------------------------
            Invoke CopyRect, Addr rect, lpRect
    
            ;--------------------------------------------------------------
            ; Create pen for outline
            ;--------------------------------------------------------------
            Invoke CreatePen, PS_SOLID, 1, dword ptr FrameColor
            mov hPen, rax
            Invoke SelectObject, hdc, hPen
            mov hPenOld, rax 
            
            ;--------------------------------------------------------------
            ; Create brush for fill
            ;--------------------------------------------------------------
            Invoke CreateSolidBrush, dword ptr FillColor
            mov hBrush, rax
            Invoke SelectObject, hdc, hBrush
            mov hBrushOld, rax
            
            ;--------------------------------------------------------------
            ; Draw outlined and filled rectangle
            ;--------------------------------------------------------------
            Invoke Rectangle, hdc, rect.left, rect.top, rect.right, rect.bottom
            
            ;--------------------------------------------------------------
            ; Tidy up
            ;--------------------------------------------------------------
            .IF hPenOld != 0
                Invoke SelectObject, hdc, hPenOld
                Invoke DeleteObject, hPenOld
            .ENDIF
            .IF hPen != 0
                Invoke DeleteObject, hPen
            .ENDIF
            .IF hBrushOld != 0
                Invoke SelectObject, hdc, hBrushOld
                Invoke DeleteObject, hBrushOld
            .ENDIF     
            .IF hBrush != 0
                Invoke DeleteObject, hBrush
            .ENDIF
            
        .ELSE
            ;--------------------------------------------------------------
            ; Paint frame only
            ;--------------------------------------------------------------
            Invoke MUIGDIPaintFrame, hdc, lpRect, FrameColor, MUIPFS_ALL
        .ENDIF
    .ELSE
        ;--------------------------------------------------------------
        ; Paint fill only
        ;--------------------------------------------------------------
        Invoke MUIGDIPaintFill, hdc, lpRect, FillColor
    .ENDIF
    ret
MUIGDIPaintRectangle ENDP






MODERNUI_LIBEND