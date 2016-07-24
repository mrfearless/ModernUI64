;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_CaptionBar x64 v1.0.0.0
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

;DEBUG64 EQU 1

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
include CommCtrl.INC

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_CaptionBar.inc

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------


_MUI_CaptionBarWndProc				        PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_CaptionBarInit                         PROTO :QWORD
_MUI_CaptionBarPaint					    PROTO :QWORD
_MUI_CaptionBarReposition                   PROTO :QWORD
_MUI_CaptionBarParentSubClassProc           PROTO :HWND, :UINT, :WPARAM, :LPARAM, :QWORD, :QWORD
_MUI_CaptionBarSetSysButtonProperty         PROTO :QWORD, :QWORD, :QWORD

_MUI_CreateCaptionBarSysButtons             PROTO :QWORD, :QWORD
_MUI_CreateSysButton                        PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_SysButtonWndProc                       PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_SysButtonInit                          PROTO :QWORD
_MUI_SysButtonCleanup                       PROTO :QWORD
_MUI_SysButtonPaint                         PROTO :QWORD
_MUI_SysButtonGetIconSize                   PROTO :QWORD, :QWORD, :QWORD

_MUI_ApplyMUIStyleToDialog                  PROTO :QWORD, :QWORD

;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; CaptionBar External Properties
MUI_CAPTIONBAR_PROPERTIES				    STRUCT 8
	dqTextColor							    DQ ?
	dqTextFont							    DQ ?
	dqBackColor							    DQ ?
	dqSysButtonTextRollColor                DQ ?
	dqSysButtonBackRollColor                DQ ?
	dqSysButtonsWidth                       DQ ? ; defaults to 32
	dqSysButtonsHeight                      DQ ? ; defaults to 28
	dqBtnIcoMin                             DQ ?
	dqBtnIcoMinAlt                          DQ ?
	dqBtnIcoMax                             DQ ?
	dqBtnIcoMaxAlt                          DQ ?
	dqBtnIcoRes                             DQ ?
	dqBtnIcoResAlt                          DQ ?
	dqBtnIcoClose                           DQ ?
	dqBtnIcoCloseAlt                        DQ ?
	dqDllInstance                           DQ ?
MUI_CAPTIONBAR_PROPERTIES				    ENDS

; CaptionBar Internal Poperties
_MUI_CAPTIONBAR_PROPERTIES				    STRUCT 8
	dqEnabledState						    DQ ?
	dqMouseOver							    DQ ?
	hSysButtonClose                         DQ ?
	hSysButtonMax                           DQ ?
	hSysButtonRes                           DQ ?
	hSysButtonMin                           DQ ?
	dqNoMoveWindow                          DQ ?
	dqUseIcons                              DQ ?
_MUI_CAPTIONBAR_PROPERTIES				    ENDS

; SysButton External Properties
MUI_SYSBUTTON_PROPERTIES                    STRUCT 8
	dqTextColor							    DQ ?
	dqTextRollColor                         DQ ?
	dqBackColor							    DQ ?
	dqBackRollColor                         DQ ?
    dqSysButtonType                         DQ ?
    dqIco                                   DQ ?
    dqIcoAlt                                DQ ?
MUI_SYSBUTTON_PROPERTIES                    ENDS

; SysButton Internal Properties
_MUI_SYSBUTTON_PROPERTIES                   STRUCT 8
    dqSysButtonFont						    DQ ?
	dqEnabledState						    DQ ?
	dqMouseOver							    DQ ?
    dqUseIcons                              DQ ?	
_MUI_SYSBUTTON_PROPERTIES                   ENDS


.CONST
align 8
MUI_SYSBUTTON_WIDTH                         EQU 32d
MUI_SYSBUTTON_HEIGHT                        EQU 28d


; CaptionBar Internal Properties
@CaptionBarEnabledState				        EQU 0
@CaptionBarMouseOver					    EQU 8
@CaptionBar_hSysButtonClose                 EQU 16
@CaptionBar_hSysButtonMax                   EQU 24
@CaptionBar_hSysButtonRes                   EQU 32
@CaptionBar_hSysButtonMin                   EQU 40
@CaptionBarNoMoveWindow                     EQU 48
@CaptionBarUseIcons                         EQU 56

; SysButton Internal Properties
@SysButtonFont                              EQU 0
@SysButtonEnabledState						EQU 8
@SysButtonMouseOver							EQU 16
@SysButtonUseIcons                          EQU 24

; SysButton External Properties
@SysButtonTextColor							EQU 0 
@SysButtonTextRollColor                     EQU 8
@SysButtonBackColor							EQU 16
@SysButtonBackRollColor                     EQU 24
@SysButtonType                              EQU 32
@SysButtonIco                               EQU 40
@SysButtonIcoAlt                            EQU 48

.DATA
align 8
szMUICaptionBarClass					    DB 'ModernUICaptionBar',0   ; Class name for our CaptionBar control
szMUISysButtonClass                         DB 'ModernUISysButton',0    ; Class name for our system buttons (min/max/restore or close buttons)
szMUISysButtonFont                          DB 'Marlett',0              ; System font used for drawing min/max/restore/close glyphs from marlett font
szMUICaptionBarFont                         DB 'Segoe UI',0             ; Font used for caption text
hMUISysButtonFont                           DQ 0                        ; Handle to system button font (marlett)
hMUICaptionBarFont                          DQ 0                        ; Handle to caption button font (segoe ui)
szMUISysMinButton                           DB '0',0                    ; Minimize button glyph from Marlett font
szMUISysMaxButton                           DB '1',0                    ; Maximize button glyph from Marlett font
szMUISysResButton                           DB '2',0                    ; Restore button glyph from Marlett font
szMUISysCloseButton                         DB 'r',0                    ; Close/exit button glyph from Marlett font
szMUISysResizeGrip                          DB 'o',0                    ; Resize grip button glyph from Marlett font


.CODE

;-------------------------------------------------------------------------------------
; Set property for CaptionBar control
;-------------------------------------------------------------------------------------
MUICaptionBarSetProperty PROC FRAME hCaptionBar:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    Invoke SendMessage, hCaptionBar, MUI_SETPROPERTY, dqProperty, dqPropertyValue
    ret
MUICaptionBarSetProperty ENDP


;-------------------------------------------------------------------------------------
; Get property for CaptionBar control
;-------------------------------------------------------------------------------------
MUICaptionBarGetProperty PROC FRAME hCaptionBar:QWORD, dqProperty:QWORD
    Invoke SendMessage, hCaptionBar, MUI_GETPROPERTY, dqProperty, NULL
    ret
MUICaptionBarGetProperty ENDP


