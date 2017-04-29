;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_Checkbox x64 v1.0.0.0
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
;include ole32.inc
ENDIF

IFDEF MUI_USEGDIPLUS
includelib gdiplus.lib
includelib ole32.lib
ENDIF

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_Checkbox.inc
include ModernUI_Checkbox_Icons.asm

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
_MUI_CheckboxWndProc					PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_CheckboxInit					    PROTO :QWORD
_MUI_CheckboxCleanup                    PROTO :QWORD
_MUI_CheckboxPaint					    PROTO :QWORD

_MUI_CheckboxPaintBackground            PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CheckboxPaintText                  PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CheckboxPaintImages                PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD

_MUI_CheckboxLoadBitmap                 PROTO :QWORD, :QWORD, :QWORD
_MUI_CheckboxLoadIcon                   PROTO :QWORD, :QWORD, :QWORD
IFDEF MUI_USEGDIPLUS
_MUI_CheckboxLoadPng                    PROTO :QWORD, :QWORD, :QWORD
ENDIF

IFDEF MUI_USEGDIPLUS
_MUI_CheckboxPngReleaseIStream          PROTO :QWORD
ENDIF
_MUI_CheckboxSetPropertyEx              PROTO :QWORD, :QWORD, :QWORD


;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; External public properties
IFNDEF MUI_CHECKBOX_PROPERTIES
MUI_CHECKBOX_PROPERTIES                 STRUCT
    dqTextFont                          DQ ?       ; hFont
    dqTextColor                         DQ ?       ; Colorref
    dqTextColorAlt                      DQ ?       ; Colorref
    dqTextColorSel                      DQ ?       ; Colorref
    dqTextColorSelAlt                   DQ ?       ; Colorref
    dqTextColorDisabled                 DQ ?       ; Colorref
    dqBackColor                         DQ ?       ; Colorref
    dqImageType                         DQ ?       ; image type
    dqImage                             DQ ?       ; hImage for empty checkbox
    dqImageAlt                          DQ ?       ; hImage for empty checkbox when mouse moves over checkbox
    dqImageSel                          DQ ?       ; hImage for checkbox with checkmark
    dqImageSelAlt                       DQ ?       ; hImage for checkbox with checkmark when mouse moves over checkbox
    dqImageDisabled                     DQ ?       ; hImage for disabled empty checkbox
    dqImageDisabledSel                  DQ ?       ; hImage for disabled checkbox with checkmark
    dqCheckboxDllInstance               DQ ?
MUI_CHECKBOX_PROPERTIES			        ENDS
ENDIF

; Internal properties
_MUI_CHECKBOX_PROPERTIES				STRUCT
	dqEnabledState						DQ ?
	dqMouseOver							DQ ?
	dqSelectedState                     DQ ?
	dqImageStream                       DQ ?
	dqImageAltStream                    DQ ?
	dqImageSelStream                    DQ ?
	dqImageSelAltStream                 DQ ?
	dqImageDisabledStream               DQ ?
	dqImageDisabledSelStream            DQ ?
_MUI_CHECKBOX_PROPERTIES				ENDS


IFDEF MUI_USEGDIPLUS
UNKNOWN STRUCT
   QueryInterface   QWORD ?
   AddRef           QWORD ?
   Release          QWORD ?
UNKNOWN ENDS

IStreamX STRUCT
IUnknown            UNKNOWN <>
Read                QWORD ?
Write               QWORD ?
Seek                QWORD ?
SetSize             QWORD ?
CopyTo              QWORD ?
Commit              QWORD ?
Revert              QWORD ?
LockRegion          QWORD ?
UnlockRegion        QWORD ?
Stat                QWORD ?
Clone               QWORD ?
IStreamX ENDS
ENDIF

.CONST
; Internal properties
@CheckboxEnabledState				    EQU 0
@CheckboxMouseOver					    EQU 8
@CheckboxSelectedState                  EQU 16
@CheckboxImageStream                    EQU 24
@CheckboxImageAltStream                 EQU 32
@CheckboxImageSelStream                 EQU 40
@CheckboxImageSelAltStream              EQU 48
@CheckboxImageDisabledStream            EQU 56
@CheckboxImageDisabledSelStream         EQU 64

; External public properties


.DATA
szMUICheckboxClass					    DB 'ModernUI_Checkbox',0 	        ; Class name for creating our ModernUI_Checkbox control
szMUICheckboxFont                       DB 'Segoe UI',0             	    ; Font used for ModernUI_Checkbox text
hMUICheckboxFont                        DQ 0                        	    ; Handle to ModernUI_Checkbox font (segoe ui)


hDefault_icoMUICheckboxTick             DQ 0
hDefault_icoMUICheckboxEmpty            DQ 0
hDefault_icoMUIRadioTick                DQ 0
hDefault_icoMUIRadioEmpty               DQ 0

.DATA
IFDEF DEBUG64
DbgVar                                      DQ ?
ENDIF


.CODE
;-------------------------------------------------------------------------------------
; Set property for ModernUI_Checkbox control
;-------------------------------------------------------------------------------------
MUICheckboxSetProperty PROC FRAME hControl:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, dqProperty, dqPropertyValue
    ret
