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

DEBUG64 EQU 1

IFDEF DEBUG64
    PRESERVEXMMREGS equ 1
    includelib \JWasm\lib\x64\Debug64.lib
    DBG64LIB equ 1
    DEBUGEXE textequ <'\Jwasm\bin\DbgWin.exe'>
    include \JWasm\include\debug64.inc
    .DATA
    RDBG_DbgWin	DB DEBUGEXE,0
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

MUI_GDIPlusToken	            DQ 0
MUI_gdipsi	                    GdiplusStartupInput	<1,0,0,0>
ENDIF

.CODE

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
; returns it in eax.
; Properties are defined as constants, which are used as offsets in memory to the 
; data alloc'd
; for example: @MouseOver EQU 0, @SelectedState EQU 4
; we might specify 4 in cbWndExtra and then GlobalAlloc 8 bytes of data to control at 
; startup and store this pointer with SetWindowLong, hControl, 0, pMem
; pMem is our pointer to our 8 bytes of storage, of which first four bytes (dword) is
; used for our @MouseOver property and the next dword for @SelectedState 
; cbWndExtraOffset is usually going to be 0 for custom registered window controls
; and some other offset for superclassed window control
;-------------------------------------------------------------------------------------
_MUIGetProperty PROC FRAME USES RBX hControl:QWORD, cbWndExtraOffset:QWORD, dqProperty:QWORD
    
    Invoke GetWindowLongPtr, hControl, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF
    mov rbx, rax
    add rbx, dqProperty
    mov rax, [rbx]
    
    ret

_MUIGetProperty ENDP


;-------------------------------------------------------------------------------------
; Sets property value and returns previous value in eax.
;-------------------------------------------------------------------------------------
_MUISetProperty PROC FRAME USES RBX hControl:QWORD, cbWndExtraOffset:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    LOCAL dqPrevValue:QWORD
    Invoke GetWindowLongPtr, hControl, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF    
    mov rbx, rax
    add rbx, dqProperty
    mov rax, [rbx]
    mov dqPrevValue, rax    
    mov rax, dqPropertyValue
    mov [rbx], rax
    mov rax, dqPrevValue
    ret

_MUISetProperty ENDP


;-------------------------------------------------------------------------------------
; Allocs memory for the properties of a control
;-------------------------------------------------------------------------------------
MUIAllocMemProperties PROC FRAME hControl:QWORD, cbWndExtraOffset:QWORD, dqSize:QWORD
    LOCAL pMem:QWORD
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, dqSize
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
MUIGetExtProperty PROC FRAME hControl:QWORD, dqProperty:QWORD
    Invoke _MUIGetProperty, hControl, 4, dqProperty ; get external properties
    ret
MUIGetExtProperty ENDP


;-------------------------------------------------------------------------------------
; Sets external property value and returns previous value in rax.
;-------------------------------------------------------------------------------------
MUISetExtProperty PROC FRAME hControl:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    Invoke _MUISetProperty, hControl, 4, dqProperty, dqPropertyValue ; set external properties
    ret
MUISetExtProperty ENDP


;-------------------------------------------------------------------------------------
; Gets internal property value and returns it in rax
;-------------------------------------------------------------------------------------
MUIGetIntProperty PROC FRAME hControl:QWORD, dqProperty:QWORD
    Invoke _MUIGetProperty, hControl, 0, dqProperty ; get internal properties
    ret
MUIGetIntProperty ENDP


;-------------------------------------------------------------------------------------
; Sets internal property value and returns previous value in eax.
;-------------------------------------------------------------------------------------
MUISetIntProperty PROC FRAME hControl:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    Invoke _MUISetProperty, hControl, 0, dqProperty, dqPropertyValue ; set internal properties
    ret
MUISetIntProperty ENDP


;-------------------------------------------------------------------------------------
; Convert font point size eg '12' to logical unit size for use with CreateFont,
; CreateFontIndirect
;-------------------------------------------------------------------------------------
MUIPointSizeToLogicalUnit PROC FRAME hWin:QWORD, dqPointSize:QWORD
    LOCAL hdc:HDC
    LOCAL dwLogicalUnit:QWORD
    
    Invoke GetDC, hWin
    mov hdc, rax
    Invoke GetDeviceCaps, hdc, LOGPIXELSY
    xor rdx, rdx
    mov rbx, dqPointSize
    mul rbx
    mov rcx, 72d
    div rcx 
    ;Invoke MulDiv, dqPointSize, rax, 72d
    mov dwLogicalUnit, rax
    Invoke ReleaseDC, hWin, hdc
    mov rax, dwLogicalUnit
    ret
