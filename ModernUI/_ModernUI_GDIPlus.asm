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
includelib gdi32.lib

include ModernUI.inc


IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib


.DATA
;------------------------------------------------------------------------------
; Controls that use gdiplus check the MUI_GDIPLUS variable first. If it is 0 
; they call MUIGDIPlusStart and increment the MUI_GDIPLUS value. 
; When the control is destroyed, they decrement the MUI_GDIPLUS value and check
; if it is 0. If it is 0 they call MUIGDIPlusFinish to finish up.
;------------------------------------------------------------------------------
MUI_GDIPLUS          DQ 0 
MUI_GDIPlusToken     DQ 0
MUI_gdipsi           GdiplusStartupInput <1,0,0,0>


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Start of ModernUI framework (wrapper for gdiplus startup)
; Placed at start of program before WinMain call
;------------------------------------------------------------------------------
MUIGDIPlusStart PROC FRAME
    .IF MUI_GDIPLUS == 0
        ;PrintText 'GdiplusStartup'
        Invoke GdiplusStartup, Addr MUI_GDIPlusToken, Addr MUI_gdipsi, NULL
    .ENDIF
    inc MUI_GDIPLUS
    ;PrintDec MUI_GDIPLUS
    xor rax, rax
    ret
MUIGDIPlusStart ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Finish ModernUI framework (wrapper for gdiplus shutdown)
; Placed after WinMain call before ExitProcess
;------------------------------------------------------------------------------
MUIGDIPlusFinish PROC FRAME
    ;PrintDec MUI_GDIPLUS
    dec MUI_GDIPLUS
    .IF MUI_GDIPLUS == 0
        ;PrintText 'GdiplusShutdown'
        Invoke GdiplusShutdown, MUI_GDIPlusToken
    .ENDIF
    xor rax, rax
    ret
MUIGDIPlusFinish ENDP


ENDIF


MODERNUI_LIBEND