MUICheckboxSetProperty ENDP


;-------------------------------------------------------------------------------------
; Get property for ModernUI_Checkbox control
;-------------------------------------------------------------------------------------
MUICheckboxGetProperty PROC FRAME hControl:QWORD, dqProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, dqProperty, NULL
    ret
MUICheckboxGetProperty ENDP


;-------------------------------------------------------------------------------------
; MUICheckboxRegister - Registers the ModernUI_Checkbox control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Checkbox
;-------------------------------------------------------------------------------------
MUICheckboxRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUICheckboxClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUICheckboxClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_CheckboxWndProc
    	mov wc.lpfnWndProc, rax
    	Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, rax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, NULL
        mov wc.cbClsExtra, 0
    	mov wc.cbWndExtra, 16 ; cbWndExtra +0 = QWORD ptr to internal properties memory block, cbWndExtra +8 = QWORD ptr to external properties memory block
    	Invoke RegisterClassEx, addr wc
    .ENDIF  
    ret

MUICheckboxRegister ENDP


;-------------------------------------------------------------------------------------
; MUICheckboxCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUICheckboxCreate PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, dqResourceID:QWORD, dqStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL dqNewStyle:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUICheckboxRegister
	
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN. Non visual prob dont need any of these.

    mov rax, dqStyle
    mov dqNewStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        or dqNewStyle, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .ENDIF
	
    Invoke CreateWindowEx, NULL, Addr szMUICheckboxClass, lpszText, dword ptr dqNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, dqResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUICheckboxCreate ENDP



