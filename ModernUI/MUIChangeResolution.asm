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

.DATA
dmScreenSettings    DEVMODE <>


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Change resolution
;------------------------------------------------------------------------------
MUIChangeScreenResolution PROC FRAME ScreenWidth:MUIVALUE, ScreenHeight:MUIVALUE, bitsPerPixel:MUIVALUE

    Invoke RtlZeroMemory, Addr dmScreenSettings, SIZEOF DEVMODE
    mov dmScreenSettings.dmSize, SIZEOF DEVMODE
    mov rax, ScreenWidth
    mov dmScreenSettings.dmPelsWidth, eax
    mov rax, ScreenHeight
    mov dmScreenSettings.dmPelsHeight, eax
    mov rax, bitsPerPixel
    .IF rax == 0
        mov eax, 32d
    .ENDIF
    mov dmScreenSettings.dmBitsPerPel, eax
    
    ;mov eax, (DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT)  ;; (040000h or 080000h or 0100000h)
    
    mov dmScreenSettings.dmFields, DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT or DM_DISPLAYFREQUENCY
    mov dmScreenSettings.dmDisplayFrequency, 60
    Invoke ChangeDisplaySettings, Addr dmScreenSettings, CDS_FULLSCREEN
    .IF (rax != DISP_CHANGE_SUCCESSFUL)
        mov rax, FALSE
    .ELSE
        mov rax, TRUE
    .ENDIF
    ret
MUIChangeScreenResolution ENDP





MODERNUI_LIBEND