;-------------------------------------------------------------------------------------
; MUICaptionBarRegister - Registers the ModernUI_CaptionBar control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_CaptionBar
;-------------------------------------------------------------------------------------
MUICaptionBarRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
	Invoke RtlZeroMemory, Addr wc, SIZEOF WNDCLASSEX
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx, hinstance, Addr szMUICaptionBarClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUICaptionBarClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
        lea rax, _MUI_CaptionBarWndProc
    	mov wc.lpfnWndProc, rax
    	Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, rax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, CS_DBLCLKS ;NULL
        mov wc.cbClsExtra, 0
    	mov wc.cbWndExtra, 16d ; cbWndExtra +0 = QWORD ptr to internal properties memory block, cbWndExtra +8 = QWORD ptr to external properties memory block
    	Invoke RegisterClassEx, addr wc
    .ENDIF
    ret

MUICaptionBarRegister ENDP


;-------------------------------------------------------------------------------------
; MUICaptionBarCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUICaptionBarCreate PROC FRAME USES rbx hWndParent:QWORD, lpszCaptionText:QWORD, dqCaptionHeight:QWORD, dqResourceID:QWORD, dqStyle:QWORD
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL rect:RECT
	LOCAL dqControlStyle:QWORD

    Invoke GetModuleHandle, NULL
    mov hinstance, rax
    ;PrintQWORD rax
	Invoke MUICaptionBarRegister
    
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN.
	mov rax, dqStyle
	or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
	mov dqControlStyle, rax

    Invoke GetWindowRect, hWndParent, Addr rect
    xor rax, rax
    mov eax, rect.right
    mov ebx, rect.left
    sub eax, ebx
	
    Invoke CreateWindowEx, NULL, Addr szMUICaptionBarClass, lpszCaptionText, dword ptr dqControlStyle, 0, 0, eax, dword ptr dqCaptionHeight, hWndParent, dqResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	;PrintQWORD rax
	mov rax, hControl
    ret
MUICaptionBarCreate ENDP


;-------------------------------------------------------------------------------------
; _MUI_CaptionBarWndProc - Main processing window for our CaptionBar control
;-------------------------------------------------------------------------------------
_MUI_CaptionBarWndProc PROC FRAME USES rbx hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    LOCAL wp:WINDOWPLACEMENT
    LOCAL hParent:QWORD
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        Invoke GetParent, hWin
        mov hParent, rax
        mov rbx, lParam
		; sets text of our CaptionBar
        Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName
        ; Set main window title
        Invoke SetWindowText, hParent, (CREATESTRUCT PTR [rbx]).lpszName
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_CAPTIONBAR_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_CAPTIONBAR_PROPERTIES ; external properties
		Invoke _MUI_CaptionBarInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8

    .ELSEIF eax == WM_COMMAND
        mov rax, wParam
        and rax, 0FFFFh
        .IF eax == 1 ; close button
            Invoke GetParent, hWin
            Invoke SendMessage, rax, WM_CLOSE, 0, 0
            ret
        .ELSEIF eax == 2 ; max button
            Invoke GetParent, hWin
            Invoke ShowWindow, rax, SW_MAXIMIZE
            Invoke _MUI_CaptionBarReposition, hWin
            ret            
        .ELSEIF eax == 3 ; res button
            Invoke GetParent, hWin
            Invoke ShowWindow, rax, SW_RESTORE
            Invoke _MUI_CaptionBarReposition, hWin
            ret
        .ELSEIF eax == 4 ; min button
            Invoke GetParent, hWin
            Invoke ShowWindow, rax, SW_MINIMIZE
            ret
        .ENDIF
        xor rax, rax
        ret

    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_CaptionBarPaint, hWin
        mov rax, 0
        ret
    
    .ELSEIF eax == WM_LBUTTONDBLCLK
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUICS_NOMAXBUTTON
        .IF rax != MUICS_NOMAXBUTTON  
            ; only needed if max/res button is present, otherwise doubleclick caption bar should do nothing. 
            Invoke GetParent, hWin
            mov hParent, rax
            Invoke GetWindowPlacement, hParent, Addr wp
            .IF wp.showCmd == SW_SHOWNORMAL    
                Invoke ShowWindow, hParent, SW_MAXIMIZE
                Invoke _MUI_CaptionBarReposition, hWin
                ret
            .ELSEIF wp.showCmd == SW_SHOWMAXIMIZED
                Invoke ShowWindow, hParent, SW_RESTORE
                Invoke _MUI_CaptionBarReposition, hWin
                ret
            .ELSE
                mov rax, 0
            .ENDIF
        .ELSE
            mov rax, 0
        .ENDIF

    .ELSEIF eax == WM_NCHITTEST
        Invoke MUIGetIntProperty, hWin, @CaptionBarNoMoveWindow
        .IF rax == TRUE
            Invoke GetParent, hWin
            Invoke SendMessage, rax, WM_NCLBUTTONDOWN, HTCAPTION, 0
        .ENDIF

   .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUIGetIntProperty, hWin, @CaptionBarEnabledState
        .IF rax == TRUE   
    		Invoke MUISetIntProperty, hWin, @CaptionBarMouseOver , TRUE
    		.IF rax != TRUE
    		    Invoke InvalidateRect, hWin, NULL, TRUE
    		    mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
    		    mov TE.dwFlags, TME_LEAVE
    		    mov rax, hWin
    		    mov TE.hwndTrack, rax
    		    mov TE.dwHoverTime, NULL
    		    Invoke TrackMouseEvent, Addr TE
    		.ENDIF
        .ENDIF
        
    .ELSEIF eax == WM_MOUSELEAVE
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseOver , FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseOver , FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
	
	.ELSEIF eax == WM_SIZE
	    Invoke _MUI_CaptionBarReposition, hWin
	    mov rax, 0
	    ret
	
	; custom messages start here
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY
		Invoke MUISetExtProperty, hWin, wParam, lParam
		
		; also set child system button properties as well if they apply
		Invoke _MUI_CaptionBarSetSysButtonProperty, hWin, wParam, lParam
		
		.IF wParam == @CaptionBarBtnWidth || wParam == @CaptionBarBtnHeight
            Invoke _MUI_CaptionBarReposition, hWin
		.ENDIF
		ret

    .ENDIF
	Invoke DefWindowProc, hWin, uMsg, wParam, lParam

    ret