;-------------------------------------------------------------------------------------
; _MUI_CheckboxWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_CheckboxWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    LOCAL hParent:QWORD
    LOCAL rect:RECT
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        mov rbx, lParam
		; sets text of our control, delete if not required.
        Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName	
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_CHECKBOX_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_CHECKBOX_PROPERTIES ; external properties
		IFDEF MUI_USEGDIPLUS
		Invoke MUIGDIPlusStart ; for png resources if used
		ENDIF		
		Invoke _MUI_CheckboxInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_CheckboxCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
		IFDEF MUI_USEGDIPLUS
		Invoke MUIGDIPlusFinish
		ENDIF
		mov rax, 0
		ret
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_CheckboxPaint, hWin
        mov rax, 0
        ret

    .ELSEIF eax == WM_SETCURSOR
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUICS_HAND
        .IF rax == MUICS_HAND
		    invoke LoadCursor, NULL, IDC_HAND
        .ELSE
            invoke LoadCursor, NULL, IDC_ARROW
        .ENDIF
        Invoke SetCursor, rax
        mov rax, 0
        ret

    .ELSEIF eax == WM_LBUTTONUP
		; simulates click on our control, delete if not required.
		Invoke GetParent, hWin
		mov hParent, rax
		Invoke GetDlgCtrlID, hWin
		Invoke PostMessage, hParent, WM_COMMAND, rax, hWin

        Invoke MUIGetIntProperty, hWin, @CheckboxSelectedState
        .IF rax == FALSE
            Invoke MUISetIntProperty, hWin, @CheckboxSelectedState, TRUE
        .ELSE
            Invoke MUISetIntProperty, hWin, @CheckboxSelectedState, FALSE
        .ENDIF
        Invoke InvalidateRect, hWin, NULL, TRUE

   .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUIGetIntProperty, hWin, @CheckboxEnabledState
        .IF rax == TRUE   
    		Invoke MUISetIntProperty, hWin, @CheckboxMouseOver , TRUE
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
        Invoke MUISetIntProperty, hWin, @CheckboxMouseOver , FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		;Invoke LoadCursor, NULL, IDC_ARROW
		;Invoke SetCursor, rax

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @CheckboxMouseOver , FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		;Invoke LoadCursor, NULL, IDC_ARROW
		;Invoke SetCursor, rax

	.ELSEIF eax == WM_ENABLE
	    Invoke MUISetIntProperty, hWin, @CheckboxEnabledState, wParam
	    Invoke InvalidateRect, hWin, NULL, TRUE
	    mov rax, 0

    .ELSEIF eax == WM_SETTEXT
        Invoke DefWindowProc, hWin, uMsg, wParam, lParam
        Invoke InvalidateRect, hWin, NULL, TRUE
        ret

    .ELSEIF eax == WM_SETFONT
        Invoke MUISetExtProperty, hWin, @CheckboxTextFont, lParam
        .IF lParam == TRUE
            Invoke InvalidateRect, hWin, NULL, TRUE
        .ENDIF  
	
	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
	    Invoke _MUI_CheckboxSetPropertyEx, hWin, wParam, lParam
		;Invoke MUISetExtProperty, hWin, wParam, lParam
		Invoke InvalidateRect, hWin, NULL, TRUE	
		ret

	.ELSEIF eax == MUICM_GETSTATE ; wParam = NULL, lParam = NULL. rax contains state (TRUE/FALSE)
	    Invoke MUIGetIntProperty, hWin, @CheckboxSelectedState
	    ret
	 
	.ELSEIF eax == MUICM_SETSTATE ; wParam = TRUE/FALSE, lParam = NULL
	    Invoke MUISetIntProperty, hWin, @CheckboxSelectedState, wParam
	    Invoke InvalidateRect, hWin, NULL, TRUE
	    ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_CheckboxWndProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_CheckboxInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_CheckboxInit PROC FRAME hControl:QWORD
    LOCAL ncm:NONCLIENTMETRICS
    LOCAL lfnt:LOGFONT
    LOCAL hFont:QWORD
    LOCAL hParent:QWORD
    LOCAL dqStyle:QWORD
    
    Invoke GetParent, hControl
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov dqStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, dqStyle
        or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov dqStyle, rax
        Invoke SetWindowLongPtr, hControl, GWL_STYLE, dqStyle
    .ENDIF
    ;PrintDec dqStyle
    
    ; Set default initial external property values     
    Invoke MUISetIntProperty, hControl, @CheckboxEnabledState, TRUE
    Invoke MUISetExtProperty, hControl, @CheckboxTextColor, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hControl, @CheckboxTextColorAlt, MUI_RGBCOLOR(41,122,185)
    Invoke MUISetExtProperty, hControl, @CheckboxTextColorSel, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hControl, @CheckboxTextColorSelAlt, MUI_RGBCOLOR(41,122,185)
    Invoke MUISetExtProperty, hControl, @CheckboxTextColorDisabled, MUI_RGBCOLOR(204,204,204)
    Invoke MUISetExtProperty, hControl, @CheckboxBackColor, MUI_RGBCOLOR(240,240,240) ;MUI_RGBCOLOR(21,133,181)
    Invoke MUISetExtProperty, hControl, @CheckboxDllInstance, 0
    
    .IF hMUICheckboxFont == 0
    	mov ncm.cbSize, SIZEOF NONCLIENTMETRICS
    	Invoke SystemParametersInfo, SPI_GETNONCLIENTMETRICS, SIZEOF NONCLIENTMETRICS, Addr ncm, 0
    	Invoke CreateFontIndirect, Addr ncm.lfMessageFont
    	mov hFont, rax
	    Invoke GetObject, hFont, SIZEOF lfnt, Addr lfnt
	    mov lfnt.lfHeight, -16d
	    ;mov lfnt.lfWeight, FW_BOLD
	    Invoke CreateFontIndirect, Addr lfnt
        mov hMUICheckboxFont, rax
        Invoke DeleteObject, hFont
    .ENDIF
    Invoke MUISetExtProperty, hControl, @CheckboxTextFont, hMUICheckboxFont

    ; create default icons for use if user hasnt specified any images
    .IF hDefault_icoMUICheckboxTick == 0
        Invoke MUICreateIconFromMemory, Addr icoMUICheckboxTick, 0
        mov hDefault_icoMUICheckboxTick, rax
    .ENDIF
    .IF hDefault_icoMUICheckboxEmpty == 0
        Invoke MUICreateIconFromMemory, Addr icoMUICheckboxEmpty, 0
        mov hDefault_icoMUICheckboxEmpty, rax
    .ENDIF
    .IF hDefault_icoMUIRadioTick == 0
        Invoke MUICreateIconFromMemory, Addr icoMUIRadioTick, 0
        mov hDefault_icoMUIRadioTick, rax
    .ENDIF
    .IF hDefault_icoMUIRadioEmpty == 0
        Invoke MUICreateIconFromMemory, Addr icoMUIRadioEmpty, 0
        mov hDefault_icoMUIRadioEmpty, rax
    .ENDIF
    Invoke MUISetExtProperty, hControl, @CheckboxImageType, MUICIT_ICO

    mov rax, dqStyle
    and rax, MUICS_RADIO
    .IF rax == MUICS_RADIO
        Invoke MUISetExtProperty, hControl, @CheckboxImage, hDefault_icoMUIRadioEmpty
        Invoke MUISetExtProperty, hControl, @CheckboxImageAlt, hDefault_icoMUIRadioEmpty
        Invoke MUISetExtProperty, hControl, @CheckboxImageSel, hDefault_icoMUIRadioTick
        Invoke MUISetExtProperty, hControl, @CheckboxImageSelAlt, hDefault_icoMUIRadioTick
    .ELSE
        Invoke MUISetExtProperty, hControl, @CheckboxImage, hDefault_icoMUICheckboxEmpty
        Invoke MUISetExtProperty, hControl, @CheckboxImageAlt, hDefault_icoMUICheckboxEmpty
        Invoke MUISetExtProperty, hControl, @CheckboxImageSel, hDefault_icoMUICheckboxTick
        Invoke MUISetExtProperty, hControl, @CheckboxImageSelAlt, hDefault_icoMUICheckboxTick
    .ENDIF

    ret

