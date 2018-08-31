;==============================================================================
;
; ModernUI x64 Control - ModernUI_Tooltip x64
;
; Copyright (c) 2018 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/ModernUI64
;
;
; This software is provided 'as-is', without any express or implied warranty. 
; In no event will the author be held liable for any damages arising from the 
; use of this software.
;
; Permission is granted to anyone to use this software for any non-commercial 
; program. If you use the library in an application, an acknowledgement in the
; application or documentation is appreciated but not required. 
;
; You are allowed to make modifications to the source code, but you must leave
; the original copyright notices intact and not misrepresent the origin of the
; software. It is not allowed to claim you wrote the original software. 
; Modified files must have a clear notice that the files are modified, and not
; in the original state. This includes the name of the person(s) who modified 
; the code. 
;
; If you want to distribute or redistribute any portion of this package, you 
; will need to include the full package in it's original state, including this
; license and all the copyrights.  
;
; While distributing this package (in it's original state) is allowed, it is 
; not allowed to charge anything for this. You may not sell or include the 
; package in any commercial package without having permission of the author. 
; Neither is it allowed to redistribute any of the package's components with 
; commercial applications.
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

;MUI_DONTUSEGDIPLUS EQU 1 ; exclude (gdiplus) support
;
;DEBUG64 EQU 1
;IFDEF DEBUG64
;    PRESERVEXMMREGS equ 1
;    includelib M:\UASM\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'M:\UASM\bin\DbgWin.exe'>
;    include M:\UASM\include\debug64.inc
;    .DATA
;    RDBG_DbgWin DB DEBUGEXE,0
;    .CODE
;ENDIF

include windows.inc
include commctrl.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib comctl32.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_Tooltip.inc

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_TooltipWndProc					PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_TooltipInit                    PROTO :QWORD, :QWORD, :QWORD
_MUI_TooltipPaint                   PROTO :QWORD
_MUI_TooltipPaintBackground         PROTO :QWORD, :QWORD, :QWORD
_MUI_TooltipPaintText               PROTO :QWORD, :QWORD, :QWORD
_MUI_TooltipPaintTextAndTitle       PROTO :QWORD, :QWORD, :QWORD
_MUI_TooltipPaintBorder             PROTO :QWORD, :QWORD, :QWORD
_MUI_TooltipSize                    PROTO :QWORD, :QWORD, :QWORD
_MUI_TooltipSetPosition             PROTO :QWORD
_MUI_TooltipCheckWidthMultiline     PROTO :QWORD
_MUI_TooltipCheckTextMultiline      PROTO :QWORD, :QWORD
_MUI_TooltipParentSubclass          PROTO :HWND, :UINT, :WPARAM, :LPARAM, :UINT, :QWORD

;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
MUI_TOOLTIP_PROPERTIES          STRUCT
    qwTooltipFont               DQ ?
    qwTooltipTextColor          DQ ?
    qwTooltipBackColor          DQ ?
    qwTooltipBorderColor        DQ ?
    qwTooltipShowDelay          DQ ?
    qwTooltipShowTimeout        DQ ?
    qwTooltipInfoTitleText      DQ ?
    qwTooltipOffsetX            DQ ?
    qwTooltipOffsetY            DQ ?
MUI_TOOLTIP_PROPERTIES          ENDS

; Internal properties
_MUI_TOOLTIP_PROPERTIES         STRUCT
    qwTooltipHandle             DQ ?
    qwMouseOver                 DQ ?
    qwParent                    DQ ?
    qwTooltipHoverTime          DQ ?
    qwTooltipWidth              DQ ?
    qwTooltipTitleFont          DQ ?    
    qwMultiline                 DQ ?
    qwPaddingWidth              DQ ?
    qwPaddingHeight             DQ ?
    qwTooltipTitleText          DQ ?
_MUI_TOOLTIP_PROPERTIES         ENDS


.CONST
MUI_TOOLTIP_SHOW_DELAY          EQU 1000 ; default time to show tooltip (in ms)


; Internal properties
@TooltipHandle                  EQU 0   ; Used in subclass
@TooltipMouseOver               EQU 8   ; Used in subclass
@TooltipParent                  EQU 16  ; Used in subclass
@TooltipHoverTime               EQU 24  ; Used in subclass
@TooltipWidth                   EQU 32  ; User specified width of tooltip
@TooltipTitleFont               EQU 40  ; hFont for TitleText
@TooltipMultiline               EQU 48  ; If tooltip is multiline text
@TooltipPaddingWidth            EQU 56  ; Padding width based on font and text height
@TooltipPaddingHeight           EQU 64  ; Padding width based on font and text height
@TooltipTitleText               EQU 72  ; pointer to memory allocated for tooltip text title string

; External public properties


.DATA
szMUITooltipClass               DB 'ModernUI_Tooltip',0     ; Class name for creating our ModernUI_Tooltip control
szMUITooltipFont                DB 'Segoe UI',0             ; Font used for ModernUI_Tooltip
hMUITooltipFont                 DQ 0                        ; handle of font for tooltip text (global)
hMUITooltipInfoTitleFont        DQ 0                        ; handle of font for tooltip text title (global)

szMUITooltipText                DB 2048 DUP (0)             ; buffer for text (global)
qwFadeInAlphaLevel              DQ 0                        ; alpha level (global)


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for ModernUI_Tooltip control
;------------------------------------------------------------------------------
MUITooltipSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUITooltipSetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for ModernUI_Tooltip control
;------------------------------------------------------------------------------
MUITooltipGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUITooltipGetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUITooltipRegister - Registers the ModernUI_Tooltip control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Tooltip
;------------------------------------------------------------------------------
MUITooltipRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUITooltipClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUITooltipClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_TooltipWndProc
    	mov wc.lpfnWndProc, rax
    	Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, rax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, CS_SAVEBITS or CS_DROPSHADOW
        mov wc.cbClsExtra, 0
    	mov wc.cbWndExtra, 16 ; cbWndExtra +0 = QWORD ptr to internal properties memory block, cbWndExtra +8 = QWORD ptr to external properties memory block
    	Invoke RegisterClassEx, addr wc
    .ENDIF  
    ret

MUITooltipRegister ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUITooltipCreate - Returns handle in rax of newly created control
;------------------------------------------------------------------------------
MUITooltipCreate PROC FRAME hWndBuddyControl:QWORD, lpszText:QWORD, qwWidth:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL qwNewStyle:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUITooltipRegister
	
    mov rax, qwStyle
    mov qwNewStyle, rax
    or qwNewStyle, WS_CLIPSIBLINGS or WS_POPUP
    and qwNewStyle, (-1 xor WS_CHILD)
	
    Invoke CreateWindowEx, WS_EX_TOOLWINDOW, Addr szMUITooltipClass, lpszText, dword ptr qwNewStyle, 0, 0, dword ptr qwWidth, 0, hWndBuddyControl, NULL, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUITooltipCreate ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipWndProc - Main processing window for our control
;------------------------------------------------------------------------------
_MUI_TooltipWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    LOCAL rect:RECT
    LOCAL sz:POINT
    LOCAL hParent:QWORD
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        mov rbx, lParam
        ; force style of our tooltip control to remove popup and add child
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        or rax, WS_CHILD or WS_CLIPSIBLINGS
        and rax, (-1 xor WS_POPUP)
        Invoke SetWindowLongPtr, hWin, GWL_STYLE, rax ;WS_CHILD or  WS_CLIPSIBLINGS ; WS_VISIBLE
        
        ; If fade in style flag is set we enable layered window for us to use transparency to fade in
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUITTS_FADEIN
        .IF rax == MUITTS_FADEIN
            Invoke GetWindowLongPtr, hWin, GWL_EXSTYLE
            or rax, WS_EX_TOOLWINDOW or WS_EX_LAYERED
            Invoke SetWindowLongPtr, hWin, GWL_EXSTYLE, rax
        .ENDIF
        
        ; set tooltip text
        mov rbx, lParam
        Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName   
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_TOOLTIP_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_TOOLTIP_PROPERTIES ; external properties
        mov rbx, lParam
        mov rax, (CREATESTRUCT PTR [rbx]).hwndParent
        mov rbx, (CREATESTRUCT PTR [rbx]).lpszName
        Invoke _MUI_TooltipInit, hWin, rax, rbx
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
        mov rax, 0
        ret	
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_TooltipPaint, hWin
        mov rax, 0
        ret

    .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUISetIntProperty, hWin, @TooltipMouseOver, FALSE
        Invoke ShowWindow, hWin, FALSE

    .ELSEIF eax == WM_SETTEXT
        Invoke _MUI_TooltipCheckTextMultiline, hWin, lParam
        .IF rax == TRUE
            Invoke GetWindowLongPtr, hWin, 0 ; check property structures where allocated
            .IF rax != 0
                Invoke _MUI_TooltipSize, hWin, TRUE, lParam
            .ENDIF
        .ELSE
            Invoke GetWindowLongPtr, hWin, 0 ; check property structures where allocated
            .IF rax != 0
                Invoke _MUI_TooltipSize, hWin, FALSE, lParam
            .ENDIF
        .ENDIF
        Invoke DefWindowProc, hWin, uMsg, wParam, lParam
        Invoke InvalidateRect, hWin, NULL, TRUE
        ret

    .ELSEIF eax == WM_SETFONT
        Invoke MUISetExtProperty, hWin, @TooltipFont, lParam
        .IF lParam == TRUE
            Invoke InvalidateRect, hWin, NULL, TRUE
        .ENDIF  

    .ELSEIF eax == WM_SHOWWINDOW
        .IF wParam == TRUE
            Invoke _MUI_TooltipSetPosition, hWin
            
            ; Check if fade in effect is to be shown
            Invoke GetWindowLongPtr, hWin, GWL_STYLE
            and rax, MUITTS_FADEIN
            .IF rax == MUITTS_FADEIN            
                mov qwFadeInAlphaLevel, 0
                Invoke SetTimer, hWin, hWin, 10, NULL
            
            .ELSE
                Invoke GetWindowLongPtr, hWin, GWL_STYLE
                and rax, MUITTS_TIMEOUT
                .IF rax == MUITTS_TIMEOUT
                    Invoke MUIGetExtProperty, hWin, @TooltipShowTimeout
                    .IF rax != 0
                        Invoke SetTimer, hWin, 1, eax, NULL
                    .ELSE ; set default timeout
                        Invoke GetDoubleClickTime
                        mov rbx, 10
                        mul rbx
                        Invoke SetTimer, hWin, 1, eax, NULL                    
                    .ENDIF
                .ENDIF
            .ENDIF    
            ;Invoke SetTimer, hWin, hWin, 200, NULL
        .ELSE
            ; Check if fade in effect is enabled, thus set to 0 transparency for hiding
            Invoke GetWindowLongPtr, hWin, GWL_STYLE
            and rax, MUITTS_FADEIN
            .IF rax == MUITTS_FADEIN         
                mov qwFadeInAlphaLevel, 0
                Invoke SetLayeredWindowAttributes, hWin, 0, byte ptr qwFadeInAlphaLevel, LWA_ALPHA
            .ENDIF
            
        .ENDIF
        mov rax, 0
        ret

    .ELSEIF eax == WM_TIMER
        mov rax, wParam
        .IF rax == hWin
            ; fade in our tooltip window 
            .IF qwFadeInAlphaLevel >= 255d
                Invoke SetLayeredWindowAttributes, hWin, 0, 255d, LWA_ALPHA
                Invoke KillTimer, hWin, hWin
                
                Invoke GetWindowLongPtr, hWin, GWL_STYLE
                and rax, MUITTS_TIMEOUT
                .IF rax == MUITTS_TIMEOUT
                    Invoke MUIGetExtProperty, hWin, @TooltipShowTimeout
                    .IF rax != 0
                        Invoke SetTimer, hWin, 1, eax, NULL
                    .ELSE ; set default timeout
                        Invoke GetDoubleClickTime
                        mov rbx, 10
                        mul rbx
                        Invoke SetTimer, hWin, 1, eax, NULL                    
                    .ENDIF
                .ENDIF
            .ELSE
                Invoke SetLayeredWindowAttributes, hWin, 0, byte ptr qwFadeInAlphaLevel, LWA_ALPHA
                add qwFadeInAlphaLevel, 32d
            .ENDIF    

        .ELSEIF eax == 1
            Invoke ShowWindow, hWin, SW_HIDE
        .ENDIF

	; custom messages start here
	
	.ELSEIF rax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF rax == MUI_SETPROPERTY	
		Invoke MUISetExtProperty, hWin, wParam, lParam
		
        mov rax, wParam
        .IF rax == @TooltipShowDelay
            Invoke MUISetIntProperty, hWin, @TooltipHoverTime, lParam
        .ELSEIF rax == @TooltipInfoTitleText
            ;Invoke MUISetIntProperty, hWin, @TooltipMultiline, TRUE
            ; todo - change size of tooltip to reflect multine with title
            ;Invoke _MUI_TooltipSize, hControl, TRUE
            ;Invoke InvalidateRect, hWin, NULL, TRUE
            Invoke GetWindowText, hWin, Addr szMUITooltipText, SIZEOF szMUITooltipText
            Invoke MUIGetIntProperty, hWin, @TooltipMultiline
            Invoke _MUI_TooltipSize, hWin, rax, Addr szMUITooltipText
            Invoke InvalidateRect, hWin, NULL, TRUE
            
        .ENDIF		
		
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_TooltipWndProc ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipInit - set initial default values
;------------------------------------------------------------------------------
_MUI_TooltipInit PROC FRAME USES RBX hWin:QWORD, hWndParent:QWORD, lpszText:QWORD
    LOCAL ncm:NONCLIENTMETRICS
    LOCAL lfnt:LOGFONT
    LOCAL hFont:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwClassStyle:QWORD
    LOCAL qwShowDelay:QWORD
    LOCAL qwShowTimeout:QWORD

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, MUITTS_NODROPSHADOW
    .IF rax == MUITTS_NODROPSHADOW
        Invoke GetClassLongPtr, hWin, GCL_STYLE
        mov qwClassStyle, rax
        and rax, CS_DROPSHADOW
        .IF rax == CS_DROPSHADOW
            and qwClassStyle,(-1 xor CS_DROPSHADOW)
            Invoke SetClassLongPtr, hWin, GCL_STYLE, qwClassStyle
        .ENDIF
    .ENDIF

    Invoke GetDoubleClickTime
    mov qwShowDelay, rax
    mov rbx, 10
    mul rbx
    mov qwShowTimeout, rax    
    
    ; Set default initial internal property values     
    Invoke MUISetIntProperty, hWin, @TooltipHandle, hWin   
    Invoke MUISetIntProperty, hWin, @TooltipParent, hWndParent
    Invoke MUISetIntProperty, hWin, @TooltipHoverTime, qwShowDelay ;MUI_TOOLTIP_SHOW_DELAY

    ; Set default initial external property values 
    Invoke MUISetExtProperty, hWin, @TooltipTextColor, MUI_RGBCOLOR(51,51,51) ;MUI_RGBCOLOR(242,242,242) ; MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hWin, @TooltipBackColor, MUI_RGBCOLOR(242,241,208) ;MUI_RGBCOLOR(242,241,208) ;MUI_RGBCOLOR(25,25,25) ;MUI_RGBCOLOR(242,241,208)
    Invoke MUISetExtProperty, hWin, @TooltipBorderColor, MUI_RGBCOLOR(190,190,190) ;MUI_RGBCOLOR(0,0,0) ;MUI_RGBCOLOR(190,190,190)
    Invoke MUISetExtProperty, hWin, @TooltipShowDelay, qwShowDelay ;MUI_TOOLTIP_SHOW_DELAY
    Invoke MUISetExtProperty, hWin, @TooltipShowTimeout, qwShowTimeout
    Invoke MUISetExtProperty, hWin, @TooltipOffsetX, 0
    Invoke MUISetExtProperty, hWin, @TooltipOffsetY, 0

   .IF hMUITooltipFont == 0
        mov ncm.cbSize, SIZEOF NONCLIENTMETRICS
        Invoke SystemParametersInfo, SPI_GETNONCLIENTMETRICS, SIZEOF NONCLIENTMETRICS, Addr ncm, 0
        Invoke CreateFontIndirect, Addr ncm.lfMessageFont
        mov hMUITooltipFont, rax
    .ENDIF
    Invoke MUISetExtProperty, hWin, @TooltipFont, hMUITooltipFont

    .IF hMUITooltipInfoTitleFont == 0
        Invoke GetObject, hMUITooltipFont, SIZEOF lfnt, Addr lfnt 
        mov lfnt.lfWeight, FW_BOLD
        Invoke CreateFontIndirect, Addr lfnt
        mov hMUITooltipInfoTitleFont, rax
    .ENDIF
    Invoke MUISetIntProperty, hWin, @TooltipTitleFont, hMUITooltipInfoTitleFont

    Invoke MUISetIntProperty, hWin, @TooltipMouseOver, FALSE
    Invoke GetWindowLongPtr, hWin, 0 ; pointer to internal properties structure
    Invoke SetWindowSubclass, hWndParent, Addr _MUI_TooltipParentSubclass, 1, rax  
    
    Invoke _MUI_TooltipCheckWidthMultiline, hWin
    .IF rax == FALSE
        Invoke _MUI_TooltipCheckTextMultiline, hWin, lpszText
    .ENDIF
    Invoke _MUI_TooltipSize, hWin, rax, lpszText

    ret
_MUI_TooltipInit ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ModernUI_TooltipPaint
;------------------------------------------------------------------------------
_MUI_TooltipPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL lpszTitleText:QWORD

    Invoke IsWindowVisible, hWin
    .IF rax == 0
        ret
    .ENDIF

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke GetClientRect, hWin, Addr rect
	Invoke CreateCompatibleDC, hdc
	mov hdcMem, rax
	Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
	mov hbmMem, rax
	Invoke SelectObject, hdcMem, hbmMem
	mov hOldBitmap, rax
	
	;----------------------------------------------------------
	; Get some property values
	;----------------------------------------------------------	
    Invoke MUIGetExtProperty, hWin, @TooltipInfoTitleText
    mov lpszTitleText, rax
	
    ;----------------------------------------------------------
    ; Background
    ;----------------------------------------------------------
    Invoke _MUI_TooltipPaintBackground, hWin, hdcMem, Addr rect

    ;----------------------------------------------------------
    ; Border
    ;----------------------------------------------------------
    Invoke _MUI_TooltipPaintBorder, hWin, hdcMem, Addr rect

    ;----------------------------------------------------------
    ; Text
    ;----------------------------------------------------------
    .IF lpszTitleText == 0
        Invoke _MUI_TooltipPaintText, hWin, hdcMem, Addr rect
    .ELSE
        Invoke _MUI_TooltipPaintTextAndTitle, hWin, hdcMem, Addr rect
    .ENDIF

    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem		
    
    Invoke EndPaint, hWin, Addr ps

    ret
_MUI_TooltipPaint ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipPaintBackground
;------------------------------------------------------------------------------
_MUI_TooltipPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL LogBrush:LOGBRUSH
    
    Invoke MUIGetExtProperty, hWin, @TooltipBackColor        ; Normal back color
    mov BackColor, rax

    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdc, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdc, dword ptr BackColor
    Invoke FillRect, hdc, lpRect, hBrush

    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF      
    ret

_MUI_TooltipPaintBackground ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipPaintText
;------------------------------------------------------------------------------
_MUI_TooltipPaintText PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL LenText:QWORD    
    LOCAL qwTextStyle:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwPaddingWidth:QWORD
    LOCAL qwPaddingHeight:QWORD
    LOCAL rect:RECT
    LOCAL bMultiline:QWORD

    
    Invoke CopyRect, Addr rect, lpRect

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    
    Invoke MUIGetExtProperty, hWin, @TooltipFont        
    mov hFont, rax
 
    Invoke MUIGetExtProperty, hWin, @TooltipBackColor        ; Normal back color
    mov BackColor, rax    

    Invoke MUIGetExtProperty, hWin, @TooltipTextColor        ; Normal text color
    mov TextColor, rax
    
    Invoke MUIGetIntProperty, hWin, @TooltipPaddingWidth
    mov qwPaddingWidth, rax
    
    Invoke MUIGetIntProperty, hWin, @TooltipPaddingHeight
    mov qwPaddingHeight, rax
    
    Invoke MUIGetIntProperty, hWin, @TooltipMultiline
    mov bMultiline, rax
    
    Invoke GetWindowText, hWin, Addr szMUITooltipText, SIZEOF szMUITooltipText
    .IF rax == 0
        ret
    .ENDIF
    ;Invoke lstrlen, Addr szText
    mov LenText, rax
    
    Invoke SelectObject, hdc, hFont
    mov hOldFont, rax

    Invoke SetBkMode, hdc, OPAQUE
    Invoke SetBkColor, hdc, dword ptr BackColor
    Invoke SetTextColor, hdc, dword ptr TextColor
    
    mov rax, qwPaddingWidth
    shr eax, 1
    add rect.left, eax ;9d
    sub rect.right, eax
    
    mov rax, qwPaddingHeight
    shr eax, 1
    add rect.top, eax
    sub rect.bottom, eax

    .IF bMultiline == TRUE
        mov qwTextStyle, DT_LEFT or DT_WORDBREAK
    .ELSE
        mov qwTextStyle, DT_SINGLELINE or DT_LEFT or DT_VCENTER
    .ENDIF
    Invoke DrawText, hdc, Addr szMUITooltipText, dword ptr LenText, Addr rect, dword ptr qwTextStyle
    
    .IF hOldFont != 0
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF
    
    ret
_MUI_TooltipPaintText ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipPaintTextAndTitle
;------------------------------------------------------------------------------
_MUI_TooltipPaintTextAndTitle PROC FRAME USES RBX hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL hFont:QWORD
    LOCAL hTitleFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL LenText:QWORD    
    LOCAL qwTextStyle:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwPaddingWidth:QWORD
    LOCAL qwPaddingHeight:QWORD
    LOCAL rect:RECT
    LOCAL bMultiline:QWORD
    LOCAL sizetitletext:POINT
    LOCAL lpszTitleText:QWORD

    Invoke CopyRect, Addr rect, lpRect

    Invoke MUIGetExtProperty, hWin, @TooltipFont        
    mov hFont, rax
 
    Invoke MUIGetExtProperty, hWin, @TooltipBackColor        ; Normal back color
    mov BackColor, rax    

    Invoke MUIGetExtProperty, hWin, @TooltipTextColor        ; Normal text color
    mov TextColor, rax
    
    Invoke MUIGetIntProperty, hWin, @TooltipPaddingWidth
    mov qwPaddingWidth, rax
    
    Invoke MUIGetIntProperty, hWin, @TooltipPaddingHeight
    mov qwPaddingHeight, rax
    
    Invoke MUIGetIntProperty, hWin, @TooltipMultiline
    mov bMultiline, rax

    Invoke SetBkMode, hdc, OPAQUE
    Invoke SetBkColor, hdc, dword ptr BackColor
    Invoke SetTextColor, hdc, dword ptr TextColor
    
    mov rax, qwPaddingWidth
    shr eax, 1
    add rect.left, eax
    sub rect.right, eax

    ; Draw Title
    Invoke MUIGetExtProperty, hWin, @TooltipInfoTitleText
    mov lpszTitleText, rax
    .IF rax != 0
        Invoke lstrlen, lpszTitleText
        mov LenText, rax
        .IF rax != 0
        
            Invoke MUIGetIntProperty, hWin, @TooltipTitleFont
            mov hTitleFont, rax
        
            Invoke SelectObject, hdc, hTitleFont
            mov hOldFont, rax
            
            mov rax, qwPaddingHeight
            shr eax, 1
            add rect.top, eax            
            
            Invoke GetTextExtentPoint32, hdc, lpszTitleText, dword ptr LenText, Addr sizetitletext
            xor rax, rax
            mov rbx, qwPaddingHeight
            shr ebx, 1            
            add ebx, sizetitletext.y
            mov eax, rect.bottom
            sub eax, ebx
            sub rect.bottom, eax

            mov qwTextStyle, DT_SINGLELINE or DT_LEFT or DT_VCENTER
            Invoke DrawText, hdc, lpszTitleText, dword ptr LenText, Addr rect, dword ptr qwTextStyle        
    
            .IF hOldFont != 0
                Invoke SelectObject, hdc, hOldFont
                Invoke DeleteObject, hOldFont
            .ENDIF    
            
            ; adjust rect for drawing tooltip text now
            Invoke CopyRect, Addr rect, lpRect
            
            mov rax, qwPaddingWidth
            shr eax, 1
            add rect.left, eax
            sub rect.right, eax
            
            mov rax, qwPaddingHeight
            shr eax, 1
            add rect.top, eax            
            mov eax, sizetitletext.y
            add eax, 4
            add rect.top, eax            

        .ELSE
            mov rax, qwPaddingHeight
            shr eax, 1
            add rect.top, eax
            sub rect.bottom, eax        
        .ENDIF
    
    .ELSE
        mov rax, qwPaddingHeight
        shr eax, 1
        add rect.top, eax
        sub rect.bottom, eax
    .ENDIF
    
    ; Draw main tooltip text
    Invoke GetWindowText, hWin, Addr szMUITooltipText, SIZEOF szMUITooltipText
    .IF rax == 0
        ret
    .ENDIF
    ;Invoke lstrlen, Addr szText
    mov LenText, rax
    Invoke SelectObject, hdc, hFont
    mov hOldFont, rax

    .IF bMultiline == TRUE
        mov qwTextStyle, DT_LEFT or DT_WORDBREAK
    .ELSE
        mov qwTextStyle, DT_SINGLELINE or DT_LEFT or DT_VCENTER
    .ENDIF
    Invoke DrawText, hdc, Addr szMUITooltipText, dword ptr LenText, Addr rect, dword ptr qwTextStyle
    
    .IF hOldFont != 0
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF
    ret
_MUI_TooltipPaintTextAndTitle ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipPaintBorder
;------------------------------------------------------------------------------
_MUI_TooltipPaintBorder PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL BorderColor:QWORD
    LOCAL BorderStyle:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL rect:RECT

    Invoke MUIGetExtProperty, hWin, @TooltipBorderColor
    
    ;mov eax, MUI_RGBCOLOR(190,190,190)
    mov BorderColor, rax
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdc, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdc, dword ptr BorderColor
    Invoke FrameRect, hdc, lpRect, hBrush
    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF      
    
    ret
_MUI_TooltipPaintBorder ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipSize - sets the size of our tooltip control based on text and title
;------------------------------------------------------------------------------
_MUI_TooltipSize PROC FRAME USES RBX hWin:QWORD, bMultiline:QWORD, lpszText:QWORD
    LOCAL hdc:HDC
    LOCAL sizetext:POINT
    LOCAL sizetitletext:POINT
    LOCAL rect:RECT
    LOCAL FinalRect:RECT
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL LenText:QWORD
    LOCAL qwPaddingWidth:QWORD
    LOCAL qwPaddingHeight:QWORD
    LOCAL qwWidth:QWORD
    LOCAL qwHeight:QWORD
    LOCAL lpszTitleText:QWORD
    
    ;PrintText '_MUI_TooltipSize'
    
    ;nvoke GetWindowText, hWin, Addr szText, SIZEOF szText
    .IF lpszText == 0
        ret
    .ENDIF    
    Invoke lstrlen, lpszText
    mov LenText, rax
    .IF eax == 0
        ret
    .ENDIF
    
    mov sizetitletext.x, 0
    mov sizetitletext.y, 0
    mov sizetext.x, 0
    mov sizetext.y, 0
    
    Invoke GetClientRect, hWin, Addr rect
    mov eax, rect.right
    mov qwWidth, rax
    ;PrintDec dwWidth
    
    Invoke GetDC, hWin
    mov hdc, rax
    
    ; Get title text height and width
    mov lpszTitleText, 0
    Invoke MUIGetExtProperty, hWin, @TooltipInfoTitleText
    .IF rax != 0
        mov lpszTitleText, rax
        Invoke lstrlen, lpszTitleText
        mov LenText, rax
        .IF rax != 0
            Invoke MUIGetIntProperty, hWin, @TooltipTitleFont
            mov hFont, rax
            .IF rax == 0
                Invoke MUIGetExtProperty, hWin, @TooltipFont
                mov hFont, rax
                .IF rax == 0
                    Invoke SendMessage, hWin, WM_GETFONT, 0, 0
                    mov hFont, rax
                .ENDIF
            .ENDIF
            Invoke SelectObject, hdc, hFont
            mov hOldFont, rax
            Invoke GetTextExtentPoint32, hdc, lpszTitleText, dword ptr LenText, Addr sizetitletext
            .IF hOldFont != 0
                Invoke SelectObject, hdc, hOldFont
                Invoke DeleteObject, hOldFont
            .ENDIF                
        .ENDIF
    .ENDIF

    ; Get main text height and width
    Invoke lstrlen, lpszText
    mov LenText, rax    
    Invoke MUIGetExtProperty, hWin, @TooltipFont
    mov hFont, rax
    .IF rax == 0
        Invoke SendMessage, hWin, WM_GETFONT, 0, 0
        mov hFont, rax
    .ENDIF
    Invoke SelectObject, hdc, hFont
    mov hOldFont, rax
    Invoke GetTextExtentPoint32, hdc, lpszText, dword ptr LenText, Addr sizetext
    .IF hOldFont != 0
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF  

    ; calc final rect size
    xor rax, rax
    mov eax, sizetext.y
    ;shr eax, 1
    and eax, 0FFFFFFFEh
    mov qwPaddingHeight, rax
    add eax, 4
    mov qwPaddingWidth, rax
    ;PrintDec dwPaddingWidth
    ;PrintDec dwPaddingHeight
    
    Invoke MUISetIntProperty, hWin, @TooltipPaddingWidth, qwPaddingWidth
    Invoke MUISetIntProperty, hWin, @TooltipPaddingHeight, qwPaddingHeight

    
    mov rax, qwWidth 
    .IF rax == 0 && bMultiline == FALSE ;sdword ptr eax > sizetext.x
        xor rax, rax
        mov eax, sizetext.x
        .IF eax > sizetitletext.x
            mov eax, sizetext.x
        .ELSE
            mov eax, sizetitletext.x
        .ENDIF
        add rax, qwPaddingWidth
        mov qwWidth, rax

        mov eax, sizetext.y
        ;add eax, dwPadding
        add rax, qwPaddingHeight
        .IF lpszTitleText != 0
            add eax, sizetitletext.y
            add eax, 4
        .ENDIF
        mov qwHeight, rax
        
        
    .ELSEIF eax == 0 && bMultiline == TRUE
        ;PrintText 'dwWidth == 0 && bMultiline == TRUE'
        mov rax, qwPaddingWidth
        shr eax, 1
        mov FinalRect.left, eax
        
        mov rax, qwPaddingHeight
        shr eax, 1
        mov FinalRect.top, eax
        
        mov eax, 250d
        ;sub eax, dwPaddingWidth
        mov FinalRect.right, eax
        mov FinalRect.bottom, 0
        
        Invoke DrawText, hdc, lpszText, dword ptr LenText, Addr FinalRect, DT_CALCRECT ;or DT_WORDBREAK
        
        mov rax, qwPaddingHeight
        shr eax, 1
        add eax, FinalRect.bottom
        sub eax, 4
        mov qwHeight, rax

        mov rax, qwPaddingWidth
        shr eax, 1
        add eax, FinalRect.right
        mov qwWidth, rax
    
    .ELSEIF sqword ptr rax > 0 && bMultiline == FALSE
        xor rax, rax
        mov eax, sizetext.x
        .IF eax > sizetitletext.x
            mov eax, sizetext.x
        .ELSE
            mov eax, sizetitletext.x
        .ENDIF
        add rax, qwPaddingWidth
        mov qwWidth, rax

        mov eax, sizetext.y
        add rax, qwPaddingHeight
        .IF lpszTitleText != 0
            add eax, sizetitletext.y
            add eax, 4
        .ENDIF
        mov qwHeight, rax
     
    .ELSEIF sqword ptr rax > 0 && bMultiline == TRUE
        ;PrintText 'dwWidth > 0 && bMultiline == TRUE'
        mov rax, qwPaddingWidth
        shr eax, 1
        mov FinalRect.left, eax
        
        mov rax, qwPaddingHeight
        shr eax, 1
        .IF lpszTitleText != 0
            add eax, sizetitletext.y
            add eax, 4
        .ENDIF
        mov FinalRect.top, eax
        
        mov rbx, qwPaddingWidth
        shr rbx, 1
        mov rax, qwWidth
        sub rax, rbx
        mov FinalRect.right, eax
        mov FinalRect.bottom, 0
        
        Invoke DrawText, hdc, lpszText, dword ptr LenText, Addr FinalRect, DT_CALCRECT ;or DT_WORDBREAK

        mov rax, qwPaddingHeight
        shr eax, 1
        add eax, FinalRect.bottom
        sub eax, 4
        mov qwHeight, rax
        
        mov rax, qwPaddingWidth
        shr eax, 1
        add eax, FinalRect.right
        mov qwWidth, rax
    
    .ENDIF
    
    ;PrintDec dwWidth
    ;PrintDec dwHeight
    



    
    
    
    Invoke ReleaseDC, hWin, hdc
    
    ;mov eax, sz.x
    ;add eax, 18d
    ;mov rect.right, eax
    ;mov eax, sz.y
    ;add eax, 12d
    ;mov rect.bottom, eax
    
    ;Invoke SetWindowPos, hWin, HWND_TOP, 0, 0, rect.right, rect.bottom,  SWP_NOACTIVATE or SWP_NOSENDCHANGING or SWP_NOZORDER or SWP_NOMOVE
    Invoke SetWindowPos, hWin, HWND_TOP, 0, 0, qwWidth, qwHeight,  SWP_NOACTIVATE or SWP_NOSENDCHANGING or SWP_NOZORDER or SWP_NOMOVE
    
    
    ;.IF eax != 0 ; check WM_CREATE has set out property structures (otherwise call from WM_SETTEXT will crash)
        Invoke _MUI_TooltipSetPosition, hWin
    ;.ENDIF
    
    ret

_MUI_TooltipSize ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets position of the tooltip relative to buddy control or mouse position
;------------------------------------------------------------------------------
_MUI_TooltipSetPosition PROC FRAME USES RBX hWin:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    LOCAL rect:RECT
    LOCAL tiprect:RECT
    LOCAL pt:POINT
    LOCAL qwOffsetX:QWORD
    LOCAL qwOffsetY:QWORD

    Invoke MUIGetIntProperty, hWin, @TooltipParent
    mov hParent, rax

    Invoke MUIGetExtProperty, hWin, @TooltipOffsetX
    mov qwOffsetX, rax
    Invoke MUIGetExtProperty, hWin, @TooltipOffsetY
    mov qwOffsetY, rax    

    Invoke GetWindowRect, hParent, Addr rect
    Invoke GetClientRect, hWin, Addr tiprect

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, MUITTS_POS_RIGHT or MUITTS_POS_ABOVE or MUITTS_POS_LEFT or MUITTS_POS_MOUSE
    
    .IF eax == 0 ; MUITTS_POS_BELOW
        mov eax, rect.bottom
        mov ebx, rect.top
        sub eax, ebx
        add eax, 2
        add rect.top, eax

    .ELSEIF eax == MUITTS_POS_RIGHT
        mov eax, rect.right
        add eax, 2
        mov rect.left, eax

    .ELSEIF eax == MUITTS_POS_ABOVE
        mov eax, tiprect.bottom
        ;mov ebx, tiprect.top
        ;sub eax, ebx
        add eax, 2
        sub rect.top, eax

    .ELSEIF eax == MUITTS_POS_LEFT
        mov eax, tiprect.right
        ;mov ebx, tiprect.left
        ;sub eax, ebx
        add eax, 2
        sub rect.left, eax

    .ELSEIF eax == MUITTS_POS_MOUSE
        Invoke GetCursorPos, Addr pt
        ;Invoke ScreenToClient, hParent, Addr pt
        mov eax, pt.x
        add eax, 8
        mov rect.left, eax
        mov eax, pt.y
        add eax, 8
        mov rect.top, eax

    .ELSE
        ;PrintText 'Unknown Pos'

    .ENDIF

    .IF qwOffsetX != 0
        mov eax, rect.left
        add rax, qwOffsetX
        mov rect.left, eax
    .ENDIF

    ;PrintDec dwOffsetY
    ;PrintDec rect.top
    .IF qwOffsetY != 0
        mov eax, rect.top
        add rax, qwOffsetY
        mov rect.top, eax
    .ENDIF
    ;PrintDec rect.top

    Invoke SetWindowPos, hWin, HWND_TOP, rect.left, rect.top, 0, 0,  SWP_NOACTIVATE or SWP_NOSENDCHANGING or SWP_NOZORDER or SWP_NOSIZE

    ret
_MUI_TooltipSetPosition ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Returns TRUE if width > 0 (assumes multiline usage)
;------------------------------------------------------------------------------
_MUI_TooltipCheckWidthMultiline PROC FRAME USES RBX hWin:QWORD
    LOCAL rect:RECT
    LOCAL bMultiline:QWORD

    mov bMultiline, FALSE
    Invoke GetClientRect, hWin, Addr rect
    mov eax, rect.right
    .IF eax != 0 
        Invoke MUISetIntProperty, hWin, @TooltipMultiline, TRUE
        mov bMultiline, TRUE
    .ENDIF
    mov rax, bMultiline
    ret
_MUI_TooltipCheckWidthMultiline ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Returns TRUE if CR LF found in string, otherwise returns FALSE
;------------------------------------------------------------------------------
_MUI_TooltipCheckTextMultiline PROC FRAME USES RBX hWin:QWORD, lpszText:QWORD
    LOCAL lenText:QWORD
    LOCAL Cnt:QWORD
    LOCAL bMultiline:QWORD

    .IF lpszText == 0
        ret
    .ENDIF
    Invoke lstrlen, lpszText
    mov lenText, rax

    mov bMultiline, FALSE
    mov rbx, lpszText
    mov Cnt, 0
    mov rax, 0
    .WHILE rax < lenText
        movzx rax, byte ptr [rbx]
        .IF al == 0
            mov bMultiline, FALSE
            .BREAK
        .ELSEIF al == 10 || al == 13
            Invoke MUISetIntProperty, hWin, @TooltipMultiline, TRUE
            mov bMultiline, TRUE
            .BREAK 
        .ENDIF
        inc rbx
        inc Cnt
        mov rax, Cnt
    .ENDW
    mov rax, bMultiline
    ret
_MUI_TooltipCheckTextMultiline ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TooltipParentSubclass - sublcass buddy/parent of the tooltip
;------------------------------------------------------------------------------
_MUI_TooltipParentSubclass PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM, uIdSubclass:UINT, qwRefData:QWORD
    LOCAL TE:TRACKMOUSEEVENT

    mov eax, uMsg
    .IF eax == WM_NCDESTROY
        Invoke RemoveWindowSubclass, hWin, Addr _MUI_TooltipParentSubclass, uIdSubclass
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam 
        ret

    .ELSEIF eax == WM_MOUSEMOVE
        mov rbx, qwRefData
        mov rax, (_MUI_TOOLTIP_PROPERTIES ptr [rbx]).qwMouseOver
        .IF rax == FALSE
            mov rax, TRUE
            mov (_MUI_TOOLTIP_PROPERTIES ptr [ebx]).qwMouseOver, rax
            mov rax, (_MUI_TOOLTIP_PROPERTIES ptr [rbx]).qwTooltipHandle
            ;Invoke ShowWindow, eax, TRUE
            ;Invoke AnimateWindow, eax, 200, AW_BLEND
            mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
            mov TE.dwFlags, TME_LEAVE or TME_HOVER
            mov rax, hWin
            mov TE.hwndTrack, rax
            mov rax, (_MUI_TOOLTIP_PROPERTIES ptr [ebx]).qwTooltipHoverTime
            mov TE.dwHoverTime, eax;HOVER_DEFAULT ;NULL
            Invoke TrackMouseEvent, Addr TE
        .ENDIF

    .ELSEIF eax == WM_MOUSEHOVER
        mov rbx, qwRefData
        mov rax, (_MUI_TOOLTIP_PROPERTIES ptr [rbx]).qwMouseOver
        .IF rax == TRUE
            mov rax, TRUE
            mov (_MUI_TOOLTIP_PROPERTIES ptr [rbx]).qwMouseOver, rax
            mov rax, (_MUI_TOOLTIP_PROPERTIES ptr [rbx]).qwTooltipHandle
            Invoke ShowWindow, rax, TRUE
            ;Invoke AnimateWindow, eax, 200, AW_BLEND
            mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
            mov TE.dwFlags, TME_LEAVE
            mov rax, hWin
            mov TE.hwndTrack, rax
            mov TE.dwHoverTime, HOVER_DEFAULT ;NULL
            Invoke TrackMouseEvent, Addr TE
        .ENDIF
    
    .ELSEIF eax == WM_MOUSELEAVE
        mov rbx, qwRefData
        mov rax, (_MUI_TOOLTIP_PROPERTIES ptr [rbx]).qwTooltipHandle
        Invoke ShowWindow, rax, FALSE
        ;Invoke AnimateWindow, eax, 200, AW_BLEND or AW_HIDE
        mov rax, FALSE
        mov (_MUI_TOOLTIP_PROPERTIES ptr [rbx]).qwMouseOver, rax        

    .ENDIF
    Invoke DefSubclassProc, hWin, uMsg, wParam, lParam         
    ret
_MUI_TooltipParentSubclass ENDP






END
