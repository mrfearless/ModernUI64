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
; MUIGDIPaintFrame - Draws a border (or parts of) around a rectangle with a 
; specific color.
; 
; lpFrameRect is a pointer to a RECT containing the bounding box of the frame
; dwFrameColor is an RGBCOLOR to paint the frame edges. If dwFrameColor is -1 
; then no painting occurs.
; dwFrameStyle indicates what parts of the frame are painted. dwFrameStyle can 
; be a combination of the following flags:
; - MUIPFS_NONE
; - MUIPFS_LEFT
; - MUIPFS_TOP
; - MUIPFS_BOTTOM
; - MUIPFS_RIGHT
; - MUIPFS_ALL
;------------------------------------------------------------------------------
MUIGDIPaintFrame PROC FRAME hdc:QWORD, lpFrameRect:QWORD, qwFrameColor:QWORD, qwFrameStyle:QWORD
    LOCAL hBrush:QWORD
    LOCAL hBrushOld:QWORD
    LOCAL hPen:QWORD
    LOCAL hPenOld:QWORD
    LOCAL rect:RECT
    LOCAL pt:POINT

    .IF dword ptr qwFrameColor != -1
        .IF qwFrameStyle != MUIPFS_NONE
            mov rax, qwFrameStyle
            and rax, MUIPFS_ALL
            .IF rax == MUIPFS_ALL 
                ;--------------------------------------------------------------
                ; Paint entire frame
                ;--------------------------------------------------------------
                Invoke GetStockObject, DC_BRUSH
                mov hBrush, rax
                Invoke SelectObject, hdc, rax
                mov hBrushOld, rax
                Invoke SetDCBrushColor, hdc, dword ptr qwFrameColor
                Invoke FrameRect, hdc, lpFrameRect, hBrush
                .IF hBrushOld != 0
                    Invoke SelectObject, hdc, hBrushOld
                    Invoke DeleteObject, hBrushOld
                .ENDIF     
                .IF hBrush != 0
                    Invoke DeleteObject, hBrush
                .ENDIF
            .ELSE
                ;--------------------------------------------------------------
                ; Paint only certain parts of the frame
                ;--------------------------------------------------------------
                Invoke CreatePen, PS_SOLID, 1, dword ptr qwFrameColor
                mov hPen, rax
                Invoke SelectObject, hdc, hPen
                mov hPenOld, rax 
                Invoke CopyRect, Addr rect, lpFrameRect
                mov rax, qwFrameStyle
                and rax, MUIPFS_TOP
                .IF rax == MUIPFS_TOP
                    Invoke MoveToEx, hdc, rect.left, rect.top, Addr pt
                    Invoke LineTo, hdc, rect.right, rect.top
                .ENDIF
                mov rax, qwFrameStyle
                and rax, MUIPFS_RIGHT
                .IF rax == MUIPFS_RIGHT
                    dec rect.right                
                    Invoke MoveToEx, hdc, rect.right, rect.top, Addr pt
                    Invoke LineTo, hdc, rect.right, rect.bottom
                    inc rect.right
                .ENDIF
                mov rax, qwFrameStyle
                and rax, MUIPFS_BOTTOM
                .IF rax == MUIPFS_BOTTOM
                    dec rect.bottom
                    Invoke MoveToEx, hdc, rect.left, rect.bottom, Addr pt
                    Invoke LineTo, hdc, rect.right, rect.bottom
                    inc rect.bottom
                .ENDIF
                mov rax, qwFrameStyle
                and rax, MUIPFS_LEFT
                .IF rax == MUIPFS_LEFT
                    Invoke MoveToEx, hdc, rect.left, rect.top, Addr pt
                    Invoke LineTo, hdc, rect.left, rect.bottom
                .ENDIF
                .IF hPenOld != 0
                    Invoke SelectObject, hdc, hPenOld
                    Invoke DeleteObject, hPenOld
                .ENDIF
                .IF hPen != 0
                    Invoke DeleteObject, hPen
                .ENDIF
            .ENDIF
        .ENDIF
    .ENDIF
    ret
MUIGDIPaintFrame ENDP


MODERNUI_LIBEND

