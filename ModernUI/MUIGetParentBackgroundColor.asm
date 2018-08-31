;==============================================================================
;
; ModernUI Library x64 v0.0.0.5
;
; Copyright (c) 2018 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
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
; Gets parent background color
; returns in eax, MUI_RGBCOLOR or -1 if NULL brush is set
; Useful for certain controls to retrieve the parents background color and then
; to set their own background color based on the same value.
;------------------------------------------------------------------------------
MUIGetParentBackgroundColor PROC FRAME hControl:QWORD
    LOCAL hParent:QWORD
    LOCAL hBrush:QWORD
    LOCAL logbrush:LOGBRUSH
    
    Invoke GetParent, hControl
    mov hParent, rax
    
    Invoke GetClassLongPtr, hParent, GCL_HBRBACKGROUND
    .IF rax == NULL
        mov eax, -1
        ret
    .ENDIF

    .IF rax > 32d
        mov hBrush, rax
        Invoke GetObject, hBrush, SIZEOF LOGBRUSH, Addr logbrush
        .IF rax == 0
            mov eax, -1
            ret
        .ENDIF
        mov eax, logbrush.lbColor
    .ELSE
        dec eax ; to adjust for initial value being COLOR_X+1
        Invoke GetSysColor, eax
        ret
    .ENDIF
    
    ret
MUIGetParentBackgroundColor ENDP


END