_MUI_CaptionBarWndProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_CaptionBarParentSubClassProc - Subclass for caption bar parent window 
; dqRefData is the handle to our CaptionBar control in this subclass proc
;-------------------------------------------------------------------------------------
_MUI_CaptionBarParentSubClassProc PROC FRAME hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM, uIdSubclass:QWORD, dqRefData:QWORD
    LOCAL wp:WINDOWPLACEMENT
    LOCAL dqStyle:QWORD
    
    mov eax, uMsg
    .IF eax == WM_NCDESTROY
        Invoke RemoveWindowSubclass, hWin, Addr _MUI_CaptionBarParentSubClassProc, uIdSubclass ; remove subclass before control destroyed.
        ret
    
    ; Handle resize of dialog/window and invalidate it if we are painting a border via MUIPaintBackground
    .ELSEIF eax == WM_NCCALCSIZE
        Invoke InvalidateRect, hWin, NULL, TRUE
    
    .ELSEIF eax == WM_THEMECHANGED
        Invoke GetWindowLongPtr, dqRefData, GWL_STYLE
        mov dqStyle, rax
        and rax, MUICS_WINNOMUISTYLE
        .IF rax != MUICS_WINNOMUISTYLE
            ; use dropshadow - unless MUICS_WINNODROPSHADOW is specified
            mov rax, dqStyle
            and rax, MUICS_WINNODROPSHADOW
            .IF rax == MUICS_WINNODROPSHADOW
                Invoke _MUI_ApplyMUIStyleToDialog, hWin, FALSE
            .ELSE
                Invoke _MUI_ApplyMUIStyleToDialog, hWin, TRUE
            .ENDIF
        .ENDIF
    
    ; If user pulls caption down whilst maximized this will be caught by this handler and we can adjust the CaptionBar control to reflect the 
    ; restore state it will be in. Or if user programmatically changes window this should catch it as well.
    .ELSEIF eax == WM_SIZE
        mov rax, wParam
        .IF rax == SIZE_MAXIMIZED
            Invoke SendMessage, dqRefData, WM_SIZE, 0, 0 ; force reposition of CaptionBar and its child controls
        .ELSEIF rax == SIZE_RESTORED
            Invoke SendMessage, dqRefData, WM_SIZE, 0, 0 ; force reposition of CaptionBar and its child controls
        .ENDIF
    .ENDIF
    
    Invoke DefSubclassProc, hWin, uMsg, wParam, lParam 
    ret        
_MUI_CaptionBarParentSubClassProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_CaptionBarInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_CaptionBarInit PROC FRAME hCaptionBar:QWORD
    LOCAL ncm:NONCLIENTMETRICS
    LOCAL lfnt:LOGFONT
    LOCAL hFont:QWORD
    LOCAL hParent:QWORD
    LOCAL dqStyle:QWORD
    
    Invoke GetParent, hCaptionBar
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hCaptionBar, GWL_STYLE
    mov dqStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, dqStyle
        or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov dqStyle, rax
        Invoke SetWindowLongPtr, hCaptionBar, GWL_STYLE, dqStyle
    .ENDIF
    ;PrintDec dqStyle
    
    ; Apply ModernUI style to window/dialog - unless MUICS_WINNOMUISTYLE is specified
    mov rax, dqStyle
    and rax, MUICS_WINNOMUISTYLE
    .IF rax != MUICS_WINNOMUISTYLE
        
        ; use dropshadow - unless MUICS_WINNODROPSHADOW is specified
        mov rax, dqStyle
        and rax, MUICS_WINNODROPSHADOW
        .IF rax == MUICS_WINNODROPSHADOW
            Invoke _MUI_ApplyMUIStyleToDialog, hParent, FALSE
        .ELSE
            Invoke _MUI_ApplyMUIStyleToDialog, hParent, TRUE
        .ENDIF
    .ENDIF
    
    ; Allow caption bar to be clicked and held to move window?
    mov rax, dqStyle
    and rax, MUICS_NOMOVEWINDOW
    .IF rax == MUICS_NOMOVEWINDOW    
        Invoke MUISetIntProperty, hCaptionBar, @CaptionBarNoMoveWindow, TRUE
    .ELSE
        Invoke MUISetIntProperty, hCaptionBar, @CaptionBarNoMoveWindow, TRUE
    .ENDIF
    
    ; Check if to use icons or not?
    mov rax, dqStyle
    and rax, MUICS_USEICONSFORBUTTONS
    .IF rax == MUICS_USEICONSFORBUTTONS  
        Invoke MUISetIntProperty, hCaptionBar, @CaptionBarUseIcons, TRUE
    .ELSE
        Invoke MUISetIntProperty, hCaptionBar, @CaptionBarUseIcons, FALSE
    .ENDIF
    
    ; Set default initial external property values     
    Invoke MUISetExtProperty, hCaptionBar, @CaptionBarTextColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(21,133,181)
    Invoke MUISetExtProperty, hCaptionBar, @CaptionBarBtnWidth, MUI_SYSBUTTON_WIDTH ;32d
    Invoke MUISetExtProperty, hCaptionBar, @CaptionBarBtnHeight, MUI_SYSBUTTON_HEIGHT ;28d
    Invoke MUISetExtProperty, hCaptionBar, @CaptionBarDllInstance, 0
    
    .IF hMUICaptionBarFont == 0
    	mov ncm.cbSize, SIZEOF NONCLIENTMETRICS
    	Invoke SystemParametersInfo, SPI_GETNONCLIENTMETRICS, SIZEOF NONCLIENTMETRICS, Addr ncm, 0
    	Invoke CreateFontIndirect, Addr ncm.lfMessageFont
    	mov hFont, rax
	    Invoke GetObject, hFont, SIZEOF lfnt, Addr lfnt
	    mov lfnt.lfHeight, -12d
	    mov lfnt.lfWeight, FW_NORMAL ;FW_BOLD
	    Invoke CreateFontIndirect, Addr lfnt
        mov hMUICaptionBarFont, rax
        Invoke DeleteObject, hFont
    .ENDIF
    Invoke MUISetExtProperty, hCaptionBar, @CaptionBarTextFont, hMUICaptionBarFont

    Invoke _MUI_CreateCaptionBarSysButtons, hCaptionBar, hParent
    
    mov rax, dqStyle
    and rax, MUICS_NOMAXBUTTON
    .IF rax != MUICS_NOMAXBUTTON
        ; only need to subclass to handle catching restore/maximize - no need if max/res button is not present 
        Invoke SetWindowSubclass, hParent, Addr _MUI_CaptionBarParentSubClassProc, hCaptionBar, hCaptionBar
    .ENDIF

    ret

