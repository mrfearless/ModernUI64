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
includelib gdi32.lib

include ModernUI.inc

IFNDEF GDIPRECT
GDIPRECT     STRUCT
    left     REAL4 ?
    top	     REAL4 ?
    right	 REAL4 ?
    bottom	 REAL4 ?
GDIPRECT     ENDS
ENDIF


.CODE


MUI_ALIGN
;-------------------------------------------------------------------------------------
; Convert normal RECT structure to GDIPRECT structure.
; Pass Addr of RECT struct (to convert from) & Addr of GDIPRECT Struct to convert to
;-------------------------------------------------------------------------------------
MUIGDIPlusRectToGdipRect PROC FRAME USES RBX RDX lpRect:QWORD, lpGdipRect:QWORD
    mov rbx, lpRect
    mov rdx, lpGdipRect
    finit
    fild [rbx].RECT.left
    lea	rax, [rdx].GDIPRECT.left
    fstp real4 ptr [rax]
    fild [rbx].RECT.top
    lea	rax, [rdx].GDIPRECT.top
    fstp real4 ptr [rax]
    fild [rbx].RECT.right
    lea	rax, [rdx].GDIPRECT.right
    fstp real4 ptr [rax]
    fild [rbx].RECT.bottom
    lea	rax, [rdx].GDIPRECT.bottom
    fstp real4 ptr [rax]
    ret
MUIGDIPlusRectToGdipRect ENDP


MODERNUI_LIBEND

