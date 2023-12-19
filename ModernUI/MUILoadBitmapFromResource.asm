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
; MUILoadBitmapFromResource - Loads specified bitmap resource into the specified 
; external property and returns old bitmap handle (if it previously existed) in 
; eax or NULL. If dwInstanceProperty != -1 fetches stored value to use as 
; hinstance to load bitmap resource. If dwProperty == -1, no property to set, 
; so eax will contain hBitmap or NULL
;
; To load a bitmap resource and simply return its handle, use -1 in property.
;
;------------------------------------------------------------------------------
MUILoadBitmapFromResource PROC FRAME hWin:MUIWND, InstanceProperty:MUIPROPERTY, Property:MUIPROPERTY, idResBitmap:RESID
    LOCAL hinstance:QWORD
    LOCAL hOldBitmap:QWORD

    .IF (hWin == NULL && InstanceProperty != -1) || idResBitmap == NULL
        mov rax, NULL
        ret
    .ENDIF

    .IF InstanceProperty != -1
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
            mov hOldBitmap, rax
        .ELSE
            mov hOldBitmap, NULL
        .ENDIF
    .ENDIF

    Invoke LoadBitmap, hinstance, idResBitmap
    .IF Property != -1
        Invoke MUISetExtProperty, hWin, Property, rax
        mov rax, hOldBitmap
    .ENDIF
    ret
MUILoadBitmapFromResource ENDP


MODERNUI_LIBEND

