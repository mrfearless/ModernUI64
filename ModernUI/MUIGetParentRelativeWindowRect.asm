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

include ModernUI.inc


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Get rectangle of a window/control relative to it's parent
;------------------------------------------------------------------------------
MUIGetParentRelativeWindowRect PROC FRAME hWin:MUIWND, lpRectControl:LPRECT
    LOCAL hParent:QWORD
    
    Invoke GetWindowRect, hWin, lpRectControl
    .IF rax == 0
        mov rax, FALSE
        ret
    .ENDIF
    Invoke GetAncestor, hWin, GA_PARENT
    mov hParent, rax
    Invoke MapWindowPoints, HWND_DESKTOP, hParent, lpRectControl, 2

    mov rax, TRUE
    ret 
MUIGetParentRelativeWindowRect ENDP


MODERNUI_LIBEND

