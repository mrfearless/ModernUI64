;======================================================================================================================================
;
; ModernUI x64 Library v0.0.0.5
;
; Copyright (c) 2016 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/ModernUI
;
;======================================================================================================================================


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

MUI_USEGDIPLUS EQU 1 ; comment out of you dont require png (gdiplus) support

;DEBUG64 EQU 1

IFDEF DEBUG64
    PRESERVEXMMREGS equ 1
    includelib \JWasm\lib\x64\Debug64.lib
    DBG64LIB equ 1
    DEBUGEXE textequ <'\Jwasm\bin\DbgWin.exe'>
    include \JWasm\include\debug64.inc
    .DATA
    RDBG_DbgWin DB DEBUGEXE,0
    .CODE
ENDIF

include windows.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

IFDEF MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib
ENDIF

include ModernUI.inc

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
_MUIGetProperty                  PROTO :QWORD, :QWORD, :QWORD           ; hControl, cbWndExtraOffset, dqProperty
_MUISetProperty                  PROTO :QWORD, :QWORD, :QWORD, :QWORD   ; hControl, cbWndExtraOffset, dqProperty, dqPropertyValue



;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------



.CONST

.DATA
IFDEF MUI_USEGDIPLUS
MUI_GDIPLUS                     DQ 0 ; controls that use gdiplus check this first, if 0 they call gdi startup and inc the value
                                     ; controls that use gdiplus when destroyed decrement this value and check if 0. If 0 they call gdi finish

MUI_GDIPlusToken                DQ 0
MUI_gdipsi                      GdiplusStartupInput <1,0,0,0>
ENDIF

.CODE

ALIGN 8

;======================================================================================================================================
; PRIVATE FUNCTIONS
;
; These functions are intended for use with controls created for the ModernUI framework
; even though they are PUBLIC they are prefixed with _ to indicate for internal use.
; Only ModernUI controls should call these functions directly.
;
; The exception to this is the MUIGetProperty and MUISetProperty which are for
; users of the ModernUI controls to use for getting and setting external properties.
;
;======================================================================================================================================



;-------------------------------------------------------------------------------------
; Start of ModernUI framework (wrapper for gdiplus startup)
; Placed at start of program before WinMain call
;-------------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
MUIGDIPlusStart PROC FRAME
    .IF MUI_GDIPLUS == 0
        ;PrintText 'GdiplusStartup'
        Invoke GdiplusStartup, Addr MUI_GDIPlusToken, Addr MUI_gdipsi, NULL
    .ENDIF
    inc MUI_GDIPLUS
    ;PrintDec MUI_GDIPLUS
    xor rax, rax
    ret
MUIGDIPlusStart ENDP
ENDIF

;-------------------------------------------------------------------------------------
; Finish ModernUI framework (wrapper for gdiplus shutdown)
; Placed after WinMain call before ExitProcess
;-------------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
MUIGDIPlusFinish PROC FRAME
    ;PrintDec MUI_GDIPLUS
    dec MUI_GDIPLUS
    .IF MUI_GDIPLUS == 0
        ;PrintText 'GdiplusShutdown'
        Invoke GdiplusShutdown, MUI_GDIPlusToken
    .ENDIF
    xor rax, rax
    ret
MUIGDIPlusFinish ENDP
ENDIF

;-------------------------------------------------------------------------------------
; Gets the pointer to memory allocated to control at startup and stored in cbWinExtra
; adds the offset to property to this pointer and fetches value at this location and
; returns it in rax.
; Properties are defined as constants, which are used as offsets in memory to the 
; data alloc'd
; for example: @MouseOver EQU 0, @SelectedState EQU 8
; we might specify 16 in cbWndExtra and then GlobalAlloc 16 bytes of data to control at 
; startup and store this pointer with SetWindowLong, hControl, 0, pMem
; pMem is our pointer to our 16 bytes of storage, of which first eight bytes (qword) is
; used for our @MouseOver property and the next qword for @SelectedState 
; cbWndExtraOffset is usually going to be 0 for custom registered window controls
; and some other offset for superclassed window control
;-------------------------------------------------------------------------------------
_MUIGetProperty PROC FRAME USES RBX hControl:QWORD, cbWndExtraOffset:QWORD, qwProperty:QWORD
    
    Invoke GetWindowLongPtr, hControl, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF
    mov rbx, rax
    add rbx, qwProperty
    mov rax, [rbx]
    
    ret

