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

IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib
ENDIF


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Same as MUIPaintBackground, but with an image.
;
; dwImageType: 0=none, 1=bmp, 2=ico
; dwImageLocation: 0=center center, 1=bottom left, 2=bottom right, 3=top left, 
; 4=top right, 5=center top, 6=center bottom
;------------------------------------------------------------------------------
MUIPaintBackgroundImage PROC FRAME USES RBX hWin:MUIWND, BackColor:MUICOLORRGB, BorderColor:MUICOLORRGB, hImage:MUIIMAGE, ImageHandleType:MUIIT, ImageLocation:MUIIL
    LOCAL ps:PAINTSTRUCT
    LOCAL rect:RECT
    LOCAL pt:POINT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hBufferBitmap:HBITMAP
    LOCAL hdcMemBmp:HDC
    LOCAL hbmMem:HBITMAP
    LOCAL hbmMemBmp:HBITMAP
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL pGraphics:QWORD
    LOCAL pGraphicsBuffer:QWORD
    LOCAL pBitmap:QWORD
    
    .IF ImageHandleType == MUIIT_PNG
        mov pGraphics, 0
        mov pGraphicsBuffer, 0
        mov pBitmap, 0
    .ENDIF
    
    Invoke BeginPaint, hWin, addr ps
    mov hdc, rax

    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke MUIGDIDoubleBufferStart, hWin, hdc, Addr hdcMem, Addr rect, Addr hBufferBitmap

    ;----------------------------------------------------------
    ; Paint background
    ;----------------------------------------------------------
    Invoke MUIGDIPaintFill, hdcMem, Addr rect, BackColor

    ;----------------------------------------------------------
    ; Paint Border
    ;----------------------------------------------------------
    .IF BorderColor != 0
        Invoke MUIGDIPaintFrame, hdcMem, Addr rect, BorderColor, MUIPFS_ALL
    .ENDIF
    
    .IF hImage != NULL
        ;----------------------------------------
        ; Calc left and top of image based on 
        ; client rect and image width and height
        ;----------------------------------------
        Invoke MUIGetImageSize, hImage, ImageHandleType, Addr ImageWidth, Addr ImageHeight

        mov rax, ImageLocation
        .IF rax == MUIIL_CENTER
            mov eax, rect.right
            shr eax, 1
            mov rbx, ImageWidth
            shr ebx, 1
            sub eax, ebx
            mov pt.x, eax
                    
            mov eax, rect.bottom
            shr eax, 1
            mov rbx, ImageHeight
            shr ebx, 1
            sub eax, ebx
            mov pt.y, eax
        
        .ELSEIF eax == MUIIL_BOTTOMLEFT
            mov pt.x, 1
            
            mov eax, rect.bottom
            mov rbx, ImageHeight
            sub eax, ebx
            dec eax
            mov pt.y, eax
        
        .ELSEIF eax == MUIIL_BOTTOMRIGHT
            mov eax, rect.right
            mov rbx, ImageWidth
            sub eax, ebx
            dec eax
            mov pt.x, eax
                    
            mov eax, rect.bottom
            mov rbx, ImageHeight
            sub eax, ebx
            dec eax
            mov pt.y, eax        
        
        .ELSEIF eax == MUIIL_TOPLEFT
            mov pt.x, 1
            mov pt.y, 1
        
        .ELSEIF eax == MUIIL_TOPRIGHT
            mov eax, rect.right
            mov rbx, ImageWidth
            sub eax, ebx
            dec eax
            mov pt.x, eax        
        
        .ELSEIF eax == MUIIL_TOPCENTER
            mov pt.x, 1

            mov eax, rect.bottom
            shr eax, 1
            mov rbx, ImageHeight
            shr ebx, 1
            sub eax, ebx
            mov pt.y, eax            
        
        .ELSEIF eax == MUIIL_BOTTOMCENTER
            mov eax, rect.right
            shr eax, 1
            mov rbx, ImageWidth
            shr ebx, 1
            sub eax, ebx
            mov pt.x, eax
                    
            mov eax, rect.bottom
            mov rbx, ImageHeight
            sub eax, ebx
            dec eax
            mov pt.y, eax
        
        .ENDIF
        
        ;----------------------------------------
        ; Draw image depending on what type it is
        ;----------------------------------------
        mov rax, ImageHandleType
        .IF rax == MUIIT_NONE
            
        .ELSEIF rax == MUIIT_BMP
            Invoke CreateCompatibleDC, hdc
            mov hdcMemBmp, rax
            Invoke SelectObject, hdcMemBmp, hImage
            mov hbmMemBmp, rax
            dec rect.right
            dec rect.bottom
            Invoke BitBlt, hdcMem, pt.x, pt.y, rect.right, rect.bottom, hdcMemBmp, 0, 0, SRCCOPY ;ImageWidth, ImageHeight
            inc rect.right
            inc rect.bottom
            Invoke SelectObject, hdcMemBmp, hbmMemBmp
            Invoke DeleteDC, hdcMemBmp
            .IF hbmMemBmp != 0
                Invoke DeleteObject, hbmMemBmp
            .ENDIF

        .ELSEIF rax == MUIIT_ICO
            Invoke DrawIconEx, hdcMem, pt.x, pt.y, hImage, 0, 0, NULL, NULL, DI_NORMAL ; 0, 0,

        
        .ELSEIF rax == MUIIT_PNG
            IFDEF MUI_USEGDIPLUS
            Invoke GdipCreateFromHDC, hdcMem, Addr pGraphics
            
            Invoke GdipCreateBitmapFromGraphics, ImageWidth, ImageHeight, pGraphics, Addr pBitmap
            Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer            
            Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
            dec rect.right
            dec rect.bottom               
            Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, rect.right, rect.bottom ;ImageWidth, ImageHeight
            inc rect.right
            inc rect.bottom               
            .IF pBitmap != NULL
                Invoke GdipDisposeImage, pBitmap
            .ENDIF
            .IF pGraphicsBuffer != NULL
                Invoke GdipDeleteGraphics, pGraphicsBuffer
            .ENDIF
            .IF pGraphics != NULL
                Invoke GdipDeleteGraphics, pGraphics
            .ENDIF
            ENDIF
        .ENDIF
        
    .ENDIF

    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Finish Double Buffering & Cleanup
    ;----------------------------------------------------------    
    Invoke MUIGDIDoubleBufferFinish, hdcMem, hBufferBitmap, 0, 0, 0, 0    

    Invoke EndPaint, hWin, addr ps
    mov rax, 0
    ret

MUIPaintBackgroundImage ENDP



MODERNUI_LIBEND



