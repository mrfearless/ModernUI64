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
includelib MSImg32.Lib

include ModernUI.inc

EXTERNDEF MUIGDIPaintFill :PROTO hdc:HDC, lpFillRect:LPRECT, FillColor:MUICOLORRGB


IFNDEF TRIVERTEX
TRIVERTEX STRUCT
  x       DWORD ?
  y       DWORD ?
  Red     WORD ?
  Green   WORD ?
  Blue    WORD ?
  Alpha   WORD ?
TRIVERTEX ENDS
ENDIF

IFNDEF GRADIENT_TRIANGLE
GRADIENT_TRIANGLE STRUCT
  Vertex1         DWORD ?
  Vertex2         DWORD ?
  Vertex3         DWORD ?
GRADIENT_TRIANGLE ENDS
ENDIF

IFNDEF GRADIENT_RECT
GRADIENT_RECT STRUCT
  UpperLeft   DWORD ?
  LowerRight  DWORD ?
GRADIENT_RECT ENDS
ENDIF

;GRADIENT_FILL_RECT_H             equ 00000000h
;GRADIENT_FILL_RECT_V             equ 00000001h


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIGDIPaintGradient - Fills specified rect in the DC with a gradient
;
; clrGradientFrom   COLORREF or MUI_RGBCOLOR from
; clrGradientTo     COLORREF or MUI_RGBCOLOR from
; HorzVertGradient  Horizontal == FALSE, Vertical == TRUE 
;
;------------------------------------------------------------------------------
MUIGDIPaintGradient PROC FRAME USES RBX hdc:HDC, lpGradientRect:LPRECT, GradientColorFrom:MUICOLORRGB, GradientColorTo:MUICOLORRGB, HorzVertGradient:MUIPGS
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL mesh:GRADIENT_RECT
    LOCAL vertex[3]:TRIVERTEX
    
    mov rax, GradientColorFrom
    .IF rax == GradientColorTo ; if same color then just do a fill instead
        Invoke MUIGDIPaintFill, hdc, lpGradientRect, GradientColorFrom
        ret
    .ENDIF
    
    ;--------------------------------------------------------------------------
    ; Seperate GradientFrom ColorRef to 3 dwords for Red, Green & Blue
    ;--------------------------------------------------------------------------
    xor rax, rax
    mov rax, GradientColorFrom
    xor rbx, rbx
    mov bh, al
    mov clrRed, ebx
    xor ebx, ebx
    mov bh, ah
    mov clrGreen, ebx
    xor rbx, rbx
    shr eax, 16d
    mov bh, al
    mov clrBlue, ebx

    ;--------------------------------------------------------------------------
    ; Populate vertex 1 structure
    ;-------------------------------------------------------------------------- 
    ; fill x from rect left
    mov rbx, lpGradientRect
    mov eax, dword ptr [rbx].RECT.left
    lea rbx, vertex
    mov dword ptr [rbx].TRIVERTEX.x, eax

    ; fill y from rect top
    mov rbx, lpGradientRect
    mov eax, dword ptr [rbx].RECT.top
    lea rbx, vertex
    mov dword ptr [rbx].TRIVERTEX.y, eax

    ; fill colors from seperated colorref
    mov word ptr [rbx].TRIVERTEX.Alpha, 0
    mov eax, clrRed
    mov word ptr [rbx].TRIVERTEX.Red, ax
    mov eax, clrGreen
    mov word ptr [rbx].TRIVERTEX.Green, ax
    mov eax, clrBlue
    mov word ptr [rbx].TRIVERTEX.Blue, ax

    ;--------------------------------------------------------------------------
    ; Seperate GradientFrom ColorRef to 3 dwords for Red, Green & Blue
    ;--------------------------------------------------------------------------   
    xor rax, rax
    mov rax, GradientColorTo
    xor rbx, rbx
    mov bh, al
    mov clrRed, ebx
    xor rbx, rbx
    mov bh, ah
    mov clrGreen, ebx
    xor rbx, rbx
    shr eax, 16d
    mov bh, al
    mov clrBlue, ebx    

    ;--------------------------------------------------------------------------
    ; Populate vertex 2 structure
    ;--------------------------------------------------------------------------
    ; fill x from rect right
    mov rbx, lpGradientRect
    mov eax, dword ptr [rbx].RECT.right
    lea rbx, vertex
    add rbx, SIZEOF TRIVERTEX
    mov dword ptr [rbx].TRIVERTEX.x, eax
    
    ; fill x from rect right
    mov rbx, lpGradientRect
    mov eax, dword ptr [rbx].RECT.bottom
    lea rbx, vertex
    add rbx, SIZEOF TRIVERTEX
    mov dword ptr [rbx].TRIVERTEX.y, eax
    
    ; fill colors from seperated colorref
    mov word ptr [rbx].TRIVERTEX.Alpha, 0
    mov eax, clrRed
    mov word ptr [rbx].TRIVERTEX.Red, ax
    mov eax, clrGreen
    mov word ptr [rbx].TRIVERTEX.Green, ax
    mov eax, clrBlue
    mov word ptr [rbx].TRIVERTEX.Blue, ax

    ;--------------------------------------------------------------------------
    ; Set the mesh (gradient rectangle) point
    ;--------------------------------------------------------------------------
    mov mesh.UpperLeft, 0
    mov mesh.LowerRight, 1

    ;--------------------------------------------------------------------------
    ; Call GradientFill function
    ;--------------------------------------------------------------------------
    Invoke GradientFill, hdc, Addr vertex, 2, Addr mesh, 1, dword ptr HorzVertGradient ; Horz = 0, Vert = 1

    ret
MUIGDIPaintGradient endp



MODERNUI_LIBEND