_MUIGetProperty ENDP


;-------------------------------------------------------------------------------------
; Sets property value and returns previous value in eax.
;-------------------------------------------------------------------------------------
_MUISetProperty PROC FRAME USES RBX hControl:QWORD, cbWndExtraOffset:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    LOCAL qwPrevValue:QWORD
    Invoke GetWindowLongPtr, hControl, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF    
    mov rbx, rax
    add rbx, qwProperty
    mov rax, [rbx]
    mov qwPrevValue, rax    
    mov rax, qwPropertyValue
    mov [rbx], rax
    mov rax, qwPrevValue
    ret

_MUISetProperty ENDP


;-------------------------------------------------------------------------------------
; Allocs memory for the properties of a control
;-------------------------------------------------------------------------------------
MUIAllocMemProperties PROC FRAME hControl:QWORD, cbWndExtraOffset:QWORD, qwSize:QWORD
    LOCAL pMem:QWORD
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, qwSize
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    mov pMem, rax
    
    Invoke SetWindowLongPtr, hControl, cbWndExtraOffset, pMem
    
    mov rax, TRUE
    ret
MUIAllocMemProperties ENDP


;-------------------------------------------------------------------------------------
; Frees memory for the properties of a control
;-------------------------------------------------------------------------------------
MUIFreeMemProperties PROC FRAME hControl:QWORD, cbWndExtraOffset:QWORD
    Invoke GetWindowLongPtr, hControl, cbWndExtraOffset
    .IF rax != NULL
        invoke GlobalFree, rax
        Invoke SetWindowLongPtr, hControl, cbWndExtraOffset, 0
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    ret
MUIFreeMemProperties ENDP


;======================================================================================================================================
; PUBLIC FUNCTIONS
;======================================================================================================================================


;-------------------------------------------------------------------------------------
; Gets external property value and returns it in rax
;-------------------------------------------------------------------------------------
MUIGetExtProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke _MUIGetProperty, hControl, 8, qwProperty ; get external properties
    ret
MUIGetExtProperty ENDP


;-------------------------------------------------------------------------------------
; Sets external property value and returns previous value in rax.
;-------------------------------------------------------------------------------------
MUISetExtProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke _MUISetProperty, hControl, 8, qwProperty, qwPropertyValue ; set external properties
    ret
MUISetExtProperty ENDP


;-------------------------------------------------------------------------------------
; Gets internal property value and returns it in rax
;-------------------------------------------------------------------------------------
MUIGetIntProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke _MUIGetProperty, hControl, 0, qwProperty ; get internal properties
    ret
MUIGetIntProperty ENDP


;-------------------------------------------------------------------------------------
; Sets internal property value and returns previous value in eax.
;-------------------------------------------------------------------------------------
MUISetIntProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke _MUISetProperty, hControl, 0, qwProperty, qwPropertyValue ; set internal properties
    ret
MUISetIntProperty ENDP


;-------------------------------------------------------------------------------------
; Convert font point size eg '12' to logical unit size for use with CreateFont,
; CreateFontIndirect
;-------------------------------------------------------------------------------------
MUIPointSizeToLogicalUnit PROC FRAME USES RBX RCX RDX hWin:QWORD, qwPointSize:QWORD
    LOCAL hdc:HDC
    LOCAL dwLogicalUnit:DWORD
    
    Invoke GetDC, hWin
    mov hdc, rax
    Invoke GetDeviceCaps, hdc, LOGPIXELSY
    xor rdx, rdx
    xor rcx, rcx
    mov ebx, dword ptr qwPointSize
    mul ebx
    mov ecx, 72d
    div ecx
    neg eax
    ;Invoke MulDiv, dqPointSize, rax, 72d
    mov dwLogicalUnit, eax
    Invoke ReleaseDC, hWin, hdc
    mov eax, dwLogicalUnit
    ret