_MUI_CheckboxInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_CheckboxCleanup - cleanup a few things before control is destroyed
;-------------------------------------------------------------------------------------
_MUI_CheckboxCleanup PROC FRAME hControl:QWORD
    LOCAL dqImageType:QWORD
    LOCAL hIStreamImage:QWORD
    LOCAL hIStreamImageAlt:QWORD
    LOCAL hIStreamImageSel:QWORD
    LOCAL hIStreamImageSelAlt:QWORD
    LOCAL hIStreamImageDisabled:QWORD
    LOCAL hIStreamImageDisabledSel:QWORD
    LOCAL hImage:QWORD
    LOCAL hImageAlt:QWORD
    LOCAL hImageSel:QWORD
    LOCAL hImageSelAlt:QWORD
    LOCAL hImageDisabled:QWORD
    LOCAL hImageDisabledSel:QWORD
    LOCAL dqStyle:QWORD
    
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov dqStyle, rax
    
    IFDEF DEBUG64
    PrintText '_MUI_CheckboxCleanup'
    ENDIF
    ; cleanup any stream handles if png where loaded as resources
    Invoke MUIGetExtProperty, hControl, @CheckboxImageType
    mov dqImageType, rax

    .IF dqImageType == 0
        ret
    .ENDIF
    
    .IF dqImageType == 3
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGetIntProperty, hControl, @CheckboxImageStream
        mov hIStreamImage, rax
        .IF rax != 0
            Invoke _MUI_CheckboxPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @CheckboxImageAltStream
        mov hIStreamImageAlt, rax
        .IF rax != 0 && rax != hIStreamImage
            Invoke _MUI_CheckboxPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @CheckboxImageSelStream
        mov hIStreamImageSel, rax
        .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt
            Invoke _MUI_CheckboxPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @CheckboxImageSelAltStream
        mov hIStreamImageSelAlt, rax
        .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt && rax != hIStreamImageSel
            Invoke _MUI_CheckboxPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @CheckboxImageDisabledStream
        mov hIStreamImageDisabled, rax
        .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt && rax != hIStreamImageSel && rax != hIStreamImageSelAlt 
            Invoke _MUI_CheckboxPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @CheckboxImageDisabledSelStream
        mov hIStreamImageDisabledSel, rax
        .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt && rax != hIStreamImageSel && rax != hIStreamImageSelAlt && rax != hIStreamImageDisabled
            Invoke _MUI_CheckboxPngReleaseIStream, rax
        .ENDIF

        
        IFDEF DEBUG64
        ; check to see if handles are cleared.
        PrintText '_MUI_CheckboxCleanup::IStream Handles cleared'
        ENDIF
        
        ENDIF        
    .ENDIF

    Invoke MUIGetExtProperty, hControl, @CheckboxImage
    mov hImage, rax
    .IF rax != 0
        .IF dqImageType != 3
            Invoke DeleteObject, rax
        .ELSE
            IFDEF MUI_USEGDIPLUS
            Invoke GdipDisposeImage, rax
            ENDIF
        .ENDIF
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @CheckboxImageAlt
    mov hImageAlt, rax
    .IF rax != 0 && rax != hImage
        .IF dqImageType != 3
            Invoke DeleteObject, rax
        .ELSE
            IFDEF MUI_USEGDIPLUS
            Invoke GdipDisposeImage, rax
            ENDIF
        .ENDIF
    .ENDIF    
    Invoke MUIGetExtProperty, hControl, @CheckboxImageSel
    mov hImageSel, rax
    .IF rax != 0 && rax != hImage && rax != hImageAlt
        .IF dqImageType != 3
            Invoke DeleteObject, rax
        .ELSE
            IFDEF MUI_USEGDIPLUS
            Invoke GdipDisposeImage, rax
            ENDIF
        .ENDIF
    .ENDIF    
    Invoke MUIGetExtProperty, hControl, @CheckboxImageSelAlt
    mov hImageSelAlt, rax
    .IF rax != 0 && rax != hImage && rax != hImageAlt && rax != hImageSel
        .IF dqImageType != 3
            Invoke DeleteObject, rax
        .ELSE
            IFDEF MUI_USEGDIPLUS
            Invoke GdipDisposeImage, rax
            ENDIF
        .ENDIF
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @CheckboxImageDisabled
    mov hImageDisabled, rax
    .IF rax != 0 && rax != hImage && rax != hImageAlt && rax != hImageSel && rax != hImageSelAlt
        .IF dqImageType != 3
            Invoke DeleteObject, rax
        .ELSE
            IFDEF MUI_USEGDIPLUS
            Invoke GdipDisposeImage, rax
            ENDIF
        .ENDIF
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @CheckboxImageDisabledSel
    mov hImageDisabledSel, rax
    .IF rax != 0 && rax != hImage && rax != hImageAlt && rax != hImageSel && rax != hImageSelAlt && rax != hImageDisabled
        .IF dqImageType != 3
            Invoke DeleteObject, rax
        .ELSE
            IFDEF MUI_USEGDIPLUS
            Invoke GdipDisposeImage, rax
            ENDIF
        .ENDIF
    .ENDIF

       
    IFDEF DEBUG64
    PrintText '_MUI_CheckboxCleanup::Image Handles cleared'
    ENDIF

    ret

_MUI_CheckboxCleanup ENDP



