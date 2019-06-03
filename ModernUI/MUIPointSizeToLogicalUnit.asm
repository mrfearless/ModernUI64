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
; Convert font point size eg '12' to logical unit size for use with CreateFont,
; CreateFontIndirect
;------------------------------------------------------------------------------
MUIPointSizeToLogicalUnit PROC FRAME USES RBX RCX RDX hWin:QWORD, qwPointSize:QWORD
    LOCAL hdc:HDC
    LOCAL dwLogicalUnit:DWORD
    
    Invoke GetDC, hWin
    mov hdc, rax
    Invoke GetDeviceCaps, hdc, LOGPIXELSY
    xor rdx, rdx
    xor rcx, rcx
    mov ebx, dword ptr qwPointSize
    mul ebx
    mov ecx, 72d
    div ecx
    neg eax
    ;Invoke MulDiv, dqPointSize, rax, 72d
    mov dwLogicalUnit, eax
    Invoke ReleaseDC, hWin, hdc
    mov eax, dwLogicalUnit
    ret
MUIPointSizeToLogicalUnit ENDP


MODERNUI_LIBEND



