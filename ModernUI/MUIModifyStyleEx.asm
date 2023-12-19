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

include ModernUI.inc


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Modifies the extended window styles of a Window to add and/or remove styles
; if bFrameChanged is TRUE then forces SWP_FRAMECHANGED call via SetWindowPos
;------------------------------------------------------------------------------
MUIModifyStyleExA PROC FRAME USES RBX hWin:MUIWND, dwRemove:MUIVALUE, dwAdd:MUIVALUE, bFrameChanged:BOOL
    Invoke GetWindowLongPtrA, hWin, GWL_EXSTYLE
    ; rax has current extended style
    
    ; Add dwAdd styles to current extended style with OR
    mov rbx, dwAdd
    or rax, rbx
    
    ; Remove dwRemove styles from current extended style with NOT (to invert dwRemove) and then AND together
    mov rbx, dwRemove
    not rbx
    and rax, rbx
    ; rax has new style
    
    Invoke SetWindowLongPtrA, hWin, GWL_EXSTYLE, rax
    
    .IF bFrameChanged == FALSE
        ;Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
    .ELSE
        ; Applies new extended styles set using the SetWindowLong function
        Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED
    .ENDIF

    xor rax, rax
    ret
MUIModifyStyleExA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Modifies the extended window styles of a Window to add and/or remove styles
; if bFrameChanged is TRUE then forces SWP_FRAMECHANGED call via SetWindowPos
;------------------------------------------------------------------------------
MUIModifyStyleExW PROC FRAME USES RBX hWin:MUIWND, dwRemove:MUIVALUE, dwAdd:MUIVALUE, bFrameChanged:BOOL
    Invoke GetWindowLongPtrW, hWin, GWL_EXSTYLE
    ; rax has current extended style
    
    ; Add dwAdd styles to current extended style with OR
    mov rbx, dwAdd
    or rax, rbx
    
    ; Remove dwRemove styles from current extended style with NOT (to invert dwRemove) and then AND together
    mov rbx, dwRemove
    not rbx
    and rax, rbx
    ; rax has new style
    
    Invoke SetWindowLongPtrW, hWin, GWL_EXSTYLE, rax
    
    .IF bFrameChanged == FALSE
        ;Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
    .ELSE
        ; Applies new extended styles set using the SetWindowLong function
        Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED
    .ENDIF

    xor rax, rax
    ret
MUIModifyStyleExW ENDP


MODERNUI_LIBEND