MUIPointSizeToLogicalUnit ENDP


;-------------------------------------------------------------------------------------
; Applies the ModernUI style to a dialog to make it a captionless, borderless form. 
; User can manually change a form in a resource editor to have the following style
; flags: WS_POPUP or WS_VISIBLE and optionally with DS_CENTER /DS_CENTERMOUSE / 
; WS_CLIPCHILDREN / WS_CLIPSIBLINGS / WS_MINIMIZE / WS_MAXIMIZE
;-------------------------------------------------------------------------------------
MUIApplyToDialog PROC FRAME hWin:QWORD, qwDropShadow:QWORD, qwClipping:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwNewStyle:QWORD
    LOCAL qwClassStyle:QWORD
    
    mov qwNewStyle, WS_POPUP
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    
    and rax, DS_CENTER
    .IF rax == DS_CENTER
        or qwNewStyle, DS_CENTER
    .ENDIF
    
    mov rax, qwStyle
    and rax, DS_CENTERMOUSE
    .IF rax == DS_CENTERMOUSE
        or qwNewStyle, DS_CENTERMOUSE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_VISIBLE
    .IF rax == WS_VISIBLE
        or qwNewStyle, WS_VISIBLE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_MINIMIZE
    .IF rax == WS_MINIMIZE
        or qwNewStyle, WS_MINIMIZE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_MAXIMIZE
    .IF rax == WS_MAXIMIZE
        or qwNewStyle, WS_MAXIMIZE
    .ENDIF        

    mov rax, qwStyle
    and rax, WS_CLIPSIBLINGS
    .IF rax == WS_CLIPSIBLINGS
        or qwNewStyle, WS_CLIPSIBLINGS
    .ENDIF        
    
    .IF qwClipping == TRUE
        mov rax, qwStyle
        and rax, WS_CLIPSIBLINGS
        .IF rax == WS_CLIPSIBLINGS
            or qwNewStyle, WS_CLIPSIBLINGS
        .ENDIF        
        or qwNewStyle, WS_CLIPCHILDREN
    .ENDIF

    Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwNewStyle
    
    ; Set dropshadow on or off on our dialog
    
    Invoke GetClassLongPtr, hWin, GCL_STYLE
    mov qwClassStyle, rax
    
    .IF qwDropShadow == TRUE
        mov rax, qwClassStyle
        and rax, CS_DROPSHADOW
        .IF rax != CS_DROPSHADOW
            or qwClassStyle, CS_DROPSHADOW
            Invoke SetClassLongPtr, hWin, GCL_STYLE, qwClassStyle
        .ENDIF
    .ELSE    
        mov rax, qwClassStyle
        and rax, CS_DROPSHADOW
        .IF rax == CS_DROPSHADOW
            and qwClassStyle,(-1 xor CS_DROPSHADOW)
            Invoke SetClassLongPtr, hWin, GCL_STYLE, qwClassStyle
        .ENDIF
    .ENDIF

    ; remove any menu that might have been assigned via class registration - for modern ui look
    Invoke GetMenu, hWin
    .IF rax != NULL
        Invoke SetMenu, hWin, NULL
    .ENDIF
    
    ret

MUIApplyToDialog ENDP



