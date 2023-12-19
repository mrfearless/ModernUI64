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
; MUILoadIconFromResource - Loads specified icon resource into the specified 
; external property and returns old icon handle (if it previously existed) in 
; eax or NULL. If dwInstanceProperty != 0 fetches stored value to use as 
; hinstance to load icon resource. If dwProperty == -1, no property to set, 
; so eax will contain hIcon or NULL
;------------------------------------------------------------------------------
MUILoadIconFromResource PROC FRAME hWin:MUIWND, InstanceProperty:MUIPROPERTY, Property:MUIPROPERTY, idResIcon:RESID
    LOCAL hinstance:QWORD
    LOCAL hOldIcon:QWORD

    .IF hWin == NULL || idResIcon == NULL
        mov rax, NULL
        ret
    .ENDIF

    .IF InstanceProperty != 0
        Invoke MUIGetExtProperty, hWin, InstanceProperty
        .IF rax == 0
            Invoke GetModuleHandle, NULL
        .ENDIF
    .ELSE
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax
    .IF Property != -1
        Invoke MUIGetExtProperty, hWin, Property
        .IF rax != 0
            mov hOldIcon, rax
        .ELSE
            mov hOldIcon, NULL
        .ENDIF
    .ENDIF
    
    Invoke LoadImage, hinstance, idResIcon, IMAGE_ICON, 0, 0, 0
    .IF Property != -1
        Invoke MUISetExtProperty, hWin, Property, rax
        mov rax, hOldIcon
    .ENDIF
    ret
MUILoadIconFromResource ENDP




MODERNUI_LIBEND

