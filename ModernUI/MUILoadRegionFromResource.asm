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

include ModernUI.inc


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUILoadRegionFromResource - Loads region from a resource
;------------------------------------------------------------------------------
MUILoadRegionFromResource PROC FRAME USES RBX hInst:QWORD, idRgnRes:QWORD, lpRegion:QWORD, lpqwSizeRegion:QWORD
    LOCAL hRes:QWORD
    ; Load region
    Invoke FindResource, hInst, idRgnRes, RT_RCDATA ; load rng image as raw data
    .IF eax != NULL
        mov hRes, rax
        Invoke SizeofResource, hInst, hRes
        .IF rax != 0
            .IF lpqwSizeRegion != NULL
                mov rbx, lpqwSizeRegion
                mov [rbx], rax
            .ELSE
                mov rax, FALSE
                ret
            .ENDIF
            Invoke LoadResource, hInst, hRes
            .IF rax != NULL
                Invoke LockResource, rax
                .IF rax != NULL
                    .IF lpRegion != NULL
                        mov rbx, lpRegion
                        mov [rbx], rax
                        mov rax, TRUE
                    .ELSE
                        mov rax, FALSE
                    .ENDIF
                .ELSE
                    ;PrintText 'Failed to lock resource'
                    mov rax, FALSE
                .ENDIF
            .ELSE
                ;PrintText 'Failed to load resource'
                mov rax, FALSE
            .ENDIF
        .ELSE
            ;PrintText 'Failed to get resource size'
            mov rax, FALSE
        .ENDIF
    .ELSE
        ;PrintText 'Failed to find resource'
        mov rax, FALSE
    .ENDIF    
    ret
MUILoadRegionFromResource ENDP


MODERNUI_LIBEND



