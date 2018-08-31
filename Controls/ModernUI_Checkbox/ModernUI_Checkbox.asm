;==============================================================================
;
; ModernUI x64 Control - ModernUI_Checkbox x64
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

MUI_DONTUSEGDIPLUS EQU 1 ; exclude (gdiplus) support
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
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

include ModernUI.inc
includelib ModernUI.lib

IFDEF MUI_USEGDIPLUS
ECHO MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib
includelib ole32.lib
ELSE
ECHO MUI_DONTUSEGDIPLUS
ENDIF

include ModernUI_Checkbox.inc
include ModernUI_Checkbox_Icons.asm

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_CheckboxWndProc					PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_CheckboxInit					    PROTO :QWORD
_MUI_CheckboxCleanup                    PROTO :QWORD
_MUI_CheckboxSetColors                  PROTO :QWORD, :QWORD
_MUI_CheckboxPaint					    PROTO :QWORD

_MUI_CheckboxPaintBackground            PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CheckboxPaintText                  PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CheckboxPaintImages                PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CheckboxPaintFocusRect             PROTO :QWORD, :QWORD, :QWORD, :QWORD

_MUI_CheckboxButtonDown                 PROTO :QWORD ; WM_LBUTTONDOWN, WM_KEYDOWN + VK_SPACE
_MUI_CheckboxButtonUp                   PROTO :QWORD ; WM_LBUTTONUP, WM_KEYUP + VK_SPACE

_MUI_CheckboxLoadBitmap                 PROTO :QWORD, :QWORD, :QWORD
_MUI_CheckboxLoadIcon                   PROTO :QWORD, :QWORD, :QWORD
IFDEF MUI_USEGDIPLUS
_MUI_CheckboxLoadPng                    PROTO :QWORD, :QWORD, :QWORD
ENDIF

IFDEF MUI_USEGDIPLUS
_MUI_CheckboxPngReleaseIStream          PROTO :QWORD
ENDIF
_MUI_CheckboxSetPropertyEx              PROTO :QWORD, :QWORD, :QWORD


;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
IFNDEF MUI_CHECKBOX_PROPERTIES
MUI_CHECKBOX_PROPERTIES                 STRUCT
    qwTextFont                          DQ ?       ; hFont
    qwTextColor                         DQ ?       ; Colorref
    qwTextColorAlt                      DQ ?       ; Colorref
    qwTextColorSel                      DQ ?       ; Colorref
    qwTextColorSelAlt                   DQ ?       ; Colorref
    qwTextColorDisabled                 DQ ?       ; Colorref
    qwBackColor                         DQ ?       ; Colorref
    qwImageType                         DQ ?       ; image type
    qwImage                             DQ ?       ; hImage for empty checkbox
    qwImageAlt                          DQ ?       ; hImage for empty checkbox when mouse moves over checkbox
    qwImageSel                          DQ ?       ; hImage for checkbox with checkmark
    qwImageSelAlt                       DQ ?       ; hImage for checkbox with checkmark when mouse moves over checkbox
    qwImageDisabled                     DQ ?       ; hImage for disabled empty checkbox
    qwImageDisabledSel                  DQ ?       ; hImage for disabled checkbox with checkmark
    qwCheckboxDllInstance               DQ ?
    qwCheckboxParam                     DQ ?
MUI_CHECKBOX_PROPERTIES			        ENDS
ENDIF

; Internal properties
_MUI_CHECKBOX_PROPERTIES				STRUCT
	qwEnabledState						DQ ?
	qwMouseOver							DQ ?
	qwSelectedState                     DQ ?
    qwFocusedState                      DQ ?
    qwMouseDown                         DQ ?  	
	qwImageStream                       DQ ?
	qwImageAltStream                    DQ ?
	qwImageSelStream                    DQ ?
	qwImageSelAltStream                 DQ ?
	qwImageDisabledStream               DQ ?
	qwImageDisabledSelStream            DQ ?
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
MUI_CHECKBOX_FOCUSRECT_OFFSET           EQU -2 ; change this to higher negative value to shrink focus rect within checkbox

; Internal properties
@CheckboxEnabledState				    EQU 0
@CheckboxMouseOver					    EQU 8
@CheckboxSelectedState                  EQU 16
@CheckboxFocusedState                   EQU 24
@CheckboxMouseDown                      EQU 32
@CheckboxImageStream                    EQU 40
@CheckboxImageAltStream                 EQU 48
@CheckboxImageSelStream                 EQU 56
@CheckboxImageSelAltStream              EQU 64
@CheckboxImageDisabledStream            EQU 72
@CheckboxImageDisabledSelStream         EQU 80

