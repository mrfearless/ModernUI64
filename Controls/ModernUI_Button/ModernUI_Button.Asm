;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_Button x64 v1.0.0.0
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
;
;IFDEF DEBUG64
;    PRESERVEXMMREGS equ 1
;    includelib \JWasm\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'\Jwasm\bin\DbgWin.exe'>
;    include \JWasm\include\debug64.inc
;    .DATA
;    RDBG_DbgWin	DB DEBUGEXE,0
;    .CODE
;ENDIF

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

include ModernUI_Button.inc

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
_MUI_ButtonWndProc					        PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_ButtonInit					            PROTO :QWORD
_MUI_ButtonCleanup                          PROTO :QWORD
_MUI_ButtonPaint					        PROTO :QWORD

_MUI_ButtonPaintBackground                  PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_ButtonPaintAccent                      PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_ButtonPaintText                        PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_ButtonPaintImages                      PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_ButtonPaintBorder                      PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_ButtonCalcPositions                    PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD

_MUI_ButtonLoadBitmap                       PROTO :QWORD, :QWORD, :QWORD
_MUI_ButtonLoadIcon                         PROTO :QWORD, :QWORD, :QWORD
IFDEF MUI_USEGDIPLUS
_MUI_ButtonLoadPng                          PROTO :QWORD, :QWORD, :QWORD
ENDIF
;_MUI_ButtonGetImageSize                     PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD

IFDEF MUI_USEGDIPLUS
_MUI_ButtonPngReleaseIStream                PROTO :QWORD
ENDIF
_MUI_ButtonSetPropertyEx                    PROTO :QWORD, :QWORD, :QWORD

;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; External public properties
IFNDEF MUI_BUTTON_PROPERTIES
MUI_BUTTON_PROPERTIES				        STRUCT
    dqTextFont                              DQ ?
    dqTextColor                             DQ ? 
    dqTextColorAlt                          DQ ? 
    dqTextColorSel                          DQ ? 
    dqTextColorSelAlt                       DQ ? 
    dqTextColorDisabled                     DQ ? 
    dqBackColor                             DQ ? 
    dqBackColorAlt                          DQ ? 
    dqBackColorSel                          DQ ? 
    dqBackColorSelAlt                       DQ ? 
    dqBackColorDisabled                     DQ ? 
    dqBorderColor                           DQ ? 
    dqBorderColorAlt                        DQ ? 
    dqBorderColorSel                        DQ ? 
    dqBorderColorSelAlt                     DQ ? 
    dqBorderColorDisabled                   DQ ? 
    dqBorderStyle                           DQ ? 
    dqAccentColor                           DQ ? 
    dqAccentColorAlt                        DQ ? 
    dqAccentColorSel                        DQ ? 
    dqAccentColorSelAlt                     DQ ? 
    dqAccentStyle                           DQ ? 
    dqAccentStyleAlt                        DQ ? 
    dqAccentStyleSel                        DQ ? 
    dqAccentStyleSelAlt                     DQ ? 
    dqImageType                             DQ ? 
    dqImage                                 DQ ? 
    dqImageAlt                              DQ ? 
    dqImageSel                              DQ ? 
    dqImageSelAlt                           DQ ? 
    dqImageDisabled                         DQ ?
	dqRightImage                            DQ ?
	dqRightImageAlt                         DQ ?
	dqRightImageSel                         DQ ?
	dqRightImageSelAlt                      DQ ?
	dqRightImageDisabled                    DQ ?	    
    dqNotifyTextFont                        DQ ? 
    dqNotifyTextColor                       DQ ? 
    dqNotifyBackColor                       DQ ? 
    dqNotifyRound                           DQ ? 
    dqNotifyImageType                       DQ ? 
    dqNotifyImage                           DQ ? 
    dqButtonNoteTextFont                    DQ ?
    dqButtonNoteTextColor                   DQ ?
    dqButtonNoteTextColorDisabled           DQ ?
    dqButtonPaddingLeftIndent               DQ ?
    dqButtonPaddingGeneral                  DQ ?
    dqButtonPaddingStyle                    DQ ?
    dqButtonPaddingTextImage                DQ ?  
    dqButtonDllInstance                     DQ ? ; Set to hInstance of dll before calling MUIButtonLoadImages or MUIButtonNotifyLoadImage if used within a dll
MUI_BUTTON_PROPERTIES				        ENDS
ENDIF

; Internal properties
; Internal properties
_MUI_BUTTON_PROPERTIES				        STRUCT
	dqEnabledState						    DQ ?
	dqMouseOver							    DQ ?
	dqSelectedState                         DQ ?
	dqMouseDown                             DQ ?
	dqNotifyState                           DQ ?
	lpszNotifyText                          DQ ?
	lpszNoteText                            DQ ?
	dqImageStream                           DQ ?
	dqImageAltStream                        DQ ?
	dqImageSelStream                        DQ ?
	dqImageSelAltStream                     DQ ?
	dqImageDisabledStream                   DQ ?
	dqRightImageStream                      DQ ?
	dqRightImageAltStream                   DQ ?
	dqRightImageSelStream                   DQ ?
	dqRightImageSelAltStream                DQ ?
	dqRightImageDisabledStream              DQ ?	
	dqNotifyImageStream                     DQ ?
	dqImageXposition                        DQ ?
	dqImageYposition                        DQ ?
	dqRightImageXposition                   DQ ?
	dqRightImageYposition                   DQ ?
	dqNotifyImageXposition                  DQ ?
	dqNotifyImageYposition                  DQ ?
	dqTextXposition                         DQ ?
	dqTextYposition                         DQ ?
	dqNoteXposition                         DQ ?
	dqNoteYposition                         DQ ?
    dqButtonRecalcPositions                 DQ ? ; set to TRUE in init and when properties change and/or wm_size, wm_settext, wm_setfont ? not sure if to implement or just calc on each wm_paint call
_MUI_BUTTON_PROPERTIES				        ENDS

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
ACCENTWIDTH                                 EQU 6d


; Internal properties
@ButtonEnabledState				            EQU 0
@ButtonMouseOver					        EQU 8
@ButtonSelectedState                        EQU 16
@ButtonMouseDown                            EQU 24
@ButtonNotifyState                          EQU 32
@ButtonszNotifyText                         EQU 40
@ButtonszNoteText                           EQU 48
@ButtonImageStream                          EQU 56
@ButtonImageAltStream                       EQU 64
@ButtonImageSelStream                       EQU 72
@ButtonImageSelAltStream                    EQU 80
@ButtonImageDisabledStream                  EQU 88
@ButtonRightImageStream                     EQU 96
@ButtonRightImageAltStream                  EQU 104
@ButtonRightImageSelStream                  EQU 112
@ButtonRightImageSelAltStream               EQU 120
@ButtonRightImageDisabledStream             EQU 128
@ButtonNotifyImageStream                    EQU 136
@ButtonImageXposition                       EQU 144
@ButtonImageYposition                       EQU 152
@ButtonRightImageXposition                  EQU 160
@ButtonRightImageYposition                  EQU 168
@ButtonNotifyImageXposition                 EQU 176
@ButtonNotifyImageYposition                 EQU 184
@ButtonTextXposition                        EQU 192
@ButtonTextYposition                        EQU 200
@ButtonNoteXposition                        EQU 208
@ButtonNoteYposition                        EQU 216
@ButtonRecalcPositions                      EQU 224

; External public properties


.DATA
szMUIButtonClass					        DB 'ModernUI_Button',0 	        ; Class name for creating our ModernUI_Button control
szMUIButtonFont                             DB 'Segoe UI',0             	; Font used for ModernUI_Button text
hMUIButtonFont                              DQ 0                        	; Handle to ModernUI_Button font (segoe ui)
hMUIButtonNotifyFont                        DQ 0
hMUIButtonNoteFont                          DQ 0


.DATA?
IFDEF DEBUG32
DbgVar                                      DQ ?
ENDIF

.CODE
;-------------------------------------------------------------------------------------
; Set property for ModernUI_Button control
;-------------------------------------------------------------------------------------
MUIButtonSetProperty PROC FRAME hControl:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, dqProperty, dqPropertyValue
    ret
MUIButtonSetProperty ENDP


;-------------------------------------------------------------------------------------
; Get property for ModernUI_Button control
;-------------------------------------------------------------------------------------
MUIButtonGetProperty PROC FRAME hControl:QWORD, dqProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, dqProperty, NULL
    ret
MUIButtonGetProperty ENDP


;-------------------------------------------------------------------------------------
; MUIButtonRegister - Registers the ModernUI_Button control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Button
;-------------------------------------------------------------------------------------
MUIButtonRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
	Invoke RtlZeroMemory, Addr wc, SIZEOF WNDCLASSEX
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUIButtonClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUIButtonClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_ButtonWndProc
    	mov wc.lpfnWndProc, rax
    	;Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, NULL ;rax
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

MUIButtonRegister ENDP


;-------------------------------------------------------------------------------------
; MUIButtonCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUIButtonCreate PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, dqResourceID:QWORD, dqStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL dqNewStyle:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUIButtonRegister
	
	;PrintQWORD hWndParent
	
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN. Non visual prob dont need any of these.
    mov rax, dqStyle
    mov dqNewStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        or dqNewStyle, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .ENDIF

    Invoke CreateWindowEx, NULL, Addr szMUIButtonClass, lpszText, dword ptr dqNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, dqResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUIButtonCreate ENDP



