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

IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib
ENDIF


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGetImageSize
;------------------------------------------------------------------------------
MUIGetImageSize PROC FRAME USES RBX hImage:MUIIMAGE, ImageHandleType:MUIIT, lpImageWidth:LPMUIVALUE, lpImageHeight:LPMUIVALUE
    LOCAL bm:BITMAP
    LOCAL iinfo:ICONINFO
    LOCAL nImageWidth:QWORD
    LOCAL nImageHeight:QWORD
    LOCAL RetVal:QWORD
    
    mov nImageWidth, 0
    mov nImageHeight, 0
    mov RetVal, FALSE
    
    .IF hImage == NULL
        ; fall out and return defaults
    .ELSE

        mov rax, ImageHandleType
        ;-----------------------------------
        ; BITMAP
        ;-----------------------------------
        .IF rax == MUIIT_BMP ; bitmap/icon
            Invoke RtlZeroMemory, Addr bm, SIZEOF BITMAP
            Invoke GetObject, hImage, SIZEOF bm, Addr bm
            .IF rax != 0
                mov eax, bm.bmWidth
                mov nImageWidth, rax
                mov eax, bm.bmHeight
                mov nImageHeight, rax
                mov RetVal, TRUE
            .ENDIF
        ;-----------------------------------


        ;-----------------------------------
        ; ICON
        ;-----------------------------------
        .ELSEIF rax == MUIIT_ICO ; icon    
            Invoke GetIconInfo, hImage, Addr iinfo ; get icon information
            mov rax, iinfo.hbmColor ; bitmap info of icon has width/height
            .IF rax != NULL
                Invoke GetObject, iinfo.hbmColor, SIZEOF bm, Addr bm
                .IF rax != 0
                    mov eax, bm.bmWidth
                    mov nImageWidth, rax
                    mov eax, bm.bmHeight
                    mov nImageHeight, rax
                    mov RetVal, TRUE
                .ENDIF
            .ELSE ; Icon has no color plane, image width/height data stored in mask
                mov rax, iinfo.hbmMask
                .IF rax != NULL
                    Invoke GetObject, iinfo.hbmMask, SIZEOF bm, Addr bm
                    .IF rax != 0
                        mov eax, bm.bmWidth
                        mov nImageWidth, rax
                        mov eax, bm.bmHeight
                        shr rax, 1 ;bmp.bmHeight / 2;
                        mov nImageHeight, rax
                        mov RetVal, TRUE
                    .ENDIF
                .ENDIF
            .ENDIF
            ; free up color and mask icons created by the GetIconInfo function
            mov rax, iinfo.hbmColor
            .IF rax != NULL
                Invoke DeleteObject, rax
            .ENDIF
            mov rax, iinfo.hbmMask
            .IF rax != NULL
                Invoke DeleteObject, rax
            .ENDIF
        ;-----------------------------------


        ;-----------------------------------
        ; PNG
        ;-----------------------------------
        .ELSEIF rax == MUIIT_PNG ; png
            IFDEF MUI_USEGDIPLUS
            Invoke GdipGetImageWidth, hImage, Addr nImageWidth
            Invoke GdipGetImageHeight, hImage, Addr nImageHeight
            mov RetVal, TRUE
            ENDIF
        .ENDIF
        ;-----------------------------------

    .ENDIF


    .IF lpImageWidth != 0
        mov rbx, lpImageWidth
        mov rax, nImageWidth
        mov [rbx], rax
    .ENDIF
    .IF lpImageHeight != 0
        mov rbx, lpImageHeight
        mov rax, nImageHeight
        mov [rbx], rax
    .ENDIF
    mov rax, RetVal
    ret
MUIGetImageSize ENDP


MODERNUI_LIBEND