; External public properties


.DATA
szMUICheckboxClass					    DB 'ModernUI_Checkbox',0 	        ; Class name for creating our ModernUI_Checkbox control
szMUICheckboxFont                       DB 'Segoe UI',0             	    ; Font used for ModernUI_Checkbox text
hMUICheckboxFont                        DQ 0                        	    ; Handle to ModernUI_Checkbox font (segoe ui)


hDefault_icoMUICheckboxTick             DQ 0
hDefault_icoMUICheckboxEmpty            DQ 0
hDefault_icoMUICheckboxDisabledTick     DQ 0
hDefault_icoMUICheckboxDisabledEmpty    DQ 0
hDefault_icoMUIRadioTick                DQ 0
hDefault_icoMUIRadioEmpty               DQ 0
hDefault_icoMUIRadioDisabledTick        DQ 0
hDefault_icoMUIRadioDisabledEmpty       DQ 0

.DATA
IFDEF DEBUG64
DbgVar                                      DQ ?
ENDIF


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for ModernUI_Checkbox control
;------------------------------------------------------------------------------
MUICheckboxSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUICheckboxSetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for ModernUI_Checkbox control
;------------------------------------------------------------------------------
MUICheckboxGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUICheckboxGetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICheckboxRegister - Registers the ModernUI_Checkbox control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Checkbox
;------------------------------------------------------------------------------
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


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICheckboxCreate - Returns handle in rax of newly created control
;------------------------------------------------------------------------------
MUICheckboxCreate PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL qwNewStyle:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUICheckboxRegister
	
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN. Non visual prob dont need any of these.

    mov rax, qwStyle
    mov qwNewStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        or qwNewStyle, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .ENDIF
	
    Invoke CreateWindowEx, NULL, Addr szMUICheckboxClass, lpszText, dword ptr qwNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUICheckboxCreate ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxWndProc - Main processing window for our control
;------------------------------------------------------------------------------
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
        and rax, MUICBS_HAND
        .IF rax == MUICBS_HAND
		    invoke LoadCursor, NULL, IDC_HAND
        .ELSE
            invoke LoadCursor, NULL, IDC_ARROW
        .ENDIF
        Invoke SetCursor, rax
        mov rax, 0
        ret

    .ELSEIF eax == WM_KEYUP
        mov rax, wParam
        .IF rax == VK_SPACE
            Invoke _MUI_CheckboxButtonUp, hWin
