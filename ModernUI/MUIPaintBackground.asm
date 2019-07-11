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
; Paint the background of the main window specified color
; optional provide dwBorderColor for border. If dwBorderColor = 0, no border is
; drawn. If you require black for border, use 1, or MUI_RGBCOLOR(1,1,1)
;
; If you are using this on a window/dialog that does not use the 
; ModernUI_CaptionBar control AND window/dialog is resizable, you should place 
; a call to InvalidateRect in the WM_NCCALCSIZE handler to prevent ugly drawing 
; artifacts when border is drawn whilst resize of window/dialog occurs. 
; The ModernUI_CaptionBar handles this call to WM_NCCALCSIZE already by default
;
; Here is an example of what to include if you need:
;
;    .ELSEIF eax == WM_NCCALCSIZE
;        Invoke InvalidateRect, hWin, NULL, TRUE
; 
;------------------------------------------------------------------------------
MUIPaintBackground PROC FRAME hWin:MUIWND, BackColor:MUICOLORRGB, BorderColor:MUICOLORRGB
    LOCAL ps:PAINTSTRUCT
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hBufferBitmap:HBITMAP

    Invoke BeginPaint, hWin, addr ps
    mov hdc, rax

    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke MUIGDIDoubleBufferStart, hWin, hdc, Addr hdcMem, Addr rect, Addr hBufferBitmap

    ;----------------------------------------------------------
    ; Paint background
    ;----------------------------------------------------------
    Invoke MUIGDIPaintFill, hdcMem, Addr rect, BackColor

    ;----------------------------------------------------------
    ; Paint Border
    ;----------------------------------------------------------
    .IF BorderColor != 0
        Invoke MUIGDIPaintFrame, hdcMem, Addr rect, BorderColor, MUIPFS_ALL
    .ENDIF
    
    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Finish Double Buffering & Cleanup
    ;----------------------------------------------------------    
    Invoke MUIGDIDoubleBufferFinish, hdcMem, hBufferBitmap, 0, 0, 0, 0    
    
    Invoke EndPaint, hWin, addr ps
    mov rax, 0
    ret

MUIPaintBackground ENDP


MODERNUI_LIBEND



