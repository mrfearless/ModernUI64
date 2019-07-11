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


IFNDEF CURSORDIR
CURSORDIR           STRUCT 8
    idReserved      WORD ?
    idType          WORD ?
    idCount         WORD ?
CURSORDIR           ENDS
ENDIF

IFNDEF CURSORDIRENTRY
CURSORDIRENTRY      STRUCT 8
    bWidth          BYTE ?  
    bHeight         BYTE ?  
    bColorCount     BYTE ? 
    bReserved       BYTE ? 
    XHotspot        WORD ?
    YHotspot        WORD ?
    dwBytesInRes    DWORD ?
    pImageData      DWORD ?
CURSORDIRENTRY      ENDS
ENDIF


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
;MUICreateCursorFromMemory
; Creates a cursor from icon/cursor data stored in the DATA or CONST SECTION
; (The cursor data is an CUR file stored directly in the executable)
;
; Parameters
;   pCursorData = Pointer to the cursor file data
;
;------------------------------------------------------------------------------
MUICreateCursorFromMemory PROC FRAME USES RBX pCursorData:POINTER
    LOCAL hinstance:QWORD
    LOCAL pCursorDirEntry:QWORD
    LOCAL pInfoHeader:QWORD
    LOCAL bWidth:QWORD
    LOCAL bHeight:QWORD
    LOCAL bColorCount:QWORD
    LOCAL XHotspot:QWORD
    LOCAL YHotspot:QWORD
    LOCAL pImageData:QWORD
    LOCAL RGBQuadSize:QWORD
    LOCAL pXORData:QWORD
    LOCAL pANDData:QWORD
    LOCAL biHeight:QWORD
    LOCAL biWidth:QWORD
    LOCAL biBitCount:QWORD
    LOCAL qwSizeImageXOR:QWORD
    LOCAL qwSizeImageAND:QWORD
    
    mov rbx, pCursorData
    movzx rax, word ptr [rbx].CURSORDIR.idCount
    .IF rax == 0 || rax > 1
        mov rax, 0
        ret
    .ENDIF

    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    mov rbx, pCursorData
    add rbx, SIZEOF CURSORDIR
    mov pCursorDirEntry, rbx
    
    movzx rax, byte ptr [rbx].CURSORDIRENTRY.bWidth
    mov bWidth, rax
    movzx rax, byte ptr [rbx].CURSORDIRENTRY.bHeight
    mov bHeight, rax
    movzx rax, byte ptr [rbx].CURSORDIRENTRY.bColorCount
    mov bColorCount, rax
    movzx rax, word ptr [rbx].CURSORDIRENTRY.XHotspot
    mov XHotspot, rax
    movzx rax, word ptr [rbx].CURSORDIRENTRY.YHotspot
    mov YHotspot, rax
    xor rax, rax
    mov eax, DWORD ptr [rbx].CURSORDIRENTRY.pImageData
    mov pImageData, rax
    
    mov rax, SIZEOF DWORD
    mov rbx, bColorCount
    mul rbx
    mov RGBQuadSize, rax
    
    mov rbx, pCursorData
    add rbx, pImageData
    mov pInfoHeader, rbx
    
    xor rax, rax
    mov eax, sdword ptr [rbx].BITMAPINFOHEADER.biWidth
    mov biWidth, rax
    xor rax, rax
    mov eax, sdword ptr [rbx].BITMAPINFOHEADER.biHeight
    mov biHeight, rax
    movzx rax, word ptr [rbx].BITMAPINFOHEADER.biBitCount
    mov biBitCount, rax
    
    .IF rax == 1 ; BI_MONOCHROME
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        shr rax, 3 ; div by 8
        mov qwSizeImageXOR, rax
        mov qwSizeImageAND, rax

    .ELSEIF rax == 4 ; BI_4_BIT
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        shr rax, 1 ; div by 2
        mov qwSizeImageXOR, rax
        
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        shr rax, 3 ; div by 8
        mov qwSizeImageAND, rax

    .ELSEIF rax == 8 ; BI_8_BIT
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        mov qwSizeImageXOR, rax
        
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        shr rax, 3 ; div by 8
        mov qwSizeImageAND, rax

    .ELSEIF rax == 0
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        mov rbx, 4
        mul rbx
        mov qwSizeImageXOR, rax

        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        shr rax, 3 ; div by 8
        mov qwSizeImageAND, rax

    .ELSE ; default
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        mov rbx, biBitCount
        shr rbx, 3 ; div by 8
        mul rbx
        mov qwSizeImageXOR, rax
        
        mov rax, biWidth
        mov rbx, biHeight
        shr rbx, 1 ; div by 2
        mul rbx
        shr rax, 3 ; div by 8
        mov qwSizeImageAND, rax

    .ENDIF

    mov rbx, pCursorData
    add rbx, pImageData
    add rbx, SIZEOF BITMAPINFOHEADER
    .IF biBitCount == 1 || biBitCount == 4 || biBitCount == 8
        add rbx, RGBQuadSize
    .ENDIF
    mov pXORData, rbx
    add rbx, qwSizeImageXOR
    mov pANDData, rbx

    Invoke CreateCursor, hinstance, dword ptr XHotspot, dword ptr YHotspot, dword ptr bWidth, dword ptr bHeight, pANDData, pXORData

    ret
MUICreateCursorFromMemory ENDP

MODERNUI_LIBEND



