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
; Paints the border of the main window a specified color.
; If BorderColor = -1, no border is drawn.
;------------------------------------------------------------------------------
MUIPaintBorder PROC FRAME hWin:MUIWND, BorderColor:MUICOLORRGB
    LOCAL hdc:HDC
    LOCAL SavedDC:DWORD
    LOCAL rect:RECT

    .IF BorderColor == -1
        ret
    .ENDIF

    Invoke GetWindowDC, hWin
    .IF rax != 0
        mov hdc, rax
        Invoke SaveDC, hdc
        mov SavedDC, eax
        Invoke GetClientRect, hWin, Addr rect
        inc rect.right
        inc rect.bottom
        inc rect.right
        inc rect.bottom
        ;------------------------------------------------------
        ; Paint Border
        ;------------------------------------------------------
        Invoke MUIGDIPaintFrame, hdc, Addr rect, BorderColor, MUIPFS_ALL
    
        Invoke RestoreDC, hdc, SavedDC
        Invoke ReleaseDC, hWin, hdc
    .ENDIF

    ret
MUIPaintBorder ENDP



MODERNUI_LIBEND