;-------------------------------------------------------------------------------------
; _MUI_CheckboxPaint
;-------------------------------------------------------------------------------------
_MUI_CheckboxPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL EnabledState:QWORD
    LOCAL MouseOver:QWORD
    LOCAL SelectedState:QWORD

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
    Invoke MUIGetIntProperty, hWin, @CheckboxEnabledState
    mov EnabledState, rax
	Invoke MUIGetIntProperty, hWin, @CheckboxMouseOver
    mov MouseOver, rax
	Invoke MUIGetIntProperty, hWin, @CheckboxSelectedState
    mov SelectedState, rax      
	
	;----------------------------------------------------------
	; Background
	;----------------------------------------------------------
	Invoke _MUI_CheckboxPaintBackground, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Images
	;----------------------------------------------------------
    Invoke _MUI_CheckboxPaintImages, hWin, hdc, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Text
	;----------------------------------------------------------
	Invoke _MUI_CheckboxPaintText, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    Invoke SelectObject, hdcMem, hOldBitmap
    Invoke DeleteDC, hdcMem
    Invoke DeleteObject, hbmMem
    .IF hOldBitmap != 0
        Invoke DeleteObject, hOldBitmap
    .ENDIF		
     
    Invoke EndPaint, hWin, Addr ps

    ret
_MUI_CheckboxPaint ENDP


;-------------------------------------------------------------------------------------
; _MUI_CheckboxPaintBackground
;-------------------------------------------------------------------------------------
_MUI_CheckboxPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    
    Invoke MUIGetExtProperty, hWin, @CheckboxBackColor
    mov BackColor, rax
    ;PrintDec BackColor

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

_MUI_CheckboxPaintBackground ENDP


;-------------------------------------------------------------------------------------
; _MUI_CheckboxPaintText
;-------------------------------------------------------------------------------------
_MUI_CheckboxPaintText PROC FRAME USES RBX hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL dwStyle:QWORD
    LOCAL dwTextStyle:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL hImage:QWORD
    LOCAL ImageType:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL rect:RECT
    LOCAL szText[256]:BYTE
    ;LOCAL LenText:DWORD

    Invoke CopyRect, Addr rect, lpRect

    Invoke MUIGetExtProperty, hWin, @CheckboxBackColor
    mov BackColor, rax
    ;PrintDec BackColor
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov dwStyle, rax
    
    Invoke MUIGetExtProperty, hWin, @CheckboxTextFont        
    mov hFont, rax
    
    ;PrintDec hFont

    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @CheckboxTextColor        ; Normal text color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @CheckboxTextColorAlt     ; Mouse over text color
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSel     ; Selected text color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSelAlt  ; Selected mouse over color 
            .ENDIF
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @CheckboxTextColorDisabled        ; Disabled text color
    .ENDIF
    .IF rax == 0 ; try to get default text color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @CheckboxTextColor                ; fallback to default Normal text color
    .ENDIF  
    mov TextColor, rax
    
    
    ;PrintDec TextColor
    
    Invoke MUIGetExtProperty, hWin, @CheckboxImageType        
    mov ImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png

    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @CheckboxImage        ; Normal image
            .ELSE
                Invoke MUIGetExtProperty, hWin, @CheckboxImageAlt     ; Mouse over image
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @CheckboxImageSel     ; Selected image
            .ELSE
                Invoke MUIGetExtProperty, hWin, @CheckboxImageSelAlt  ; Selected mouse over image 
            .ENDIF
        .ENDIF
    .ELSE
        .IF bSelectedState == FALSE
            Invoke MUIGetExtProperty, hWin, @CheckboxImageDisabled        ; Disabled image
        .ELSE
            Invoke MUIGetExtProperty, hWin, @CheckboxImageDisabledSel        ; Disabled image
        .ENDIF
    .ENDIF
    mov hImage, rax    
    
    ;Invoke lstrlen, Addr szText
    ;mov LenText, eax
    
    mov rect.left, 8
    ;mov rect.top, 4
    ;sub rect.bottom, 4
    sub rect.right, 4
    
    .IF hImage != 0
        
        Invoke MUIGetImageSize, hImage, ImageType, Addr ImageWidth, Addr ImageHeight

        mov rax, ImageWidth
        add rect.left, eax
        add rect.left, 8d

    .ENDIF

	Invoke SelectObject, hdc, hFont
    mov hOldFont, rax
    Invoke GetWindowText, hWin, Addr szText, sizeof szText

    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdc, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdc, dword ptr BackColor

    
    Invoke SetBkMode, hdc, OPAQUE
    Invoke SetBkColor, hdc, dword ptr BackColor    
    Invoke SetTextColor, hdc, dword ptr TextColor
    
    ;PrintDec rect.right
    ;mov dwTextStyle, 
    
    Invoke DrawText, hdc, Addr szText, -1, Addr rect, DT_SINGLELINE or DT_LEFT or DT_VCENTER
    
    .IF hOldFont != 0
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF
    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    
    ret

_MUI_CheckboxPaintText ENDP


