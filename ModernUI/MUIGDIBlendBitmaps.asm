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
includelib msimg32.lib

include ModernUI.inc

.DATA
szMUIGDIBlendBitmapsDisplayDC DB 'DISPLAY',0


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIBlendBitmaps - Blends two bitmaps together, or alternatively one bitmap
; and a block of color. dwTransparency determines level of blending
;------------------------------------------------------------------------------
MUIGDIBlendBitmaps PROC FRAME USES RBX hBitmap1:HBITMAP, hBitmap2:HBITMAP, ColorBitmap2:MUICOLORRGB, Transparency:MUIVALUE
    LOCAL nBmpWidth:QWORD
    LOCAL nBmpHeight:QWORD  
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hdcTemp:HDC
    LOCAL hdcBmp:HDC
    LOCAL pvBitsMem:QWORD
    LOCAL pvBitsTemp:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hbmMemOld:QWORD
    LOCAL hbmTemp:QWORD
    LOCAL hbmTempOld:QWORD
    LOCAL hBitmap1Old:QWORD
    LOCAL hBitmap2Old:QWORD
    LOCAL hBrush:QWORD
    LOCAL hBrushOld:QWORD
    LOCAL bmi:BITMAPINFO
    LOCAL bf:BLENDFUNCTION    
    LOCAL bm:BITMAP
    LOCAL rect:RECT

    Invoke CreateDC, Addr szMUIGDIBlendBitmapsDisplayDC, NULL, NULL, NULL
    mov hdc, rax
    
    Invoke RtlZeroMemory, Addr bm, SIZEOF BITMAP
    Invoke GetObject, hBitmap1, SIZEOF bm, Addr bm
    mov eax, bm.bmWidth
    mov nBmpWidth, rax
    mov eax, bm.bmHeight
    mov nBmpHeight, rax    
    
    
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    Invoke CreateCompatibleDC, hdc
    mov hdcTemp, rax

    Invoke RtlZeroMemory, Addr bmi, SIZEOF BITMAPINFO

    ; setup bitmap info  
    mov bmi.bmiHeader.biSize, SIZEOF BITMAPINFOHEADER
    mov rax, nBmpWidth
    mov bmi.bmiHeader.biWidth, eax
    mov rax, nBmpHeight
    mov bmi.bmiHeader.biHeight, eax
    mov bmi.bmiHeader.biPlanes, 1
    mov bmi.bmiHeader.biBitCount, 32
    mov bmi.bmiHeader.biCompression, BI_RGB
    mov rax, nBmpWidth
    mov rbx, nBmpHeight
    mul ebx
    mov ebx, 4
    mul ebx
    mov bmi.bmiHeader.biSizeImage, eax

    ; create our DIB section and select the bitmap into the dc 
    Invoke CreateDIBSection, hdcMem, Addr bmi, DIB_RGB_COLORS, Addr pvBitsMem, NULL, 0
    mov hbmMem, rax

    Invoke CreateDIBSection, hdcTemp, Addr bmi, DIB_RGB_COLORS, Addr pvBitsTemp, NULL, 0
    mov hbmTemp, rax

    Invoke SelectObject, hdcMem, hbmMem
    mov hbmMemOld, rax

    Invoke SelectObject, hdcTemp, hbmTemp
    mov hbmTempOld, rax

    Invoke CreateCompatibleDC, hdcMem
    mov hdcBmp, rax 
    Invoke SelectObject, hdcBmp, hBitmap1
    mov hBitmap1Old, rax
    Invoke BitBlt, hdcMem, 0, 0, dword ptr nBmpWidth, dword ptr nBmpHeight, hdcBmp, 0, 0, SRCCOPY
    Invoke SelectObject, hdcBmp, hBitmap1Old
    Invoke DeleteObject, hBitmap1Old
    Invoke DeleteDC, hdcBmp

    .IF hBitmap2 != 0
        Invoke CreateCompatibleDC, hdcTemp
        mov hdcBmp, rax 
        Invoke SelectObject, hdcBmp, hBitmap2
        mov hBitmap2Old, rax
        Invoke BitBlt, hdcTemp, 0, 0, dword ptr nBmpWidth, dword ptr nBmpHeight, hdcBmp, 0, 0, SRCCOPY
        Invoke SelectObject, hdcBmp, hBitmap2Old
        Invoke DeleteObject, hBitmap2Old
        Invoke DeleteDC, hdcBmp
    .ELSE
        Invoke CreateSolidBrush, dword ptr ColorBitmap2
        mov hBrush, rax
        Invoke SelectObject, hdcTemp, hBrush
        mov hBrushOld, rax
        mov rect.left, 0
        mov rect.top, 0
        mov rax, nBmpWidth
        mov rect.right, eax
        mov rax, nBmpHeight
        mov rect.bottom, eax
        Invoke FillRect, hdcTemp, Addr rect, hBrush
        Invoke SelectObject, hdcTemp, hBrushOld
        Invoke DeleteObject, hBrushOld
        Invoke DeleteObject, hBrush
    .ENDIF

    mov bf.BlendOp, AC_SRC_OVER
    mov bf.BlendFlags, 0
    mov rax, Transparency
    mov bf.SourceConstantAlpha, al ;transparency
    mov bf.AlphaFormat, 0 ;0;AC_SRC_ALPHA; AC_SRC_ALPHA   

    ;mov eax, dword ptr bf
    Invoke AlphaBlend, hdcMem, 0, 0, dword ptr nBmpWidth, dword ptr nBmpHeight, hdcTemp, 0, 0, dword ptr nBmpWidth, dword ptr nBmpHeight, dword ptr bf

    Invoke SelectObject, hdcTemp, hbmTempOld
    Invoke DeleteObject, hbmTempOld
    Invoke DeleteObject, hbmTemp
    Invoke SelectObject, hdcMem, hbmMemOld
    Invoke DeleteObject, hbmMemOld

    Invoke DeleteDC, hdcMem
    Invoke DeleteDC, hdcTemp
    Invoke DeleteDC, hdc
    
    mov rax, hbmMem
    ret
MUIGDIBlendBitmaps ENDP


MODERNUI_LIBEND