;-------------------------------------------------------------------------------------
; _MUI_ButtonWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_ButtonWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
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
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_BUTTON_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_BUTTON_PROPERTIES ; external properties
		Invoke MUIGDIPlusStart ; for png resources if used
		Invoke _MUI_ButtonInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_ButtonCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
		Invoke MUIGDIPlusFinish
		mov rax, 0
		ret
		
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_ButtonPaint, hWin
        mov rax, 0
        ret
    
    .ELSEIF eax == WM_SETCURSOR
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUIBS_HAND
        .IF rax == MUIBS_HAND
		    invoke LoadCursor, NULL, IDC_HAND
        .ELSE
            invoke LoadCursor, NULL, IDC_ARROW
        .ENDIF
        Invoke SetCursor, rax
        mov rax, 0
        ret

    .ELSEIF eax == WM_LBUTTONUP
        ;PrintText 'WM_LBUTTONUP'
		; simulates click on our control, delete if not required.
		Invoke GetParent, hWin
		mov hParent, rax
		Invoke GetDlgCtrlID, hWin
		;PrintQWORD rax
		Invoke PostMessage, hParent, WM_COMMAND, rax, hWin
		;PrintQWORD hParent
		
		Invoke MUIGetIntProperty, hWin, @ButtonMouseDown
        .IF rax == TRUE
            invoke GetClientRect, hWin, addr rect
            Invoke GetParent, hWin
            mov hParent, rax            
            invoke MapWindowPoints, hWin, hParent, addr rect, 2   
            sub rect.top, 1
            Invoke SetWindowPos, hWin, NULL, rect.left, rect.top, rect.right, rect.bottom, SWP_NOSIZE + SWP_NOZORDER  + SWP_FRAMECHANGED
            Invoke MUISetIntProperty, hWin, @ButtonMouseDown, FALSE
        .ELSE
            Invoke InvalidateRect, hWin, NULL, TRUE
            Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_FRAMECHANGED	
        .ENDIF
        
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUIBS_AUTOSTATE
        .IF rax == MUIBS_AUTOSTATE
            Invoke MUIGetIntProperty, hWin, @ButtonSelectedState
            .IF rax == FALSE
	            Invoke MUISetIntProperty, hWin, @ButtonSelectedState, TRUE
            .ELSE
                Invoke MUISetIntProperty, hWin, @ButtonSelectedState, FALSE
            .ENDIF
            Invoke InvalidateRect, hWin, NULL, TRUE
        .ENDIF
      

    .ELSEIF eax == WM_LBUTTONDOWN
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUIBS_PUSHBUTTON
        .IF rax == MUIBS_PUSHBUTTON
            invoke GetClientRect, hWin, addr rect
            Invoke GetParent, hWin
            mov hParent, rax
            invoke MapWindowPoints, hWin, hParent, addr rect, 2        
            add rect.top, 1
            Invoke SetWindowPos, hWin, NULL, rect.left, rect.top, rect.right, rect.bottom, SWP_NOSIZE + SWP_NOZORDER + SWP_FRAMECHANGED
            Invoke MUISetIntProperty, hWin, @ButtonMouseDown, TRUE
        .ELSE
            Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_FRAMECHANGED
        .ENDIF
     

    .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUIGetIntProperty, hWin, @ButtonEnabledState
        .IF rax == TRUE   
    		Invoke MUISetIntProperty, hWin, @ButtonMouseOver , TRUE
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
        Invoke MUISetIntProperty, hWin, @ButtonMouseOver, FALSE
		Invoke MUIGetIntProperty, hWin, @ButtonMouseDown
        .IF rax == TRUE		
            invoke GetClientRect, hWin, addr rect
            Invoke GetParent, hWin
            mov hParent, rax            
            invoke MapWindowPoints, hWin, hParent, addr rect, 2   
            sub rect.top, 1
            Invoke SetWindowPos, hWin, NULL, rect.left, rect.top, rect.right, rect.bottom, SWP_NOSIZE + SWP_NOZORDER + SWP_FRAMECHANGED
            Invoke MUISetIntProperty, hWin, @ButtonMouseDown, FALSE
        .ELSE
            Invoke InvalidateRect, hWin, NULL, FALSE
            ;Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_FRAMECHANGED 
        .ENDIF

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @ButtonMouseOver , FALSE
		Invoke MUIGetIntProperty, hWin, @ButtonMouseDown
        .IF rax == TRUE		
            invoke GetClientRect, hWin, addr rect
            Invoke GetParent, hWin
            mov hParent, rax            
            invoke MapWindowPoints, hWin, hParent, addr rect, 2   
            sub rect.top, 1
            Invoke SetWindowPos, hWin, NULL, rect.left, rect.top, rect.right, rect.bottom, SWP_NOSIZE + SWP_NOZORDER + SWP_FRAMECHANGED
            Invoke MUISetIntProperty, hWin, @ButtonMouseDown, FALSE
        .ELSE
            Invoke InvalidateRect, hWin, NULL, FALSE
            ;Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_FRAMECHANGED 
        .ENDIF

	.ELSEIF eax == WM_ENABLE
	    Invoke MUISetIntProperty, hWin, @ButtonEnabledState, wParam
	    Invoke InvalidateRect, hWin, NULL, TRUE
	    mov eax, 0


    .ELSEIF eax == WM_SETTEXT
        Invoke DefWindowProc, hWin, uMsg, wParam, lParam
        Invoke InvalidateRect, hWin, NULL, TRUE
        ret
        
    .ELSEIF eax == WM_SETFONT
        Invoke MUISetExtProperty, hWin, @ButtonTextFont, lParam
        .IF lParam == TRUE
            Invoke InvalidateRect, hWin, NULL, TRUE
        .ENDIF   

	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
		; by default set other similar properties when main one is set
		Invoke _MUI_ButtonSetPropertyEx, hWin, wParam, lParam
		Invoke InvalidateRect, hWin, NULL, TRUE
		ret

	.ELSEIF eax == MUIBM_NOTIFYSETTEXT ; wParam = lpszNotifyText, lParam = Redraw TRUE/FALSE
	    Invoke MUISetIntProperty, hWin, @ButtonszNotifyText, wParam
	    .IF lParam == TRUE
	        Invoke InvalidateRect, hWin, NULL, TRUE
	    .ENDIF
	    ret
	    
	.ELSEIF eax == MUIBM_NOTIFY ; wParam = TRUE/FALSE, lParam = NULL
	    Invoke MUISetIntProperty, hWin, @ButtonNotifyState, wParam
        Invoke InvalidateRect, hWin, NULL, TRUE
        ret
    
	.ELSEIF eax == MUIBM_NOTIFYSETFONT ; wParam = hFont, lParam = TRUE/FALSE to redraw control
	    Invoke MUISetExtProperty, hWin, @ButtonNotifyTextFont, lParam
	    .IF lParam == TRUE
	        Invoke InvalidateRect, hWin, NULL, TRUE
	    .ENDIF
	    ret
	    
	.ELSEIF eax == MUIBM_NOTIFYSETIMAGE ; wParam = dwImageType, lParam = Handle of Image
        .IF wParam == 0
            ret
        .ENDIF
        Invoke MUISetExtProperty, hWin, @ButtonNotifyImageType, wParam
        .IF lParam != 0
            Invoke MUISetExtProperty, hWin, @ButtonNotifyImage, lParam
        .ENDIF
        Invoke InvalidateRect, hWin, NULL, TRUE
        ret
    
	.ELSEIF eax == MUIBM_NOTIFYLOADIMAGE ; wParam = dwImageType, lParam = ResourceID
        .IF wParam == 0
            ret
        .ENDIF
        Invoke MUISetExtProperty, hWin, @ButtonNotifyImageType, wParam
        mov rax, wParam
        .IF rax == 1 ; bitmap
            Invoke _MUI_ButtonLoadBitmap, hWin, @ButtonNotifyImage, lParam
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_ButtonLoadIcon, hWin, @ButtonNotifyImage, lParam
        
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_ButtonLoadPng, hWin, @ButtonNotifyImage, lParam
            ENDIF
        
        .ENDIF
        Invoke InvalidateRect, hWin, NULL, TRUE
        ret
    
	.ELSEIF eax == MUIBM_NOTESETTEXT ; wParam = lpszNoteText, lParam = TRUE/FALSE to redraw control
	    Invoke MUISetIntProperty, hWin, @ButtonszNoteText, wParam
	    .IF lParam == TRUE
	        Invoke InvalidateRect, hWin, NULL, TRUE
	    .ENDIF
	    ret	
    
	.ELSEIF eax == MUIBM_NOTESETFONT ; wParam = hFont, lParam = TRUE/FALSE to redraw control
	    Invoke MUISetExtProperty, hWin, @ButtonNoteTextFont, lParam
	    .IF lParam == TRUE
	        Invoke InvalidateRect, hWin, NULL, TRUE
	    .ENDIF
	    ret	
    
	.ELSEIF eax == MUIBM_GETSTATE ; wParam = NULL, lParam = NULL. EAX contains state (TRUE/FALSE)
	    Invoke MUIGetIntProperty, hWin, @ButtonSelectedState
	    ret
	 
	.ELSEIF eax == MUIBM_SETSTATE ; wParam = TRUE/FALSE, lParam = NULL
	    Invoke MUISetIntProperty, hWin, @ButtonSelectedState, wParam
	    Invoke InvalidateRect, hWin, NULL, TRUE
	    ret

    .ENDIF

    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_ButtonWndProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_ButtonInit PROC FRAME hControl:QWORD
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
    Invoke MUISetIntProperty, hControl, @ButtonEnabledState, TRUE

    Invoke MUISetExtProperty, hControl, @ButtonTextColor, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hControl, @ButtonTextColorAlt, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hControl, @ButtonTextColorSel, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hControl, @ButtonTextColorSelAlt, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hControl, @ButtonTextColorDisabled, MUI_RGBCOLOR(204,204,204)

    Invoke MUISetExtProperty, hControl, @ButtonBackColor, MUI_RGBCOLOR(255,255,255) ;MUI_RGBCOLOR(21,133,181)
    Invoke MUISetExtProperty, hControl, @ButtonBackColorAlt, MUI_RGBCOLOR(221,221,221)
    Invoke MUISetExtProperty, hControl, @ButtonBackColorSel, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hControl, @ButtonBackColorSelAlt, MUI_RGBCOLOR(221,221,221)
    Invoke MUISetExtProperty, hControl, @ButtonBackColorDisabled, MUI_RGBCOLOR(192,192,192)
    
    Invoke MUISetExtProperty, hControl, @ButtonBorderColor, MUI_RGBCOLOR(204,204,204)
    Invoke MUISetExtProperty, hControl, @ButtonBorderColorAlt, MUI_RGBCOLOR(204,204,204)
    Invoke MUISetExtProperty, hControl, @ButtonBorderColorSel, MUI_RGBCOLOR(27,161,226)
    Invoke MUISetExtProperty, hControl, @ButtonBorderColorSelAlt, MUI_RGBCOLOR(27,161,226)
    Invoke MUISetExtProperty, hControl, @ButtonBorderColorDisabled, MUI_RGBCOLOR(204,204,204)
    
    Invoke MUISetExtProperty, hControl, @ButtonBorderStyle, MUIBBS_ALL
    
    Invoke MUISetExtProperty, hControl, @ButtonNotifyTextColor, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hControl, @ButtonNotifyBackColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hControl, @ButtonNoteTextColor, MUI_RGBCOLOR(96,96,96)
    Invoke MUISetExtProperty, hControl, @ButtonNoteTextColorDisabled, MUI_RGBCOLOR(204,204,204)
    
    
    Invoke MUISetExtProperty, hControl, @ButtonPaddingLeftIndent, 0
    Invoke MUISetExtProperty, hControl, @ButtonPaddingGeneral, 4d
    Invoke MUISetExtProperty, hControl, @ButtonPaddingStyle, MUIBPS_ALL
    Invoke MUISetExtProperty, hControl, @ButtonPaddingTextImage, 8    
    
    Invoke MUISetExtProperty, hControl, @ButtonDllInstance, 0
    
    .IF hMUIButtonFont == 0
    	mov ncm.cbSize, SIZEOF NONCLIENTMETRICS
    	Invoke SystemParametersInfo, SPI_GETNONCLIENTMETRICS, SIZEOF NONCLIENTMETRICS, Addr ncm, 0
    	Invoke CreateFontIndirect, Addr ncm.lfMessageFont
    	mov hFont, rax
	    Invoke GetObject, hFont, SIZEOF lfnt, Addr lfnt
	    mov lfnt.lfHeight, -16d
	    ;mov lfnt.lfWeight, FW_BOLD
	    Invoke CreateFontIndirect, Addr lfnt
        mov hMUIButtonFont, rax
        
        mov lfnt.lfHeight, -12d
        mov lfnt.lfWeight, FW_BOLD
        Invoke CreateFontIndirect, Addr lfnt
        mov hMUIButtonNotifyFont, rax
        
	    mov lfnt.lfHeight, -12d
	    mov lfnt.lfWeight, FW_NORMAL
	    Invoke CreateFontIndirect, Addr lfnt
        mov hMUIButtonNoteFont, rax
        Invoke DeleteObject, hFont
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @ButtonTextFont, hMUIButtonFont
    Invoke MUISetExtProperty, hControl, @ButtonNotifyTextFont, hMUIButtonNotifyFont
    Invoke MUISetExtProperty, hControl, @ButtonNoteTextFont, hMUIButtonNoteFont

    ret