;        .ELSEIF eax == VK_TAB
;            Invoke GetParent, hWin
;            mov hParent, eax
;            Invoke GetAsyncKeyState, VK_SHIFT
;            .IF eax != 0
;                Invoke GetWindow, hWin, GW_HWNDPREV
;            .ELSE
;                Invoke GetWindow, hWin, GW_HWNDNEXT
;            .ENDIF
;            .IF eax != 0
;                Invoke SetFocus, eax
;            .ENDIF
        .ENDIF

    .ELSEIF eax == WM_KEYDOWN
        mov rax, wParam
        .IF rax == VK_SPACE
            Invoke _MUI_CheckboxButtonDown, hWin
        .ENDIF

    .ELSEIF eax == WM_LBUTTONUP
        Invoke _MUI_CheckboxButtonUp, hWin

    .ELSEIF eax == WM_LBUTTONDOWN
        Invoke _MUI_CheckboxButtonDown, hWin

   .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUIGetIntProperty, hWin, @CheckboxEnabledState
        .IF rax == TRUE   
    		Invoke MUISetIntProperty, hWin, @CheckboxMouseOver, TRUE
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
        Invoke MUIGetIntProperty, hWin, @CheckboxFocusedState
        .IF rax == FALSE
            Invoke MUISetIntProperty, hWin, @CheckboxMouseOver, FALSE
        .ENDIF
        Invoke MUISetIntProperty, hWin, @CheckboxMouseDown, FALSE
        Invoke InvalidateRect, hWin, NULL, TRUE

    .ELSEIF eax == WM_SETFOCUS
        Invoke MUISetIntProperty, hWin, @CheckboxFocusedState, TRUE
        Invoke MUISetIntProperty, hWin, @CheckboxMouseOver, TRUE
        Invoke InvalidateRect, hWin, NULL, TRUE
        mov rax, 0
        ret

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @CheckboxFocusedState, FALSE
        Invoke MUISetIntProperty, hWin, @CheckboxMouseOver, FALSE
        Invoke InvalidateRect, hWin, NULL, TRUE
        mov rax, 0
        ret  

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

    .ELSEIF eax == WM_SYSCOLORCHANGE
        Invoke _MUI_CheckboxSetColors, hWin, FALSE
        ret
	
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxInit - set initial default values
;------------------------------------------------------------------------------
_MUI_CheckboxInit PROC FRAME hWin:QWORD
    LOCAL ncm:NONCLIENTMETRICS
    LOCAL lfnt:LOGFONT
    LOCAL hFont:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    
    Invoke GetParent, hWin
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, qwStyle
        or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov qwStyle, rax
        Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwStyle
    .ENDIF
    ;PrintDec qwStyle
    
    ; Set default initial internal property values
    mov rax, qwStyle
    and rax, WS_DISABLED
    .IF rax == WS_DISABLED
        Invoke MUISetIntProperty, hWin, @CheckboxEnabledState, FALSE
    .ELSE
        Invoke MUISetIntProperty, hWin, @CheckboxEnabledState, TRUE
    .ENDIF        
    
    ; Set default initial external property values
    Invoke _MUI_CheckboxSetColors, hWin, TRUE

    Invoke MUISetExtProperty, hWin, @CheckboxDllInstance, 0
    
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
    Invoke MUISetExtProperty, hWin, @CheckboxTextFont, hMUICheckboxFont

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
    .IF hDefault_icoMUIRadioDisabledEmpty == 0
        Invoke MUICreateIconFromMemory, Addr icoMUIRadioDisabledEmpty, 0
        mov hDefault_icoMUIRadioDisabledEmpty, rax
    .ENDIF
    .IF hDefault_icoMUIRadioDisabledTick == 0
        Invoke MUICreateIconFromMemory, Addr icoMUIRadioDisabledTick, 0
        mov hDefault_icoMUIRadioDisabledTick, rax
    .ENDIF
    .IF hDefault_icoMUICheckboxDisabledEmpty == 0
        Invoke MUICreateIconFromMemory, Addr icoMUICheckboxDisabledEmpty, 0
        mov hDefault_icoMUICheckboxDisabledEmpty, rax
    .ENDIF
    .IF hDefault_icoMUICheckboxDisabledTick == 0
        Invoke MUICreateIconFromMemory, Addr icoMUICheckboxDisabledTick, 0
        mov hDefault_icoMUICheckboxDisabledTick, rax
    .ENDIF    
    Invoke MUISetExtProperty, hWin, @CheckboxImageType, MUICIT_ICO

    mov rax, qwStyle
    and rax, MUICBS_RADIO
    .IF rax == MUICBS_RADIO
        Invoke MUISetExtProperty, hWin, @CheckboxImage, hDefault_icoMUIRadioEmpty
        Invoke MUISetExtProperty, hWin, @CheckboxImageAlt, hDefault_icoMUIRadioEmpty
        Invoke MUISetExtProperty, hWin, @CheckboxImageSel, hDefault_icoMUIRadioTick
        Invoke MUISetExtProperty, hWin, @CheckboxImageSelAlt, hDefault_icoMUIRadioTick
        Invoke MUISetExtProperty, hWin, @CheckboxImageDisabled, hDefault_icoMUIRadioDisabledEmpty
        Invoke MUISetExtProperty, hWin, @CheckboxImageDisabledSel, hDefault_icoMUIRadioDisabledTick
    .ELSE
        Invoke MUISetExtProperty, hWin, @CheckboxImage, hDefault_icoMUICheckboxEmpty
        Invoke MUISetExtProperty, hWin, @CheckboxImageAlt, hDefault_icoMUICheckboxEmpty
        Invoke MUISetExtProperty, hWin, @CheckboxImageSel, hDefault_icoMUICheckboxTick
        Invoke MUISetExtProperty, hWin, @CheckboxImageSelAlt, hDefault_icoMUICheckboxTick
        Invoke MUISetExtProperty, hWin, @CheckboxImageDisabled, hDefault_icoMUICheckboxDisabledEmpty
        Invoke MUISetExtProperty, hWin, @CheckboxImageDisabledSel, hDefault_icoMUICheckboxDisabledTick
    .ENDIF

    ret

