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


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
;CreateIconFromData
; Creates an icon from icon data stored in the DATA or CONST SECTION
; (The icon data is an ICO file stored directly in the executable)
;
; Parameters
;   pIconData = Pointer to the ico file data
;   iIcon = zero based index of the icon to load
;
; If successful will return an icon handle, this handle must be freed
; using DestroyIcon when it is no longer needed. The size of the icon
; is returned in RDX, the high order word contains the width and the
; low order word the height.
; 
; Returns 0 if there is an error.
; If the index is greater than the number of icons in the file RDX will
; be set to the number of icons available otherwise RDX is 0. To find
; the number of available icons set the index to -1
;
;http://www.masmforum.com/board/index.php?topic=16267.msg134434#msg134434
;------------------------------------------------------------------------------
MUICreateIconFromMemory PROC FRAME USES RDX pIconData:QWORD, iIcon:QWORD
    LOCAL sz[2]:DWORD
    LOCAL pbIconBits:QWORD
    LOCAL cbIconBits:DWORD
    LOCAL cxDesired:DWORD
    LOCAL cyDesired:DWORD

    xor rax, rax
    mov rdx, [pIconData]
    or rdx, rdx
    jz ERRORCATCH

    movzx rax, WORD PTR [rdx+4]
    cmp rax, [iIcon]
    ja @F
        ERRORCATCH:
        push rax
        invoke SetLastError, ERROR_RESOURCE_NAME_NOT_FOUND
        pop rdx
        xor rax, rax
        ret
    @@:

    mov rax, [iIcon]
    shl rax, 4
    add rdx, rax
    add rdx, 6

    movzx eax, BYTE PTR [rdx]
    mov [sz], eax
    mov cxDesired, eax
    movzx eax, BYTE PTR [rdx+1]
    mov [sz+4], eax
    mov cyDesired, eax

    mov rdx, [pIconData]
    mov rax, [iIcon]
    shl rax, 4
    add rdx, rax
    add rdx, 6
    xor eax, eax
    mov eax, dword ptr [rdx+8]
    mov cbIconBits, eax
    
    mov rdx, [pIconData]
    mov rax, [iIcon]
    shl rax, 4
    add rdx, rax
    add rdx, 6
    xor eax, eax
    mov eax, dword ptr [rdx+12]
    add rax, [pIconData]
    mov pbIconBits, rax

    Invoke CreateIconFromResourceEx, pbIconBits, cbIconBits, 1, 030000h, cxDesired, cyDesired, 0
    
    xor rdx, rdx
    mov edx,[sz]
    shl edx,16
    mov dx, word ptr [sz+4]

    ret
MUICreateIconFromMemory ENDP


MODERNUI_LIBEND