_MUI_ButtonInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonCleanup - cleanup a few things before control is destroyed
;-------------------------------------------------------------------------------------
_MUI_ButtonCleanup PROC FRAME hControl:QWORD
    LOCAL dqImageType:QWORD
    LOCAL hIStreamImage:QWORD
    LOCAL hIStreamImageAlt:QWORD
    LOCAL hIStreamImageSel:QWORD
    LOCAL hIStreamImageSelAlt:QWORD
    LOCAL hIStreamImageDisabled:QWORD
    LOCAL hIStreamNotify:QWORD
    LOCAL hImage:QWORD
    LOCAL hImageAlt:QWORD
    LOCAL hImageSel:QWORD
    LOCAL hImageSelAlt:QWORD
    LOCAL hImageDisabled:QWORD
    LOCAL hImageNotify:QWORD
    LOCAL dqStyle:QWORD
    
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov dqStyle, rax
    and rax, MUIBS_KEEPIMAGES
    .IF rax == MUIBS_KEEPIMAGES
        ret
    .ENDIF
    
    IFDEF DEBUG64
    PrintText '_MUI_ButtonCleanup'
    ENDIF
    ; cleanup any stream handles if png where loaded as resources

    .IF dqImageType == 3
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGetIntProperty, hControl, @ButtonImageStream
        mov hIStreamImage, rax
        .IF rax != 0
            Invoke _MUI_ButtonPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @ButtonImageAltStream
        mov hIStreamImageAlt, rax
        .IF rax != 0 && rax != hIStreamImage
            Invoke _MUI_ButtonPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @ButtonImageSelStream
        mov hIStreamImageSel, rax
        .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt
            Invoke _MUI_ButtonPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @ButtonImageSelAltStream
        mov hIStreamImageSelAlt, rax
        .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt && rax != hIStreamImageSel
            Invoke _MUI_ButtonPngReleaseIStream, rax
        .ENDIF
        Invoke MUIGetIntProperty, hControl, @ButtonImageDisabledStream
        mov hIStreamImageDisabled, rax
        .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt && rax != hIStreamImageSel && rax != hIStreamImageSelAlt 
            Invoke _MUI_ButtonPngReleaseIStream, rax
        .ENDIF
        
        IFDEF DEBUG64
        ; check to see if handles are cleared.
        PrintText '_MUI_ButtonCleanup::IStream Handles cleared'
        ENDIF
        
        ENDIF        
    .ENDIF


    Invoke MUIGetExtProperty, hControl, @ButtonImageType
    mov dqImageType, rax
    .IF dqImageType == 0
        ret
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonImage
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
    Invoke MUIGetExtProperty, hControl, @ButtonImageAlt
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
    Invoke MUIGetExtProperty, hControl, @ButtonImageSel
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
    Invoke MUIGetExtProperty, hControl, @ButtonImageSelAlt
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
    Invoke MUIGetExtProperty, hControl, @ButtonImageDisabled
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
    

       
    IFDEF DEBUG64
    PrintText '_MUI_ButtonCleanup::Image Handles cleared'
    ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonNotifyImageType
    mov dqImageType, rax
    .IF dqImageType == 0
        ret
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonNotifyImage
    .IF rax != 0 && rax != hImage && rax != hImageAlt && rax != hImageSel && rax != hImageSelAlt && rax != hImageDisabled
        .IF dqImageType != 3
            Invoke DeleteObject, rax
        .ELSE
            IFDEF MUI_USEGDIPLUS
            Invoke GdipDisposeImage, rax
            
            Invoke MUIGetIntProperty, hControl, @ButtonNotifyImageStream
            .IF rax != 0 && rax != hIStreamImage && rax != hIStreamImageAlt && rax != hIStreamImageSel && rax != hIStreamImageSelAlt && rax != hIStreamImageDisabled
                Invoke GlobalFree, rax
            .ENDIF
            IFDEF DEBUG64
            PrintText '_MUI_ButtonCleanup::Notify IStream Handle cleared'
            ENDIF
            
            ENDIF 
        .ENDIF
    .ENDIF
    
    IFDEF DEBUG64
    PrintText '_MUI_ButtonCleanup::Notify Image Handles cleared'
    ENDIF
    ret

_MUI_ButtonCleanup ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonPaint
;-------------------------------------------------------------------------------------
_MUI_ButtonPaint PROC FRAME hWin:QWORD
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
    Invoke MUIGetIntProperty, hWin, @ButtonEnabledState
    mov EnabledState, rax
	Invoke MUIGetIntProperty, hWin, @ButtonMouseOver
    mov MouseOver, rax
	Invoke MUIGetIntProperty, hWin, @ButtonSelectedState
    mov SelectedState, rax    
	
	;----------------------------------------------------------
	; Background
	;----------------------------------------------------------
	Invoke _MUI_ButtonPaintBackground, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Accent
	;----------------------------------------------------------
    Invoke _MUI_ButtonPaintAccent, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; calc positions for text and images
	;----------------------------------------------------------    
    Invoke _MUI_ButtonCalcPositions, hWin, hdc, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Images
	;----------------------------------------------------------
    Invoke _MUI_ButtonPaintImages, hWin, hdc, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Text
	;----------------------------------------------------------
	Invoke _MUI_ButtonPaintText, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

	;----------------------------------------------------------
	; Border
	;----------------------------------------------------------
	Invoke _MUI_ButtonPaintBorder, hWin, hdcMem, Addr rect, EnabledState, MouseOver, SelectedState

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
_MUI_ButtonPaint ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonPaintBackground
;-------------------------------------------------------------------------------------
_MUI_ButtonPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    
    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColor        ; Normal back color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColorAlt     ; Mouse over back color
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColorSel     ; Selected back color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColorSelAlt  ; Selected mouse over color 
            .ENDIF
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @ButtonBackColorDisabled        ; Disabled back color
    .ENDIF
    .IF rax == 0 ; try to get default back color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @ButtonBackColor                ; fallback to default Normal back color
    .ENDIF
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

_MUI_ButtonPaintBackground ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonPaintAccent
;-------------------------------------------------------------------------------------
_MUI_ButtonPaintAccent PROC FRAME USES RBX hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL AccentColor:QWORD
    LOCAL AccentStyle:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL hPen:QWORD
    LOCAL hOldPen:QWORD
    LOCAL AccentRect:RECT
    LOCAL rect:RECT
    LOCAL pt:POINT    
    
    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentColor        ; Normal accent color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentColorAlt     ; Mouse over accent color
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentColorSel     ; Selected accent color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentColorSelAlt  ; Selected mouse over accent color 
            .ENDIF
        .ENDIF
    .ELSE
        ret
    .ENDIF
    mov AccentColor, rax

    .IF AccentColor != 0
        
        Invoke CopyRect, Addr rect, lpRect
        
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentStyle        ; Normal accent style
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentStyleAlt     ; Mouse over accent style
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentStyleSel     ; Selected accent style
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonAccentStyleSelAlt  ; Selected mouse over accent style
            .ENDIF
        .ENDIF
        mov AccentStyle, rax

        .IF AccentStyle != MUIBAS_NONE
        
            mov rax, AccentStyle
            AND rax, MUIBAS_LEFT
            .IF rax == MUIBAS_LEFT
                xor rax, rax
                mov AccentRect.left, 0
                mov eax, ACCENTWIDTH
                mov AccentRect.right, eax
                mov AccentRect.top, 0
                mov eax, rect.bottom
                mov AccentRect.bottom, eax
                
                Invoke GetStockObject, DC_BRUSH
                mov hBrush, rax
                Invoke SelectObject, hdc, rax
                mov hOldBrush, rax
                Invoke SetDCBrushColor, hdc, dword ptr AccentColor
                Invoke FillRect, hdc, Addr AccentRect, hBrush
                
                .IF hOldBrush != 0
                    Invoke SelectObject, hdc, hOldBrush
                    Invoke DeleteObject, hOldBrush
                .ENDIF     
                .IF hBrush != 0
                    Invoke DeleteObject, hBrush
                .ENDIF
            .ENDIF 

            mov rax, AccentStyle
            AND rax, MUIBAS_TOP
            .IF rax == MUIBAS_TOP
                xor rax, rax
                mov AccentRect.left, 0
                mov eax, rect.right
                mov AccentRect.right, eax
                mov AccentRect.top, 0
                mov eax, ACCENTWIDTH
                mov AccentRect.bottom, eax

                Invoke GetStockObject, DC_BRUSH
                mov hBrush, rax
                Invoke SelectObject, hdc, rax
                mov hOldBrush, rax
                Invoke SetDCBrushColor, hdc, dword ptr AccentColor
                Invoke FillRect, hdc, Addr AccentRect, hBrush
                
                .IF hOldBrush != 0
                    Invoke SelectObject, hdc, hOldBrush
                    Invoke DeleteObject, hOldBrush
                .ENDIF     
                .IF hBrush != 0
                    Invoke DeleteObject, hBrush
                .ENDIF
            .ENDIF
            
            mov rax, AccentStyle
            AND rax, MUIBAS_RIGHT
            .IF rax == MUIBAS_RIGHT
                xor rax, rax
                xor rbx, rbx
                mov eax, rect.right
                mov ebx, ACCENTWIDTH
                sub eax, ebx
                mov AccentRect.left, eax
                mov eax, rect.right
                mov AccentRect.right, eax
                mov AccentRect.top, 0
                mov eax, rect.bottom
                mov AccentRect.bottom, eax

                Invoke GetStockObject, DC_BRUSH
                mov hBrush, rax
                Invoke SelectObject, hdc, rax
                mov hOldBrush, rax
                Invoke SetDCBrushColor, hdc, dword ptr AccentColor
                Invoke FillRect, hdc, Addr AccentRect, hBrush
                
                .IF hOldBrush != 0
                    Invoke SelectObject, hdc, hOldBrush
                    Invoke DeleteObject, hOldBrush
                .ENDIF     
                .IF hBrush != 0
                    Invoke DeleteObject, hBrush
                .ENDIF
            .ENDIF
            
            mov rax, AccentStyle
            AND rax, MUIBAS_BOTTOM
            .IF rax == MUIBAS_BOTTOM
                xor rax, rax
                xor rbx, rbx
                mov AccentRect.left, 0
                mov eax, rect.right
                mov AccentRect.right, eax
                mov eax, rect.bottom
                mov ebx, ACCENTWIDTH
                sub eax, ebx
                mov AccentRect.top, eax
                mov eax, rect.bottom
                mov AccentRect.bottom, eax

                Invoke GetStockObject, DC_BRUSH
                mov hBrush, rax
                Invoke SelectObject, hdc, rax
                mov hOldBrush, rax
                Invoke SetDCBrushColor, hdc, dword ptr AccentColor
                Invoke FillRect, hdc, Addr AccentRect, hBrush
                
                .IF hOldBrush != 0
                    Invoke SelectObject, hdc, hOldBrush
                    Invoke DeleteObject, hOldBrush
                .ENDIF     
                .IF hBrush != 0
                    Invoke DeleteObject, hBrush
                .ENDIF
            .ENDIF
            
            mov rax, AccentStyle
            AND rax, MUIBAS_ALL
            .IF rax == MUIBAS_ALL
                Invoke GetStockObject, DC_BRUSH
                mov hBrush, rax
                Invoke SelectObject, hdc, rax
                mov hOldBrush, rax
                Invoke SetDCBrushColor, hdc, dword ptr AccentColor 
                
                xor rax, rax
                xor rbx, rbx
                mov AccentRect.left, 0
                mov eax, ACCENTWIDTH
                mov AccentRect.right, eax
                mov AccentRect.top, 0
                mov eax, rect.bottom
                mov AccentRect.bottom, eax
                Invoke FillRect, hdc, Addr AccentRect, hBrush

                mov AccentRect.left, 0
                mov eax, rect.right
                mov AccentRect.right, eax
                mov AccentRect.top, 0
                mov eax, ACCENTWIDTH
                mov AccentRect.bottom, eax
                Invoke FillRect, hdc, Addr AccentRect, hBrush
                
                mov eax, rect.right
                mov ebx, ACCENTWIDTH
                sub eax, ebx
                mov AccentRect.left, eax
                mov eax, rect.right
                mov AccentRect.right, eax
                mov AccentRect.top, 0
                mov eax, rect.bottom
                mov AccentRect.bottom, eax
                Invoke FillRect, hdc, Addr AccentRect, hBrush

                mov AccentRect.left, 0
                mov eax, rect.right
                mov AccentRect.right, eax
                mov eax, rect.bottom
                mov ebx, ACCENTWIDTH
                sub eax, ebx
                mov AccentRect.top, eax
                mov eax, rect.bottom
                mov AccentRect.bottom, eax
                Invoke FillRect, hdc, Addr AccentRect, hBrush

            .ENDIF
        .ENDIF
    .ENDIF

    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF

    ret