_MUI_CheckboxInit ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxCleanup - cleanup a few things before control is destroyed
;------------------------------------------------------------------------------
_MUI_CheckboxCleanup PROC FRAME hControl:QWORD
    LOCAL qwImageType:QWORD
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
    LOCAL qwStyle:QWORD
    
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov qwStyle, rax
    
    IFDEF DEBUG64
    PrintText '_MUI_CheckboxCleanup'
    ENDIF
    ; cleanup any stream handles if png where loaded as resources
    Invoke MUIGetExtProperty, hControl, @CheckboxImageType
    mov qwImageType, rax

    .IF qwImageType == MUICIT_NONE
        ret
    .ENDIF
    
    .IF qwImageType == MUICIT_PNG
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
        .IF qwImageType != MUICIT_PNG
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
        .IF qwImageType != MUICIT_PNG
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
        .IF qwImageType != MUICIT_PNG
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
        .IF qwImageType != MUICIT_PNG
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
        .IF qwImageType != MUICIT_PNG
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
        .IF qwImageType != MUICIT_PNG
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxSetColors - Set colors on init or syscolorchange if MUIBS_THEME 
; style used
;------------------------------------------------------------------------------
_MUI_CheckboxSetColors PROC FRAME hWin:QWORD, bInit:QWORD

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    and rax, MUICBS_THEME
    .IF rax == MUICBS_THEME
        ; Set color property values based on system colors
        Invoke GetSysColor, COLOR_BTNTEXT
        Invoke MUISetExtProperty, hWin, @CheckboxTextColor, rax
        Invoke GetSysColor, COLOR_HOTLIGHT
        Invoke MUISetExtProperty, hWin, @CheckboxTextColorAlt, rax
        Invoke GetSysColor, COLOR_HIGHLIGHT
        Invoke MUISetExtProperty, hWin, @CheckboxTextColorSel, rax
        Invoke GetSysColor, COLOR_HOTLIGHT
        Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, rax
        Invoke GetSysColor, COLOR_GRAYTEXT
        Invoke MUISetExtProperty, hWin, @CheckboxTextColorDisabled, rax


        Invoke GetSysColor, COLOR_WINDOW
        Invoke MUISetExtProperty, hWin, @CheckboxBackColor, rax

    .ELSE

        .IF bInit == TRUE
            ; Set color property values based on custom values
            Invoke MUISetExtProperty, hWin, @CheckboxTextColor, MUI_RGBCOLOR(51,51,51)
            Invoke MUISetExtProperty, hWin, @CheckboxTextColorAlt, MUI_RGBCOLOR(41,122,185)
            Invoke MUISetExtProperty, hWin, @CheckboxTextColorSel, MUI_RGBCOLOR(51,51,51)
            Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, MUI_RGBCOLOR(41,122,185)
            Invoke MUISetExtProperty, hWin, @CheckboxTextColorDisabled, MUI_RGBCOLOR(204,204,204)
        
            Invoke MUIGetParentBackgroundColor, hWin
            .IF rax == -1 ; if background was NULL then try a color as default
                Invoke GetSysColor, COLOR_WINDOW
            .ENDIF
            Invoke MUISetExtProperty, hWin, @CheckboxBackColor, eax
            ;Invoke MUISetExtProperty, hWin, @CheckboxBackColor, MUI_RGBCOLOR(240,240,240) ;MUI_RGBCOLOR(21,133,181)
        .ENDIF
    .ENDIF
    ret
_MUI_CheckboxSetColors ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxButtonDown - Mouse button down or keyboard down from vk_space
;------------------------------------------------------------------------------
_MUI_CheckboxButtonDown PROC FRAME hWin:QWORD
    LOCAL hParent:QWORD
    LOCAL rect:RECT    

    Invoke GetFocus
    .IF rax != hWin
        Invoke SetFocus, hWin
        Invoke MUISetIntProperty, hWin, @CheckboxFocusedState, FALSE
    .ENDIF

    Invoke MUISetIntProperty, hWin, @CheckboxMouseDown, TRUE
    Invoke InvalidateRect, hWin, NULL, TRUE

    ret