;-------------------------------------------------------------------------------------
; Center child window hWndChild into parent window or desktop if hWndParent is NULL. 
; Parent doesnt need to be the owner.
; No returned value
;-------------------------------------------------------------------------------------
MUICenterWindow PROC FRAME hWndChild:QWORD, hWndParent:QWORD
    LOCAL rectChild:RECT         ; Child window coordonate
    LOCAL rectParent:RECT        ; Parent window coordonate
    LOCAL rectDesktop:RECT       ; Desktop coordonate (WORKAREA)
    LOCAL dwChildLeft:DWORD      ;
    LOCAL dwChildTop:DWORD       ; Child window new coordonate
    LOCAL dwChildWidth:DWORD     ; used by MoveWindow
    LOCAL dwChildHeight:DWORD    ;
    LOCAL bParentMinimized:QWORD ; Is parent window minimized
    LOCAL bParentVisible:QWORD   ; Is parent window visible

    Invoke IsIconic, hWndParent
    mov bParentMinimized, rax
    
    Invoke IsWindowVisible, hWndParent
    mov bParentVisible, rax

    Invoke GetWindowRect, hWndChild, addr rectChild
    .IF rax != 0    ; 0 = no centering possible

        Invoke SystemParametersInfo, SPI_GETWORKAREA, NULL, addr rectDesktop, NULL
        .IF rax != 0    ; 0 = no centering possible
            
            .IF bParentMinimized == FALSE || bParentVisible == FALSE || hWndParent == NULL ; use desktop space
                xor rax, rax
                mov eax, rectDesktop.left
                mov rectParent.left, eax
                mov eax, rectDesktop.top
                mov rectParent.top, eax
                mov eax, rectDesktop.right
                mov rectParent.right, eax
                mov eax, rectDesktop.bottom
                mov rectParent.bottom, eax
            .ELSE
                Invoke GetWindowRect, hWndParent, addr rectParent
                .IF rax == 0    ; 0 = we take the desktop as parent (invalid or NULL hWndParent)
                    xor rax, rax
                    mov eax, rectDesktop.left
                    mov rectParent.left, eax
                    mov eax, rectDesktop.top
                    mov rectParent.top, eax
                    mov eax, rectDesktop.right
                    mov rectParent.right, eax
                    mov eax, rectDesktop.bottom
                    mov rectParent.bottom, eax
                .ENDIF
            .ENDIF
            ;
            ; Get new coordonate and make sure the child window
            ; is not moved outside the desktop workarea
            ;
            xor rax, rax
            mov eax, rectChild.right                   ; width = right - left
            sub eax, rectChild.left
            mov dwChildWidth, eax
            mov eax, rectParent.right
            sub eax, rectParent.left
            sub eax, dwChildWidth                      ; eax = Parent width - Child width...
            sar eax, 1                                 ; divided by 2
            add eax, rectParent.left                   ; eax = temporary left coord (need validation)
            .IF sdword ptr eax < rectDesktop.left
                mov eax, rectDesktop.left
            .ENDIF
            mov dwChildLeft, eax
            add eax, dwChildWidth                      ; eax = new left coord + child width
            .IF sdword ptr eax > rectDesktop.right     ; if child right outside desktop workarea
                mov eax, rectDesktop.right
                sub eax, dwChildWidth                  ; right = desktop right - child width
                mov dwChildLeft, eax                   ;
            .ENDIF

            mov eax, rectChild.bottom                  ; height = bottom - top
            sub eax, rectChild.top
            mov dwChildHeight, eax
            mov eax, rectParent.bottom
            sub eax, rectParent.top
            sub eax, dwChildHeight                     ; eax = Parent height - Child height...
            sar eax, 1
            add eax, rectParent.top
            .IF sdword ptr eax < rectDesktop.top       ; eax (child top) must not be smaller, if so...
                mov eax, rectDesktop.top               ; child top = Desktop.top
            .ENDIF
            mov dwChildTop, eax
            add eax, dwChildHeight                     ; eax = new top coord + child height
            .IF sdword ptr eax > rectDesktop.bottom
                mov eax, rectDesktop.bottom            ; child is outside desktop bottom
                sub eax, dwChildHeight                 ; child top = Desktop.bottom - child height
                mov dwChildTop, eax                    ;
           .ENDIF
           ;
           ; Now we have the new coordonate - the dialog window can be moved
           ;
           Invoke MoveWindow, hWndChild, dword ptr dwChildLeft, dword ptr dwChildTop, dword ptr dwChildWidth, dword ptr dwChildHeight, TRUE
        .ENDIF
    .ENDIF
    xor rax, rax
    ret

MUICenterWindow ENDP