_MUI_ButtonPaintAccent ENDP



;-------------------------------------------------------------------------------------
; _MUI_ButtonCalcPositions - calculate x, y positions of images, text etc
;-------------------------------------------------------------------------------------
_MUI_ButtonCalcPositions PROC FRAME USES RBX hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL dqStyle:QWORD
    LOCAL hImage:QWORD
    LOCAL dqImageType:QWORD
    LOCAL NotifyImageType:QWORD
    LOCAL hNotifyImage:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL rect:RECT
    LOCAL pt:POINT
    LOCAL sz:SIZE_
    LOCAL lpszNotifyText:QWORD
    LOCAL LenNotifyText:QWORD
    LOCAL szText[256]:BYTE
    LOCAL xpos:QWORD
    LOCAL ypos:QWORD
    LOCAL paddingstyle:QWORD
    LOCAL padding:QWORD
    LOCAL indent:QWORD

    mov xpos, 0
    mov ypos, 0

    Invoke CopyRect, Addr rect, lpRect
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov dqStyle, rax

    ;--------------------------------------------------------------
    ; Padding & Indent
    ;--------------------------------------------------------------
    
    mov rax, dqStyle
    and rax, MUIBS_BOTTOM 
    .IF rax != MUIBS_BOTTOM    
        Invoke MUIGetExtProperty, hWin, @ButtonPaddingLeftIndent
        .IF rax > 0
            add xpos, rax ; add indent to xpos
        .ENDIF
        Invoke MUIGetExtProperty, hWin, @ButtonPaddingGeneral
        .IF rax > 0
            mov padding, rax
            
            Invoke MUIGetExtProperty, hWin, @ButtonPaddingStyle
            mov paddingstyle, rax
            
            .IF rax != MUIBPS_NONE
                mov rax, paddingstyle
                and rax, MUIBPS_LEFT
                .IF rax == MUIBPS_LEFT
                    mov rax, padding
                    add xpos, rax
                .ENDIF
    
                mov rax, paddingstyle
                and rax, MUIBPS_TOP
                .IF rax == MUIBPS_TOP
                    mov rax, padding
                    add ypos, rax
                .ENDIF
    
                mov rax, paddingstyle
                and rax, MUIBPS_RIGHT
                .IF rax == MUIBPS_RIGHT
                    mov rax, padding
                    sub rect.right, eax
                .ENDIF
    
                mov rax, paddingstyle
                and rax, MUIBPS_BOTTOM
                .IF rax == MUIBPS_BOTTOM
                    mov rax, padding
                    sub rect.bottom, eax
                .ENDIF
            .ENDIF
    
        .ENDIF
    .ENDIF
    
    ;--------------------------------------------------------------
    ; Image position
    ;--------------------------------------------------------------
    Invoke MUIGetExtProperty, hWin, @ButtonImageType        
    mov dqImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png

    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonImage        ; Normal image
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonImageAlt     ; Mouse over image
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonImageSel     ; Selected image
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonImageSelAlt  ; Selected mouse over image 
            .ENDIF
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @ButtonImageDisabled        ; Disabled image
    .ENDIF
    mov hImage, rax    

    .IF hImage != 0
        
        Invoke MUIGetImageSize, hImage, dqImageType, Addr ImageWidth, Addr ImageHeight
        ;Invoke _MUI_ButtonGetImageSize, hWin, ImageType, hImage, Addr ImageWidth, Addr ImageHeight
        
        mov rax, dqStyle
        and rax, MUIBS_BOTTOM 
        .IF rax == MUIBS_BOTTOM
        
            Invoke MUIGetExtProperty, hWin, @ButtonPaddingGeneral
            .IF rax > 0
                mov padding, rax
                add ypos, rax
            .ENDIF        
        
            mov eax, rect.right
            mov rbx, ImageWidth
            sub eax, ebx
            shr eax, 1 ; div by 1
            mov xpos, rax
        .ELSE
            mov eax, rect.bottom
            mov rbx, ImageHeight
            sub eax, ebx
            shr ebx, 1
            add ypos, rax
        .ENDIF         
    .ENDIF
    Invoke MUISetIntProperty, hWin, @ButtonImageXposition, xpos
    Invoke MUISetIntProperty, hWin, @ButtonImageYposition, ypos
    

    ;--------------------------------------------------------------
    ; Text position
    ;--------------------------------------------------------------
    .IF hImage != 0
        mov rax, ImageWidth
        add xpos, rax
        Invoke MUIGetExtProperty, hWin, @ButtonPaddingTextImage
        add xpos, rax
    .ENDIF
    Invoke MUISetIntProperty, hWin, @ButtonTextXposition, xpos
    Invoke MUISetIntProperty, hWin, @ButtonTextYposition, ypos


    mov rax, dqStyle
    and rax, MUIBS_BOTTOM 
    .IF rax != MUIBS_BOTTOM

        ;--------------------------------------------------------------
        ; Note text position
        ;--------------------------------------------------------------
        Invoke MUISetIntProperty, hWin, @ButtonNoteXposition, xpos
        
        ; ypos based on getextent of ypos + (text height *2 - textnote height)
        ;Invoke MUISetIntProperty, hWin, @ButtonNoteYposition, ypos
        
        ;--------------------------------------------------------------
        ; Notify Image Position
        ;--------------------------------------------------------------
        ; decide on notify image position based on property? after text + a small bit of padding
        ; or before right image (+ small padding) or right side if no right image?
        Invoke MUISetIntProperty, hWin, @ButtonNotifyImageXposition, xpos
        Invoke MUISetIntProperty, hWin, @ButtonNotifyImageYposition, ypos
        
        
        
        ;--------------------------------------------------------------
        ; Right Image Position
        ;--------------------------------------------------------------
        .IF bEnabledState == TRUE
            .IF bSelectedState == FALSE
                .IF bMouseOver == FALSE
                    Invoke MUIGetExtProperty, hWin, @ButtonRightImage        ; Normal image
                .ELSE
                    Invoke MUIGetExtProperty, hWin, @ButtonRightImageAlt     ; Mouse over image
                .ENDIF
            .ELSE
                .IF bMouseOver == FALSE
                    Invoke MUIGetExtProperty, hWin, @ButtonRightImageSel     ; Selected image
                .ELSE
                    Invoke MUIGetExtProperty, hWin, @ButtonRightImageSelAlt  ; Selected mouse over image 
                .ENDIF
            .ENDIF
        .ELSE
            Invoke MUIGetExtProperty, hWin, @ButtonRightImageDisabled        ; Disabled image
        .ENDIF
        mov hImage, rax    
    
        .IF hImage != 0
            Invoke MUIGetImageSize, hImage, ImageType, Addr ImageWidth, Addr ImageHeight
            ;Invoke _MUI_ButtonGetImageSize, hWin, ImageType, hImage, Addr ImageWidth, Addr ImageHeight
            xor rax, rax
            xor rbx, rbx
            mov eax, rect.right
            sub rax, ImageWidth
            mov xpos, rax
            
            mov eax, rect.bottom
            mov rbx, ImageHeight
            sub eax, ebx
            shr ebx, 1
            add ypos, rax
            
            Invoke MUISetIntProperty, hWin, @ButtonRightImageXposition, xpos
            Invoke MUISetIntProperty, hWin, @ButtonRightImageYposition, ypos            
            
        .ELSE
            Invoke MUISetIntProperty, hWin, @ButtonRightImageXposition, 0
            Invoke MUISetIntProperty, hWin, @ButtonRightImageYposition, 0    
        .ENDIF

    .ELSE
        Invoke MUISetIntProperty, hWin, @ButtonNoteXposition, 0
        Invoke MUISetIntProperty, hWin, @ButtonNoteYposition, 0    
        Invoke MUISetIntProperty, hWin, @ButtonNotifyImageXposition, 0
        Invoke MUISetIntProperty, hWin, @ButtonNotifyImageYposition, 0    
        Invoke MUISetIntProperty, hWin, @ButtonRightImageXposition, 0
        Invoke MUISetIntProperty, hWin, @ButtonRightImageYposition, 0     
    .ENDIF
    
    ret

