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

.DATA
szMUIGDIStretchBitmapDisplayDC DB 'DISPLAY',0

.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIStretchBitmap - Returns new stretch bitmap in rax. Bitmap is scaled to
; fit rectangle specified by lpBoundsRect. On return the new bitmap height and 
; width are returned in lpqwBitmapWidth and lpqwBitmapHeight. Additionaly the
; x and y positioning to center the new bitmap in the rectangle specified by
; lpBoundsRect are returned in lpqwX and lpqwY.
;------------------------------------------------------------------------------
MUIGDIStretchBitmap PROC FRAME USES RBX hBitmap:HBITMAP, lpBoundsRect:LPRECT, lpBitmapWidth:LPMUIVALUE, lpBitmapHeight:LPMUIVALUE, lpBitmapX:LPMUIVALUE, lpBitmapY:LPMUIVALUE
    LOCAL qwBitmapWidth:QWORD
    LOCAL qwBitmapHeight:QWORD
    LOCAL qwNewBitmapWidth:QWORD
    LOCAL qwNewBitmapHeight:QWORD
    LOCAL qwWidth:QWORD
    LOCAL qwHeight:QWORD
    LOCAL qwWidthRatio:QWORD
    LOCAL qwHeightRatio:QWORD    
    LOCAL X:QWORD
    LOCAL Y:QWORD
    LOCAL BoundsRect:RECT
    LOCAL hdc:HDC
    LOCAL hdcBitmap:HDC
    LOCAL hStretchedBitmap:QWORD
    LOCAL hStretchedBitmapOld:QWORD
    LOCAL hBitmapOld:QWORD
    
    .IF hBitmap == 0 || lpBoundsRect == 0
        .IF lpBitmapWidth != 0
            mov rbx, lpBitmapWidth
            mov rax, 0
            mov [rbx], rax
        .ENDIF
        .IF lpBitmapHeight != 0
            mov rbx, lpBitmapHeight
            mov rax, 0
            mov [rbx], rax
        .ENDIF
        .IF lpBitmapX != 0
            mov rbx, lpBitmapX
            mov rax, 0
            mov [rbx], rax    
        .ENDIF
        .IF lpBitmapY != 0
            mov rbx, lpBitmapY
            mov rax, 0
            mov [rbx], rax
        .ENDIF    
        mov rax, 0
        ret
    .ENDIF
    
    Invoke CopyRect, Addr BoundsRect, lpBoundsRect
    Invoke MUIGetImageSize, hBitmap, MUIIT_BMP, Addr qwBitmapWidth, Addr qwBitmapHeight

    mov eax, BoundsRect.right
    sub eax, BoundsRect.left
    mov qwWidth, rax
    mov eax, BoundsRect.bottom
    sub eax, BoundsRect.top
    mov qwHeight, rax
    
    finit
    fild qwBitmapWidth
    fild qwWidth
    fdiv
    fistp qwWidthRatio
    
    fild qwBitmapHeight
    fild qwHeight
    fdiv
    fistp qwHeightRatio

    mov rax, qwWidthRatio
    .IF rax >= qwHeightRatio ; Width constrained
        mov rax, qwWidth
        mov qwNewBitmapWidth, rax

        fild qwNewBitmapWidth
        fild qwBitmapWidth
        fdiv
        fld st
        fild qwBitmapHeight
        fmul
        fistp qwNewBitmapHeight
        
    .ELSE ; Height constrained
        mov rax, qwHeight
        mov qwNewBitmapHeight, rax    

        fild qwNewBitmapHeight
        fild qwBitmapHeight
        fdiv
        fld st
        fild qwBitmapWidth
        fmul
        fistp qwNewBitmapWidth  
          
    .ENDIF
    
    ; calc centering position
    mov rax, qwWidth
    sub rax, qwNewBitmapWidth
    shr rax, 1 ; div by 2
    mov X, rax
    
    mov rax, qwHeight
    sub rax, qwNewBitmapHeight
    shr rax, 1 ; div by 2
    mov Y, rax    
    
    Invoke CreateDC, Addr szMUIGDIStretchBitmapDisplayDC, NULL, NULL, NULL
    mov hdc, rax
    
    Invoke CreateCompatibleBitmap, hdc, dword ptr qwNewBitmapWidth, dword ptr qwNewBitmapHeight
    mov hStretchedBitmap, rax
    Invoke SelectObject, hdc, hStretchedBitmap
    mov hStretchedBitmapOld, rax    

    Invoke CreateCompatibleDC, hdc
    mov hdcBitmap, rax
    Invoke SelectObject, hdcBitmap, hBitmap
    mov hBitmapOld, rax

    Invoke SetStretchBltMode, hdc, HALFTONE
    Invoke SetBrushOrgEx, hdc, 0, 0, 0
    Invoke StretchBlt, hdc, 0, 0, dword ptr qwNewBitmapWidth, dword ptr qwNewBitmapHeight, hdcBitmap, 0, 0, dword ptr qwBitmapWidth, dword ptr qwBitmapHeight, SRCCOPY        

    Invoke SelectObject, hdcBitmap, hBitmapOld
    Invoke DeleteObject, hBitmapOld
    Invoke DeleteDC, hdcBitmap
    Invoke SelectObject, hdc, hStretchedBitmapOld
    Invoke DeleteObject, hStretchedBitmapOld     
    Invoke DeleteDC, hdc

    .IF lpBitmapWidth != 0
        mov rbx, lpBitmapWidth
        mov rax, qwNewBitmapWidth
        mov [rbx], rax
    .ENDIF

    .IF lpBitmapHeight != 0
        mov rbx, lpBitmapHeight
        mov rax, qwNewBitmapHeight
        mov [rbx], rax
    .ENDIF

    .IF lpBitmapX != 0
        mov rbx, lpBitmapX
        mov rax, X
        mov [rbx], rax    
    .ENDIF

    .IF lpBitmapY != 0
        mov rbx, lpBitmapY
        mov rax, Y
        mov [rbx], rax
    .ENDIF

    mov rax, hStretchedBitmap
    ret
MUIGDIStretchBitmap ENDP

MODERNUI_LIBEND