;-------------------------------------------------------------------------------------
; _MUI_CheckboxPaintImages
;-------------------------------------------------------------------------------------
_MUI_CheckboxPaintImages PROC FRAME USES RBX hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL dqStyle:QWORD
    LOCAL dqImageType:QWORD
    LOCAL hImage:QWORD
    LOCAL hdcMem:HDC
    LOCAL hbmOld:QWORD
    LOCAL pGraphics:QWORD
    LOCAL pGraphicsBuffer:QWORD
    LOCAL pBitmap:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL rect:RECT
    LOCAL pt:POINT
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov dqStyle, rax
    
    Invoke MUIGetExtProperty, hWin, @CheckboxImageType        
    mov dqImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png
    
    ;PrintDec ImageType
    
    .IF dqImageType == 0
        ret
    .ENDIF    
    
    .IF dqImageType != 0
        .IF bEnabledState == TRUE
            .IF bSelectedState == FALSE
                .IF bMouseOver == FALSE
                    Invoke MUIGetExtProperty, hWin, @CheckboxImage        ; Normal image
                .ELSE
                    Invoke MUIGetExtProperty, hWin, @CheckboxImageAlt     ; Mouse over image
                .ENDIF
            .ELSE
                .IF bMouseOver == FALSE
                    Invoke MUIGetExtProperty, hWin, @CheckboxImageSel     ; Selected image
                .ELSE
                    Invoke MUIGetExtProperty, hWin, @CheckboxImageSelAlt  ; Selected mouse over image 
                .ENDIF
            .ENDIF
        .ELSE
            .IF bSelectedState == FALSE
                Invoke MUIGetExtProperty, hWin, @CheckboxImageDisabled        ; Disabled image
            .ELSE
                Invoke MUIGetExtProperty, hWin, @CheckboxImageDisabledSel     ; Disabled image
            .ENDIF
        .ENDIF
        .IF rax == 0 ; try to get default image if none others have a valid handle
            Invoke MUIGetExtProperty, hWin, @CheckboxImage                ; fallback to default Normal image
        .ENDIF
        mov hImage, rax
    .ELSE
        mov hImage, 0
    .ENDIF
    
    .IF hImage != 0
    
        Invoke CopyRect, Addr rect, lpRect
        Invoke MUIGetImageSize, hImage, dqImageType, Addr ImageWidth, Addr ImageHeight
        
        mov pt.x, 8d
        mov pt.y, 4d
        xor rax, rax
        xor rbx, rbx
        mov eax, rect.bottom
        shr eax, 1
        mov rbx, ImageHeight
        shr ebx, 1
        sub eax, ebx
        
        mov pt.y, eax

        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            
            Invoke CreateCompatibleDC, hdcMain
            mov hdcMem, rax
            Invoke SelectObject, hdcMem, hImage
            mov hbmOld, rax
    
            Invoke BitBlt, hdcDest, pt.x, pt.y, dword ptr ImageWidth, dword ptr ImageHeight, hdcMem, 0, 0, SRCCOPY
    
            Invoke SelectObject, hdcMem, hbmOld
            Invoke DeleteDC, hdcMem
            .IF hbmOld != 0
                Invoke DeleteObject, hbmOld
            .ENDIF
            
        .ELSEIF rax == 2 ; icon
            Invoke DrawIconEx, hdcDest, pt.x, pt.y, hImage, 0, 0, 0, 0, DI_NORMAL
        
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
                Invoke GdipCreateFromHDC, hdcDest, Addr pGraphics
                
                Invoke GdipCreateBitmapFromGraphics, ImageWidth, ImageHeight, pGraphics, Addr pBitmap
                Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer            
                Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
                Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, ImageWidth, ImageHeight
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

    ret

_MUI_CheckboxPaintImages ENDP


;-------------------------------------------------------------------------------------
; _MUI_CheckboxSetPropertyEx
;-------------------------------------------------------------------------------------
_MUI_CheckboxSetPropertyEx PROC FRAME USES RBX hWin:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    
    mov rax, dqProperty
    .IF rax == @CheckboxTextFont
        .IF dqPropertyValue != 0
            Invoke MUISetExtProperty, hWin, dqProperty, dqPropertyValue 
        .ENDIF    
    .ELSE
        Invoke MUISetExtProperty, hWin, dqProperty, dqPropertyValue
    .ENDIF
    
	mov rax, dqProperty
	.IF rax == @CheckboxTextColor ; set other text colors to this if they are not set
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxTextColorAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxTextColorSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, rax
	        .ENDIF
	    .ENDIF
	
	.ELSEIF rax == @CheckboxTextColorSel
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSelAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, dqPropertyValue
	    .ENDIF

	.ELSEIF rax == @CheckboxImage
	    Invoke MUIGetExtProperty, hWin, @CheckboxImageAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxImageAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @CheckboxImageSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxImageSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @CheckboxImageSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @CheckboxImageSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @CheckboxImageSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @CheckboxImageSelAlt, rax
	        .ENDIF
	    .ENDIF			
	.ENDIF

    ret
_MUI_CheckboxSetPropertyEx ENDP


