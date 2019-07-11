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


; Prototypes for internal use
_MUIGetProperty PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
_MUISetProperty PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE

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
;   Invoke SetWindowLong, hWin, 0, pMem
;
; pMem is our pointer to our 16 bytes of storage, of which first eight bytes 
; (qword) is used for our @MouseOver property and the next qword for 
; @SelectedState 
;
;------------------------------------------------------------------------------
_MUIGetProperty PROC FRAME USES RBX hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
    
    Invoke GetWindowLongPtr, hWin, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF
    mov rbx, rax
    add rbx, Property
    mov rax, [rbx]
    
    ret

_MUIGetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets property value and returns previous value in eax.
;------------------------------------------------------------------------------
_MUISetProperty PROC FRAME USES RBX hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    LOCAL qwPrevValue:QWORD
    Invoke GetWindowLongPtr, hWin, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF    
    mov rbx, rax
    add rbx, Property
    mov rax, [rbx]
    mov qwPrevValue, rax    
    mov rax, PropertyValue
    mov [rbx], rax
    mov rax, qwPrevValue
    ret

_MUISetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets external property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetExtProperty PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetProperty, hWin, 8, Property ; get external properties
    ret
MUIGetExtProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets external property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetExtProperty PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetProperty, hWin, 8, Property, PropertyValue ; set external properties
    ret
MUISetExtProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets internal property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetIntProperty PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetProperty, hWin, 0, Property ; get internal properties
    ret
MUIGetIntProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets internal property value and returns previous value in eax.
;------------------------------------------------------------------------------
MUISetIntProperty PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetProperty, hWin, 0, Property, PropertyValue ; set internal properties
    ret
MUISetIntProperty ENDP


MODERNUI_LIBEND