_MUI_ButtonCalcPositions ENDP



;-------------------------------------------------------------------------------------
; _MUI_ButtonPaintText
;-------------------------------------------------------------------------------------
_MUI_ButtonPaintText PROC FRAME USES RBX hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL dqStyle:QWORD
    LOCAL dqTextStyle:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL hPen:QWORD
    LOCAL hOldPen:QWORD
    LOCAL hImage:QWORD
    LOCAL dqImageType:QWORD
    LOCAL NotifyImageType:QWORD
    LOCAL hNotifyImage:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL rect:RECT
    LOCAL pt:POINT
    LOCAL sz:SIZE_
    LOCAL lpszNotifyText:QWORD
    LOCAL LenNotifyText:QWORD
    LOCAL szText[256]:BYTE
    LOCAL LenText:QWORD
    LOCAL dqRoundRect:QWORD

    Invoke CopyRect, Addr rect, lpRect
    
    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColor        ; Normal back color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColorAlt     ; Mouse over back color
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColorSel     ; Selected back color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonBackColorSelAlt  ; Selected mouse over color 
            .ENDIF
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @ButtonBackColorDisabled        ; Disabled back color
    .ENDIF
    .IF eax == 0 ; try to get default back color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @ButtonBackColor                ; fallback to default Normal back color
    .ENDIF    
    mov BackColor, rax    
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov dqStyle, rax
    
    Invoke MUIGetExtProperty, hWin, @ButtonTextFont        
    mov hFont, rax

    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonTextColor        ; Normal text color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonTextColorAlt     ; Mouse over text color
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonTextColorSel     ; Selected text color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonTextColorSelAlt  ; Selected mouse over color 
            .ENDIF
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @ButtonTextColorDisabled        ; Disabled text color
    .ENDIF
    .IF rax == 0 ; try to get default text color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @ButtonTextColor                ; fallback to default Normal text color
    .ENDIF  
    mov TextColor, rax
    
    Invoke MUIGetExtProperty, hWin, @ButtonImageType        
    mov dqImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png

    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonImage        ; Normal image
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonImageAlt     ; Mouse over image
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonImageSel     ; Selected image
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonImageSelAlt  ; Selected mouse over image 
            .ENDIF
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @ButtonImageDisabled        ; Disabled image
    .ENDIF
    mov hImage, rax    
    
    Invoke lstrlen, Addr szText
    mov LenText, rax
    
    mov rect.left, 8
    ;mov rect.top, 4
    ;sub rect.bottom, 4
    sub rect.right, 4
    
    .IF hImage != 0
        
        Invoke MUIGetImageSize, hImage, dqImageType, Addr ImageWidth, Addr ImageHeight
        ;Invoke _MUI_ButtonGetImageSize, hWin, dqImageType, hImage, Addr ImageWidth, Addr ImageHeight

        mov rax, ImageWidth
        add rect.left, eax
        add rect.left, 8d
        
        mov rax, dqStyle
        and rax, MUIBS_BOTTOM 
        .IF rax == MUIBS_BOTTOM
            xor rax, rax
            xor rbx, rbx   
            mov eax, rect.bottom
            sub eax, 4d
            mov rbx, ImageHeight
            sub eax, ebx
            mov rect.top, eax
        .ELSE
        
;            Invoke GetTextExtentPoint32, hdc, Addr szText, LenText, Addr sz
;
;            mov eax, rect.bottom
;            shr eax, 1
;            mov ebx, sz.y
;            shr ebx, 1
;            sub eax, ebx
;            mov rect.top, eax
;            
;            mov eax, rect.bottom
;            shr eax, 1
;            mov ebx, sz.y
;            shr ebx, 1
;            add eax, ebx
;            mov rect.bottom, eax
        
            ;mov eax, rect.bottom
            ;shr eax, 1
            ;mov ebx, ImageHeight
            ;shr ebx, 1
            ;sub eax, ebx
            ;mov rect.top, eax
        .ENDIF        
        
    .ENDIF
    
    Invoke MUIGetExtProperty, hWin, @ButtonNotifyImageType        
    mov NotifyImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png

    .IF bEnabledState == TRUE
        Invoke MUIGetExtProperty, hWin, @ButtonNotifyImage        ; Normal Notify image
    .ENDIF
    mov hNotifyImage, rax      
    
    .IF hNotifyImage != 0
        
        Invoke MUIGetImageSize, hNotifyImage, NotifyImageType, Addr ImageWidth, Addr ImageHeight
        ;Invoke _MUI_ButtonGetImageSize, hWin, NotifyImageType, hNotifyImage, Addr ImageWidth, Addr ImageHeight
        ;PrintDec ImageWidth
        mov rax, ImageWidth
        sub rect.right, eax
        sub rect.right, 4d
        ;PrintDec rect.right
    .ENDIF

    
	Invoke SelectObject, hdc, hFont
    mov hOldFont, rax
    Invoke GetWindowText, hWin, Addr szText, sizeof szText
    
    Invoke SetBkMode, hdc, OPAQUE
    Invoke SetBkColor, hdc, dword ptr BackColor    
    Invoke SetTextColor, hdc, dword ptr TextColor
    
    mov dqTextStyle, DT_SINGLELINE
    mov rax, dqStyle
    and rax, MUIBS_CENTER
    .IF rax == MUIBS_CENTER
        or dqTextStyle, DT_CENTER
    .ELSE
        or dqTextStyle, DT_LEFT
    .ENDIF
    
    mov rax, dqStyle
    and rax, MUIBS_BOTTOM 
    .IF rax == MUIBS_BOTTOM
        or dqTextStyle, DT_BOTTOM
    .ELSE ; center
        or dqTextStyle, DT_VCENTER
    .ENDIF
    
    Invoke DrawText, hdc, Addr szText, -1, Addr rect, dword ptr dqTextStyle
    
    .IF hOldFont != 0
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF
    
    ; Draw notify text
    Invoke MUIGetIntProperty, hWin, @ButtonNotifyState
    .IF rax == FALSE
        ret
    .ENDIF    
    
    Invoke MUIGetIntProperty, hWin, @ButtonszNotifyText
    .IF rax != 0
        mov lpszNotifyText, rax
        Invoke lstrlen, lpszNotifyText
        mov LenNotifyText, rax
        .IF rax != 0
            Invoke MUIGetExtProperty, hWin, @ButtonNotifyTextFont
            mov hFont, rax
            Invoke MUIGetExtProperty, hWin, @ButtonNotifyTextColor
            mov TextColor, rax
            Invoke MUIGetExtProperty, hWin, @ButtonNotifyBackColor
            mov BackColor, rax
            
            Invoke GetTextExtentPoint32, hdc, lpszNotifyText, dword ptr LenNotifyText, Addr sz
            Invoke CopyRect, Addr rect, lpRect
            
            add sz.cx_, 8d
            add sz.cy, 4d
            xor rax, rax
            xor rbx, rbx
            mov eax, rect.right
            sub eax, 4
            sub eax, sz.cx_
            mov rect.left, eax
    
            mov eax, rect.right
            mov ebx, rect.left
            sub eax, ebx
    
    ;        .IF eax < 28d
    ;            mov eax, rect.right
    ;            sub eax, 28d
    ;            mov rect.left, eax
    ;        .ENDIF
    
            mov rax, dqStyle
            and rax, MUIBS_BOTTOM 
            .IF rax == MUIBS_BOTTOM
                xor rax, rax
                xor rbx, rbx
                mov eax, rect.bottom
                sub eax, 4d
                mov ebx, sz.cy
                sub eax, ebx
                mov rect.top, eax
                sub rect.bottom, 4d
            .ELSE
                xor rax, rax
                xor rbx, rbx
                mov eax, rect.bottom
                shr eax, 1
                mov ebx, sz.cy
                shr ebx, 1
                sub eax, ebx
                ;sub eax, 4d            
                mov rect.top, eax
                
                mov eax, rect.bottom
                shr eax, 1
                mov ebx, sz.cy
                shr ebx, 1
                add eax, ebx
                ;add eax, 4d            
                mov rect.bottom, eax
                
            .ENDIF
            sub rect.right, 4d
    
    
    	    Invoke SelectObject, hdc, hFont
            mov hOldFont, rax
            
            Invoke SetBkMode, hdc, OPAQUE
            Invoke SetBkColor, hdc, dword ptr BackColor    
            Invoke SetTextColor, hdc, dword ptr TextColor        
    
            Invoke GetStockObject, DC_BRUSH
            mov hBrush, rax
            Invoke SelectObject, hdc, rax
            mov hOldBrush, rax
            Invoke SetDCBrushColor, hdc, dword ptr BackColor
            
            Invoke GetStockObject, DC_PEN
            mov hPen, rax
            Invoke SelectObject, hdc, hPen
            mov hOldPen, rax         
            Invoke SetDCPenColor, hdc, dword ptr BackColor
            Invoke MUIGetExtProperty, hWin, @ButtonNotifyRound
            mov dqRoundRect, rax
            Invoke RoundRect, hdc, rect.left, rect.top, rect.right, rect.bottom, dword ptr dqRoundRect, dword ptr dqRoundRect
            
            Invoke DrawText, hdc, lpszNotifyText, dword ptr LenNotifyText, Addr rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER
        .ENDIF
    .ENDIF
    
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
    .IF hOldPen != 0
        Invoke SelectObject, hdc, hOldPen
        Invoke DeleteObject, hOldPen
    .ENDIF     
    .IF hPen != 0
        Invoke DeleteObject, hPen
    .ENDIF            
        

    
    ret