_MUI_CaptionBarInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_CaptionBarPaint - main CaptionBar painting
;-------------------------------------------------------------------------------------
_MUI_CaptionBarPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL MouseOver:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL dqStyle:QWORD
    LOCAL szText[256]:BYTE    

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
	; Get properties
	;----------------------------------------------------------
	;Invoke _MUIGetIntProperty, hWin, @CaptionBarStyle
	;mov dqStyle, rax
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov dqStyle, rax	
	
	Invoke MUIGetIntProperty, hWin, @CaptionBarMouseOver
    mov MouseOver, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarTextColor        ; normal text color
    mov TextColor, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarBackColor        ; normal back color
    mov BackColor, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarTextFont        
    mov hFont, rax
	
	;----------------------------------------------------------
	; Fill background
	;----------------------------------------------------------
    Invoke SetBkMode, hdcMem, OPAQUE
    Invoke SetBkColor, hdcMem, dword ptr BackColor
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr BackColor
    Invoke FillRect, hdcMem, Addr rect, hBrush


    mov rax, dqStyle
    and rax, MUICS_NOCAPTIONTITLETEXT
    .IF rax != MUICS_NOCAPTIONTITLETEXT
    	;----------------------------------------------------------
    	; Draw Text
    	;----------------------------------------------------------
    	Invoke SelectObject, hdcMem, hFont
        mov hOldFont, rax
        Invoke GetWindowText, hWin, Addr szText, sizeof szText
        Invoke SetTextColor, hdcMem, dword ptr TextColor
        
        mov rax, dqStyle
        and rax, MUICS_CENTER
        .IF rax == MUICS_CENTER
            Invoke DrawText, hdcMem, Addr szText, -1, Addr rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER
        .ELSE
            add rect.left, 6d
            Invoke DrawText, hdcMem, Addr szText, -1, Addr rect, DT_SINGLELINE or DT_LEFT or DT_VCENTER
            sub rect.left, 6d
        .ENDIF
    .ENDIF
    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    Invoke DeleteDC, hdcMem
    Invoke DeleteObject, hbmMem
    .IF hOldBitmap != 0
        Invoke DeleteObject, hOldBitmap
    .ENDIF		
    .IF hOldFont != 0
        Invoke DeleteObject, hOldFont
    .ENDIF
    .IF hOldBrush != 0
        Invoke DeleteObject, hOldBrush
    .ENDIF        
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    
    Invoke EndPaint, hWin, Addr ps
	

    ret
_MUI_CaptionBarPaint ENDP


;-------------------------------------------------------------------------------------
; _MUI_CreateCaptionBarSysButtons - create all specified system buttons
;-------------------------------------------------------------------------------------
_MUI_CreateCaptionBarSysButtons PROC FRAME USES rbx hCaptionBar:QWORD, hCaptionBarParent:QWORD
    LOCAL wp:WINDOWPLACEMENT
    LOCAL dqLeftOffset:QWORD
    LOCAL rect:RECT
    LOCAL xpos:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    LOCAL dqSysButtonWidth:QWORD
    LOCAL dqSysButtonHeight:QWORD
    LOCAL dqStyle:QWORD
    LOCAL dqUseIcons:QWORD
    
    
    Invoke GetWindowRect, hCaptionBar, Addr rect
    
    Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnWidth
    mov dqSysButtonWidth, rax
    mov dqLeftOffset, rax ;32d ; start with width of first button
    Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnHeight
    mov dqSysButtonHeight, rax
    
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBarUseIcons
    mov dqUseIcons, rax
    
    Invoke GetWindowLongPtr, hCaptionBar, GWL_STYLE
    mov dqStyle, rax
    
    mov rax, dqStyle
    and rax, MUICS_NOCLOSEBUTTON
    .IF rax != MUICS_NOCLOSEBUTTON
        ; create close button
        xor rax, rax
        mov eax, rect.right
        mov ebx, rect.left
        sub eax, ebx
        sub rax, dqLeftOffset
        Invoke _MUI_CreateSysButton, hCaptionBar, Addr szMUISysCloseButton, rax, 0, dqSysButtonWidth, dqSysButtonHeight, 1 ; 32d, 24d, 1  
        mov hSysButtonClose, rax
        ;PrintQWORD rax
        ;PrintText 'CLOSEBUTTON'
        
        ; check if red button style is supplied, if so we override colors for this button
        mov rax, dqStyle
        and rax, MUICS_REDCLOSEBUTTON
        .IF rax == MUICS_REDCLOSEBUTTON
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextRollColor, MUI_RGBCOLOR(255,255,255)
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackRollColor, MUI_RGBCOLOR(166,26,32)
        .ENDIF
        
        .IF dqUseIcons == TRUE
            Invoke MUISetIntProperty, hSysButtonClose, @SysButtonUseIcons, TRUE
        .ELSE
            Invoke MUISetIntProperty, hSysButtonClose, @SysButtonUseIcons, FALSE
        .ENDIF
        mov rax, dqSysButtonWidth
        add dqLeftOffset, rax ;32d
    .ELSE
        ;PrintText 'NO CLOSEBUTTON'
        mov hSysButtonClose, 0
    .ENDIF    
    
    mov rax, dqStyle
    and rax, MUICS_NOMAXBUTTON
    .IF rax != MUICS_NOMAXBUTTON
        ; create max and restore buttons
        xor rax, rax
        mov eax, rect.right
        mov ebx, rect.left
        sub eax, ebx
        sub rax, dqLeftOffset
        mov xpos, rax
        Invoke _MUI_CreateSysButton, hCaptionBar, Addr szMUISysMaxButton, xpos, 0, dqSysButtonWidth, dqSysButtonHeight, 2 ;32d, 24d, 2
        mov hSysButtonMax, rax
        ;PrintText 'MAXBUTTON'
        ;PrintQWORD hSysButtonMax
        Invoke _MUI_CreateSysButton, hCaptionBar, Addr szMUISysResButton, xpos, 0, dqSysButtonWidth, dqSysButtonHeight, 3 ;32d, 24d, 3
        mov hSysButtonRes, rax
        ;PrintQWORD rax 
        ;PrintText 'RESBUTTON'
               
        mov rax, dqSysButtonWidth
        add dqLeftOffset, rax ;32d
        ; hide max/res button depending on current window placement
        Invoke GetWindowPlacement, hCaptionBarParent, Addr wp
        .IF wp.showCmd == SW_SHOWNORMAL
            Invoke ShowWindow, hSysButtonRes, SW_HIDE
        .ELSE
            Invoke ShowWindow, hSysButtonMax, SW_HIDE
        .ENDIF
        
        .IF dqUseIcons == TRUE
            Invoke MUISetIntProperty, hSysButtonMax, @SysButtonUseIcons, TRUE
            Invoke MUISetIntProperty, hSysButtonRes, @SysButtonUseIcons, TRUE
        .ELSE
            Invoke MUISetIntProperty, hSysButtonMax, @SysButtonUseIcons, FALSE
            Invoke MUISetIntProperty, hSysButtonRes, @SysButtonUseIcons, FALSE
        .ENDIF        
        
    .ELSE
       ; PrintText 'NO MAXRESBUTTONS'
        mov hSysButtonMax, 0
        mov hSysButtonRes, 0
    .ENDIF
    
    mov rax, dqStyle
    and rax, MUICS_NOMINBUTTON
    .IF rax != MUICS_NOMINBUTTON
        ; create min button
        xor rax, rax
        mov eax, rect.right
        mov ebx, rect.left
        sub eax, ebx
        sub rax, dqLeftOffset
        Invoke _MUI_CreateSysButton, hCaptionBar, Addr szMUISysMinButton, rax, 0, dqSysButtonWidth, dqSysButtonHeight, 4 ;32d, 24d, 4
        mov hSysButtonMin, rax
        ;PrintQWORD rax
        ;PrintQWORD hSysButtonMin
        ;PrintText 'MINBUTTON'
                  
        mov rax, dqSysButtonWidth
        add dqLeftOffset, rax ;32d
        
        .IF dqUseIcons == TRUE
            Invoke MUISetIntProperty, hSysButtonMin, @SysButtonUseIcons, TRUE
        .ELSE
            Invoke MUISetIntProperty, hSysButtonMin, @SysButtonUseIcons, FALSE
        .ENDIF        
        
    .ELSE
        ;PrintText 'NO MINBUTTON'
        mov hSysButtonMin, 0
    .ENDIF

    ; save handles to child system buttons in our internal properties of CaptionBar
    Invoke MUISetIntProperty, hCaptionBar, @CaptionBar_hSysButtonClose, hSysButtonClose
    Invoke MUISetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMax, hSysButtonMax
    Invoke MUISetIntProperty, hCaptionBar, @CaptionBar_hSysButtonRes, hSysButtonRes
    Invoke MUISetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMin, hSysButtonMin
    xor rax, rax
    ret

