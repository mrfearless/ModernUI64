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
includelib msimg32.lib

include ModernUI.inc


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIBlend - Blends an existing dc (which can have a bitmap in it) with a 
; block of color. Transparency determines level of blending
;------------------------------------------------------------------------------
MUIGDIBlend PROC FRAME USES RBX hWin:MUIWND, hdc:HDC, BlendColor:MUICOLORRGB, Transparency:MUIVALUE
    LOCAL hdcMem:HDC
    LOCAL pvBitsMem:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hbmMemOld:QWORD
    LOCAL nWidth:QWORD
    LOCAL nHeight:QWORD
    LOCAL hBrush:QWORD
    LOCAL hBrushOld:QWORD    
    LOCAL bmi:BITMAPINFO
    LOCAL bf:BLENDFUNCTION    
    LOCAL rect:RECT
    
    Invoke GetClientRect, hWin, Addr rect
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    
    Invoke RtlZeroMemory, Addr bmi, SIZEOF BITMAPINFO
    mov bmi.bmiHeader.biSize, SIZEOF BITMAPINFOHEADER
    mov eax, rect.right
    sub eax, rect.left
    mov nWidth, rax
    mov bmi.bmiHeader.biWidth, eax
    mov eax, rect.bottom
    sub eax, rect.top
    mov nHeight, rax
    mov bmi.bmiHeader.biHeight, eax
    mov bmi.bmiHeader.biPlanes, 1
    mov bmi.bmiHeader.biBitCount, 32
    mov bmi.bmiHeader.biCompression, BI_RGB
    xor rax, rax
    xor rbx, rbx
    mov rax, nWidth
    mov rbx, nHeight
    mul ebx
    mov ebx, 4
    mul ebx
    mov bmi.bmiHeader.biSizeImage, eax    
    
    Invoke CreateDIBSection, hdcMem, Addr bmi, DIB_RGB_COLORS, Addr pvBitsMem, NULL, 0
    mov hbmMem, rax
    Invoke SelectObject, hdcMem, hbmMem
    mov hbmMemOld, rax
    
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr BlendColor
    Invoke SelectObject, hdcMem, hBrush
    mov hBrushOld, rax
    Invoke FillRect, hdcMem, Addr rect, hBrush
    Invoke SelectObject, hdcMem, hBrushOld
    Invoke DeleteObject, hBrushOld
    Invoke DeleteObject, hBrush
    
    mov bf.BlendOp, AC_SRC_OVER
    mov bf.BlendFlags, 0
    mov rax, Transparency
    mov bf.SourceConstantAlpha, al
    mov bf.AlphaFormat, 0 ; AC_SRC_ALPHA   
    Invoke AlphaBlend, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, rect.right, rect.bottom, dword ptr bf
    
    Invoke SelectObject, hdcMem, hbmMemOld
    Invoke DeleteObject, hbmMemOld
    Invoke DeleteDC, hdcMem
    ret
MUIGDIBlend ENDP


MODERNUI_LIBEND

