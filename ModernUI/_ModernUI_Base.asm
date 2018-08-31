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

include ModernUI.inc


; Prototypes for internal use
_MUIGetProperty PROTO :QWORD, :QWORD, :QWORD           ; hControl, cbWndExtraOffset, qwProperty
_MUISetProperty PROTO :QWORD, :QWORD, :QWORD, :QWORD   ; hControl, cbWndExtraOffset, qwProperty, qwPropertyValue

.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets the pointer to memory allocated to control at startup and stored in 
; cbWinExtra adds the offset to property to this pointer and fetches value at 
; this location and returns it in rax.
;
; Properties are defined as constants, which are used as offsets in memory to 
; the data alloc'd, for example: @MouseOver EQU 0, @SelectedState EQU 8
; we might specify 16 in cbWndExtra and then GlobalAlloc 16 bytes of data to 
; control at startup and store this pointer with:
;
;   Invoke SetWindowLong, hControl, 0, pMem
;
; pMem is our pointer to our 16 bytes of storage, of which first eight bytes 
; (qword) is used for our @MouseOver property and the next qword for 
; @SelectedState 
;
;------------------------------------------------------------------------------
_MUIGetProperty PROC FRAME USES RBX hControl:QWORD, cbWndExtraOffset:QWORD, qwProperty:QWORD
    
    Invoke GetWindowLongPtr, hControl, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF
    mov rbx, rax
    add rbx, qwProperty
    mov rax, [rbx]
    
    ret

_MUIGetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets property value and returns previous value in eax.
;------------------------------------------------------------------------------
_MUISetProperty PROC FRAME USES RBX hControl:QWORD, cbWndExtraOffset:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    LOCAL qwPrevValue:QWORD
    Invoke GetWindowLongPtr, hControl, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF    
    mov rbx, rax
    add rbx, qwProperty
    mov rax, [rbx]
    mov qwPrevValue, rax    
    mov rax, qwPropertyValue
    mov [rbx], rax
    mov rax, qwPrevValue
    ret

_MUISetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets external property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetExtProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke _MUIGetProperty, hControl, 8, qwProperty ; get external properties
    ret
MUIGetExtProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets external property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetExtProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke _MUISetProperty, hControl, 8, qwProperty, qwPropertyValue ; set external properties
    ret
MUISetExtProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets internal property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetIntProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke _MUIGetProperty, hControl, 0, qwProperty ; get internal properties
    ret
MUIGetIntProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets internal property value and returns previous value in eax.
;------------------------------------------------------------------------------
MUISetIntProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke _MUISetProperty, hControl, 0, qwProperty, qwPropertyValue ; set internal properties
    ret
MUISetIntProperty ENDP


END