;-------------------------------------------------------------------------------------
; Paint the background of the main window specified color
; optional provide dwBorderColor for border. If dwBorderColor = 0, no border is drawn
; if you require black for border, use 1, or MUI_RGBCOLOR(1,1,1)
;
; If you are using this on a window/dialog that does not use the ModernUI_CaptionBar
; control AND window/dialog is resizable, you should place a call to InvalideRect
; in the WM_NCCALCSIZE handler to prevent ugly drawing artifacts when border is drawn
; whilst resize of window/dialog occurs. The ModernUI_CaptionBar handles this call to 
; WM_NCCALCSIZE already by default. Here is an example of what to include if you need:
;
;    .ELSEIF eax == WM_NCCALCSIZE
;        Invoke InvalidateRect, hWin, NULL, TRUE
; 
;-------------------------------------------------------------------------------------
MUIPaintBackground PROC FRAME hWin:QWORD, qwBackcolor:QWORD, qwBorderColor:QWORD
    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:HDC
    LOCAL rect:RECT
    LOCAL hdcMem:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBrush:QWORD

    invoke BeginPaint, hWin, addr ps
    mov hdc, rax
    Invoke GetClientRect, hWin, Addr rect
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
    mov hbmMem, rax
    Invoke SelectObject, hdcMem, hbmMem
    mov hOldBitmap, rax 

    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr qwBackcolor
    Invoke FillRect, hdcMem, Addr rect, hBrush

    .IF qwBorderColor != 0
        Invoke GetStockObject, DC_BRUSH
        mov hBrush, rax
        Invoke SelectObject, hdcMem, rax
        Invoke SetDCBrushColor, hdcMem, dword ptr qwBorderColor
        Invoke FrameRect, hdcMem, Addr rect, hBrush
    .ENDIF
    
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

;    .IF dwBorderColor != 0
;        Invoke GetStockObject, DC_BRUSH
;        mov hBrush, eax
;        Invoke SelectObject, hdc, eax
;        Invoke SetDCBrushColor, hdc, dwBorderColor
;        Invoke FrameRect, hdc, Addr rect, hBrush
;    .ENDIF

    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem
    Invoke DeleteObject, hOldBitmap
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    invoke ReleaseDC, hWin, hdc
    invoke EndPaint, hWin, addr ps
    mov rax, 0
    ret

MUIPaintBackground ENDP


