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


IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib

IFNDEF FP4
    FP4 MACRO value
    LOCAL vname
    .data
    align 4
      vname REAL4 value
    .code
    EXITM <vname>
    ENDM
ENDIF


IFNDEF GDIPRECT
GDIPRECT     STRUCT
    left     REAL4 ?
    top	     REAL4 ?
    right	 REAL4 ?
    bottom	 REAL4 ?
GDIPRECT     ENDS
ENDIF


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIPlusPaintFrame - Draws a border (or parts of) around a rectangle with a 
; specific color.
; 
; lpFrameRect is a pointer to a RECT containing the bounding box of the frame
; dwFrameColor is an ARGBCOLOR to paint the frame edges. If dwFrameColor is -1 
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
MUIGDIPlusPaintFrame PROC FRAME pGraphics:GPGRAPHICS, lpFrameGdipRect:LPGPRECT, FrameColor:MUICOLORARGB, FrameStyle:MUIPFS
    LOCAL pPen:QWORD
    
    .IF FrameColor != -1
        .IF FrameStyle != MUIPFS_NONE
            mov rax, FrameStyle
            and rax, MUIPFS_ALL
            .IF rax == MUIPFS_ALL
                ;--------------------------------------------------------------
                ; Paint entire frame
                ;--------------------------------------------------------------
                Invoke GdipCreatePen1, dword ptr FrameColor, FP4(1.0), UnitPixel, Addr pPen
                Invoke GdipDrawRectangleI, pGraphics, pPen, [lpFrameGdipRect].GDIPRECT.left, [lpFrameGdipRect].GDIPRECT.top, [lpFrameGdipRect].GDIPRECT.right, [lpFrameGdipRect].GDIPRECT.bottom
                Invoke GdipDeletePen, pPen
            .ELSE
                ;--------------------------------------------------------------
                ; Paint only certain parts of the frame
                ;--------------------------------------------------------------
                Invoke GdipCreatePen1, dword ptr FrameColor, FP4(1.0), UnitPixel, Addr pPen
                
                mov rax, FrameStyle
                and rax, MUIPFS_TOP
                .IF rax == MUIPFS_TOP
                    Invoke GdipDrawLine, pGraphics, pPen, [lpFrameGdipRect].GDIPRECT.left, [lpFrameGdipRect].GDIPRECT.top, [lpFrameGdipRect].GDIPRECT.right, [lpFrameGdipRect].GDIPRECT.top
                .ENDIF
                mov rax, FrameStyle
                and rax, MUIPFS_RIGHT
                .IF rax == MUIPFS_RIGHT
                    Invoke GdipDrawLine, pGraphics, pPen, [lpFrameGdipRect].GDIPRECT.right, [lpFrameGdipRect].GDIPRECT.top, [lpFrameGdipRect].GDIPRECT.right, [lpFrameGdipRect].GDIPRECT.bottom
                .ENDIF
                mov rax, FrameStyle
                and rax, MUIPFS_BOTTOM
                .IF rax == MUIPFS_BOTTOM
                    Invoke GdipDrawLine, pGraphics, pPen, [lpFrameGdipRect].GDIPRECT.left, [lpFrameGdipRect].GDIPRECT.bottom, [lpFrameGdipRect].GDIPRECT.right, [lpFrameGdipRect].GDIPRECT.bottom
                .ENDIF
                mov rax, FrameStyle
                and rax, MUIPFS_LEFT
                .IF rax == MUIPFS_LEFT
                    Invoke GdipDrawLine, pGraphics, pPen, [lpFrameGdipRect].GDIPRECT.left, [lpFrameGdipRect].GDIPRECT.top, [lpFrameGdipRect].GDIPRECT.left, [lpFrameGdipRect].GDIPRECT.bottom
                .ENDIF
                Invoke GdipDeletePen, pPen
            .ENDIF
        .ENDIF
    .ENDIF
    ret
MUIGDIPlusPaintFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIPlusPaintFrameI - Draws a border (or parts of) around a rectangle with a 
; specific color.
; 
; lpFrameRect is a pointer to a RECT containing the bounding box of the frame
; dwFrameColor is an ARGBCOLOR to paint the frame edges. If dwFrameColor is -1 
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
MUIGDIPlusPaintFrameI PROC FRAME pGraphics:GPGRAPHICS, lpFrameRectI:LPRECT, FrameColor:MUICOLORARGB, FrameStyle:MUIPFS
    LOCAL pPen:QWORD
    
    .IF FrameColor != -1
        .IF FrameStyle != MUIPFS_NONE
            mov rax, FrameStyle
            and rax, MUIPFS_ALL
            .IF rax == MUIPFS_ALL
                ;--------------------------------------------------------------
                ; Paint entire frame
                ;--------------------------------------------------------------
                Invoke GdipCreatePen1, dword ptr FrameColor, FP4(1.0), UnitPixel, Addr pPen
                Invoke GdipDrawRectangleI, pGraphics, pPen, [lpFrameRectI].RECT.left, [lpFrameRectI].RECT.top, [lpFrameRectI].RECT.right, [lpFrameRectI].RECT.bottom
                Invoke GdipDeletePen, pPen
            .ELSE
                ;--------------------------------------------------------------
                ; Paint only certain parts of the frame
                ;--------------------------------------------------------------
                Invoke GdipCreatePen1, dword ptr FrameColor, FP4(1.0), UnitPixel, Addr pPen
                
                mov rax, FrameStyle
                and rax, MUIPFS_TOP
                .IF rax == MUIPFS_TOP
                    Invoke GdipDrawLineI, pGraphics, pPen, [lpFrameRectI].RECT.left, [lpFrameRectI].RECT.top, [lpFrameRectI].RECT.right, [lpFrameRectI].RECT.top
                .ENDIF
                mov rax, FrameStyle
                and rax, MUIPFS_RIGHT
                .IF rax == MUIPFS_RIGHT
                    Invoke GdipDrawLineI, pGraphics, pPen, [lpFrameRectI].RECT.right, [lpFrameRectI].RECT.top, [lpFrameRectI].RECT.right, [lpFrameRectI].RECT.bottom
                .ENDIF
                mov rax, FrameStyle
                and rax, MUIPFS_BOTTOM
                .IF rax == MUIPFS_BOTTOM
                    Invoke GdipDrawLineI, pGraphics, pPen, [lpFrameRectI].RECT.left, [lpFrameRectI].RECT.bottom, [lpFrameRectI].RECT.right, [lpFrameRectI].RECT.bottom
                .ENDIF
                mov rax, FrameStyle
                and rax, MUIPFS_LEFT
                .IF rax == MUIPFS_LEFT
                    Invoke GdipDrawLineI, pGraphics, pPen, [lpFrameRectI].RECT.left, [lpFrameRectI].RECT.top, [lpFrameRectI].RECT.left, [lpFrameRectI].RECT.bottom
                .ENDIF
                Invoke GdipDeletePen, pPen
            .ENDIF
        .ENDIF
    .ENDIF
    ret
MUIGDIPlusPaintFrameI ENDP


ENDIF


MODERNUI_LIBEND

