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
; MUILoadImageFromResource
;------------------------------------------------------------------------------
MUILoadImageFromResource PROC FRAME hWin:MUIWND, InstanceProperty:MUIPROPERTY, Property:MUIPROPERTY, ImageHandleType:MUIIT, idResImage:RESID
    mov rax, ImageHandleType
    .IF rax == MUIIT_NONE
        mov rax, NULL
    .ELSEIF rax == MUIIT_BMP ; bitmap/icon
        Invoke MUILoadBitmapFromResource, hWin, InstanceProperty, Property, idResImage
    .ELSEIF rax == MUIIT_ICO ; icon  
        Invoke MUILoadIconFromResource, hWin, InstanceProperty, Property, idResImage
    IFDEF MUI_USEGDIPLUS
    ;.ELSEIF rax == MUIIT_PNG ; png
        ;Invoke MUILoadPngFromResource, hWin, InstanceProperty, Property, idResImage
    .ELSEIF rax > MUIIT_PNG
        mov rax, NULL
    ELSE
    .ELSEIF eax > MUIIT_BMP
        mov rax, NULL
    ENDIF
    .ENDIF
    ret
MUILoadImageFromResource ENDP



MODERNUI_LIBEND