;-------------------------------------------------------------------------------------
; MUICheckboxLoadImages - Loads images from resource ids and stores the handles in the
; appropriate property.
;-------------------------------------------------------------------------------------
MUICheckboxLoadImages PROC FRAME hControl:QWORD, dqImageType:QWORD, dqResIDImage:QWORD, dqResIDImageAlt:QWORD, dqResIDImageSel:QWORD, dqResIDImageSelAlt:QWORD, dqResIDImageDisabled:QWORD, dqResIDImageDisabledSel:QWORD

    .IF dqImageType == 0
        ret
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @CheckboxImageType, dqImageType

    .IF dqResIDImage != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImage, dqResIDImage
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImage, dqResIDImage
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImage, dqResIDImage
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageAlt != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageAlt, dqResIDImageAlt
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageAlt, dqResIDImageAlt
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageAlt, dqResIDImageAlt
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageSel != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageSel, dqResIDImageSel
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageSel, dqResIDImageSel
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageSel, dqResIDImageSel
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageSelAlt != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageSelAlt, dqResIDImageSelAlt
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageSelAlt, dqResIDImageSelAlt
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageSelAlt, dqResIDImageSelAlt
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageDisabled != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageDisabled, dqResIDImageDisabled
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageDisabled, dqResIDImageDisabled
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageDisabled, dqResIDImageDisabled
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageDisabledSel != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageDisabledSel, dqResIDImageDisabledSel
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageDisabledSel, dqResIDImageDisabledSel
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageDisabledSel, dqResIDImageDisabledSel
            ENDIF
        .ENDIF
    .ENDIF
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    
    ret
MUICheckboxLoadImages ENDP


;-------------------------------------------------------------------------------------
; MUICheckboxSetImages - Sets the property handles for image types
;-------------------------------------------------------------------------------------
MUICheckboxSetImages PROC FRAME hControl:QWORD, dqImageType:QWORD, hImage:QWORD, hImageAlt:QWORD, hImageSel:QWORD, hImageSelAlt:QWORD, hImageDisabled:QWORD, hImageDisabledSel:QWORD

    .IF dqImageType == 0
        ret
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @CheckboxImageType, dqImageType

    .IF hImage != 0
        Invoke MUISetExtProperty, hControl, @CheckboxImage, hImage
    .ENDIF

    .IF hImageAlt != 0
        Invoke MUISetExtProperty, hControl, @CheckboxImageAlt, hImageAlt
    .ENDIF

    .IF hImageSel != 0
        Invoke MUISetExtProperty, hControl, @CheckboxImageSel, hImageSel
    .ENDIF

    .IF hImageSelAlt != 0
        Invoke MUISetExtProperty, hControl, @CheckboxImageSelAlt, hImageSelAlt
    .ENDIF

    .IF hImageDisabled != 0
        Invoke MUISetExtProperty, hControl, @CheckboxImageDisabled, hImageDisabled
    .ENDIF

    .IF hImageDisabledSel != 0
        Invoke MUISetExtProperty, hControl, @CheckboxImageDisabledSel, hImageDisabledSel
    .ENDIF
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    
    ret

MUICheckboxSetImages ENDP


;-------------------------------------------------------------------------------------
; MUICheckboxGetState
;-------------------------------------------------------------------------------------
MUICheckboxGetState PROC FRAME hControl:QWORD
    Invoke SendMessage, hControl, MUICM_GETSTATE, 0, 0
    ret
MUICheckboxGetState ENDP


;-------------------------------------------------------------------------------------
; MUICheckboxSetState
;-------------------------------------------------------------------------------------
MUICheckboxSetState PROC FRAME hControl:QWORD, bState:QWORD
    Invoke SendMessage, hControl, MUICM_SETSTATE, bState, 0
    ret
MUICheckboxSetState ENDP



;-------------------------------------------------------------------------------------
; _MUI_CheckboxLoadBitmap - if succesful, loads specified bitmap resource into the specified
; external property and returns TRUE in eax, otherwise FALSE.
;-------------------------------------------------------------------------------------
_MUI_CheckboxLoadBitmap PROC FRAME hWin:QWORD, dqProperty:QWORD, idResBitmap:QWORD
    LOCAL hinstance:QWORD

    .IF idResBitmap == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hWin, @CheckboxDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax
    
	Invoke LoadBitmap, hinstance, idResBitmap
    Invoke MUISetExtProperty, hWin, dqProperty, rax
	mov rax, TRUE
    
    ret

_MUI_CheckboxLoadBitmap ENDP


;-------------------------------------------------------------------------------------
; _MUI_CheckboxLoadIcon - if succesful, loads specified icon resource into the specified
; external property and returns TRUE in eax, otherwise FALSE.
;-------------------------------------------------------------------------------------
_MUI_CheckboxLoadIcon PROC FRAME hWin:QWORD, dqProperty:QWORD, idResIcon:QWORD
    LOCAL hinstance:QWORD

    .IF idResIcon == NULL
        mov rax, FALSE
        ret
    .ENDIF
    Invoke MUIGetExtProperty, hWin, @CheckboxDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax

	Invoke LoadImage, hinstance, idResIcon, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
    Invoke MUISetExtProperty, hWin, dqProperty, rax

	mov rax, TRUE

    ret

_MUI_CheckboxLoadIcon ENDP



