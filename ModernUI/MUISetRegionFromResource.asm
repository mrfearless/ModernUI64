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
includelib kernel32.lib
includelib gdi32.lib

include ModernUI.inc

EXTERNDEF MUILoadRegionFromResource :PROTO :QWORD,:QWORD,:QWORD,:QWORD

.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets a window/controls region from a region stored as an RC_DATA resource: 
; idRgnRes if lpdwCopyRgn != NULL a copy of region handle is provided (for any
; future calls to FrameRgn for example)
;------------------------------------------------------------------------------
MUISetRegionFromResource PROC FRAME USES RBX hWin:QWORD, idRgnRes:QWORD, lpqwCopyRgn:QWORD, bRedraw:QWORD
    LOCAL hinstance:QWORD
    LOCAL ptrRegionData:QWORD
    LOCAL qwRegionDataSize:QWORD
    LOCAL hRgn:QWORD
    
    .IF idRgnRes == NULL
        Invoke SetWindowRgn, hWin, NULL, FALSE
        ret
    .ENDIF
 
    Invoke GetModuleHandle, NULL
    mov hinstance, rax
    
    Invoke MUILoadRegionFromResource, hinstance, idRgnRes, Addr ptrRegionData, Addr qwRegionDataSize
    .IF rax == FALSE
        .IF lpqwCopyRgn != NULL
            mov rax, NULL
            mov rbx, lpqwCopyRgn
            mov [rbx], rax
        .ENDIF
        mov rax, FALSE    
        ret
    .ENDIF
    
    Invoke SetWindowRgn, hWin, NULL, FALSE
    Invoke ExtCreateRegion, NULL, dword ptr qwRegionDataSize, ptrRegionData
    mov hRgn, rax
    .IF rax == NULL
        .IF lpqwCopyRgn != NULL
            mov rax, NULL
            mov rbx, lpqwCopyRgn
            mov [rbx], rax
        .ENDIF
        mov rax, FALSE
        ret
    .ENDIF
    Invoke SetWindowRgn, hWin, hRgn, dword ptr bRedraw
    
    .IF lpqwCopyRgn != NULL
        Invoke ExtCreateRegion, NULL, dword ptr qwRegionDataSize, ptrRegionData
        mov hRgn, rax
        mov rbx, lpqwCopyRgn
        mov [ebx], rax
    .ENDIF

    mov rax, TRUE    
    ret

MUISetRegionFromResource ENDP

MODERNUI_LIBEND