_MUI_ButtonPaintText ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonPaintImages
;-------------------------------------------------------------------------------------
_MUI_ButtonPaintImages PROC FRAME USES RBX hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL dqStyle:QWORD
    LOCAL dqImageType:QWORD
    LOCAL hImage:QWORD
    LOCAL NotifyImageType:QWORD
    LOCAL hNotifyImage:QWORD    
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
    
    Invoke MUIGetExtProperty, hWin, @ButtonImageType        
    mov dqImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png
    
    Invoke MUIGetExtProperty, hWin, @ButtonNotifyImageType        
    mov NotifyImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png
        
    .IF dqImageType == 0 && NotifyImageType == 0
        ret
    .ENDIF    
    
    .IF dqImageType != 0
        .IF bEnabledState == TRUE
            .IF bSelectedState == FALSE
                .IF bMouseOver == FALSE
                    Invoke MUIGetExtProperty, hWin, @ButtonImage        ; Normal image
                .ELSE
                    Invoke MUIGetExtProperty, hWin, @ButtonImageAlt     ; Mouse over image
                .ENDIF
            .ELSE
                .IF bMouseOver == FALSE
                    Invoke MUIGetExtProperty, hWin, @ButtonImageSel     ; Selected image
                .ELSE
                    Invoke MUIGetExtProperty, hWin, @ButtonImageSelAlt  ; Selected mouse over image 
                .ENDIF
            .ENDIF
        .ELSE
            Invoke MUIGetExtProperty, hWin, @ButtonImageDisabled        ; Disabled image
        .ENDIF
        .IF eax == 0 ; try to get default image if none others have a valid handle
            Invoke MUIGetExtProperty, hWin, @ButtonImage                ; fallback to default Normal image
        .ENDIF
        mov hImage, rax
    .ELSE
        mov hImage, 0
    .ENDIF
    
    .IF hImage != 0
    
        Invoke CopyRect, Addr rect, lpRect
        
        Invoke MUIGetImageSize, hImage, dqImageType, Addr ImageWidth, Addr ImageHeight
        ;Invoke _MUI_ButtonGetImageSize, hWin, dqImageType, hImage, Addr ImageWidth, Addr ImageHeight
        
        mov pt.x, 8d
        mov pt.y, 4d
        mov rax, dqStyle
        and rax, MUIBS_BOTTOM 
        .IF rax == MUIBS_BOTTOM
            xor rax, rax
            xor rbx, rbx
            mov eax, rect.bottom
            sub eax, 4d
            mov rbx, ImageHeight
            sub eax, ebx
            mov pt.y, eax
        .ELSE
            xor rax, rax
            xor rbx, rbx        
            mov eax, rect.bottom
            shr eax, 1
            mov rbx, ImageHeight
            shr ebx, 1
            sub eax, ebx
            
            mov pt.y, eax
        .ENDIF
        
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
;            PrintText 'hImage'
;            PrintDec ImageWidth
;            PrintDec ImageHeight
;            PrintDec pt.x
;            PrintDec pt.y        
        
        
            Invoke GdipCreateFromHDC, hdcDest, Addr pGraphics
            
            Invoke GdipCreateBitmapFromGraphics, ImageWidth, ImageHeight, pGraphics, Addr pBitmap
            Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer            
            Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
            Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, dword ptr ImageWidth, dword ptr ImageHeight
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

    
    Invoke MUIGetIntProperty, hWin, @ButtonNotifyState
    .IF rax == FALSE
        ret
    .ENDIF

    Invoke MUIGetExtProperty, hWin, @ButtonNotifyImageType        
    mov NotifyImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png

    ; Notify Image
    .IF NotifyImageType != 0
        Invoke MUIGetExtProperty, hWin, @ButtonNotifyImage        ; Normal Notify image
        mov hNotifyImage, rax
    .ELSE
        ret
    .ENDIF
    

    
    .IF hNotifyImage != 0
        
        Invoke CopyRect, Addr rect, lpRect
        
        Invoke MUIGetImageSize, hNotifyImage, NotifyImageType, Addr ImageWidth, Addr ImageHeight
        ;Invoke _MUI_ButtonGetImageSize, hWin, NotifyImageType, hNotifyImage, Addr ImageWidth, Addr ImageHeight
        xor rax, rax
        xor rbx, rbx
        mov eax, rect.right
        sub eax, 4
        mov rbx, ImageWidth
        sub eax, ebx
        mov pt.x, eax

        mov rax, dqStyle
        and rax, MUIBS_BOTTOM 
        .IF rax == MUIBS_BOTTOM
            xor rax, rax
            xor rbx, rbx
            mov eax, rect.bottom
            sub eax, 4d
            mov rbx, ImageHeight
            sub eax, ebx
            mov pt.y, eax
        .ELSE
            xor rax, rax
            xor rbx, rbx        
            mov eax, rect.bottom
            shr eax, 1
            mov rbx, ImageHeight
            shr ebx, 1
            sub eax, ebx
            mov pt.y, eax
        .ENDIF


        mov rax, NotifyImageType
        .IF rax == 1 ; bitmap
            
            Invoke CreateCompatibleDC, hdcMain
            mov hdcMem, rax
            Invoke SelectObject, hdcMem, hNotifyImage
            mov hbmOld, rax
    
            Invoke BitBlt, hdcDest, pt.x, pt.y, dword ptr ImageWidth, dword ptr ImageHeight, hdcMem, 0, 0, SRCCOPY
    
            Invoke SelectObject, hdcMem, hbmOld
            Invoke DeleteDC, hdcMem
            .IF hbmOld != 0
                Invoke DeleteObject, hbmOld
            .ENDIF
            
        .ELSEIF rax == 2 ; icon
            Invoke DrawIconEx, hdcDest, pt.x, pt.y, hNotifyImage, 0, 0, 0, 0, DI_NORMAL
        
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
;            PrintText 'hNotifyImage'
;            PrintDec ImageWidth
;            PrintDec ImageHeight
;            PrintDec pt.x
;            PrintDec pt.y
        
            Invoke GdipCreateFromHDC, hdcDest, Addr pGraphics
            
            Invoke GdipCreateBitmapFromGraphics, ImageWidth, ImageHeight, pGraphics, Addr pBitmap
            Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer            
            Invoke GdipDrawImageI, pGraphicsBuffer, hNotifyImage, 0, 0
            Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, dword ptr ImageWidth, dword ptr ImageHeight
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

_MUI_ButtonPaintImages ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonPaintBorder
;-------------------------------------------------------------------------------------
_MUI_ButtonPaintBorder PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD, bSelectedState:QWORD
    LOCAL BorderColor:QWORD
    LOCAL BorderStyle:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL hPen:QWORD
    LOCAL hOldPen:QWORD
    LOCAL rect:RECT
    LOCAL pt:POINT

    .IF bEnabledState == TRUE
        .IF bSelectedState == FALSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonBorderColor        ; Normal border color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonBorderColorAlt     ; Mouse over border color
            .ENDIF
        .ELSE
            .IF bMouseOver == FALSE
                Invoke MUIGetExtProperty, hWin, @ButtonBorderColorSel     ; Selected border color
            .ELSE
                Invoke MUIGetExtProperty, hWin, @ButtonBorderColorSelAlt  ; Selected mouse over border color 
            .ENDIF
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @ButtonBorderColorDisabled        ; Disabled border color
    .ENDIF
    mov BorderColor, rax

    .IF BorderColor != 0
        Invoke MUIGetExtProperty, hWin, @ButtonBorderStyle
        mov BorderStyle, rax

        .IF BorderStyle != MUIBBS_NONE
            mov rax, BorderStyle
            and rax, MUIBBS_ALL
            .IF rax == MUIBBS_ALL
                Invoke GetStockObject, DC_BRUSH
                mov hBrush, rax
                Invoke SelectObject, hdc, rax
                mov hOldBrush, rax
                Invoke SetDCBrushColor, hdc, dword ptr BorderColor
                Invoke FrameRect, hdc, lpRect, hBrush
            .ELSE
                Invoke CreatePen, PS_SOLID, 1, dword ptr BorderColor
                mov hPen, rax
                Invoke SelectObject, hdc, hPen
                mov hOldPen, rax 
                ;Invoke InflateRect, Addr rect, -1, 0
                
                Invoke CopyRect, Addr rect, lpRect
                
                mov rax, BorderStyle
                and rax, MUIBBS_TOP
                .IF rax == MUIBBS_TOP
                    Invoke MoveToEx, hdc, rect.left, rect.top, Addr pt
                    Invoke LineTo, hdc, rect.right, rect.top
                .ENDIF
                mov rax, BorderStyle
                and rax, MUIBBS_RIGHT
                .IF rax == MUIBBS_RIGHT
                    dec rect.right                
                    Invoke MoveToEx, hdc, rect.right, rect.top, Addr pt
                    Invoke LineTo, hdc, rect.right, rect.bottom
                    inc rect.right
                .ENDIF
                mov rax, BorderStyle
                and rax, MUIBBS_BOTTOM
                .IF rax == MUIBBS_BOTTOM
                    dec rect.bottom
                    Invoke MoveToEx, hdc, rect.left, rect.bottom, Addr pt
                    Invoke LineTo, hdc, rect.right, rect.bottom
                    inc rect.bottom
                .ENDIF
                mov rax, BorderStyle
                and rax, MUIBBS_LEFT
                .IF rax == MUIBBS_LEFT
                    Invoke MoveToEx, hdc, rect.left, rect.top, Addr pt
                    Invoke LineTo, hdc, rect.left, rect.bottom
                .ENDIF
                .IF hOldPen != 0
                    Invoke SelectObject, hdc, hOldPen
                    Invoke DeleteObject, hOldPen
                .ENDIF
                .IF hPen != 0
                    Invoke DeleteObject, hPen
                .ENDIF

            .ENDIF
        .ENDIF
    .ENDIF

    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF      
    
    ret

_MUI_ButtonPaintBorder ENDP