_MUI_CheckboxButtonDown ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxButtonUp - Mouse button up or keyboard up from vk_space
;------------------------------------------------------------------------------
_MUI_CheckboxButtonUp PROC FRAME hWin:QWORD
    LOCAL hParent:QWORD
    LOCAL wID:QWORD
    LOCAL rect:RECT

    Invoke MUIGetIntProperty, hWin, @CheckboxMouseDown
    .IF eax == TRUE
        Invoke GetDlgCtrlID, hWin
        mov wID,rax
        Invoke GetParent, hWin
        mov hParent, rax
        Invoke PostMessage, hParent, WM_COMMAND, wID, hWin ; simulates click on our control    
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @CheckboxSelectedState
    .IF rax == FALSE
        Invoke MUISetIntProperty, hWin, @CheckboxSelectedState, TRUE
    .ELSE
        Invoke MUISetIntProperty, hWin, @CheckboxSelectedState, FALSE
    .ENDIF
    Invoke InvalidateRect, hWin, NULL, TRUE
    ret
_MUI_CheckboxButtonUp ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxPaint
;------------------------------------------------------------------------------
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
    LOCAL FocusedState:QWORD
    LOCAL SavedDChdcMem:QWORD

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
    Invoke MUIGetIntProperty, hWin, @CheckboxFocusedState
    mov FocusedState, rax
	
	Invoke SaveDC, hdcMem ; save hdcmem for focus rect
	mov SavedDChdcMem, rax ; otherwise color of focus is off 
	
	;----------------------------------------------------------
	; Background
	;----------------------------------------------------------
	Invoke _MUI_CheckboxPaintBackground, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Images
	;----------------------------------------------------------
    Invoke _MUI_CheckboxPaintImages, hWin, hdcMem, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Text
	;----------------------------------------------------------
	Invoke _MUI_CheckboxPaintText, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

    ;----------------------------------------------------------
    ; Focused state
    ;----------------------------------------------------------
    Invoke RestoreDC, hdcMem, dword ptr SavedDChdcMem
    Invoke _MUI_CheckboxPaintFocusRect, hWin, hdcMem, Addr rect, FocusedState

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
_MUI_CheckboxPaint ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxPaintBackground
;------------------------------------------------------------------------------
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxPaintText
;------------------------------------------------------------------------------
_MUI_CheckboxPaintText PROC FRAME USES RBX hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwTextStyle:QWORD
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
    mov qwStyle, rax
    
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
    ;mov qwTextStyle, 
    
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxPaintImages
;------------------------------------------------------------------------------
_MUI_CheckboxPaintImages PROC FRAME USES RBX hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwImageType:QWORD
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
    mov qwStyle, rax
    
    Invoke MUIGetExtProperty, hWin, @CheckboxImageType        
    mov qwImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png
    
    ;PrintDec ImageType
    
    .IF qwImageType == 0
        ret
    .ENDIF    
    
    .IF qwImageType != 0
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
        Invoke MUIGetImageSize, hImage, qwImageType, Addr ImageWidth, Addr ImageHeight
        
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

        mov rax, qwImageType
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxPaintFocusRect
;------------------------------------------------------------------------------
_MUI_CheckboxPaintFocusRect PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bFocusedState:QWORD
    LOCAL rect:RECT

    .IF bFocusedState == FALSE
        ret
    .ENDIF

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    and rax, MUICBS_NOFOCUSRECT
    .IF rax == MUICBS_NOFOCUSRECT
        ret
    .ENDIF

    Invoke CopyRect, Addr rect, lpRect
    Invoke InflateRect, Addr rect, MUI_CHECKBOX_FOCUSRECT_OFFSET, MUI_CHECKBOX_FOCUSRECT_OFFSET
    Invoke DrawFocusRect, hdc, Addr rect
 
    ret
_MUI_CheckboxPaintFocusRect ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxSetPropertyEx
;------------------------------------------------------------------------------
_MUI_CheckboxSetPropertyEx PROC FRAME USES RBX hWin:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    
    mov rax, qwProperty
    .IF rax == @CheckboxTextFont
        .IF qwPropertyValue != 0
            Invoke MUISetExtProperty, hWin, qwProperty, qwPropertyValue 
        .ENDIF    
    .ELSE
        Invoke MUISetExtProperty, hWin, qwProperty, qwPropertyValue
    .ENDIF
    
	mov rax, qwProperty
	.IF rax == @CheckboxTextColor ; set other text colors to this if they are not set
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxTextColorAlt, qwPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxTextColorSel, qwPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, qwPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, rax
	        .ENDIF
	    .ENDIF
	
	.ELSEIF rax == @CheckboxTextColorSel
	    Invoke MUIGetExtProperty, hWin, @CheckboxTextColorSelAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxTextColorSelAlt, qwPropertyValue
	    .ENDIF

	.ELSEIF rax == @CheckboxImage
	    Invoke MUIGetExtProperty, hWin, @CheckboxImageAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxImageAlt, qwPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @CheckboxImageSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @CheckboxImageSel, qwPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @CheckboxImageSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @CheckboxImageSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @CheckboxImageSelAlt, qwPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @CheckboxImageSelAlt, rax
	        .ENDIF
	    .ENDIF			
	.ENDIF

    ret