;-------------------------------------------------------------------------------------
; Same as MUIPaintBackground, but with an image (dwImageType 0=none, 1=bmp, 2=ico)
; dwImageLocation: 0=center center, 1=bottom left, 2=bottom right, 3=top left, 
; 4=top right, 5=center top, 6=center bottom
;-------------------------------------------------------------------------------------
MUIPaintBackgroundImage PROC FRAME USES RBX hWin:QWORD, qwBackcolor:QWORD, qwBorderColor:QWORD, hImage:QWORD, qwImageType:QWORD, qwImageLocation:QWORD
    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:HDC
    LOCAL rect:RECT
    LOCAL pt:POINT
    LOCAL hdcMem:QWORD
    LOCAL hdcMemBmp:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hbmMemBmp:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBrush:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL pGraphics:QWORD
    LOCAL pGraphicsBuffer:QWORD
    LOCAL pBitmap:QWORD
    
    .IF qwImageType == MUIIT_PNG
        mov pGraphics, 0
        mov pGraphicsBuffer, 0
        mov pBitmap, 0
    .ENDIF
    
    invoke BeginPaint, hWin, addr ps
    mov hdc, rax
    Invoke GetClientRect, hWin, Addr rect
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
    mov hbmMem, rax
    Invoke SelectObject, hdcMem, hbmMem
    mov hOldBitmap, rax 

    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr qwBackcolor
    Invoke FillRect, hdcMem, Addr rect, hBrush

    .IF qwBorderColor != 0
        Invoke GetStockObject, DC_BRUSH
        mov hBrush, rax
        Invoke SelectObject, hdcMem, rax
        Invoke SetDCBrushColor, hdcMem, dword ptr qwBorderColor
        Invoke FrameRect, hdcMem, Addr rect, hBrush
    .ENDIF
    
    .IF hImage != NULL
        ;----------------------------------------
        ; Calc left and top of image based on 
        ; client rect and image width and height
        ;----------------------------------------
        Invoke MUIGetImageSize, hImage, qwImageType, Addr ImageWidth, Addr ImageHeight

        mov rax, qwImageLocation
        .IF rax == MUIIL_CENTER
            xor rax, rax
            xor rbx, rbx
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
        
        .ELSEIF rax == MUIIL_BOTTOMLEFT
            mov pt.x, 1
            xor rax, rax
            xor rbx, rbx
            mov eax, rect.bottom
            mov rbx, ImageHeight
            sub eax, ebx
            dec eax
            mov pt.y, eax
        
        .ELSEIF eax == MUIIL_BOTTOMRIGHT
            xor rax, rax
            xor rbx, rbx        
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
        
        .ELSEIF rax == MUIIL_TOPLEFT
            mov pt.x, 1
            mov pt.y, 1
        
        .ELSEIF rax == MUIIL_TOPRIGHT
            xor rax, rax
            xor rbx, rbx        
            mov eax, rect.right
            mov rbx, ImageWidth
            sub eax, ebx
            dec eax
            mov pt.x, eax        
        
        .ELSEIF rax == MUIIL_TOPCENTER
            mov pt.x, 1
            xor rax, rax
            xor rbx, rbx
            mov eax, rect.bottom
            shr eax, 1
            mov rbx, ImageHeight
            shr ebx, 1
            sub eax, ebx
            mov pt.y, eax            
        
        .ELSEIF rax == MUIIL_BOTTOMCENTER
            xor rax, rax
            xor rbx, rbx        
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
        mov rax, qwImageType
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
    
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem
    Invoke DeleteObject, hOldBitmap
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    invoke ReleaseDC, hWin, hdc
    invoke EndPaint, hWin, addr ps
    mov rax, 0
    ret

MUIPaintBackgroundImage ENDP


;-------------------------------------------------------------------------------------
; Gets parent background color
; returns in eax, MUI_RGBCOLOR or -1 if NULL brush is set
; Useful for certain controls to retrieve the parents background color and then to 
; set their own background color based on the same value.
;-------------------------------------------------------------------------------------
MUIGetParentBackgroundColor PROC FRAME hControl:QWORD
    LOCAL hParent:QWORD
    LOCAL hBrush:QWORD
    LOCAL logbrush:LOGBRUSH
    
    Invoke GetParent, hControl
    mov hParent, rax
    
    Invoke GetClassLongPtr, hParent, GCL_HBRBACKGROUND
    .IF rax == NULL
        mov eax, -1
        ret
    .ENDIF

    .IF rax > 32d
        mov hBrush, rax
        Invoke GetObject, hBrush, SIZEOF LOGBRUSH, Addr logbrush
        .IF rax == 0
            mov eax, -1
            ret
        .ENDIF
        mov eax, logbrush.lbColor
    .ELSE
        dec eax ; to adjust for initial value being COLOR_X+1
        Invoke GetSysColor, eax
        ret
    .ENDIF
    
    ret
MUIGetParentBackgroundColor ENDP


;-------------------------------------------------------------------------------------
; MUIGetImageSize
;-------------------------------------------------------------------------------------
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