;-------------------------------------------------------------------------------------
; _MUI_ButtonSetPropertyEx
;-------------------------------------------------------------------------------------
_MUI_ButtonSetPropertyEx PROC FRAME USES RBX hWin:QWORD, dqProperty:QWORD, dqPropertyValue:QWORD
    
    mov rax, dqProperty
    .IF rax == @ButtonTextFont || rax == @ButtonNoteTextFont || rax == @ButtonNotifyTextFont
        .IF dqPropertyValue != 0
            Invoke MUISetExtProperty, hWin, dqProperty, dqPropertyValue 
        .ENDIF    
    .ELSE
        Invoke MUISetExtProperty, hWin, dqProperty, dqPropertyValue
    .ENDIF
    
	mov rax, dqProperty
	.IF rax == @ButtonTextColor ; set other text colors to this if they are not set
	    Invoke MUIGetExtProperty, hWin, @ButtonTextColorAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonTextColorAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @ButtonTextColorSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonTextColorSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @ButtonTextColorSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @ButtonTextColorSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @ButtonTextColorSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @ButtonTextColorSelAlt, rax
	        .ENDIF
	    .ENDIF
        Invoke MUIGetExtProperty, hWin, @ButtonNotifyTextColor
        .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonNotifyTextColor, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @ButtonNoteTextColor
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonNoteTextColor, dqPropertyValue
	    .ENDIF
	
	.ELSEIF rax == @ButtonTextColorSel
	    Invoke MUIGetExtProperty, hWin, @ButtonTextColorSelAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonTextColorSelAlt, dqPropertyValue
	    .ENDIF
	
	.ELSEIF rax == @ButtonBackColor
	    Invoke MUIGetExtProperty, hWin, @ButtonBackColorAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonBackColorAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @ButtonBackColorSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonBackColorSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @ButtonBackColorSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @ButtonBackColorSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @ButtonBackColorSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @ButtonBackColorSelAlt, rax
	        .ENDIF
	    .ENDIF
        Invoke MUIGetExtProperty, hWin, @ButtonNotifyBackColor
        .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonNotifyBackColor, dqPropertyValue
	    .ENDIF

	.ELSEIF rax == @ButtonBorderColor
	    Invoke MUIGetExtProperty, hWin, @ButtonBorderColorAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonBorderColorAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @ButtonBorderColorSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonBorderColorSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @ButtonBorderColorSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @ButtonBorderColorSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @ButtonBorderColorSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @ButtonBorderColorSelAlt, rax
	        .ENDIF
	    .ENDIF	

	.ELSEIF rax == @ButtonAccentColor
	    Invoke MUIGetExtProperty, hWin, @ButtonAccentColorAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonAccentColorAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @ButtonAccentColorSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonAccentColorSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @ButtonAccentColorSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @ButtonAccentColorSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @ButtonAccentColorSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @ButtonAccentColorSelAlt, rax
	        .ENDIF
	    .ENDIF		

	.ELSEIF rax == @ButtonAccentStyle
	    Invoke MUIGetExtProperty, hWin, @ButtonAccentStyleAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonAccentStyleAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @ButtonAccentStyleSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonAccentStyleSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @ButtonAccentStyleSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @ButtonAccentStyleSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @ButtonAccentStyleSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @ButtonAccentStyleSelAlt, rax
	        .ENDIF
	    .ENDIF		

	.ELSEIF rax == @ButtonImage
	    Invoke MUIGetExtProperty, hWin, @ButtonImageAlt
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonImageAlt, dqPropertyValue
	    .ENDIF
	    Invoke MUIGetExtProperty, hWin, @ButtonImageSel
	    .IF rax == 0
	        Invoke MUISetExtProperty, hWin, @ButtonImageSel, dqPropertyValue
	    .ENDIF
	    ; except this, if sel has a color, then use this for selalt if it has a value
	    Invoke MUIGetExtProperty, hWin, @ButtonImageSelAlt
	    .IF rax == 0
	        Invoke MUIGetExtProperty, hWin, @ButtonImageSel
	        .IF rax == 0
	            Invoke MUISetExtProperty, hWin, @ButtonImageSelAlt, dqPropertyValue
	        .ELSE
	            Invoke MUISetExtProperty, hWin, @ButtonImageSelAlt, rax
	        .ENDIF
	    .ENDIF			
	.ENDIF

    ret
_MUI_ButtonSetPropertyEx ENDP


;--------------------------------------------------------------------------------------------------------------------------------------
; Other PUBLIC function wrappers - most equate to same as custom messages
;--------------------------------------------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------
; MUIButtonGetState
;-------------------------------------------------------------------------------------
MUIButtonGetState PROC FRAME hControl:QWORD
    Invoke SendMessage, hControl, MUIBM_GETSTATE, 0, 0
    ret
MUIButtonGetState ENDP

;-------------------------------------------------------------------------------------
; MUIButtonSetState
;-------------------------------------------------------------------------------------
MUIButtonSetState PROC FRAME hControl:QWORD, bState:QWORD
    Invoke SendMessage, hControl, MUIBM_SETSTATE, bState, 0
    ret
MUIButtonSetState ENDP

;-------------------------------------------------------------------------------------
; MUIButtonLoadImages - Loads images from resource ids and stores the handles in the
; appropriate property.
;-------------------------------------------------------------------------------------
MUIButtonLoadImages PROC FRAME hControl:QWORD, dqImageType:QWORD, dqResIDImage:QWORD, dqResIDImageAlt:QWORD, dqResIDImageSel:QWORD, dqResIDImageSelAlt:QWORD, dqResIDImageDisabled:QWORD

    .IF dqImageType == 0
        ret
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @ButtonImageType, dqImageType

    .IF dqResIDImage != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_ButtonLoadBitmap, hControl, @ButtonImage, dqResIDImage
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_ButtonLoadIcon, hControl, @ButtonImage, dqResIDImage
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_ButtonLoadPng, hControl, @ButtonImage, dqResIDImage
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageAlt != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_ButtonLoadBitmap, hControl, @ButtonImageAlt, dqResIDImageAlt
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_ButtonLoadIcon, hControl, @ButtonImageAlt, dqResIDImageAlt
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_ButtonLoadPng, hControl, @ButtonImageAlt, dqResIDImageAlt
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageSel != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_ButtonLoadBitmap, hControl, @ButtonImageSel, dqResIDImageSel
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_ButtonLoadIcon, hControl, @ButtonImageSel, dqResIDImageSel
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_ButtonLoadPng, hControl, @ButtonImageSel, dqResIDImageSel
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageSelAlt != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_ButtonLoadBitmap, hControl, @ButtonImageSelAlt, dqResIDImageSelAlt
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_ButtonLoadIcon, hControl, @ButtonImageSelAlt, dqResIDImageSelAlt
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_ButtonLoadPng, hControl, @ButtonImageSelAlt, dqResIDImageSelAlt
            ENDIF
        .ENDIF
    .ENDIF

    .IF dqResIDImageDisabled != 0
        mov rax, dqImageType
        .IF rax == 1 ; bitmap
            Invoke _MUI_ButtonLoadBitmap, hControl, @ButtonImageDisabled, dqResIDImageDisabled
        .ELSEIF rax == 2 ; icon
            Invoke _MUI_ButtonLoadIcon, hControl, @ButtonImageDisabled, dqResIDImageDisabled
        .ELSEIF rax == 3 ; png
            IFDEF MUI_USEGDIPLUS
            Invoke _MUI_ButtonLoadPng, hControl, @ButtonImageDisabled, dqResIDImageDisabled
            ENDIF
        .ENDIF
    .ENDIF
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    
    ret
MUIButtonLoadImages ENDP

;-------------------------------------------------------------------------------------
; MUIButtonSetImages - Sets the property handles for image types
;-------------------------------------------------------------------------------------
MUIButtonSetImages PROC FRAME hControl:QWORD, dqImageType:QWORD, hImage:QWORD, hImageAlt:QWORD, hImageSel:QWORD, hImageSelAlt:QWORD, hImageDisabled:QWORD

    .IF dqImageType == 0
        ret
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @ButtonImageType, dqImageType

    .IF hImage != 0
        Invoke MUISetExtProperty, hControl, @ButtonImage, hImage
    .ENDIF

    .IF hImageAlt != 0
        Invoke MUISetExtProperty, hControl, @ButtonImageAlt, hImageAlt
    .ENDIF

    .IF hImageSel != 0
        Invoke MUISetExtProperty, hControl, @ButtonImageSel, hImageSel
    .ENDIF

    .IF hImageSelAlt != 0
        Invoke MUISetExtProperty, hControl, @ButtonImageSelAlt, hImageSelAlt
    .ENDIF

    .IF hImageDisabled != 0
        Invoke MUISetExtProperty, hControl, @ButtonImageDisabled, hImageDisabled
    .ENDIF
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    
    ret

MUIButtonSetImages ENDP

;-------------------------------------------------------------------------------------
; MUIButtonNotifySetText
;-------------------------------------------------------------------------------------
MUIButtonNotifySetText PROC FRAME hControl:QWORD, lpszNotifyText:QWORD, bRedraw:QWORD
    Invoke SendMessage, hControl, MUIBM_NOTIFYSETTEXT, lpszNotifyText, bRedraw
    ret
MUIButtonNotifySetText ENDP

;-------------------------------------------------------------------------------------
; MUIButtonNotifyLoadImage
;-------------------------------------------------------------------------------------
MUIButtonNotifyLoadImage PROC FRAME hControl:QWORD, dqImageType:QWORD, dqResIDNotifyImage:QWORD
    Invoke SendMessage, hControl, MUIBM_NOTIFYLOADIMAGE, dqImageType, dqResIDNotifyImage
    ret
MUIButtonNotifyLoadImage ENDP

;-------------------------------------------------------------------------------------
; MUIButtonNotifySetImage
;-------------------------------------------------------------------------------------
MUIButtonNotifySetImage PROC FRAME hControl:QWORD, dqImageType:QWORD, hNotifyImage:QWORD
    Invoke SendMessage, hControl, MUIBM_NOTIFYSETIMAGE, dqImageType, hNotifyImage
    ret
MUIButtonNotifySetImage ENDP

;-------------------------------------------------------------------------------------
; MUIButtonNotifySetFont
;-------------------------------------------------------------------------------------
MUIButtonNotifySetFont PROC FRAME hControl:QWORD, hFont:QWORD, bRedraw:QWORD
    Invoke SendMessage, hControl, MUIBM_NOTIFYSETFONT, hFont, bRedraw
    ret
MUIButtonNotifySetFont ENDP

;-------------------------------------------------------------------------------------
; MUIButtonNotify
;-------------------------------------------------------------------------------------
MUIButtonNotify PROC FRAME hControl:QWORD, bNotify:QWORD
    Invoke SendMessage, hControl, MUIBM_NOTIFY, bNotify, 0 
    ret
MUIButtonNotify ENDP

;-------------------------------------------------------------------------------------
; MUIButtonNoteSetText
;-------------------------------------------------------------------------------------
MUIButtonNoteSetText PROC FRAME hControl:QWORD, lpszNoteText:QWORD, bRedraw:QWORD
    Invoke SendMessage, hControl, MUIBM_NOTESETTEXT, lpszNoteText, bRedraw
    ret
MUIButtonNoteSetText ENDP

;-------------------------------------------------------------------------------------
; MUIButtonNoteSetFont
;-------------------------------------------------------------------------------------
MUIButtonNoteSetFont PROC FRAME hControl:QWORD, hFont:QWORD, bRedraw:QWORD
    Invoke SendMessage, hControl, MUIBM_NOTESETFONT, hFont, bRedraw
    ret
MUIButtonNoteSetFont ENDP