MUIPointSizeToLogicalUnit ENDP


;-------------------------------------------------------------------------------------
; Applies the ModernUI style to a dialog to make it a captionless, borderless form. 
; User can manually change a form in a resource editor to have the following style
; flags: WS_POPUP or WS_VISIBLE and optionally with DS_CENTER /DS_CENTERMOUSE / 
; WS_CLIPCHILDREN / WS_CLIPSIBLINGS / WS_MINIMIZE / WS_MAXIMIZE
;-------------------------------------------------------------------------------------
MUIApplyToDialog PROC FRAME hWin:QWORD, dqDropShadow:QWORD
    LOCAL dqStyle:QWORD
    LOCAL dqNewStyle:QWORD
    LOCAL dqClassStyle:QWORD
    
    mov dqNewStyle, WS_POPUP
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov dqStyle, rax
    
    and rax, DS_CENTER
    .IF rax == DS_CENTER
        or dqNewStyle, DS_CENTER
    .ENDIF
    
    mov rax, dqStyle
    and rax, DS_CENTERMOUSE
    .IF rax == DS_CENTERMOUSE
        or dqNewStyle, DS_CENTERMOUSE
    .ENDIF
    
    mov rax, dqStyle
    and rax, WS_VISIBLE
    .IF rax == WS_VISIBLE
        or dqNewStyle, WS_VISIBLE
    .ENDIF
    
    mov rax, dqStyle
    and rax, WS_MINIMIZE
    .IF rax == WS_MINIMIZE
        or dqNewStyle, WS_MINIMIZE
    .ENDIF
    
    mov rax, dqStyle
    and rax, WS_MAXIMIZE
    .IF rax == WS_MAXIMIZE
        or dqNewStyle, WS_MAXIMIZE
    .ENDIF        

    mov rax, dqStyle
    and rax, WS_CLIPSIBLINGS
    .IF rax == WS_CLIPSIBLINGS
        or dqNewStyle, WS_CLIPSIBLINGS
    .ENDIF        
    
    or dqNewStyle, WS_CLIPCHILDREN

	Invoke SetWindowLongPtr, hWin, GWL_STYLE, dqNewStyle
	
	; Set dropshadow on or off on our dialog
	
	Invoke GetClassLongPtr, hWin, GCL_STYLE
	mov dqClassStyle, rax
	
	.IF dqDropShadow == TRUE
	    mov rax, dqClassStyle
	    and rax, CS_DROPSHADOW
	    .IF rax != CS_DROPSHADOW
	        or dqClassStyle, CS_DROPSHADOW
	        Invoke SetClassLongPtr, hWin, GCL_STYLE, dqClassStyle
	    .ENDIF
	.ELSE    
	    mov rax, dqClassStyle
	    and rax, CS_DROPSHADOW
	    .IF rax == CS_DROPSHADOW
	        and dqClassStyle,(-1 xor CS_DROPSHADOW)
            Invoke SetClassLongPtr, hWin, GCL_STYLE, dqClassStyle
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
MUIPaintBackground PROC FRAME hWin:QWORD, dqBackcolor:QWORD, dqBorderColor:QWORD
	LOCAL ps:PAINTSTRUCT
	LOCAL hdc:HDC
    LOCAL rect:RECT
    LOCAL hdcMem:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBrush:QWORD

	invoke BeginPaint, hWin, addr ps
	mov	hdc, rax
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
    Invoke SetDCBrushColor, hdcMem, dword ptr dqBackcolor
    Invoke FillRect, hdcMem, Addr rect, hBrush

    .IF dqBorderColor != 0
        Invoke GetStockObject, DC_BRUSH
        mov hBrush, rax
        Invoke SelectObject, hdcMem, rax
        Invoke SetDCBrushColor, hdcMem, dword ptr dqBorderColor
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
MUIPaintBackgroundImage PROC FRAME USES RBX hWin:QWORD, dqBackcolor:QWORD, dqBorderColor:QWORD, hImage:QWORD, dqImageType:QWORD, dqImageLocation:QWORD
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
    
    .IF dqImageType == MUIIT_PNG
        mov pGraphics, 0
        mov pGraphicsBuffer, 0
        mov pBitmap, 0
    .ENDIF
    
	invoke BeginPaint, hWin, addr ps
	mov	hdc, rax
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
    Invoke SetDCBrushColor, hdcMem, dword ptr dqBackcolor
    Invoke FillRect, hdcMem, Addr rect, hBrush

    .IF dqBorderColor != 0
        Invoke GetStockObject, DC_BRUSH
        mov hBrush, rax
        Invoke SelectObject, hdcMem, rax
        Invoke SetDCBrushColor, hdcMem, dword ptr dqBorderColor
        Invoke FrameRect, hdcMem, Addr rect, hBrush
    .ENDIF
    
    .IF hImage != NULL
        ;----------------------------------------
        ; Calc left and top of image based on 
        ; client rect and image width and height
        ;----------------------------------------
        Invoke MUIGetImageSize, hImage, dqImageType, Addr ImageWidth, Addr ImageHeight

        mov rax, dqImageLocation
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
        mov rax, dqImageType
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
; MUIGetImageSize
;-------------------------------------------------------------------------------------
MUIGetImageSize PROC FRAME USES RBX hImage:QWORD, dqImageType:QWORD, lpdqImageWidth:QWORD, lpdqImageHeight:QWORD
    LOCAL bm:BITMAP
    LOCAL iinfo:ICONINFO
    LOCAL nImageWidth:QWORD
    LOCAL nImageHeight:QWORD

    mov rax, dqImageType
    .IF rax == MUIIT_NONE
        mov rax, 0
        mov rbx, lpdqImageWidth
        mov [rbx], rax
        mov rbx, lpdqImageHeight
        mov [rbx], rax    
        mov rax, FALSE
        ret
        
    .ELSEIF rax == MUIIT_BMP ; bitmap/icon
        Invoke GetObject, hImage, SIZEOF bm, Addr bm
        xor rax, rax
        mov eax, bm.bmWidth
        mov rbx, lpdqImageWidth
        mov [rbx], rax
        mov eax, bm.bmHeight
        mov rbx, lpdqImageHeight
        mov [rbx], rax
    
    .ELSEIF rax == MUIIT_ICO ; icon    
        Invoke GetIconInfo, hImage, Addr iinfo ; get icon information
        mov rax, iinfo.hbmColor ; bitmap info of icon has width/height
        .IF rax != NULL
            Invoke GetObject, iinfo.hbmColor, SIZEOF bm, Addr bm
            xor rax, rax
            mov eax, bm.bmWidth
            mov rbx, lpdqImageWidth
            mov [rbx], rax
            mov eax, bm.bmHeight
            mov rbx, lpdqImageHeight
            mov [rbx], rax
        .ELSE ; Icon has no color plane, image width/height data stored in mask
            mov rax, iinfo.hbmMask
            .IF rax != NULL
                Invoke GetObject, iinfo.hbmMask, SIZEOF bm, Addr bm
                xor rax, rax
                mov eax, bm.bmWidth
                mov rbx, lpdqImageWidth
                mov [rbx], rax
                mov eax, bm.bmHeight
                shr rax, 1 ;bmp.bmHeight / 2;
                mov rbx, lpdqImageHeight
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
        mov rbx, lpdqImageWidth
        mov [rbx], rax
        mov rax, nImageHeight
        mov rbx, lpdqImageHeight
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
MUIAllocStructureMemory PROC FRAME USES RBX dqPtrStructMem:QWORD, TotalItems:QWORD, ItemSize:QWORD
    LOCAL StructDataOffset:QWORD
    LOCAL StructSize:QWORD
    LOCAL StructData:QWORD
    
    ;PrintText 'AllocStructureMemory'
    .IF TotalItems == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, ItemSize ;
        .IF rax != NULL
            mov StructData, rax
            mov rbx, dqPtrStructMem
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
        
        .IF dqPtrStructMem != NULL
        
            ; calc new size to grow structure and offset to new entry
            mov rax, TotalItems
            inc rax
            mov rbx, ItemSize
            mul rbx
            mov StructSize, rax ; save new size to alloc mem for
            mov rbx, ItemSize
            sub rax, rbx
            mov StructDataOffset, rax ; save offset for new entry
            
            mov rbx, dqPtrStructMem ; get value from addr of passed dword dwPtrStructMem into eax, this is our pointer to previous mem location of structure
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
                
                mov rbx, dqPtrStructMem
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



END
