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

IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib
ENDIF


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGetImageSize
;------------------------------------------------------------------------------
MUIGetImageSize PROC FRAME USES RBX hImage:QWORD, qwImageType:QWORD, lpqwImageWidth:QWORD, lpqwImageHeight:QWORD
    LOCAL bm:BITMAP
    LOCAL iinfo:ICONINFO
    LOCAL nImageWidth:QWORD
    LOCAL nImageHeight:QWORD

    mov rax, qwImageType
    .IF rax == MUIIT_NONE
        mov rax, 0
        mov rbx, lpqwImageWidth
        mov [rbx], rax
        mov rbx, lpqwImageHeight
        mov [rbx], rax    
        mov rax, FALSE
        ret
        
    .ELSEIF rax == MUIIT_BMP ; bitmap/icon
        Invoke GetObject, hImage, SIZEOF bm, Addr bm
        xor rax, rax
        mov eax, bm.bmWidth
        mov rbx, lpqwImageWidth
        mov [rbx], rax
        mov eax, bm.bmHeight
        mov rbx, lpqwImageHeight
        mov [rbx], rax
    
    .ELSEIF rax == MUIIT_ICO ; icon    
        Invoke GetIconInfo, hImage, Addr iinfo ; get icon information
        mov rax, iinfo.hbmColor ; bitmap info of icon has width/height
        .IF rax != NULL
            Invoke GetObject, iinfo.hbmColor, SIZEOF bm, Addr bm
            xor rax, rax
            mov eax, bm.bmWidth
            mov rbx, lpqwImageWidth
            mov [rbx], rax
            mov eax, bm.bmHeight
            mov rbx, lpqwImageHeight
            mov [rbx], rax
        .ELSE ; Icon has no color plane, image width/height data stored in mask
            mov rax, iinfo.hbmMask
            .IF rax != NULL
                Invoke GetObject, iinfo.hbmMask, SIZEOF bm, Addr bm
                xor rax, rax
                mov eax, bm.bmWidth
                mov rbx, lpqwImageWidth
                mov [rbx], rax
                mov eax, bm.bmHeight
                shr rax, 1 ;bmp.bmHeight / 2;
                mov rbx, lpqwImageHeight
                mov [rbx], rax                
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
    
    .ELSEIF rax == MUIIT_PNG ; png
        IFDEF MUI_USEGDIPLUS
        Invoke GdipGetImageWidth, hImage, Addr nImageWidth
        Invoke GdipGetImageHeight, hImage, Addr nImageHeight
        mov rax, nImageWidth
        mov rbx, lpqwImageWidth
        mov [rbx], rax
        mov rax, nImageHeight
        mov rbx, lpqwImageHeight
        mov [rbx], rax
        ENDIF
    .ENDIF
    
    mov rax, TRUE
    ret

MUIGetImageSize ENDP


MODERNUI_LIBEND