_MUI_CheckboxSetPropertyEx ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICheckboxLoadImages - Loads images from resource ids and stores the handles in the
; appropriate property.
;------------------------------------------------------------------------------
MUICheckboxLoadImages PROC FRAME hControl:QWORD, qwImageType:QWORD, qwResIDImage:QWORD, qwResIDImageAlt:QWORD, qwResIDImageSel:QWORD, qwResIDImageSelAlt:QWORD, qwResIDImageDisabled:QWORD, qwResIDImageDisabledSel:QWORD

    .IF qwImageType == 0
        ret
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @CheckboxImageType, qwImageType

    .IF qwResIDImage != 0
        mov rax, qwImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImage, qwResIDImage
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImage, qwResIDImage
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImage, qwResIDImage
            ENDIF
        .ENDIF
    .ENDIF

    .IF qwResIDImageAlt != 0
        mov rax, qwImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageAlt, qwResIDImageAlt
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageAlt, qwResIDImageAlt
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageAlt, qwResIDImageAlt
            ENDIF
        .ENDIF
    .ENDIF

    .IF qwResIDImageSel != 0
        mov rax, qwImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageSel, qwResIDImageSel
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageSel, qwResIDImageSel
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageSel, qwResIDImageSel
            ENDIF
        .ENDIF
    .ENDIF

    .IF qwResIDImageSelAlt != 0
        mov rax, qwImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageSelAlt, qwResIDImageSelAlt
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageSelAlt, qwResIDImageSelAlt
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageSelAlt, qwResIDImageSelAlt
            ENDIF
        .ENDIF
    .ENDIF

    .IF qwResIDImageDisabled != 0
        mov rax, qwImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageDisabled, qwResIDImageDisabled
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageDisabled, qwResIDImageDisabled
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageDisabled, qwResIDImageDisabled
            ENDIF
        .ENDIF
    .ENDIF

    .IF qwResIDImageDisabledSel != 0
        mov rax, qwImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_CheckboxLoadBitmap, hControl, @CheckboxImageDisabledSel, qwResIDImageDisabledSel
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_CheckboxLoadIcon, hControl, @CheckboxImageDisabledSel, qwResIDImageDisabledSel
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_CheckboxLoadPng, hControl, @CheckboxImageDisabledSel, qwResIDImageDisabledSel
            ENDIF
        .ENDIF
    .ENDIF
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    
    ret
MUICheckboxLoadImages ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICheckboxSetImages - Sets the property handles for image types
;------------------------------------------------------------------------------
MUICheckboxSetImages PROC FRAME hControl:QWORD, qwImageType:QWORD, hImage:QWORD, hImageAlt:QWORD, hImageSel:QWORD, hImageSelAlt:QWORD, hImageDisabled:QWORD, hImageDisabledSel:QWORD

    .IF qwImageType == 0
        ret
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @CheckboxImageType, qwImageType

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


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICheckboxGetState
;------------------------------------------------------------------------------
MUICheckboxGetState PROC FRAME hControl:QWORD
    Invoke SendMessage, hControl, MUICM_GETSTATE, 0, 0
    ret
MUICheckboxGetState ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICheckboxSetState
;------------------------------------------------------------------------------
MUICheckboxSetState PROC FRAME hControl:QWORD, bState:QWORD
    Invoke SendMessage, hControl, MUICM_SETSTATE, bState, 0
    ret
MUICheckboxSetState ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxLoadBitmap - if succesful, loads specified bitmap resource into the specified
; external property and returns TRUE in eax, otherwise FALSE.
;------------------------------------------------------------------------------
_MUI_CheckboxLoadBitmap PROC FRAME hWin:QWORD, qwProperty:QWORD, idResBitmap:QWORD
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
    Invoke MUISetExtProperty, hWin, qwProperty, rax
	mov rax, TRUE
    
    ret