_MUI_CreateCaptionBarSysButtons ENDP


;-------------------------------------------------------------------------------------
; _MUI_CaptionBarReposition - Reposition window and child system buttons after main
; window resizes - called via SendMessage, hControl, WM_SIZE, 0, 0
;-------------------------------------------------------------------------------------
_MUI_CaptionBarReposition PROC FRAME USES rbx hCaptionBar:QWORD
    LOCAL wp:WINDOWPLACEMENT
    LOCAL hDefer:QWORD
    LOCAL dqClientWidth:QWORD
    LOCAL dqClientHeight:QWORD
    LOCAL TotalItems:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    LOCAL dqCaptionHeight:QWORD
    LOCAL dqLeftOffset:QWORD
    LOCAL dqSysButtonWidth:QWORD
    LOCAL dqSysButtonHeight:QWORD    
    LOCAL hParent:QWORD
    LOCAL rect:RECT

    Invoke GetParent, hCaptionBar
    mov hParent, rax

    Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnWidth
    mov dqSysButtonWidth, rax
    mov dqLeftOffset, rax ;32d
    Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnHeight
    mov dqSysButtonHeight, rax

    Invoke GetClientRect, hCaptionBar, Addr rect
    mov eax, rect.bottom
    mov dqCaptionHeight, rax

    Invoke GetWindowPlacement, hParent, Addr wp
    
    Invoke GetWindowRect, hParent, Addr rect
    xor rax, rax
    mov eax, rect.right
    mov ebx, rect.left
    sub eax, ebx
    mov dqClientWidth, rax
    mov eax, rect.bottom
    mov ebx, rect.top
    sub eax, ebx
    mov dqClientHeight, rax
    
    mov TotalItems, 0
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonClose
    mov hSysButtonClose, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMax
    mov hSysButtonMax, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonRes
    mov hSysButtonRes, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMin
    mov hSysButtonMin, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF

    Invoke BeginDeferWindowPos, TotalItems
    mov hDefer, rax
    ; have to move this caption bar first, so that child controls can be moved inside of the new width (cant use defer on this window)
    .IF wp.showCmd == SW_SHOWNORMAL
        sub dqClientWidth, 2
        Invoke SetWindowPos, hCaptionBar, NULL, 1, 1, dqClientWidth, dqCaptionHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOREDRAW or SWP_NOACTIVATE or SWP_NOSENDCHANGING	 ;SWP_NOCOPYBITS	 or SWP_NOREDRAW
    .ELSE
        Invoke SetWindowPos, hCaptionBar, NULL, 1, 1, dqClientWidth, dqCaptionHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOREDRAW or SWP_NOACTIVATE or SWP_NOSENDCHANGING	 ;SWP_NOCOPYBITS	 or SWP_NOREDRAW
    .ENDIF 

    .IF hSysButtonClose != NULL
        mov rax, dqClientWidth
        sub rax, dqLeftOffset
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonClose, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER  or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	;or SWP_NOCOPYBITS
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonClose, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ENDIF
        mov rax, dqSysButtonWidth
        add dqLeftOffset, rax ;32d
    .ENDIF

    .IF hSysButtonMax != NULL && hSysButtonRes != NULL
        mov rax, dqClientWidth
        sub rax, dqLeftOffset
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonMax, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonMax, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER  or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ENDIF

        mov rax, dqClientWidth
        sub rax, dqLeftOffset        
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonRes, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonRes, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ENDIF
        mov rax, dqSysButtonWidth
        add dqLeftOffset, rax ;32d
    .ENDIF
    
    .IF hSysButtonMin != NULL
        mov rax, dqClientWidth
        sub rax, dqLeftOffset
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonMin, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonMin, NULL, rax, 0, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ENDIF
    .ENDIF

    .IF hDefer != NULL
        Invoke EndDeferWindowPos, hDefer
    .ENDIF    

    Invoke InvalidateRect, hCaptionBar, NULL, TRUE

    Invoke GetWindowPlacement, hParent, Addr wp
    .IF wp.showCmd == SW_SHOWNORMAL
        Invoke ShowWindow, hSysButtonRes, SW_HIDE
        Invoke ShowWindow, hSysButtonMax, SW_SHOW
    .ELSE
        Invoke ShowWindow, hSysButtonMax, SW_HIDE
        Invoke ShowWindow, hSysButtonRes, SW_SHOW
    .ENDIF
    
    ret

_MUI_CaptionBarReposition ENDP