;-------------------------------------------------------------------------------------
; MUIButtonSetAllProperties - Set all properties at once from long poiner to a 
; MUI_BUTTON_PROPERTIES structure.
;-------------------------------------------------------------------------------------
MUIButtonSetAllProperties PROC FRAME USES RBX RCX hControl:QWORD, lpMUIBUTTONPROPERTIES:QWORD, dqSizeMUIBP:QWORD
    LOCAL lpdqExternalProperties:QWORD
    
    Invoke GetWindowLongPtr, hControl, MUI_EXTERNAL_PROPERTIES ; 4
    .IF rax == 0
        mov rax, FALSE
        ret
    .ENDIF
    mov lpdqExternalProperties, rax
    
    mov rax, dqSizeMUIBP
    .IF rax != SIZEOF MUI_BUTTON_PROPERTIES
        mov rax, FALSE
        ret
    .ENDIF
    
    mov rcx, lpdqExternalProperties
    mov rbx, lpMUIBUTTONPROPERTIES
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqTextFont
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqTextFont, rax 
    .ENDIF
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqTextColor
    mov [rcx].MUI_BUTTON_PROPERTIES.dqTextColor, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqTextColorAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqTextColorAlt, rax    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqTextColorSel
    mov [rcx].MUI_BUTTON_PROPERTIES.dqTextColorSel, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqTextColorSelAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqTextColorSelAlt, rax    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqTextColorDisabled
    mov [rcx].MUI_BUTTON_PROPERTIES.dqTextColorDisabled, rax      
        
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBackColor
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBackColor, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBackColorAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBackColorAlt, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBackColorSel
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBackColorSel, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBackColorSelAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBackColorSelAlt, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBackColorDisabled
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBackColorDisabled, rax    
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBorderColor
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBorderColor, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBorderColorAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBorderColorAlt, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBorderColorSel
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBorderColorSel, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBorderColorSelAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBorderColorSelAlt, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBorderColorDisabled
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBorderColorDisabled, rax
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqBorderStyle
    mov [rcx].MUI_BUTTON_PROPERTIES.dqBorderStyle, rax

    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentColor
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentColor, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentColorAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentColorAlt, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentColorSel
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentColorSel, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentColorSelAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentColorSelAlt, rax

    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentStyle
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentStyle, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentStyleAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentStyleAlt, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentStyleSel
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentStyleSel, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqAccentStyleSelAlt
    mov [rcx].MUI_BUTTON_PROPERTIES.dqAccentStyleSelAlt, rax
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqImageType
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqImageType, rax
    .ENDIF
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqImage
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqImage, rax
    .ENDIF
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqRightImage
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqRightImage, rax
    .ENDIF
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqNotifyTextFont
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqNotifyTextFont, rax
    .ENDIF
    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqNotifyTextColor
    mov [rcx].MUI_BUTTON_PROPERTIES.dqNotifyTextColor, rax    
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqNotifyBackColor
    mov [rcx].MUI_BUTTON_PROPERTIES.dqNotifyBackColor, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqNotifyRound
    mov [rcx].MUI_BUTTON_PROPERTIES.dqNotifyRound, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqNotifyImageType
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqNotifyImageType, rax
    .ENDIF
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqNotifyImage
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqNotifyImage, rax
    .ENDIF
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonNoteTextFont
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonNoteTextFont, rax
    .ENDIF
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonNoteTextColor
    mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonNoteTextColor, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonNoteTextColorDisabled
    mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonNoteTextColorDisabled, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonPaddingLeftIndent
    mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonPaddingLeftIndent, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonPaddingGeneral
    mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonPaddingGeneral, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonPaddingStyle
    mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonPaddingStyle, rax
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonPaddingTextImage
    .IF rax != NULL
        mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonPaddingTextImage, rax
    .ENDIF
    mov rax, [rbx].MUI_BUTTON_PROPERTIES.dqButtonDllInstance
    mov [rcx].MUI_BUTTON_PROPERTIES.dqButtonDllInstance, rax
    ;Invoke RtlMoveMemory, lpdqInternalProperties, lpMUIBUTTONPROPERTIES, SIZEOF MUI_BUTTON_PROPERTIES

    ; check default values: text colors
    Invoke MUIGetExtProperty, hControl, @ButtonTextColorAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonTextColor
        Invoke MUISetExtProperty, hControl, @ButtonTextColorAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonTextColorSel
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonTextColor
        Invoke MUISetExtProperty, hControl, @ButtonTextColorSel, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonTextColorSelAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonTextColorSel
        Invoke MUISetExtProperty, hControl, @ButtonTextColorSelAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonTextColorDisabled
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonTextColor
        Invoke MUISetExtProperty, hControl, @ButtonTextColorDisabled, rax
    .ENDIF
    
    ; check default values: back colors
    Invoke MUIGetExtProperty, hControl, @ButtonBackColorAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBackColor
        Invoke MUISetExtProperty, hControl, @ButtonBackColorAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonBackColorSel
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBackColor
        Invoke MUISetExtProperty, hControl, @ButtonBackColorSel, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonBackColorSelAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBackColorSel
        Invoke MUISetExtProperty, hControl, @ButtonBackColorSelAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonBackColorDisabled
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBackColor
        Invoke MUISetExtProperty, hControl, @ButtonBackColorDisabled, rax
    .ENDIF

    ; check default values: border colors
    Invoke MUIGetExtProperty, hControl, @ButtonBorderColorAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBorderColor
        Invoke MUISetExtProperty, hControl, @ButtonBorderColorAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonBorderColorSel
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBorderColor
        Invoke MUISetExtProperty, hControl, @ButtonBorderColorSel, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonBorderColorSelAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBorderColorSel
        Invoke MUISetExtProperty, hControl, @ButtonBorderColorSelAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonBorderColorDisabled
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonBorderColor
        Invoke MUISetExtProperty, hControl, @ButtonBorderColorDisabled, rax
    .ENDIF

    ; check default values: accent colors
    Invoke MUIGetExtProperty, hControl, @ButtonAccentColorAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonAccentColor
        Invoke MUISetExtProperty, hControl, @ButtonAccentColorAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonAccentColorSel
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonAccentColor
        Invoke MUISetExtProperty, hControl, @ButtonAccentColorSel, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonAccentColorSelAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonAccentColorSel
        Invoke MUISetExtProperty, hControl, @ButtonAccentColorSelAlt, rax
    .ENDIF

    ; check default values: accent styles
    Invoke MUIGetExtProperty, hControl, @ButtonAccentStyleAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonAccentStyle
        Invoke MUISetExtProperty, hControl, @ButtonAccentStyleAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonAccentStyleSel
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonAccentStyle
        Invoke MUISetExtProperty, hControl, @ButtonAccentStyleSel, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonAccentStyleSelAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonAccentStyleSel
        Invoke MUISetExtProperty, hControl, @ButtonAccentStyleSelAlt, rax
    .ENDIF
    
    ; check default values: images
    Invoke MUIGetExtProperty, hControl, @ButtonImageAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonImage
        Invoke MUISetExtProperty, hControl, @ButtonImageAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonImageSel
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonImage
        Invoke MUISetExtProperty, hControl, @ButtonImageSel, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonImageSelAlt
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonImageSel
        Invoke MUISetExtProperty, hControl, @ButtonImageSelAlt, rax
    .ENDIF
    Invoke MUIGetExtProperty, hControl, @ButtonImageDisabled
    .IF rax == 0
        Invoke MUIGetExtProperty, hControl, @ButtonImage
        Invoke MUISetExtProperty, hControl, @ButtonImageDisabled, rax
    .ENDIF
    
    mov rax, TRUE
    
    ret

MUIButtonSetAllProperties ENDP

;-------------------------------------------------------------------------------------
; _MUI_ButtonLoadIcon - if succesful, loads specified bitmap resource into the specified
; external property and returns TRUE in rax, otherwise FALSE.
;-------------------------------------------------------------------------------------
_MUI_ButtonLoadBitmap PROC FRAME hWin:QWORD, dqProperty:QWORD, idResBitmap:QWORD
    LOCAL hinstance:QWORD

    .IF idResBitmap == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hWin, @ButtonDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax
    
	Invoke LoadBitmap, hinstance, idResBitmap
    Invoke MUISetExtProperty, hWin, dqProperty, rax
	mov rax, TRUE
    
    ret

_MUI_ButtonLoadBitmap ENDP

;-------------------------------------------------------------------------------------
; _MUI_ButtonLoadIcon - if succesful, loads specified icon resource into the specified
; external property and returns TRUE in rax, otherwise FALSE.
;-------------------------------------------------------------------------------------
_MUI_ButtonLoadIcon PROC FRAME hWin:QWORD, dqProperty:QWORD, idResIcon:QWORD
    LOCAL hinstance:QWORD

    .IF idResIcon == NULL
        mov rax, FALSE
        ret
    .ENDIF
    Invoke MUIGetExtProperty, hWin, @ButtonDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax

	Invoke LoadImage, hinstance, idResIcon, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
    Invoke MUISetExtProperty, hWin, dqProperty, eax

	mov rax, TRUE

    ret

_MUI_ButtonLoadIcon ENDP

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
_MUI_ButtonLoadPng PROC FRAME hWin:QWORD, dqProperty:QWORD, idResPng:QWORD
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

    Invoke MUIGetExtProperty, hWin, @ButtonDllInstance
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
	jmp		_MUI_ButtonLoadPng@Close
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
	jmp		_MUI_ButtonLoadPng@Close
@@:	mov		sizeOfRes, rax
	
	invoke	LockResource, hResData
	or		rax, rax
	jnz		@f
	jmp		_MUI_ButtonLoadPng@Close
@@:	mov		pResData, rax

	invoke	GlobalAlloc, GMEM_MOVEABLE, sizeOfRes
	or		rax, rax
	jnz		@f
	jmp		_MUI_ButtonLoadPng@Close
@@:	mov		hbuffer, rax

	invoke	GlobalLock, hbuffer
	mov		pbuffer, rax
	
	invoke	RtlMoveMemory, pbuffer, hResData, sizeOfRes
	invoke	CreateStreamOnHGlobal, pbuffer, TRUE, addr pIStream
	or		rax, rax
	jz		@f
	jmp		_MUI_ButtonLoadPng@Close
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

    Invoke MUISetExtProperty, hWin, dqProperty, pBitmapFromStream
    ;PrintDec dwProperty
    ;PrintDec pBitmapFromStream
    
    mov rax, dqProperty
    .IF rax == @ButtonImage
        Invoke MUISetIntProperty, hWin, @ButtonImageStream, hIStream
    .ELSEIF rax == @ButtonImageAlt
        Invoke MUISetIntProperty, hWin, @ButtonImageAltStream, hIStream
    .ELSEIF rax == @ButtonImageSel
        Invoke MUISetIntProperty, hWin, @ButtonImageSelStream, hIStream
    .ELSEIF rax == @ButtonImageSelAlt
        Invoke MUISetIntProperty, hWin, @ButtonImageSelAltStream, hIStream
    .ELSEIF rax == @ButtonImageDisabled
        Invoke MUISetIntProperty, hWin, @ButtonImageDisabledStream, hIStream
    .ELSEIF rax == @ButtonNotifyImage
        Invoke MUISetIntProperty, hWin, @ButtonNotifyImageStream, hIStream
    .ENDIF

	mov rax, TRUE
	
_MUI_ButtonLoadPng@Close:
	ret
_MUI_ButtonLoadPng ENDP
ENDIF

;-------------------------------------------------------------------------------------
; _MUI_ButtonPngReleaseIStream - releases png stream handle
;-------------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
_MUI_ButtonPngReleaseIStream PROC FRAME hIStream:QWORD
    
    mov rax, hIStream
    push rax
    mov rax, QWORD PTR [rax]
    call IStreamX.IUnknown.Release[rax]                               ; release the stream
    ret

_MUI_ButtonPngReleaseIStream ENDP
ENDIF







END