_MUI_CheckboxLoadBitmap ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CheckboxLoadIcon - if succesful, loads specified icon resource into the specified
; external property and returns TRUE in eax, otherwise FALSE.
;------------------------------------------------------------------------------
_MUI_CheckboxLoadIcon PROC FRAME hWin:QWORD, qwProperty:QWORD, idResIcon:QWORD
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
    Invoke MUISetExtProperty, hWin, qwProperty, rax

	mov rax, TRUE

    ret

_MUI_CheckboxLoadIcon ENDP



;MUICreateIconFromMemoryTest PROC FRAME USES RDX pIconData:QWORD, iIcon:QWORD
;    LOCAL sz[2]:DWORD
;    LOCAL pbIconBits:QWORD
;    LOCAL cbIconBits:DWORD
;    LOCAL cxDesired:DWORD
;    LOCAL cyDesired:DWORD
;
;    xor rax, rax
;    mov rdx, [pIconData]
;    or rdx, rdx
;    jz ERRORCATCH
;
;    movzx rax, WORD PTR [rdx+4]
;    cmp rax, [iIcon]
;    ja @F
;        ERRORCATCH:
;        push rax
;        invoke SetLastError, ERROR_RESOURCE_NAME_NOT_FOUND
;        pop rdx
;        xor rax, rax
;        ret
;    @@:
;
;    mov rax, [iIcon]
;    shl rax, 4
;    add rdx, rax
;    add rdx, 6
;
;    movzx eax, BYTE PTR [rdx]
;    mov [sz], eax
;    mov cxDesired, eax
;    movzx eax, BYTE PTR [rdx+1]
;    mov [sz+4], eax
;    mov cyDesired, eax
;
;    mov rdx, [pIconData]
;    mov rax, [iIcon]
;    shl rax, 4
;    add rdx, rax
;    add rdx, 6
;    xor eax, eax
;    mov eax, dword ptr [rdx+8]
;    mov cbIconBits, eax
;    
;    mov rdx, [pIconData]
;    mov rax, [iIcon]
;    shl rax, 4
;    add rdx, rax
;    add rdx, 6
;    xor eax, eax
;    mov eax, dword ptr [rdx+12]
;    add rax, [pIconData]
;    mov pbIconBits, rax
;
;    mov rax, pbIconBits
;    PrintQWORD rax
;    
;    xor rax, rax
;    mov eax, cbIconBits
;    PrintQWORD rax
;    
;    xor rax, rax
;    mov eax, cxDesired
;    PrintQWORD rax
;    
;    xor rax, rax
;    mov eax, cyDesired
;    PrintQWORD rax
;
;    Invoke CreateIconFromResourceEx, pbIconBits, cbIconBits, 1, 030000h, cxDesired, cyDesired, 0
;    PrintQWORD rax
;    
;    xor rdx, rdx
;    mov edx,[sz]
;    shl edx,16
;    mov dx, word ptr [sz+4]
;
;    RET
;
;
;MUICreateIconFromMemoryTest ENDP



;------------------------------------------------------------------------------
; Load JPG/PNG from resource using GDI+
;   Actually, this function can load any image format supported by GDI+
;
; by: Chris Vega
;
; Addendum KSR 2014 : Needs OLE32 include and lib for CreateStreamOnHGlobal and 
; GetHGlobalFromStream calls. Underlying stream needs to be left open for the life of
; the bitmap or corruption of png occurs. store png as RCDATA in resource file.
;------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
MUI_ALIGN
_MUI_CheckboxLoadPng PROC FRAME hWin:QWORD, qwProperty:QWORD, idResPng:QWORD
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

    Invoke MUISetExtProperty, hWin, qwProperty, pBitmapFromStream
    ;PrintDec qwProperty
    ;PrintDec pBitmapFromStream
    
    mov rax, qwProperty
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


;------------------------------------------------------------------------------
; _MUI_CheckboxPngReleaseIStream - releases png stream handle
;------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
MUI_ALIGN
_MUI_CheckboxPngReleaseIStream PROC FRAME hIStream:QWORD
    
    mov rax, hIStream
    push rax
    mov rax, QWORD PTR [rax]
    call IStreamX.IUnknown.Release[rax]                               ; release the stream
    ret

_MUI_CheckboxPngReleaseIStream ENDP
ENDIF


END