;-------------------------------------------------------------------------------------
; _MUI_CaptionBarSetSysButtonProperty - Sets the system button properties from the message
; MUIM_SETPROPERTY set to the parent CaptionBar control 
;-------------------------------------------------------------------------------------
_MUI_CaptionBarSetSysButtonProperty PROC FRAME USES rbx hCaptionBar:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    LOCAL dqStyle:QWORD
    LOCAL dqSysButtonWidth:QWORD
    LOCAL dqSysButtonHeight:QWORD

    .IF dqProperty == @CaptionBarTextFont
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonClose
    mov hSysButtonClose, rax
    .IF rax != NULL
        mov rax, dqProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor || rax == @CaptionBarBtnBckRollColor
        
            Invoke GetWindowLongPtr, hCaptionBar, GWL_STYLE
            mov dqStyle, rax        
            ;Invoke _MUIGetIntProperty, hCaptionBar, @CaptionBarStyle
            and rax, MUICS_REDCLOSEBUTTON
            .IF rax == MUICS_REDCLOSEBUTTON
                Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextRollColor, MUI_RGBCOLOR(255,255,255)
                Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackRollColor, MUI_RGBCOLOR(166,26,32)
            .ELSE
                mov rax, dqProperty
                .IF rax == @CaptionBarBtnTxtRollColor
                    Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextRollColor, dqPropertyValue
                .ELSEIF rax == @CaptionBarBtnBckRollColor
                    Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackRollColor, dqPropertyValue
                .ENDIF
            .ENDIF
        .ELSEIF rax == @CaptionBarBtnIcoClose
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIco, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoCloseAlt
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIcoAlt, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnHeight
            mov dqSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonClose, NULL, 0, 0, dqPropertyValue, dqSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnWidth
            mov dqSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonClose, NULL, 0, 0, dqSysButtonWidth, dqPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ENDIF
    .ENDIF
    
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMax
    mov hSysButtonMax, rax
    .IF rax != NULL
        mov rax, dqProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonTextColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonBackColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonTextRollColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnBckRollColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonBackRollColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMax
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIco, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMaxAlt
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIcoAlt, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnHeight
            mov dqSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonMax, NULL, 0, 0, dqPropertyValue, dqSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnWidth
            mov dqSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonMax, NULL, 0, 0, dqSysButtonWidth, dqPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE         
        .ENDIF
    .ENDIF
    
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonRes
    mov hSysButtonRes, rax
    .IF rax != NULL
        mov rax, dqProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonTextColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonBackColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonTextRollColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnBckRollColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonBackRollColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoRes
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIco, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoResAlt
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIcoAlt, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnHeight
            mov dqSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonRes, NULL, 0, 0, dqPropertyValue, dqSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnWidth
            mov dqSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonRes, NULL, 0, 0, dqSysButtonWidth, dqPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE          
        .ENDIF
    .ENDIF
    
    Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMin
    mov hSysButtonMin, rax
    .IF rax != NULL
        mov rax, dqProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonTextColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonBackColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonTextRollColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnBckRollColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonBackRollColor, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMin
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIco, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMinAlt
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIcoAlt, dqPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnHeight
            mov dqSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonMin, NULL, 0, 0, dqPropertyValue, dqSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarBtnWidth
            mov dqSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonMin, NULL, 0, 0, dqSysButtonWidth, dqPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE        
        .ENDIF
    .ENDIF
    
    ret
_MUI_CaptionBarSetSysButtonProperty ENDP


;-------------------------------------------------------------------------------------
; _MUI_CreateSysButton - create a system button (min, max, restore or close button)
;-------------------------------------------------------------------------------------
_MUI_CreateSysButton PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, dqResourceID:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
    LOCAL dwControlStyle:DWORD
    
    Invoke RtlZeroMemory, Addr wc, SIZEOF WNDCLASSEX
    
    Invoke GetModuleHandle, NULL
    mov hinstance, rax
    ;PrintQWORD rax

    

    ;PrintText '_MUI_CreateSysButton'
    
    xor rax, rax
    mov eax, WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS
    mov dwControlStyle, eax
    
    invoke GetClassInfoEx,hinstance, Addr szMUISysButtonClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUISysButtonClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
        lea rax, _MUI_SysButtonWndProc
    	mov wc.lpfnWndProc, rax
    	Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, rax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, NULL
        mov wc.cbClsExtra, 0
    	mov wc.cbWndExtra, 16d
    	Invoke RegisterClassEx, addr wc
    	.IF rax == 0
    	    ;PrintText 'Failed to register sys button'
    	.endif
    .ENDIF

   ; Invoke CreateWindowEx, NULL, Addr szMUICaptionBarClass, lpszCaptionText, dqControlStyle, 0, 0, rax, dqCaptionHeight, hWndParent, dqResourceID, hinstance, NULL
    
    
    Invoke CreateWindowEx, NULL, Addr szMUISysButtonClass, lpszText, dwControlStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, dqResourceID, hinstance, NULL ;WS_EX_TRANSPARENT needed only for click through or WS_CLIPSIBLINGS
    .IF rax == NULL
        ;PrintText 'Failed to create sys button'
    .endif
    ret

_MUI_CreateSysButton ENDP


;-------------------------------------------------------------------------------------
; _MUI_SysButtonWndProc - Main processing window for system buttons: min/max/res/close 
;-------------------------------------------------------------------------------------
_MUI_SysButtonWndProc PROC FRAME USES rbx hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    
    mov eax,uMsg
    .IF eax == WM_CREATE
        ;PrintText '_MUI_SysButtonWndProc::WM_CREATE'
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_SYSBUTTON_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_SYSBUTTON_PROPERTIES ; external properties
		Invoke _MUI_SysButtonInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_SysButtonCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8   
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_SysButtonPaint, hWin
        mov eax, 0
        ret
   
    .ELSEIF eax == WM_LBUTTONUP
		Invoke GetDlgCtrlID, hWin
		mov rbx,rax
		Invoke GetParent, hWin
		Invoke PostMessage, rax, WM_COMMAND, rbx, hWin
		xor rax, rax
		ret
   
   .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUISetIntProperty, hWin, @SysButtonMouseOver, TRUE
		.IF rax != TRUE
		    Invoke InvalidateRect, hWin, NULL, TRUE
		    mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
		    mov TE.dwFlags, TME_LEAVE
		    mov rax, hWin
		    mov TE.hwndTrack, rax
		    mov TE.dwHoverTime, NULL
		    Invoke TrackMouseEvent, Addr TE
		.ENDIF

    .ELSEIF eax == WM_MOUSELEAVE
        Invoke MUISetIntProperty, hWin, @SysButtonMouseOver, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, rax

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @SysButtonMouseOver, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, rax
	
    .ENDIF
	Invoke DefWindowProc, hWin, uMsg, wParam, lParam
	ret