;-------------------------------------------------------------------------------------
; Load JPG/PNG from resource using GDI+
;   Actually, this function can load any image format supported by GDI+
;
; by: Chris Vega
;
; Addendum KSR 2014 : Needs OLE32 include and lib for CreateStreamOnHGlobal and 
; GetHGlobalFromStream calls. Underlying stream needs to be left open for the life of
; the bitmap or corruption of png occurs. store png as RCDATA in resource file.
;-------------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
_MUI_CheckboxLoadPng PROC FRAME hWin:QWORD, dqProperty:QWORD, idResPng:QWORD
	local rcRes:HRSRC
	local hResData:HRSRC
	local pResData:HANDLE
	local sizeOfRes:QWORD
	local hbuffer:HANDLE
	local pbuffer:QWORD
	local pIStream:QWORD
	local hIStream:QWORD
    LOCAL hinstance:QWORD
    LOCAL pBitmapFromStream:QWORD

    Invoke MUIGetExtProperty, hWin, @CheckboxDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax

	; ------------------------------------------------------------------
	; STEP 1: Find the resource
	; ------------------------------------------------------------------
	invoke	FindResource, hinstance, idResPng, RT_RCDATA
	or 		rax, rax
	jnz		@f
	jmp		_MUI_CheckboxLoadPng@Close
@@:	mov		rcRes, rax
	
	; ------------------------------------------------------------------
	; STEP 2: Load the resource
	; ------------------------------------------------------------------
	invoke	LoadResource, hinstance, rcRes
	or		rax, rax
	jnz		@f
	ret		; Resource was not loaded
@@:	mov		hResData, rax

	; ------------------------------------------------------------------
	; STEP 3: Create a stream to contain our loaded resource
	; ------------------------------------------------------------------
	invoke	SizeofResource, hinstance, rcRes
	or		rax, rax
	jnz		@f
	jmp		_MUI_CheckboxLoadPng@Close
@@:	mov		sizeOfRes, rax
	
	invoke	LockResource, hResData
	or		rax, rax
	jnz		@f
	jmp		_MUI_CheckboxLoadPng@Close
@@:	mov		pResData, rax

	invoke	GlobalAlloc, GMEM_MOVEABLE, sizeOfRes
	or		rax, rax
	jnz		@f
	jmp		_MUI_CheckboxLoadPng@Close
@@:	mov		hbuffer, rax

	invoke	GlobalLock, hbuffer
	mov		pbuffer, rax
	
	invoke	RtlMoveMemory, pbuffer, hResData, sizeOfRes
	invoke	CreateStreamOnHGlobal, pbuffer, TRUE, addr pIStream
	or		rax, rax
	jz		@f
	jmp		_MUI_CheckboxLoadPng@Close
@@:	

	; ------------------------------------------------------------------
	; STEP 4: Create an image object from stream
	; ------------------------------------------------------------------
	invoke	GdipCreateBitmapFromStream, pIStream, Addr pBitmapFromStream
	
	; ------------------------------------------------------------------
	; STEP 5: Free all used locks and resources
	; ------------------------------------------------------------------
	invoke	GetHGlobalFromStream, pIStream, addr hIStream ; had to uncomment as corrupts pngs if left in, googling shows underlying stream needs to be left open for the life of the bitmap
	;invoke	GlobalFree, hIStream
	invoke	GlobalUnlock, hbuffer
	invoke	GlobalFree, hbuffer

    Invoke MUISetExtProperty, hWin, dwProperty, pBitmapFromStream
    ;PrintDec dwProperty
    ;PrintDec pBitmapFromStream
    
    mov rax, dqProperty
    .IF rax == @CheckboxImage
        Invoke MUISetIntProperty, hWin, @CheckboxImageStream, hIStream
    .ELSEIF rax == @CheckboxImageAlt
        Invoke MUISetIntProperty, hWin, @CheckboxImageAltStream, hIStream
    .ELSEIF rax == @CheckboxImageSel
        Invoke MUISetIntProperty, hWin, @CheckboxImageSelStream, hIStream
    .ELSEIF rax == @CheckboxImageSelAlt
        Invoke MUISetIntProperty, hWin, @CheckboxImageSelAltStream, hIStream
    .ELSEIF rax == @CheckboxImageDisabled
        Invoke MUISetIntProperty, hWin, @CheckboxImageDisabledStream, hIStream
    .ELSEIF rax == @CheckboxImageDisabledSel
        Invoke MUISetIntProperty, hWin, @CheckboxImageDisabledSelStream, hIStream
    .ENDIF

	mov rax, TRUE
	
_MUI_CheckboxLoadPng@Close:
	ret
_MUI_CheckboxLoadPng endp
ENDIF


;-------------------------------------------------------------------------------------
; _MUI_CheckboxPngReleaseIStream - releases png stream handle
;-------------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
_MUI_CheckboxPngReleaseIStream PROC FRAME hIStream:QWORD
    
    mov rax, hIStream
    push rax
    mov rax, QWORD PTR [rax]
    call IStreamX.IUnknown.Release[rax]                               ; release the stream
    ret

_MUI_CheckboxPngReleaseIStream ENDP
ENDIF


END
