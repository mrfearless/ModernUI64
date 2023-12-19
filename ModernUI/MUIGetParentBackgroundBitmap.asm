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


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets parent's background bitmap from parent DC, at the child's location and 
; size. For use in setting background of child to 'transparent'
; Returns in eax hBitmap or NULL
;------------------------------------------------------------------------------
MUIGetParentBackgroundBitmap PROC FRAME hWin:MUIWND
    LOCAL rcWin:RECT
    LOCAL rcWnd:RECT
    LOCAL parWnd:QWORD
    LOCAL parDc:QWORD
    LOCAL hdcMem:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hOldBitmap:QWORD
	LOCAL qwWidth:QWORD
	LOCAL qwHeight:QWORD      

    Invoke GetParent, hWin; // Get the parent window.
    mov parWnd, rax
    Invoke GetDC, parWnd; // Get its DC.
    mov parDc, rax 
    ;Invoke UpdateWindow, hWnd
    Invoke GetWindowRect, hWin, Addr rcWnd;
    Invoke ScreenToClient, parWnd, Addr rcWnd; // Convert to the parent's co-ordinates
    Invoke GetClipBox, parDc, Addr rcWin
    ; Copy from parent DC.
    xor rax, rax
    mov eax, rcWin.right
    sub eax, rcWin.left
    mov qwWidth, rax
    
    xor rax, rax
    mov eax, rcWin.bottom
    sub eax, rcWin.top
    mov qwHeight, rax    

    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke CreateCompatibleDC, parDc
    mov hdcMem, rax
    Invoke CreateCompatibleBitmap, parDc, dword ptr qwWidth, dword ptr qwHeight
    mov hbmMem, rax
    Invoke SelectObject, hdcMem, hbmMem
    mov hOldBitmap, rax

    Invoke BitBlt, hdcMem, 0, 0, dword ptr qwWidth, dword ptr qwHeight, parDc, rcWnd.left, rcWnd.top, SRCCOPY;

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    Invoke SelectObject, hdcMem, hOldBitmap
    Invoke DeleteDC, hdcMem
    ;Invoke DeleteObject, hbmMem ; need to keep this bitmap to return it
    .IF hOldBitmap != 0
        Invoke DeleteObject, hOldBitmap
    .ENDIF          
    Invoke ReleaseDC, parWnd, parDc
    
    mov rax, hbmMem
    ret

MUIGetParentBackgroundBitmap ENDP


MODERNUI_LIBEND