_MUI_SysButtonWndProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_SysButtonInit - default intial values for properties for SysButton
;-------------------------------------------------------------------------------------
_MUI_SysButtonInit PROC FRAME hSysButton:QWORD
    
    ;PrintText '_MUI_SysButtonInit'
    ; Set default initial external property values     
    Invoke MUISetExtProperty, hSysButton, @SysButtonTextColor, MUI_RGBCOLOR(228,228,228)
    Invoke MUISetExtProperty, hSysButton, @SysButtonTextRollColor, MUI_RGBCOLOR(0,0,0)
    Invoke MUISetExtProperty, hSysButton, @SysButtonBackColor, MUI_RGBCOLOR(21,133,181)
    Invoke MUISetExtProperty, hSysButton, @SysButtonBackRollColor, MUI_RGBCOLOR(138,194,218)
    

    .IF hMUISysButtonFont == 0
        Invoke CreateFont, -10, 0, 0, 0, FW_THIN, FALSE, FALSE, FALSE, SYMBOL_CHARSET, 0, 0, 0, 0, Addr szMUISysButtonFont
        mov hMUISysButtonFont, rax
    .ENDIF
    
    ; Set internal property for font for system buttons 
    Invoke MUISetIntProperty, hSysButton, @SysButtonFont, hMUISysButtonFont

    ret

_MUI_SysButtonInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_SysButtonCleanup - cleanup some stuff on control being destroyed
;-------------------------------------------------------------------------------------
_MUI_SysButtonCleanup PROC FRAME hSysButton:QWORD
    
    Invoke GetParent, hSysButton
    Invoke GetWindowLongPtr, rax, GWL_STYLE
    and rax, MUICS_KEEPICONS
    .IF rax == MUICS_KEEPICONS
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hSysButton, @SysButtonUseIcons
    .IF rax == TRUE    
        Invoke MUIGetExtProperty, hSysButton, @SysButtonIco
        .IF rax != NULL
            Invoke DestroyIcon, rax
        .ENDIF
         Invoke MUIGetExtProperty, hSysButton, @SysButtonIcoAlt
        .IF rax != NULL
            Invoke DestroyIcon, rax
        .ENDIF
    .ENDIF
    ret

_MUI_SysButtonCleanup ENDP


;-------------------------------------------------------------------------------------
; _MUI_SysButtonPaint - System button painting
;-------------------------------------------------------------------------------------
_MUI_SysButtonPaint PROC FRAME USES rbx hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL pt:POINT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL MouseOver:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL UseIcons:QWORD
    LOCAL hIcon:QWORD
    LOCAL nIcoWidth:QWORD
    LOCAL nIcoHeight:QWORD
    LOCAL szText[16]:BYTE
    
    ; null some vars
    mov hFont, 0
    mov hOldFont, 0
    mov hBrush, 0
    mov hOldBrush, 0
    mov hIcon, 0
    mov nIcoWidth, 0
    mov nIcoHeight, 0
    
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
	; Get properties
	;----------------------------------------------------------
	Invoke MUIGetIntProperty, hWin, @SysButtonMouseOver
    mov MouseOver, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hWin, @SysButtonTextColor        ; normal text color
    .ELSE
        Invoke MUIGetExtProperty, hWin, @SysButtonTextRollColor    ; mouseover text color
    .ENDIF
    mov TextColor, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hWin, @SysButtonBackColor        ; normal back color
    .ELSE
        Invoke MUIGetExtProperty, hWin, @SysButtonBackRollColor    ; mouseover back color
    .ENDIF
    mov BackColor, rax
    Invoke MUIGetIntProperty, hWin, @SysButtonFont             ; Marlett font
    mov hFont, rax
    
    Invoke MUIGetIntProperty, hWin, @SysButtonUseIcons
    mov UseIcons, rax
    .IF UseIcons == TRUE
        .IF MouseOver == 0
            Invoke MUIGetExtProperty, hWin, @SysButtonIco
        .ELSE
            Invoke MUIGetExtProperty, hWin, @SysButtonIcoAlt
            .IF rax == NULL ; try to get ordinary icon handle
                Invoke MUIGetExtProperty, hWin, @SysButtonIco
            .ENDIF
        .ENDIF
        mov hIcon, rax
    .ENDIF

	;----------------------------------------------------------
	; Fill background
	;----------------------------------------------------------    
    Invoke SetBkMode, hdcMem, OPAQUE
    Invoke SetBkColor, hdcMem, dword ptr BackColor
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr BackColor
    Invoke FillRect, hdcMem, Addr rect, hBrush

    .IF UseIcons == FALSE || hIcon == NULL
    	;----------------------------------------------------------
    	; Draw Text
    	;----------------------------------------------------------
    	Invoke SelectObject, hdcMem, hFont
        mov hOldFont, rax
        ;PrintDec hFont
        ;PrintDec hOldFont
        Invoke GetWindowText, hWin, Addr szText, sizeof szText
        Invoke SetTextColor, hdcMem, dword ptr TextColor
        Invoke DrawText, hdcMem, Addr szText, -1, Addr rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER

    .ELSE
    	;----------------------------------------------------------
    	; Draw Icon
    	;----------------------------------------------------------
        
        ; get icon width and height and center it in our client
        Invoke MUIGetImageSize, hIcon, MUIIT_ICO, Addr nIcoWidth, Addr nIcoHeight
        ;Invoke _MUI_SysButtonGetIconSize, hIcon, Addr nIcoWidth, Addr nIcoHeight
        xor rax, rax
        mov eax, rect.right
        shr eax, 1
        mov rbx, nIcoWidth
        shr ebx, 1
        sub eax, ebx
        mov pt.x, eax
                
        mov eax, rect.bottom
        shr eax, 1
        mov rbx, nIcoHeight
        shr ebx, 1
        sub eax, ebx
        mov pt.y, eax

        Invoke DrawIconEx, hdcMem, pt.x, pt.y, hIcon, 0, 0, NULL, NULL, DI_NORMAL

    .ENDIF

    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------

    Invoke DeleteDC, hdcMem
    Invoke DeleteObject, hbmMem
    .IF hOldBitmap != 0
        Invoke DeleteObject, hOldBitmap
    .ENDIF		
    .IF hOldFont != 0
       Invoke DeleteObject, hOldFont
    .ENDIF
    .IF hOldBrush != 0
        Invoke DeleteObject, hOldBrush
    .ENDIF        
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    
    Invoke EndPaint, hWin, Addr ps
    ret

_MUI_SysButtonPaint ENDP