;--------------------------------------------------------------------------------------------------------------------
; Dynamically allocates or resizes a memory location based on items in a structure and the size of the structure
;
; StructMemPtr is an address to receive the pointer to memory location of the base structure in memory.
; StructMemPtr can be NULL if TotalItems are 0. Otherwise it must contain the address of the base structure in memory
; if the memory is to be increased, TotalItems > 0
; ItemSize is typically SIZEOF structure to be allocated (this function calcs for you the size * TotalItems)
; If StructMemPtr is NULL then memory object is initialized to the size of total items * itemsize and pointer to mem
; is returned in eax.
; On return eax contains the pointer to the new structure item or -1 if there was a problem alloc'ing memory.
;--------------------------------------------------------------------------------------------------------------------
MUIAllocStructureMemory PROC FRAME USES RBX qwPtrStructMem:QWORD, TotalItems:QWORD, ItemSize:QWORD
    LOCAL StructDataOffset:QWORD
    LOCAL StructSize:QWORD
    LOCAL StructData:QWORD
    
    ;PrintText 'AllocStructureMemory'
    .IF TotalItems == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, ItemSize ;
        .IF rax != NULL
            mov StructData, rax
            mov rbx, qwPtrStructMem
            mov [rbx], rax ; save pointer to memory alloc'd for structure
            mov StructDataOffset, 0 ; save offset for new entry
            ;IFDEF DEBUG32
            ;    PrintDec StructData
            ;ENDIF
        .ELSE
            IFDEF DEBUG64
            PrintText '_AllocStructureMemory::Mem error GlobalAlloc'
            ENDIF
            mov rax, -1
            ret
        .ENDIF
    .ELSE
        
        .IF qwPtrStructMem != NULL
        
            ; calc new size to grow structure and offset to new entry
            mov rax, TotalItems
            inc rax
            mov rbx, ItemSize
            mul rbx
            mov StructSize, rax ; save new size to alloc mem for
            mov rbx, ItemSize
            sub rax, rbx
            mov StructDataOffset, rax ; save offset for new entry
            
            mov rbx, qwPtrStructMem ; get value from addr of passed dword dwPtrStructMem into eax, this is our pointer to previous mem location of structure
            mov rax, [rbx]
            mov StructData, rax
            ;IFDEF DEBUG32
            ;    PrintDec StructData
            ;    PrintDec StructSize
            ;ENDIF
            
            .IF TotalItems >= 2
                Invoke GlobalUnlock, StructData
            .ENDIF
            Invoke GlobalReAlloc, StructData, StructSize, GMEM_ZEROINIT + GMEM_MOVEABLE ; resize memory for structure
            .IF rax != NULL
                ;PrintDec eax
                Invoke GlobalLock, rax
                mov StructData, rax
                
                mov rbx, qwPtrStructMem
                mov [rbx], rax ; save new pointer to memory alloc'd for structure back to dword address passed as dwPtrStructMem
            .ELSE
                IFDEF DEBUG64
                PrintText '_AllocStructureMemory::Mem error GlobalReAlloc'
                ENDIF
                mov rax, -1
                ret
            .ENDIF
        
        .ELSE ; initialize structure size to the size specified by items * size
            
            ; calc size of structure
            mov rax, TotalItems
            mov rbx, ItemSize
            mul rbx
            mov StructSize, rax ; save new size to alloc mem for        
            Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, StructSize ;GMEM_FIXED+GMEM_ZEROINIT
            .IF rax != NULL
                mov StructData, rax
                ;mov ebx, dwPtrStructMem ; alloc memory so dont return anything to this as it was null when we got it
                ;mov [ebx], eax ; save pointer to memory alloc'd for structure
                mov StructDataOffset, 0 ; save offset for new entry
                ;IFDEF DEBUG32
                ;    PrintDec StructData
                ;ENDIF
            .ELSE
                IFDEF DEBUG64
                PrintText '_AllocStructureMemory::Mem error GlobalAlloc'
                ENDIF
                mov rax, -1
                ret
            .ENDIF
        .ENDIF
    .ENDIF

    ; calc entry to new item, (base address of memory alloc'd for structure + size of mem for new structure size - size of structure item)
    ;PrintText 'AllocStructureMemory END'
    mov rax, StructData
    add rax, StructDataOffset
    
    ret
MUIAllocStructureMemory endp


;--------------------------------------------------------------------------------------------------------------------
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
; is returned in EDX, the high order word contains the width and the
; low order word the height.
; 
; Returns 0 if there is an error.
; If the index is greater than the number of icons in the file EDX will
; be set to the number of icons available otherwise EDX is 0. To find
; the number of available icons set the index to -1
;
;http://www.masmforum.com/board/index.php?topic=16267.msg134434#msg134434
;--------------------------------------------------------------------------------------------------------------------
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

    RET


MUICreateIconFromMemory ENDP


;-------------------------------------------------------------------------------------
; MUILoadRegionFromResource - Loads region from a resource
;-------------------------------------------------------------------------------------
MUILoadRegionFromResource PROC FRAME USES RBX hInst:QWORD, idRgnRes:QWORD, lpRegion:QWORD, lpqwSizeRegion:QWORD
    LOCAL hRes:QWORD
    ; Load region
    Invoke FindResource, hInst, idRgnRes, RT_RCDATA ; load rng image as raw data
    .IF eax != NULL
        mov hRes, rax
        Invoke SizeofResource, hInst, hRes
        .IF rax != 0
            .IF lpqwSizeRegion != NULL
                mov rbx, lpqwSizeRegion
                mov [rbx], rax
            .ELSE
                mov rax, FALSE
                ret
            .ENDIF
            Invoke LoadResource, hInst, hRes
            .IF rax != NULL
                Invoke LockResource, rax
                .IF rax != NULL
                    .IF lpRegion != NULL
                        mov rbx, lpRegion
                        mov [rbx], rax
                        mov rax, TRUE
                    .ELSE
                        mov rax, FALSE
                    .ENDIF
                .ELSE
                    ;PrintText 'Failed to lock resource'
                    mov rax, FALSE
                .ENDIF
            .ELSE
                ;PrintText 'Failed to load resource'
                mov rax, FALSE
            .ENDIF
        .ELSE
            ;PrintText 'Failed to get resource size'
            mov rax, FALSE
        .ENDIF
    .ELSE
        ;PrintText 'Failed to find resource'
        mov rax, FALSE
    .ENDIF    
    ret
MUILoadRegionFromResource ENDP


;-------------------------------------------------------------------------------------
; Sets a window/controls region from a region stored as an RC_DATA resource: idRgnRes
; if lpdwCopyRgn != NULL a copy of region handle is provided (for FrameRgn for example)
;-------------------------------------------------------------------------------------
MUISetRegionFromResource PROC FRAME USES RBX hWin:QWORD, idRgnRes:QWORD, lpqwCopyRgn:QWORD, bRedraw:QWORD
    LOCAL hinstance:QWORD
    LOCAL ptrRegionData:QWORD
    LOCAL qwRegionDataSize:QWORD
    LOCAL hRgn:QWORD
    
    .IF idRgnRes == NULL
        Invoke SetWindowRgn, hWin, NULL, FALSE
        ret
    .ENDIF
 
    Invoke GetModuleHandle, NULL
    mov hinstance, rax
    
    Invoke MUILoadRegionFromResource, hinstance, idRgnRes, Addr ptrRegionData, Addr qwRegionDataSize
    .IF rax == FALSE
        .IF lpqwCopyRgn != NULL
            mov rax, NULL
            mov rbx, lpqwCopyRgn
            mov [rbx], rax
        .ENDIF
        mov rax, FALSE    
        ret
    .ENDIF
    
    Invoke SetWindowRgn, hWin, NULL, FALSE
    Invoke ExtCreateRegion, NULL, dword ptr qwRegionDataSize, ptrRegionData
    mov hRgn, rax
    .IF rax == NULL
        .IF lpqwCopyRgn != NULL
            mov rax, NULL
            mov rbx, lpqwCopyRgn
            mov [rbx], rax
        .ENDIF
        mov rax, FALSE
        ret
    .ENDIF
    Invoke SetWindowRgn, hWin, hRgn, dword ptr bRedraw
    
    .IF lpqwCopyRgn != NULL
        Invoke ExtCreateRegion, NULL, dword ptr qwRegionDataSize, ptrRegionData
        mov hRgn, rax
        mov rbx, lpqwCopyRgn
        mov [ebx], rax
    .ENDIF

    mov rax, TRUE    
    ret

MUISetRegionFromResource ENDP




END