;-------------------------------------------------------------------------------------
; Applies the ModernUI style to a dialog to make it a captionless, borderless form. 
; User can manually change a form in a resource editor to have the following style
; flags: WS_POPUP or WS_VISIBLE and optionally with DS_CENTER /DS_CENTERMOUSE / 
; WS_CLIPCHILDREN / WS_CLIPSIBLINGS / WS_MINIMIZE / WS_MAXIMIZE
;-------------------------------------------------------------------------------------
_MUI_ApplyMUIStyleToDialog PROC FRAME hWin:QWORD, dqDropShadow:QWORD
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

_MUI_ApplyMUIStyleToDialog ENDP


;-------------------------------------------------------------------------------------
; _MUI_SysButtonGetIconSize
;-------------------------------------------------------------------------------------
;_MUI_SysButtonGetIconSize PROC PRIVATE USES rbx hIcon:QWORD, lpdqIconWidth:QWORD, lpdqIconHeight:QWORD
;    LOCAL bm:BITMAP
;    LOCAL iinfo:ICONINFO
;
;    Invoke GetIconInfo, hIcon, Addr iinfo ; get icon information
;    mov rax, iinfo.hbmColor ; bitmap info of icon has width/height
;    .IF rax != NULL
;        Invoke GetObject, iinfo.hbmColor, SIZEOF bm, Addr bm
;        mov rax, bm.bmWidth
;        mov rbx, lpdqIconWidth
;        mov [rbx], rax
;        mov rax, bm.bmHeight
;        mov rbx, lpdqIconHeight
;        mov [rbx], rax
;    .ELSE ; Icon has no color plane, image width/height data stored in mask
;        mov rax, iinfo.hbmMask
;        .IF rax != NULL
;            Invoke GetObject, iinfo.hbmMask, SIZEOF bm, Addr bm
;            mov rax, bm.bmWidth
;            mov rbx, lpdqIconWidth
;            mov [rbx], rax
;            mov rax, bm.bmHeight
;            shr rax, 1 ;bmp.bmHeight / 2;
;            mov rbx, lpdqIconHeight
;            mov [rbx], rax                
;        .ENDIF
;    .ENDIF
;    ; free up color and mask icons created by the GetIconInfo function
;    mov rax, iinfo.hbmColor
;    .IF rax != NULL
;        Invoke DeleteObject, rax
;    .ENDIF
;    mov rax, iinfo.hbmMask
;    .IF rax != NULL
;        Invoke DeleteObject, rax
;    .ENDIF
;
;    mov rax, TRUE
;    ret
;
;_MUI_SysButtonGetIconSize ENDP


;-------------------------------------------------------------------------------------
; MUICaptionBarLoadIcons
;-------------------------------------------------------------------------------------
MUICaptionBarLoadIcons PROC FRAME hCaptionBar:QWORD, idResMin:QWORD, idResMinAlt:QWORD, idResMax:QWORD, idResMaxAlt:QWORD, idResRes:QWORD, idResResAlt:QWORD, idResClose:QWORD, idResCloseAlt:QWORD 
    LOCAL hinstance:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    
    Invoke MUIGetExtProperty, hCaptionBar, @CaptionBarDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax
    
    .IF idResMin != NULL || idResMinAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMin
        mov hSysButtonMin, rax
        
        .IF idResMin != NULL
    	    Invoke LoadImage, hinstance, idResMin, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIco, rax
        .ENDIF
        .IF idResMinAlt != NULL
    	    Invoke LoadImage, hinstance, idResMinAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF

    .IF idResMax != NULL || idResMaxAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMax
        mov hSysButtonMax, rax
        
        .IF idResMax != NULL
    	    Invoke LoadImage, hinstance, idResMax, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIco, rax
        .ENDIF
        .IF idResMaxAlt != NULL
    	    Invoke LoadImage, hinstance, idResMaxAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF

    .IF idResRes != NULL || idResResAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonRes
        mov hSysButtonRes, rax
        
        .IF idResRes != NULL
    	    Invoke LoadImage, hinstance, idResRes, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIco, rax
        .ENDIF
        .IF idResResAlt != NULL
    	    Invoke LoadImage, hinstance, idResResAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF
    
    .IF idResClose != NULL || idResCloseAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonClose
        mov hSysButtonClose, rax
        
        .IF idResClose != NULL
    	    Invoke LoadImage, hinstance, idResClose, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIco, rax
        .ENDIF
        .IF idResClose != NULL
    	    Invoke LoadImage, hinstance, idResCloseAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF
    

	mov rax, TRUE
    ret

MUICaptionBarLoadIcons ENDP


;-------------------------------------------------------------------------------------
; MUICaptionBarLoadIcons - version for loading from DLL's that have the icon resources
;-------------------------------------------------------------------------------------
MUICaptionBarLoadIconsDll PROC FRAME hCaptionBar:QWORD, hInst:QWORD, idResMin:QWORD, idResMinAlt:QWORD, idResMax:QWORD, idResMaxAlt:QWORD, idResRes:QWORD, idResResAlt:QWORD, idResClose:QWORD, idResCloseAlt:QWORD 
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    
    .IF idResMin != NULL || idResMinAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMin
        mov hSysButtonMin, rax
        
        .IF idResMin != NULL
    	    Invoke LoadImage, hInst, idResMin, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIco, rax
        .ENDIF
        .IF idResMinAlt != NULL
    	    Invoke LoadImage, hInst, idResMinAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF

    .IF idResMax != NULL || idResMaxAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonMax
        mov hSysButtonMax, rax
        
        .IF idResMax != NULL
    	    Invoke LoadImage, hInst, idResMax, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIco, rax
        .ENDIF
        .IF idResMaxAlt != NULL
    	    Invoke LoadImage, hInst, idResMaxAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF

    .IF idResRes != NULL || idResResAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonRes
        mov hSysButtonRes, rax
        
        .IF idResRes != NULL
    	    Invoke LoadImage, hInst, idResRes, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIco, rax
        .ENDIF
        .IF idResResAlt != NULL
    	    Invoke LoadImage, hInst, idResResAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF
    
    .IF idResClose != NULL || idResCloseAlt != NULL
        Invoke MUIGetIntProperty, hCaptionBar, @CaptionBar_hSysButtonClose
        mov hSysButtonClose, rax
        
        .IF idResClose != NULL
    	    Invoke LoadImage, hInst, idResClose, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIco, rax
        .ENDIF
        .IF idResClose != NULL
    	    Invoke LoadImage, hInst, idResCloseAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIcoAlt, rax
        .ENDIF
    .ENDIF
    

	mov rax, TRUE
    ret

MUICaptionBarLoadIconsDll ENDP









END
