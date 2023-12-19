;==============================================================================
;
; ModernUI x64 Control - ModernUI_CaptionBar x64
;
; Copyright (c) 2023 by fearless
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
include commctrl.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib comctl32.lib

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

include ModernUI_CaptionBar.inc

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------


_MUI_CaptionBarWndProc			PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_CaptionBarInit             PROTO :QWORD
_MUI_CaptionBarCleanup          PROTO :QWORD
_MUI_CaptionBarPaint			PROTO :QWORD
_MUI_CaptionBarPaintBackground  PROTO :QWORD, :QWORD, :QWORD
_MUI_CaptionBarPaintImage       PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CaptionBarReposition       PROTO :QWORD
_MUI_CaptionBarParentSubClassProc PROTO :HWND, :UINT, :WPARAM, :LPARAM, :QWORD, :QWORD

_MUI_CaptionBarBackLoadBitmap   PROTO :QWORD, :QWORD, :QWORD
_MUI_CaptionBarBackLoadIcon     PROTO :QWORD, :QWORD, :QWORD

_MUI_CreateCaptionBarSysButtons PROTO :QWORD, :QWORD
_MUI_CreateSysButton            PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_SysButtonWndProc           PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_SysButtonInit              PROTO :QWORD
_MUI_SysButtonCleanup           PROTO :QWORD
_MUI_SysButtonPaint             PROTO :QWORD
_MUI_SysButtonSetPropertyEx     PROTO :QWORD, :QWORD, :QWORD

_MUI_ApplyMUIStyleToDialog      PROTO :QWORD, :QWORD


_MUI_CreateCapButton            PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CapButtonWndProc           PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_CapButtonInit              PROTO :QWORD
_MUI_CapButtonCleanup           PROTO :QWORD
_MUI_CapButtonPaint             PROTO :QWORD
_MUI_CapButtonsReposition       PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_CapButtonSetPropertyEx     PROTO :QWORD, :QWORD, :QWORD

_CBP_MouseOverBorders           PROTO :QWORD, :QWORD



;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; CaptionBar External Properties
IFNDEF MUI_CAPTIONBAR_PROPERTIES
MUI_CAPTIONBAR_PROPERTIES       STRUCT 8
    qwTextColor                 DQ ?    ; RGBCOLOR. Text color for captionbar text and system buttons (min/max/restore/close)
    qwTextFont                  DQ ?    ; hFont. Font for captionbar text
    qwBackColor                 DQ ?    ; RGBCOLOR. Background color of captionbar and system buttons (min/max/restore/close)
    qwBackImageType             DQ ?    ; QWORD. Image Type - One of the following: MUICBIT_NONE,MUICBIT_BMP, MUICBIT_ICO, MUICBIT_PNG
    qwBackImage                 DQ ?    ; hImage. Image to display in captionbar background.
    qwBackImageOffsetX          DQ ?    ; QWORD. Offset x +/- to set position of hImage
    qwBackImageOffsetY          DQ ?    ; QWORD. Offset y +/- to set position of hImage    
    qwButtonTextRollColor       DQ ?    ; RGBCOLOR. Text color for system buttons (min/max/restore/close) when mouse moves over button
    qwButtonBackRollColor       DQ ?    ; RGBCOLOR. Background color for system buttons (min/max/restore/close) when mouse moves over button
    qwButtonBorderColor         DQ ?    ; RGBCOLOR. Border color for system buttons (min/max/restore/close). 0 = use same as @CaptionBarBackColor
    qwButtonBorderRollColor     DQ ?    ; RGBCOLOR. Border color for system buttons (min/max/restore/close) when mouse moves over button. 0 = use @CaptionBarBtnBckRollColor  
    qwButtonsWidth              DQ ?    ; QWORD. System buttons width. Defaults = 32px
    qwButtonsHeight             DQ ?    ; QWORD. System buttons height. Defaults = 28px
    qwButtonsOffsetX            DQ ?    ; QWORD. Offset y +/- to set position of system buttons (min/max/restore/close) in relation to right of captionbar
    qwButtonsOffsetY            DQ ?    ; QWORD. Offset y + to set position of system buttons (min/max/restore/close) in relation to top of captionbar    
    qwBtnIcoMin                 DQ ?    ; hIcon. For minimize button
    qwBtnIcoMinAlt              DQ ?    ; hIcon. For minimize button when mouse moves over button
    qwBtnIcoMax                 DQ ?    ; hIcon. For maximize button
    qwBtnIcoMaxAlt              DQ ?    ; hIcon. For maximize button when mouse moves over button
    qwBtnIcoRes                 DQ ?    ; hIcon. For restore button
    qwBtnIcoResAlt              DQ ?    ; hIcon. For restore button when mouse moves over button
    qwBtnIcoClose               DQ ?    ; hIcon. For close button
    qwBtnIcoCloseAlt            DQ ?    ; hIcon. For close button when mouse moves over button
    qwWindowBackColor           DQ ?    ; RGBCOLOR. If -1 = No painting of window/dialog background, handled by user or default system.
    qwWindowBorderColor         DQ ?    ; RGBCOLOR. If -1 = No border. if WindowBackColor != -1 then color of border to paint on window.    
    qwDllInstance               DQ ?    ; hInstance. For loading resources (icons) - normally set to 0 (current module) but when resources are in a dll set this before calling MUICaptionBarLoadIcons
    qwCaptionBarParam           DQ ?    ; QWORD. Custom user data
MUI_CAPTIONBAR_PROPERTIES       ENDS
ENDIF

; CaptionBar Internal Poperties
_MUI_CAPTIONBAR_PROPERTIES		STRUCT 8
	qwEnabledState				DQ ?
	qwMouseOver					DQ ?
    qwMouseDown                 DQ ? 	
	hSysButtonClose             DQ ?
	hSysButtonMax               DQ ?
	hSysButtonRes               DQ ?
	hSysButtonMin               DQ ?
	qwNoMoveWindow              DQ ?
	qwUseIcons                  DQ ?
    qwButtonsLeftOffset         DQ ? ; calced left offset of all buttons including x offsets
    qwTotalButtons              DQ ?
    qwButtonArray               DQ ?    	
_MUI_CAPTIONBAR_PROPERTIES		ENDS

; SysButton External Properties
IFNDEF MUI_SYSBUTTON_PROPERTIES
MUI_SYSBUTTON_PROPERTIES        STRUCT 8
	qwTextColor					DQ ?
	qwTextRollColor             DQ ?
	qwBackColor					DQ ?
	qwBackRollColor             DQ ?
    qwBorderColor               DQ ?
    qwBorderRollColor           DQ ?	
    qwSysButtonType             DQ ?
    qwIco                       DQ ?
    qwIcoAlt                    DQ ?
    qwParam                     DQ ?
    qwResourceID                DQ ?    
MUI_SYSBUTTON_PROPERTIES        ENDS
ENDIF

; SysButton Internal Properties
_MUI_SYSBUTTON_PROPERTIES       STRUCT 8
    qwSysButtonFont				DQ ?
	qwEnabledState				DQ ?
	qwMouseOver					DQ ?
    qwUseIcons                  DQ ?	
_MUI_SYSBUTTON_PROPERTIES       ENDS


IFNDEF MUI_CAPBUTTON_PROPERTIES
MUI_CAPBUTTON_PROPERTIES        STRUCT 8
    qwTextColor                 DQ ?    ; RGBCOLOR
    qwTextRollColor             DQ ?    ; RGBCOLOR
    qwBackColor                 DQ ?    ; RGBCOLOR. Color of back of button.
    qwBackRollColor             DQ ?    ; RGBCOLOR. Color of back of button when mouse moves over.
    qwBorderColor               DQ ?    ; RGBCOLOR. Color of border of button. 0 = use same as qwBackColor
    qwBorderRollColor           DQ ?    ; RGBCOLOR. Color of border of button when mouse moves over. 0 = use same as qwBackRollColor
    qwIco                       DQ ?    ; hIcon. Handle of icon to use for button
    qwIcoAlt                    DQ ?    ; hIcon. Handle of icon to use for button when mouse moves over it
    qwParam                     DQ ?    ; QWORD. Custom user data. Passed as wNotifyCode (HIWORD of wParam) in WM_COMMAND
    qwResourceID                DQ ?    ; QWORD. Resource ID for button    
MUI_CAPBUTTON_PROPERTIES        ENDS
ENDIF

_MUI_CAPBUTTON_PROPERTIES       STRUCT 8
    qwSysButtonFont             DQ ?
    qwEnabledState              DQ ?
    qwMouseOver                 DQ ?
    qwWidth                     DQ ?
_MUI_CAPBUTTON_PROPERTIES       ENDS


.CONST
align 8
WM_DWMCOMPOSITIONCHANGED        EQU  031Eh
; Resource IDs for System Buttons: Min, Max, Restore and Close
; IDs for custom buttons are 1 to (MUI_SYSBUTTON_CLOSE-4)
MUI_SYSBUTTON_CLS_ID                        EQU 0FFFFh
MUI_SYSBUTTON_MAX_ID                        EQU (MUI_SYSBUTTON_CLS_ID -1)
MUI_SYSBUTTON_RES_ID                        EQU (MUI_SYSBUTTON_CLS_ID -2)
MUI_SYSBUTTON_MIN_ID                        EQU (MUI_SYSBUTTON_CLS_ID -3)


MUI_BORDER_SIZE                             EQU 8d
MUI_CAPTIONBAR_IMAGETEXT_PADDING            EQU 10d ; Padding space between end of image and start of text
MUI_CAPTIONBAR_TEXTLEFT_PADDING             EQU 6d  ; Padding space from left of ModernUI_CaptionBar to start of text if no image present
MUI_DEFAULT_CAPTION_HEIGHT                  EQU 32d ; Default height of caption bar control
MUI_SYSBUTTON_WIDTH                         EQU 32d ; Default width of system buttons
MUI_SYSBUTTON_HEIGHT                        EQU 28d ; Default height of system buttons
MUI_SYSBUTTONS_SPACING                      EQU 0   ; Spacing between each system button
MUI_SYSCAPBUTTON_SPACING                    EQU 12  ; Spacing between system buttons and capbuttons
MUI_CAPBUTTON_MAX                           EQU 8   ; Max no of capbuttons
MUI_CAPBUTTON_TEXT_PADDING                  EQU 3   ; Padding space from left of capbutton to start of text (if any text) 
MUI_CAPBUTTON_IMAGETEXT_PADDING             EQU 3   ; Padding space between end of image and start of text in capbutton 
MUI_CAPBUTTONS_SPACING                      EQU 4   ; Spacing between each capbutton
MUI_CAPBUTTON_TEXT_MAX                      EQU 32  ; Default max length of captionbutton text


; CaptionBar Internal Properties
@CaptionBarEnabledState                     EQU 0
@CaptionBarMouseOver                        EQU 8
@CaptionBarMouseDown                        EQU 16
@CaptionBar_hSysButtonClose                 EQU 24
@CaptionBar_hSysButtonMax                   EQU 32
@CaptionBar_hSysButtonRes                   EQU 40
@CaptionBar_hSysButtonMin                   EQU 48
@CaptionBarNoMoveWindow                     EQU 56
@CaptionBarUseIcons                         EQU 64
@CaptionBarButtonsLeftOffset                EQU 72
@CaptionBarTotalButtons                     EQU 80
@CaptionBarButtonArray                      EQU 88

; SysButton Internal Properties
@SysButtonFont                              EQU 0
@SysButtonEnabledState						EQU 8
@SysButtonMouseOver							EQU 16
@SysButtonUseIcons                          EQU 24

; SysButton External Properties
@SysButtonTextColor                         EQU 0 
@SysButtonTextRollColor                     EQU 8
@SysButtonBackColor                         EQU 16
@SysButtonBackRollColor                     EQU 24
@SysButtonBorderColor                       EQU 32
@SysButtonBorderRollColor                   EQU 40
@SysButtonIco                               EQU 48
@SysButtonIcoAlt                            EQU 56
@SysButtonParam                             EQU 64
@SysButtonResourceID                        EQU 72

; CapButton Internal Properties
@CapButtonFont                              EQU 0
@CapButtonEnabledState                      EQU 8
@CapButtonMouseOver                         EQU 16
@CapButtonWidth                             EQU 24


.DATA
align 8
szMUICaptionBarClass                        DB 'ModernUI_CaptionBar',0  ; Class name for our CaptionBar control
szMUISysButtonClass                         DB 'ModernUI_SysButton',0   ; Class name for our system buttons (min/max/restore or close buttons)
szMUICapButtonClass                         DB 'ModernUI_CapButton',0   ; Class name for our custom captionbar buttons (shown before system buttons)
szMUISysButtonFont                          DB 'Marlett',0              ; System font used for drawing min/max/restore/close glyphs from marlett font
szMUICapButtonFont                          DB 'Segoe UI',0             ; Font used for drawing custom captionbar buttons
szMUICaptionBarFont                         DB 'Segoe UI',0             ; Font used for caption text
hMUICaptionBarFont                          DQ 0                        ; Handle to caption button font (segoe ui)
hMUISysButtonFont                           DQ 0                        ; Handle to system button font (marlett)
hMUICapButtonFont                           DQ 0                        ; Handle to capbutton font
szMUISysMinButton                           DB '0',0                    ; Minimize button glyph from Marlett font
szMUISysMaxButton                           DB '1',0                    ; Maximize button glyph from Marlett font
szMUISysResButton                           DB '2',0                    ; Restore button glyph from Marlett font
szMUISysCloseButton                         DB 'r',0                    ; Close/exit button glyph from Marlett font
szMUISysResizeGrip                          DB 'o',0                    ; Resize grip button glyph from Marlett font


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for CaptionBar control
;------------------------------------------------------------------------------
MUICaptionBarSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUICaptionBarSetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for CaptionBar control
;------------------------------------------------------------------------------
MUICaptionBarGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUICaptionBarGetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICaptionBarRegister - Registers the ModernUI_CaptionBar control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_CaptionBar
;------------------------------------------------------------------------------
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


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICaptionBarCreate - Returns handle in rax of newly created control
;------------------------------------------------------------------------------
MUICaptionBarCreate PROC FRAME USES rbx hWndParent:QWORD, lpszCaptionText:QWORD, qwCaptionHeight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL rect:RECT
	LOCAL qwControlStyle:QWORD

    Invoke GetModuleHandle, NULL
    mov hinstance, rax
    ;PrintQWORD rax
	Invoke MUICaptionBarRegister
    
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN.
	mov rax, qwStyle
	or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
	mov qwControlStyle, rax

    Invoke GetWindowRect, hWndParent, Addr rect
    xor rax, rax
    mov eax, rect.right
    mov ebx, rect.left
    sub eax, ebx
	
    Invoke CreateWindowEx, NULL, Addr szMUICaptionBarClass, lpszCaptionText, dword ptr qwControlStyle, 0, 0, eax, dword ptr qwCaptionHeight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	;PrintQWORD rax
	mov rax, hControl
    ret
MUICaptionBarCreate ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarWndProc - Main processing window for our CaptionBar control
;------------------------------------------------------------------------------
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
        Invoke _MUI_CaptionBarCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
		mov rax, 0
		ret    		

    .ELSEIF eax == WM_COMMAND
        mov rax, wParam
        and rax, 0FFFFh
        .IF eax == MUI_SYSBUTTON_CLS_ID ; close button
            Invoke GetParent, hWin
            Invoke SendMessage, rax, WM_SYSCOMMAND, SC_CLOSE, 0
            ;Invoke SendMessage, rax, WM_CLOSE, 0, 0
            ret
        .ELSEIF eax == MUI_SYSBUTTON_MAX_ID ; max button
            Invoke GetParent, hWin
            Invoke SendMessage, rax, WM_SYSCOMMAND, SC_MAXIMIZE, 0
            ;Invoke ShowWindow, rax, SW_MAXIMIZE
            Invoke _MUI_CaptionBarReposition, hWin
            ret            
        .ELSEIF eax == MUI_SYSBUTTON_RES_ID ; res button
            Invoke GetParent, hWin
            Invoke SendMessage, rax, WM_SYSCOMMAND, SC_RESTORE, 0
            ;Invoke ShowWindow, rax, SW_RESTORE
            Invoke _MUI_CaptionBarReposition, hWin
            ret
        .ELSEIF eax == MUI_SYSBUTTON_MIN_ID ; min button
            Invoke GetParent, hWin
            Invoke SendMessage, rax, WM_SYSCOMMAND, SC_MINIMIZE, 0
            ;Invoke ShowWindow, rax, SW_MINIMIZE
            ret
        .ELSE ; pass on any WM_COMMANDS back to parent - Main window proc for processing
            Invoke GetParent, hWin
            Invoke PostMessage, rax, WM_COMMAND, wParam, lParam ; useful for hosted controls inside CaptionBar            
        .ENDIF
        xor rax, rax
        ret

    .ELSEIF eax == WM_NOTIFY ; pass on any WM_NOTIFY back to parent - Main window proc for notifications
        Invoke GetParent, hWin
        Invoke PostMessage, rax, WM_NOTIFY, wParam, lParam ; useful for hosted controls inside CaptionBar
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

    .ELSEIF eax == WM_LBUTTONDOWN
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseDown, TRUE
        
    .ELSEIF eax == WM_LBUTTONUP
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseDown, FALSE

    .ELSEIF eax == WM_NCHITTEST
        ; https://github.com/mrfearless/ModernUI/issues/7
        ; add additonal logic to prevent wine sticky (until ESC pressed) of the mouse cursor on the caption
            
        Invoke MUIGetIntProperty, hWin, @CaptionBarMouseDown
        .IF rax == TRUE ; mouse is actually down
            Invoke MUIGetIntProperty, hWin, @CaptionBarNoMoveWindow
            .IF rax == FALSE
                Invoke GetParent, hWin
                Invoke SendMessage, rax, WM_NCLBUTTONDOWN, HTCAPTION, 0
            .ENDIF
        .ELSE ; otherwise we didnt detect mouse down ourselves, so no sticky move of caption hopefully
            ; do we need to force it to nowhere?
            ;Invoke GetParent, hWin
            ;Invoke SendMessage, eax, WM_NCLBUTTONDOWN, HTNOWHERE, 0
        .ENDIF

   .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUIGetIntProperty, hWin, @CaptionBarEnabledState
        .IF rax == TRUE   
    		Invoke MUISetIntProperty, hWin, @CaptionBarMouseOver, TRUE
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
        ;Invoke GetParent, hWin
        ;Invoke PostMessage, rax, WM_MOUSEMOVE, wParam, lParam ; pass mousemove to parent            
        
    .ELSEIF eax == WM_MOUSELEAVE
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseOver, FALSE
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseDown, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseOver, FALSE
        Invoke MUISetIntProperty, hWin, @CaptionBarMouseDown, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
	
	.ELSEIF eax == WM_SIZE
	    Invoke _MUI_CaptionBarReposition, hWin
	    mov rax, 0
	    ret

    .ELSEIF eax == WM_SETTEXT
        Invoke GetParent, hWin
        mov hParent, rax
         ; sets text of our CaptionBar
        Invoke DefWindowProc, hWin, uMsg, wParam, lParam
        ; Set main window title
        Invoke SetWindowText, hParent, lParam
        Invoke InvalidateRect, hWin, NULL, FALSE
        mov eax, TRUE
        ret

    .ELSEIF eax == WM_SETICON
        Invoke MUISetExtProperty, hWin, @CaptionBarBackImageType, MUICBIT_ICO
        Invoke MUISetExtProperty, hWin, @CaptionBarBackImage, lParam
        Invoke InvalidateRect, hWin, NULL, FALSE
        ret

	; custom messages start here
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY
		Invoke MUISetExtProperty, hWin, wParam, lParam
		
        ; also set child system button properties as well if they apply
        Invoke _MUI_SysButtonSetPropertyEx, hWin, wParam, lParam
        ; also set child CapButton properties as well if they apply
        Invoke _MUI_CapButtonSetPropertyEx, hWin, wParam, lParam
		
		mov rax, wParam
		.IF rax == @CaptionBarBtnWidth || rax == @CaptionBarBtnHeight || rax == @CaptionBarBtnOffsetX || rax == @CaptionBarBtnOffsetY
            Invoke _MUI_CaptionBarReposition, hWin
        .ELSEIF rax == @CaptionBarBackImageOffsetX || rax == @CaptionBarBackImageOffsetY
            Invoke InvalidateRect, hWin, NULL, FALSE
        .ELSEIF rax == @CaptionBarWindowBorderColor 
            .IF lParam == -1
                Invoke GetWindowLongPtr, hWin, GWL_STYLE
                or rax, MUICS_NOBORDER ; no border color, so set no border style on as we want pos 0,0
            .ELSE
                Invoke GetWindowLongPtr, hWin, GWL_STYLE
                and rax, (-1 xor MUICS_NOBORDER) ; we have border color so set no border style off as we want pos 1,1
            .ENDIF
            Invoke SetWindowLongPtr, hWin, GWL_STYLE, rax
            Invoke _MUI_CaptionBarReposition, hWin
        .ELSEIF rax == @CaptionBarWindowBackColor
            Invoke GetParent, hWin
            Invoke InvalidateRect, rax, NULL, TRUE
        .ENDIF            
		ret

    .ENDIF
	Invoke DefWindowProc, hWin, uMsg, wParam, lParam

    ret
_MUI_CaptionBarWndProc ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarParentSubClassProc - Subclass for caption bar parent window 
; qwRefData is the handle to our CaptionBar control in this subclass proc
;------------------------------------------------------------------------------
_MUI_CaptionBarParentSubClassProc PROC FRAME hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM, uIdSubclass:QWORD, qwRefData:QWORD
    LOCAL wp:WINDOWPLACEMENT
    LOCAL qwStyle:QWORD
    LOCAL BackColor:QWORD    
    
    mov eax, uMsg
    .IF eax == WM_NCDESTROY
        Invoke RemoveWindowSubclass, hWin, Addr _MUI_CaptionBarParentSubClassProc, uIdSubclass ; remove subclass before control destroyed.
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
        ret
    
    ; Handle resize of dialog/window and invalidate it if we are painting a border via MUIPaintBackground
    .ELSEIF eax == WM_NCCALCSIZE
        Invoke InvalidateRect, hWin, NULL, TRUE
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
        ret
    
    .ELSEIF eax == WM_THEMECHANGED  || eax == WM_DWMCOMPOSITIONCHANGED ;  0x031E
        Invoke GetWindowLongPtr, qwRefData, GWL_STYLE
        mov qwStyle, rax
        and rax, MUICS_WINNOMUISTYLE
        .IF rax != MUICS_WINNOMUISTYLE
            ; use dropshadow - unless MUICS_WINNODROPSHADOW is specified
            mov rax, qwStyle
            and rax, MUICS_WINNODROPSHADOW
            .IF rax == MUICS_WINNODROPSHADOW
                Invoke _MUI_ApplyMUIStyleToDialog, hWin, FALSE
            .ELSE
                Invoke _MUI_ApplyMUIStyleToDialog, hWin, TRUE
            .ENDIF
            Invoke InvalidateRect, hWin, NULL, TRUE
            Invoke UpdateWindow, hWin            
        .ENDIF

    .ELSEIF eax == WM_ERASEBKGND
        Invoke MUIGetExtProperty, qwRefData, @CaptionBarWindowBackColor
        .IF rax == -1
            Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
            ret
        .ELSE
            ;PrintText 'Parent WM_ERASEBKGND'
            mov rax, 1
            ret
        .ENDIF

    .ELSEIF eax == WM_PAINT
        Invoke MUIGetExtProperty, qwRefData, @CaptionBarWindowBackColor
        .IF rax == -1
            Invoke DefSubclassProc, hWin, uMsg, wParam, lParam         
            ret
        .ELSE
            ;PrintText 'Parent WM_PAINT'
            mov BackColor, rax
            Invoke MUIGetExtProperty, qwRefData, @CaptionBarWindowBorderColor
            Invoke MUIPaintBackground, hWin, BackColor, rax
            ret
        .ENDIF

    .ELSEIF eax == WM_LBUTTONDOWN
        Invoke GetWindowLongPtr, qwRefData, GWL_STYLE
        and rax, MUICS_WINSIZE
        .IF rax == MUICS_WINSIZE    
            Invoke _CBP_MouseOverBorders, hWin, TRUE
            .IF rax != 0
                .IF rax == 1 ; left
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTLEFT, 0
                .ELSEIF rax == 2 ; top
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTTOP, 0
                .ELSEIF rax == 3 ; right
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTRIGHT, 0
                .ELSEIF rax == 4 ; bottom
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTBOTTOM, 0
                .ELSEIF rax == 5 ; NW
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTTOPLEFT, 0
                .ELSEIF rax == 6 ; NE
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTTOPRIGHT, 0
                .ELSEIF rax == 7 ; SW
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTBOTTOMLEFT, 0
                .ELSEIF rax == 8 ; SE
                    Invoke SendMessage, hWin, WM_NCLBUTTONDOWN, HTBOTTOMRIGHT, 0
                .ENDIF
                ; todo investigate weird artifacts on resizing, its like parts of the dropshadow are showing, or maybe its the border?
                ;Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED ;or SWP_NOSENDCHANGING
                ;Invoke InvalidateRect, hWin, NULL, TRUE
                ;Invoke UpdateWindow, hWin
            .ENDIF
        .ENDIF
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
        ret  

    .ELSEIF eax == WM_MOUSEMOVE
        Invoke GetWindowLongPtr, qwRefData, GWL_STYLE
        and rax, MUICS_WINSIZE
        .IF rax == MUICS_WINSIZE 
            Invoke _CBP_MouseOverBorders, hWin, TRUE
        .ENDIF
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
    
    ; If user pulls caption down whilst maximized this will be caught by this handler and we can adjust the CaptionBar control to reflect the 
    ; restore state it will be in. Or if user programmatically changes window this should catch it as well.
    .ELSEIF eax == WM_SIZE
        mov rax, wParam
        .IF rax == SIZE_MAXIMIZED
            Invoke SendMessage, qwRefData, WM_SIZE, 0, 0 ; force reposition of CaptionBar and its child controls
        .ELSEIF rax == SIZE_RESTORED
            Invoke SendMessage, qwRefData, WM_SIZE, 0, 0 ; force reposition of CaptionBar and its child controls
        .ENDIF
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
        
    .ELSE
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
        ret
    .ENDIF
    ret        
_MUI_CaptionBarParentSubClassProc ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _CBP_MouseOverBorders - set initial default values
;------------------------------------------------------------------------------
; precalc rects? store somewhere for checking later on, recalc on resize
_CBP_MouseOverBorders PROC FRAME hWin:QWORD, bShowCursor:QWORD
    LOCAL qwPos:QWORD
    LOCAL winrect:RECT
    LOCAL borderleft:RECT
    LOCAL bordertop:RECT
    LOCAL borderright:RECT
    LOCAL borderbottom:RECT
    LOCAL cornernw:RECT
    LOCAL cornerne:RECT
    LOCAL cornersw:RECT
    LOCAL cornerse:RECT
    LOCAL pt:POINT
    
    Invoke GetWindowRect, hWin, Addr winrect
    Invoke GetCursorPos, Addr pt
    Invoke CopyRect, Addr borderleft, Addr winrect
    Invoke CopyRect, Addr bordertop, Addr winrect
    Invoke CopyRect, Addr borderright, Addr winrect
    Invoke CopyRect, Addr borderbottom, Addr winrect
    Invoke CopyRect, Addr cornernw, Addr winrect
    Invoke CopyRect, Addr cornerne, Addr winrect
    Invoke CopyRect, Addr cornersw, Addr winrect
    Invoke CopyRect, Addr cornerse, Addr winrect
    
    xor rax, rax
    mov eax, borderleft.left
    add eax, MUI_BORDER_SIZE
    mov borderleft.right, eax
    add borderleft.top, MUI_BORDER_SIZE
    sub borderleft.bottom, MUI_BORDER_SIZE
    
    mov eax, bordertop.top
    add eax, MUI_BORDER_SIZE
    mov bordertop.bottom, eax
    add bordertop.left, MUI_BORDER_SIZE
    sub bordertop.right, MUI_BORDER_SIZE
   
    mov eax, borderright.right
    sub eax, MUI_BORDER_SIZE
    mov borderright.left, eax
    add borderright.top, MUI_BORDER_SIZE
    sub borderright.bottom, MUI_BORDER_SIZE
    
    mov eax, borderbottom.bottom
    sub eax, MUI_BORDER_SIZE
    mov borderbottom.top, eax
    add borderbottom.left, MUI_BORDER_SIZE
    sub borderbottom.right, MUI_BORDER_SIZE
    
    ; Corner NW
    mov eax, cornernw.left
    add eax, MUI_BORDER_SIZE
    mov cornernw.right, eax
    mov eax, cornernw.top
    add eax, MUI_BORDER_SIZE
    mov cornernw.bottom, eax
    
    ; Corner NE
    mov eax, cornerne.right
    sub eax, MUI_BORDER_SIZE
    mov cornerne.left, eax
    mov eax, cornerne.top
    add eax, MUI_BORDER_SIZE
    mov cornerne.bottom, eax
    
    ; Corner SW
    mov eax, cornersw.left
    add eax, MUI_BORDER_SIZE
    mov cornersw.right, eax
    mov eax, cornersw.bottom
    sub eax, MUI_BORDER_SIZE
    mov cornersw.top, eax
    
    ; Corner SE
    mov eax, cornerse.right
    sub eax, MUI_BORDER_SIZE
    mov cornerse.left, eax
    mov eax, cornerse.bottom
    sub eax, MUI_BORDER_SIZE
    mov cornerse.top, eax
    
    mov qwPos, 0
    Invoke PtInRect, Addr borderleft, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'leftborder'
        mov qwPos, 1
    .ENDIF
    
    Invoke PtInRect, Addr bordertop, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'topborder'
        mov qwPos, 2
    .ENDIF
    
    Invoke PtInRect, Addr borderright, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'rightborder'
        mov qwPos, 3
    .ENDIF
    
    Invoke PtInRect, Addr borderbottom, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'bottomborder'
        mov qwPos, 4
    .ENDIF
    
    Invoke PtInRect, Addr cornernw, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'NW'
        mov qwPos, 5
    .ENDIF
    
    Invoke PtInRect, Addr cornerne, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'NE'
        mov qwPos, 6
    .ENDIF
    
    Invoke PtInRect, Addr cornersw, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'SW'
        mov qwPos, 7
    .ENDIF
    
    Invoke PtInRect, Addr cornerse, Addr pt ;pt.x, pt.y
    .IF rax == TRUE
        ;PrintText 'SE'
        mov qwPos, 8
    .ENDIF
    
    .IF bShowCursor == TRUE
        mov rax, qwPos
        .IF rax == 1
            Invoke LoadCursor, NULL, IDC_SIZEWE
        .ELSEIF rax == 2 
            Invoke LoadCursor, NULL, IDC_SIZENS
        .ELSEIF rax == 3
            Invoke LoadCursor, NULL, IDC_SIZEWE
        .ELSEIF rax == 4
            Invoke LoadCursor, NULL, IDC_SIZENS
        .ELSEIF rax == 5 ; NW
            Invoke LoadCursor, NULL, IDC_SIZENWSE
        .ELSEIF rax == 6 ; NE
            Invoke LoadCursor, NULL, IDC_SIZENESW
        .ELSEIF rax == 7 ; SW
            Invoke LoadCursor, NULL, IDC_SIZENESW
        .ELSEIF rax == 8 ; SE
            Invoke LoadCursor, NULL, IDC_SIZENWSE
        .ELSE
            Invoke LoadCursor, NULL, IDC_ARROW
        .ENDIF
        Invoke SetCursor, rax
    .ENDIF
    
    mov rax, qwPos
    ret

_CBP_MouseOverBorders ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarInit - set initial default values
;------------------------------------------------------------------------------
_MUI_CaptionBarInit PROC FRAME hWin:QWORD
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
    
    ; Apply ModernUI style to window/dialog - unless MUICS_WINNOMUISTYLE is specified
    mov rax, qwStyle
    and rax, MUICS_WINNOMUISTYLE
    .IF rax != MUICS_WINNOMUISTYLE
        
        ; use dropshadow - unless MUICS_WINNODROPSHADOW is specified
        mov rax, qwStyle
        and rax, MUICS_WINNODROPSHADOW
        .IF rax == MUICS_WINNODROPSHADOW
            Invoke _MUI_ApplyMUIStyleToDialog, hParent, FALSE
        .ELSE
            Invoke _MUI_ApplyMUIStyleToDialog, hParent, TRUE
        .ENDIF
    .ENDIF
    
    ; Allow caption bar to be clicked and held to move window?
    mov rax, qwStyle
    and rax, MUICS_NOMOVEWINDOW
    .IF rax == MUICS_NOMOVEWINDOW
        Invoke MUISetIntProperty, hWin, @CaptionBarNoMoveWindow, TRUE
    .ELSE
        Invoke MUISetIntProperty, hWin, @CaptionBarNoMoveWindow, FALSE
    .ENDIF
    
    ; Check if to use icons or not?
    mov rax, qwStyle
    and rax, MUICS_USEICONSFORBUTTONS
    .IF rax == MUICS_USEICONSFORBUTTONS  
        Invoke MUISetIntProperty, hWin, @CaptionBarUseIcons, TRUE
    .ELSE
        Invoke MUISetIntProperty, hWin, @CaptionBarUseIcons, FALSE
    .ENDIF
    
    ; Set default initial external property values     
    Invoke MUISetExtProperty, hWin, @CaptionBarTextColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hWin, @CaptionBarBackColor, MUI_RGBCOLOR(27,161,226);MUI_RGBCOLOR(21,133,181)
    Invoke MUISetExtProperty, hWin, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(61,61,61)
    Invoke MUISetExtProperty, hWin, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(87,193,244) 
    Invoke MUISetExtProperty, hWin, @CaptionBarBtnWidth, MUI_SYSBUTTON_WIDTH ;32d
    Invoke MUISetExtProperty, hWin, @CaptionBarBtnHeight, MUI_SYSBUTTON_HEIGHT ;28d
    Invoke MUISetExtProperty, hWin, @CaptionBarDllInstance, 0
    Invoke MUISetExtProperty, hWin, @CaptionBarBackImageOffsetX, 0
    Invoke MUISetExtProperty, hWin, @CaptionBarBackImageOffsetY, 0
    Invoke MUISetExtProperty, hWin, @CaptionBarBtnOffsetX, 0
    Invoke MUISetExtProperty, hWin, @CaptionBarBtnOffsetY, 0
    Invoke MUISetExtProperty, hWin, @CaptionBarWindowBackColor, -1
    Invoke MUISetExtProperty, hWin, @CaptionBarWindowBorderColor, -1
    
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
    Invoke MUISetExtProperty, hWin, @CaptionBarTextFont, hMUICaptionBarFont

    Invoke _MUI_CreateCaptionBarSysButtons, hWin, hParent
    
    ;mov rax, qwStyle
    ;and rax, MUICS_NOMAXBUTTON
    ;.IF rax != MUICS_NOMAXBUTTON
        ; only need to subclass to handle catching restore/maximize - no need if max/res button is not present 
        Invoke SetWindowSubclass, hParent, Addr _MUI_CaptionBarParentSubClassProc, hWin, hWin
    ;.ENDIF

    ; alloc space for capbuttons
    mov rax, SIZEOF DWORD
    mov rbx, MUI_CAPBUTTON_MAX
    mul rbx
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    .IF rax != 0
        Invoke MUISetIntProperty, hWin, @CaptionBarButtonArray, rax
    .ENDIF

    ret

_MUI_CaptionBarInit ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarCleanup - cleanup a few things before control is destroyed
;------------------------------------------------------------------------------
_MUI_CaptionBarCleanup PROC FRAME hWin:QWORD
    LOCAL qwImageType:QWORD
    LOCAL hImage:QWORD

    Invoke MUIGetExtProperty, hWin, @CaptionBarBackImageType
    mov qwImageType, rax

    .IF qwImageType == 0
        ret
    .ENDIF

    Invoke MUIGetExtProperty, hWin, @CaptionBarBackImage
    mov hImage, rax
    .IF rax != 0
        .IF qwImageType != 3
            Invoke DeleteObject, rax
        ;.ELSE
        ;    IFDEF MUI_USEGDIPLUS
        ;    Invoke GdipDisposeImage, eax
        ;    ENDIF
        .ENDIF
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @CaptionBarButtonArray
    .IF rax != 0
        Invoke GlobalFree, rax
    .ENDIF    
    
    ret
_MUI_CaptionBarCleanup ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarPaint - main CaptionBar painting
;------------------------------------------------------------------------------
_MUI_CaptionBarPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL textrect:RECT
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
    LOCAL qwStyle:QWORD
    LOCAL qwBtnHeight:QWORD
    LOCAL qwOffsetY:QWORD
    LOCAL qwOffsetX:QWORD
    LOCAL qwImageWidth:QWORD    
    LOCAL szText[256]:BYTE    

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke GetClientRect, hWin, Addr rect
    Invoke CopyRect, Addr textrect, Addr rect
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
	;mov qwStyle, rax
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax	
	
	Invoke MUIGetIntProperty, hWin, @CaptionBarMouseOver
    mov MouseOver, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarTextColor        ; normal text color
    mov TextColor, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarBackColor        ; normal back color
    mov BackColor, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarTextFont        
    mov hFont, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
    mov qwBtnHeight, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnOffsetY
    .IF rax != 0
        .IF sqword ptr rax < 0
            neg rax
        .ENDIF    
    .ELSE
        mov rax, 0
    .ENDIF
    mov qwOffsetY, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarBackImageOffsetX
    .IF rax != 0
        .IF sqword ptr rax < 0
            neg rax
        .ENDIF    
    .ELSE
        mov rax, 0
    .ENDIF
    mov qwOffsetX, rax

    ;----------------------------------------------------------
    ; Fill background
    ;----------------------------------------------------------	
    Invoke _MUI_CaptionBarPaintBackground, hWin, hdcMem, Addr rect

    ;----------------------------------------------------------
    ; Image (if any)
    ;----------------------------------------------------------
    Invoke _MUI_CaptionBarPaintImage, hWin, hdc, hdcMem, Addr rect
    mov qwImageWidth, rax

    ;----------------------------------------------------------
    ; Draw Text
    ;----------------------------------------------------------
    Invoke SetBkMode, hdcMem, OPAQUE
    Invoke SetBkColor, hdcMem, dword ptr BackColor
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr BackColor
    ;Invoke FillRect, hdcMem, Addr rect, hBrush
    mov rax, qwStyle
    and rax, MUICS_NOCAPTIONTITLETEXT
    .IF rax != MUICS_NOCAPTIONTITLETEXT
    	
    	Invoke SelectObject, hdcMem, hFont
        mov hOldFont, rax
        Invoke GetWindowText, hWin, Addr szText, sizeof szText
        Invoke SetTextColor, hdcMem, dword ptr TextColor

        mov rax, qwBtnHeight
        add rax, qwOffsetY
        add rax, qwOffsetY
        mov textrect.bottom, eax
        mov rax, qwImageWidth
        add rax, qwOffsetX
        add textrect.left, eax

        mov rax, qwStyle
        and rax, MUICS_CENTER
        .IF rax == MUICS_CENTER
            Invoke DrawText, hdcMem, Addr szText, -1, Addr textrect, DT_SINGLELINE or DT_CENTER or DT_VCENTER
        .ELSE ; MUICS_LEFT
            .IF qwImageWidth != 0
                add textrect.left, MUI_CAPTIONBAR_IMAGETEXT_PADDING
            .ELSE
                add textrect.left, MUI_CAPTIONBAR_TEXTLEFT_PADDING
            .ENDIF
            Invoke DrawText, hdcMem, Addr szText, -1, Addr textrect, DT_SINGLELINE or DT_LEFT or DT_VCENTER
        .ENDIF
    .ENDIF
    
    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    .IF hOldBrush != 0
        Invoke SelectObject, hdcMem, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    .IF hOldFont != 0
        Invoke SelectObject, hdcMem, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem
    
    Invoke EndPaint, hWin, Addr ps

    ret
_MUI_CaptionBarPaint ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarPaintBackground
;------------------------------------------------------------------------------
_MUI_CaptionBarPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    
    Invoke MUIGetExtProperty, hWin, @CaptionBarBackColor
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
_MUI_CaptionBarPaintBackground ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarPaintImage - Returns in rax ImageWidth if image painted, or 0
;------------------------------------------------------------------------------
_MUI_CaptionBarPaintImage PROC FRAME hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD
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
    LOCAL qwOffsetX:QWORD
    LOCAL qwOffsetY:QWORD    
    
    Invoke MUIGetExtProperty, hWin, @CaptionBarBackImageType        
    mov qwImageType, rax ; 0 = none, 1 = bitmap, 2 = icon, 3 = png
    
    .IF qwImageType == 0
        mov rax, 0
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hWin, @CaptionBarBackImage
    mov hImage, rax    
    
    .IF hImage != 0
        Invoke MUIGetExtProperty, hWin, @CaptionBarBackImageOffsetX
        mov qwOffsetX, rax
        Invoke MUIGetExtProperty, hWin, @CaptionBarBackImageOffsetY
        mov qwOffsetY, rax
        Invoke CopyRect, Addr rect, lpRect
        Invoke MUIGetImageSize, hImage, qwImageType, Addr ImageWidth, Addr ImageHeight

        mov pt.x, 1
        mov pt.y, 1
        
        .IF qwOffsetX != 0
            mov rax, qwOffsetX
            .IF sqword ptr rax < 0
                xor rax, rax
                mov eax, pt.x
                sub rax, qwOffsetX
            .ELSE
                xor rax, rax
                mov eax, pt.x
                add rax, qwOffsetX
            .ENDIF
            mov pt.x, eax
        .ENDIF
        .IF qwOffsetY != 0
            mov rax, qwOffsetY
            .IF sqword ptr rax < 0
                xor rax, rax
                mov eax, pt.y
                sub rax, qwOffsetY
            .ELSE
                xor rax, rax
                mov eax, pt.y
                add rax, qwOffsetY
            .ENDIF
            mov pt.y, eax
        .ENDIF
        
        mov rax, qwImageType
        .IF rax == MUICBIT_BMP ; bitmap
            
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
            
        .ELSEIF rax == MUICBIT_ICO ; icon
            Invoke DrawIconEx, hdcDest, pt.x, pt.y, hImage, 0, 0, 0, 0, DI_NORMAL
        
;        .ELSEIF rax == MUICBIT_PNG ; png
;            IFDEF MUI_USEGDIPLUS
;
;            Invoke GdipCreateFromHDC, hdcDest, Addr pGraphics
;            
;            Invoke GdipCreateBitmapFromGraphics, ImageWidth, ImageHeight, pGraphics, Addr pBitmap
;            Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer            
;            Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
;            Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, ImageWidth, ImageHeight
;            .IF pBitmap != NULL
;                Invoke GdipDisposeImage, pBitmap
;            .ENDIF
;            .IF pGraphicsBuffer != NULL
;                Invoke GdipDeleteGraphics, pGraphicsBuffer
;            .ENDIF
;            .IF pGraphics != NULL
;                Invoke GdipDeleteGraphics, pGraphics
;            .ENDIF
;            ENDIF
        .ELSE
            mov rax, 0
            ret
        .ENDIF
        mov rax, ImageWidth ; success returns imagewidth in eax
        ret
        
    .ENDIF     
    mov rax, 0
    ret
_MUI_CaptionBarPaintImage ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CreateCaptionBarSysButtons - create all specified system buttons
;------------------------------------------------------------------------------
_MUI_CreateCaptionBarSysButtons PROC FRAME hWin:QWORD, hCaptionBarParent:QWORD
    LOCAL wp:WINDOWPLACEMENT
    LOCAL qwClientWidth:QWORD
    LOCAL qwLeftOffset:QWORD
    LOCAL qwTopOffset:QWORD    
    LOCAL rect:RECT
    LOCAL xpos:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    LOCAL qwSysButtonWidth:QWORD
    LOCAL qwSysButtonHeight:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwUseIcons:QWORD

    Invoke GetWindowRect, hWin, Addr rect
    mov qwTopOffset, 0
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnWidth
    mov qwSysButtonWidth, rax
    mov qwLeftOffset, 0 ;32d ; start with width of first button
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
    mov qwSysButtonHeight, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnOffsetX
    .IF rax != 0
        add qwLeftOffset, rax
    .ENDIF
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnOffsetY
    .IF rax != 0
        add qwTopOffset, rax
    .ENDIF
    Invoke MUIGetIntProperty, hWin, @CaptionBarUseIcons
    mov qwUseIcons, rax
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    mov qwClientWidth, rax    
    
    mov rax, qwStyle
    and rax, MUICS_NOCLOSEBUTTON
    .IF rax != MUICS_NOCLOSEBUTTON
        ; create close button
        mov rax, qwClientWidth
        sub rax, qwSysButtonWidth ;qwLeftOffset
        Invoke _MUI_CreateSysButton, hWin, Addr szMUISysCloseButton, rax, qwTopOffset, qwSysButtonWidth, qwSysButtonHeight, MUI_SYSBUTTON_CLS_ID ; 32d, 24d, 1  
        mov hSysButtonClose, rax
        ;PrintQWORD rax
        ;PrintText 'CLOSEBUTTON'
        
        ; check if red button style is supplied, if so we override colors for this button
        mov rax, qwStyle
        and rax, MUICS_REDCLOSEBUTTON
        .IF rax == MUICS_REDCLOSEBUTTON
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextRollColor, MUI_RGBCOLOR(255,255,255)
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackRollColor, MUI_RGBCOLOR(166,26,32)
        .ENDIF
        
        .IF qwUseIcons == TRUE
            Invoke MUISetIntProperty, hSysButtonClose, @SysButtonUseIcons, TRUE
        .ELSE
            Invoke MUISetIntProperty, hSysButtonClose, @SysButtonUseIcons, FALSE
        .ENDIF
        mov rax, qwSysButtonWidth
        add rax, MUI_SYSBUTTONS_SPACING
        add qwLeftOffset, rax ;32d
    .ELSE
        ;PrintText 'NO CLOSEBUTTON'
        mov hSysButtonClose, 0
    .ENDIF    
    
    mov rax, qwStyle
    and rax, MUICS_NOMAXBUTTON
    .IF rax != MUICS_NOMAXBUTTON
        ; create max and restore buttons
        mov rax, qwClientWidth
        sub rax, qwSysButtonWidth
        sub rax, qwLeftOffset
        mov xpos, rax
        Invoke _MUI_CreateSysButton, hWin, Addr szMUISysMaxButton, xpos, qwTopOffset, qwSysButtonWidth, qwSysButtonHeight, MUI_SYSBUTTON_MAX_ID ;32d, 24d, 2
        mov hSysButtonMax, rax
        ;PrintText 'MAXBUTTON'
        ;PrintQWORD hSysButtonMax
        Invoke _MUI_CreateSysButton, hWin, Addr szMUISysResButton, xpos, qwTopOffset, qwSysButtonWidth, qwSysButtonHeight, MUI_SYSBUTTON_RES_ID ;32d, 24d, 3
        mov hSysButtonRes, rax
        ;PrintQWORD rax 
        ;PrintText 'RESBUTTON'
               
        mov rax, qwSysButtonWidth
        add rax, MUI_SYSBUTTONS_SPACING
        add qwLeftOffset, rax ;32d
        ; hide max/res button depending on current window placement
        Invoke GetWindowPlacement, hCaptionBarParent, Addr wp
        .IF wp.showCmd == SW_SHOWNORMAL
            Invoke ShowWindow, hSysButtonRes, SW_HIDE
        .ELSE
            Invoke ShowWindow, hSysButtonMax, SW_HIDE
        .ENDIF
        
        .IF qwUseIcons == TRUE
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
    
    mov rax, qwStyle
    and rax, MUICS_NOMINBUTTON
    .IF rax != MUICS_NOMINBUTTON
        ; create min button
        mov rax, qwClientWidth
        sub rax, qwSysButtonWidth
        sub rax, qwLeftOffset
        Invoke _MUI_CreateSysButton, hWin, Addr szMUISysMinButton, rax, qwTopOffset, qwSysButtonWidth, qwSysButtonHeight, MUI_SYSBUTTON_MIN_ID ;32d, 24d, 4
        mov hSysButtonMin, rax
        mov rax, qwSysButtonWidth
        add rax, MUI_SYSBUTTONS_SPACING
        add qwLeftOffset, rax ;32d
        
        .IF qwUseIcons == TRUE
            Invoke MUISetIntProperty, hSysButtonMin, @SysButtonUseIcons, TRUE
        .ELSE
            Invoke MUISetIntProperty, hSysButtonMin, @SysButtonUseIcons, FALSE
        .ENDIF        
        
    .ELSE
        ;PrintText 'NO MINBUTTON'
        mov hSysButtonMin, 0
    .ENDIF

    Invoke MUISetIntProperty, hWin, @CaptionBarButtonsLeftOffset, qwLeftOffset

    ; save handles to child system buttons in our internal properties of CaptionBar
    Invoke MUISetIntProperty, hWin, @CaptionBar_hSysButtonClose, hSysButtonClose
    Invoke MUISetIntProperty, hWin, @CaptionBar_hSysButtonMax, hSysButtonMax
    Invoke MUISetIntProperty, hWin, @CaptionBar_hSysButtonRes, hSysButtonRes
    Invoke MUISetIntProperty, hWin, @CaptionBar_hSysButtonMin, hSysButtonMin
    xor rax, rax
    ret

_MUI_CreateCaptionBarSysButtons ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarReposition - Reposition window and child system buttons after main
; window resizes - called via SendMessage, hControl, WM_SIZE, 0, 0
;------------------------------------------------------------------------------
_MUI_CaptionBarReposition PROC FRAME hWin:QWORD
    LOCAL wp:WINDOWPLACEMENT
    LOCAL hDefer:QWORD
    LOCAL qwClientWidth:QWORD
    LOCAL qwClientHeight:QWORD
    LOCAL TotalItems:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    LOCAL qwCaptionHeight:QWORD
    LOCAL qwLeftOffset:QWORD
    LOCAL qwTopOffset:QWORD
    LOCAL qwSysButtonWidth:QWORD
    LOCAL qwSysButtonHeight:QWORD    
    LOCAL hParent:QWORD
    LOCAL rect:RECT
    LOCAL qwStyle:QWORD
    LOCAL bBorder:QWORD    

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax

    Invoke GetParent, hWin
    mov hParent, rax
    
    mov qwTopOffset, 0
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnWidth
    mov qwSysButtonWidth, rax
    mov qwLeftOffset, 0 ;32d
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
    mov qwSysButtonHeight, rax
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnOffsetX
    .IF rax != 0
        .IF sqword ptr rax < 0
            neg rax
        .ENDIF
        add qwLeftOffset, rax
    .ENDIF
    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnOffsetY
    .IF rax != 0
        .IF sqword ptr rax < 0
            neg rax
        .ENDIF    
        add qwTopOffset, rax
    .ENDIF    

    Invoke GetClientRect, hWin, Addr rect
    mov eax, rect.bottom
    mov qwCaptionHeight, rax
    .IF sqword ptr rax < 6
        mov qwCaptionHeight, MUI_DEFAULT_CAPTION_HEIGHT
    .ENDIF
    Invoke GetWindowPlacement, hParent, Addr wp
    
    mov rax, qwStyle
    and rax, MUICS_WINNOMUISTYLE
    .IF rax == MUICS_WINNOMUISTYLE
        Invoke GetClientRect, hParent, Addr rect
    .ELSE       
        Invoke GetWindowRect, hParent, Addr rect
    .ENDIF    
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    mov qwClientWidth, rax
    xor rax, rax
    mov eax, rect.bottom
    sub eax, rect.top
    mov qwClientHeight, rax

    mov rax, qwStyle
    and rax, MUICS_NOBORDER
    .IF rax == MUICS_NOBORDER
        mov bBorder, FALSE
    .ELSE
        mov bBorder, TRUE
    .ENDIF
    
    mov TotalItems, 0
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonClose
    mov hSysButtonClose, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonMax
    mov hSysButtonMax, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonRes
    mov hSysButtonRes, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonMin
    mov hSysButtonMin, rax
    .IF rax != NULL
        inc TotalItems
    .ENDIF

    Invoke BeginDeferWindowPos, TotalItems
    mov hDefer, rax
    ; have to move this caption bar first, so that child controls can be moved inside of the new width (cant use defer on this window)
    .IF wp.showCmd == SW_SHOWNORMAL
        .IF bBorder == TRUE
            sub qwClientWidth, 2
            mov rax, 1
        .ELSE
            mov rax, 0
        .ENDIF
        Invoke SetWindowPos, hWin, NULL, rax, rax, qwClientWidth, qwCaptionHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOREDRAW or SWP_NOACTIVATE or SWP_NOSENDCHANGING	 ;SWP_NOCOPYBITS	 or SWP_NOREDRAW
    .ELSE
        .IF bBorder == TRUE
            sub qwClientWidth, 2
            mov rax, 1
        .ELSE
            mov rax, 0
        .ENDIF       
        Invoke SetWindowPos, hWin, NULL, rax, rax, qwClientWidth, qwCaptionHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOREDRAW or SWP_NOACTIVATE or SWP_NOSENDCHANGING	 ;SWP_NOCOPYBITS	 or SWP_NOREDRAW
    .ENDIF 

    .IF hSysButtonClose != NULL
        mov rax, qwClientWidth
        sub rax, qwSysButtonWidth
        sub rax, qwLeftOffset
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonClose, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER  or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	;or SWP_NOCOPYBITS
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonClose, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING
            mov hDefer, rax
        .ENDIF
        mov rax, qwSysButtonWidth
        add rax, MUI_SYSBUTTONS_SPACING
        add qwLeftOffset, rax ;32d
    .ENDIF

    .IF hSysButtonMax != NULL && hSysButtonRes != NULL
        mov rax, qwClientWidth
        sub rax, qwSysButtonWidth
        sub rax, qwLeftOffset
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonMax, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonMax, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER  or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING
            mov hDefer, rax	
        .ENDIF

        mov rax, qwClientWidth
        sub rax, qwSysButtonWidth
        sub rax, qwLeftOffset         
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonRes, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonRes, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING
            mov hDefer, rax	
        .ENDIF
        mov rax, qwSysButtonWidth
        add rax, MUI_SYSBUTTONS_SPACING
        add qwLeftOffset, rax ;32d
    .ENDIF
    
    .IF hSysButtonMin != NULL
        mov rax, qwClientWidth
        sub rax, qwSysButtonWidth
        sub rax, qwLeftOffset
        .IF hDefer == NULL
            Invoke SetWindowPos, hSysButtonMin, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING	
        .ELSE
            Invoke DeferWindowPos, hDefer, hSysButtonMin, NULL, rax, qwTopOffset, 0, 0, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOSIZE ;or SWP_NOSENDCHANGING
            mov hDefer, rax	
        .ENDIF
        mov rax, qwSysButtonWidth
        add rax, MUI_SYSBUTTONS_SPACING
        add qwLeftOffset, rax ;32d           
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @CaptionBarTotalButtons
    .IF rax != 0
        Invoke _MUI_CapButtonsReposition, hWin, hDefer, qwTopOffset, qwLeftOffset, qwClientWidth
    .ELSE
        ;PrintText '_MUI_CaptionBarReposition'
        ;PrintDec qwLeftOffset
        Invoke MUISetIntProperty, hWin, @CaptionBarButtonsLeftOffset, qwLeftOffset
    .ENDIF

    .IF hDefer != NULL
        Invoke EndDeferWindowPos, hDefer
    .ENDIF    

    Invoke InvalidateRect, hWin, NULL, TRUE

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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SysButtonSetPropertyEx - Sets the system button properties from the message
; MUIM_SETPROPERTY set to the parent CaptionBar control 
;------------------------------------------------------------------------------
_MUI_SysButtonSetPropertyEx PROC FRAME hWin:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwSysButtonWidth:QWORD
    LOCAL qwSysButtonHeight:QWORD

    .IF qwProperty == @CaptionBarTextFont
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonClose
    mov hSysButtonClose, rax
    .IF rax != NULL
        mov rax, qwProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor || rax == @CaptionBarBtnBckRollColor || rax == @CaptionBarBtnBorderRollColor
        
            Invoke GetWindowLongPtr, hWin, GWL_STYLE
            mov qwStyle, rax        
            ;Invoke _MUIGetIntProperty, hCaptionBar, @CaptionBarStyle
            and rax, MUICS_REDCLOSEBUTTON
            .IF rax == MUICS_REDCLOSEBUTTON
                Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextRollColor, MUI_RGBCOLOR(255,255,255)
                Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackRollColor, MUI_RGBCOLOR(166,26,32)
                Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBorderRollColor, MUI_RGBCOLOR(166,26,32)
            .ELSE
                mov rax, qwProperty
                .IF rax == @CaptionBarBtnTxtRollColor
                    Invoke MUISetExtProperty, hSysButtonClose, @SysButtonTextRollColor, qwPropertyValue
                .ELSEIF rax == @CaptionBarBtnBckRollColor
                    Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBackRollColor, qwPropertyValue
                .ELSEIF rax == @CaptionBarBtnBorderRollColor
                    Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBorderRollColor, qwPropertyValue                    
                .ENDIF
            .ENDIF
        .ELSEIF rax == @CaptionBarBtnIcoClose
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIco, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoCloseAlt
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonIcoAlt, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
            mov qwSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonClose, NULL, 0, 0, qwPropertyValue, qwSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnWidth
            mov qwSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonClose, NULL, 0, 0, qwSysButtonWidth, qwPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnBorderColor
            Invoke MUISetExtProperty, hSysButtonClose, @SysButtonBorderColor, qwPropertyValue            
        .ENDIF
        Invoke InvalidateRect, hSysButtonClose, NULL, TRUE        
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonMax
    mov hSysButtonMax, rax
    .IF rax != NULL
        mov rax, qwProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonTextColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonBackColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonTextRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBckRollColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonBackRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMax
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIco, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMaxAlt
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonIcoAlt, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
            mov qwSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonMax, NULL, 0, 0, qwPropertyValue, qwSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnWidth
            mov qwSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonMax, NULL, 0, 0, qwSysButtonWidth, qwPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnBorderColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonBorderColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBorderRollColor
            Invoke MUISetExtProperty, hSysButtonMax, @SysButtonBorderRollColor, qwPropertyValue
        .ENDIF
        Invoke InvalidateRect, hSysButtonMax, NULL, TRUE        
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonRes
    mov hSysButtonRes, rax
    .IF rax != NULL
        mov rax, qwProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonTextColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonBackColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonTextRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBckRollColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonBackRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoRes
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIco, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoResAlt
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonIcoAlt, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
            mov qwSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonRes, NULL, 0, 0, qwPropertyValue, qwSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnWidth
            mov qwSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonRes, NULL, 0, 0, qwSysButtonWidth, qwPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnBorderColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonBorderColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBorderRollColor
            Invoke MUISetExtProperty, hSysButtonRes, @SysButtonBorderRollColor, qwPropertyValue              
        .ENDIF
        Invoke InvalidateRect, hSysButtonRes, NULL, TRUE
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @CaptionBar_hSysButtonMin
    mov hSysButtonMin, rax
    .IF rax != NULL
        mov rax, qwProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonTextColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonBackColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonTextRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBckRollColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonBackRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMin
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIco, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnIcoMinAlt
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonIcoAlt, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnWidth
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
            mov qwSysButtonHeight, rax
            Invoke SetWindowPos, hSysButtonMin, NULL, 0, 0, qwPropertyValue, qwSysButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnHeight
            Invoke MUIGetExtProperty, hWin, @CaptionBarBtnWidth
            mov qwSysButtonWidth, rax
            Invoke SetWindowPos, hSysButtonMin, NULL, 0, 0, qwSysButtonWidth, qwPropertyValue, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE
        .ELSEIF rax == @CaptionBarBtnBorderColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonBorderColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBorderRollColor
            Invoke MUISetExtProperty, hSysButtonMin, @SysButtonBorderRollColor, qwPropertyValue                
        .ENDIF
        Invoke InvalidateRect, hSysButtonMin, NULL, TRUE
    .ENDIF
    
    ret
_MUI_SysButtonSetPropertyEx ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CreateSysButton - create a system button (min, max, restore or close button)
;------------------------------------------------------------------------------
_MUI_CreateSysButton PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
    LOCAL hSysButton:QWORD
    
    Invoke RtlZeroMemory, Addr wc, SIZEOF WNDCLASSEX
    Invoke GetModuleHandle, NULL
    mov hinstance, rax
    
    Invoke GetClassInfoEx,hinstance, Addr szMUISysButtonClass, Addr wc 
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
    .ENDIF
    Invoke CreateWindowEx, NULL, Addr szMUISysButtonClass, lpszText, WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL ;WS_EX_TRANSPARENT needed only for click through or WS_CLIPSIBLINGS
    mov hSysButton, rax
    .IF rax != NULL
        Invoke MUISetExtProperty, hSysButton, @SysButtonResourceID, qwResourceID
    .ENDIF
    mov rax, hSysButton
    ret

_MUI_CreateSysButton ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SysButtonWndProc - Main processing window for system buttons: min/max/res/close 
;------------------------------------------------------------------------------
_MUI_SysButtonWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
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
		mov rax, 0
		ret
        
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SysButtonInit - default intial values for properties for SysButton
;------------------------------------------------------------------------------
_MUI_SysButtonInit PROC FRAME hSysButton:QWORD
    LOCAL hParent:QWORD
    
    Invoke GetParent, hSysButton
    mov hParent, rax

    Invoke MUIGetExtProperty, hParent, @CaptionBarTextColor
    Invoke MUISetExtProperty, hSysButton, @SysButtonTextColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnTxtRollColor
    Invoke MUISetExtProperty, hSysButton, @SysButtonTextRollColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBackColor
    Invoke MUISetExtProperty, hSysButton, @SysButtonBackColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnBckRollColor
    Invoke MUISetExtProperty, hSysButton, @SysButtonBackRollColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnBorderColor
    Invoke MUISetExtProperty, hSysButton, @SysButtonBorderColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnBorderRollColor
    Invoke MUISetExtProperty, hSysButton, @SysButtonBorderRollColor, rax

    .IF hMUISysButtonFont == 0
        Invoke CreateFont, -10, 0, 0, 0, FW_THIN, FALSE, FALSE, FALSE, SYMBOL_CHARSET, 0, 0, 0, 0, Addr szMUISysButtonFont
        mov hMUISysButtonFont, rax
    .ENDIF
    
    ; Set internal property for font for system buttons 
    Invoke MUISetIntProperty, hSysButton, @SysButtonFont, hMUISysButtonFont

    ret

_MUI_SysButtonInit ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SysButtonCleanup - cleanup some stuff on control being destroyed
;------------------------------------------------------------------------------
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SysButtonPaint - System button painting
;------------------------------------------------------------------------------
_MUI_SysButtonPaint PROC FRAME USES rbx hSysButton:QWORD
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
    LOCAL BorderColor:QWORD
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
    
    Invoke BeginPaint, hSysButton, Addr ps
    mov hdc, rax
    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke GetClientRect, hSysButton, Addr rect
	Invoke CreateCompatibleDC, hdc
	mov hdcMem, rax
	Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
	mov hbmMem, rax
	Invoke SelectObject, hdcMem, hbmMem
	mov hOldBitmap, rax
	
	;----------------------------------------------------------
	; Get properties
	;----------------------------------------------------------
	Invoke MUIGetIntProperty, hSysButton, @SysButtonMouseOver
    mov MouseOver, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hSysButton, @SysButtonTextColor        ; normal text color
    .ELSE
        Invoke MUIGetExtProperty, hSysButton, @SysButtonTextRollColor    ; mouseover text color
    .ENDIF
    mov TextColor, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hSysButton, @SysButtonBackColor        ; normal back color
    .ELSE
        Invoke MUIGetExtProperty, hSysButton, @SysButtonBackRollColor    ; mouseover back color
    .ENDIF
    mov BackColor, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hSysButton, @SysButtonBorderColor      ; normal border color
    .ELSE
        Invoke MUIGetExtProperty, hSysButton, @SysButtonBorderRollColor  ; mouseover border color
    .ENDIF
    mov BorderColor, rax
        
    Invoke MUIGetIntProperty, hSysButton, @SysButtonFont             ; Marlett font
    mov hFont, rax
    
    Invoke MUIGetIntProperty, hSysButton, @SysButtonUseIcons
    mov UseIcons, rax
    .IF UseIcons == TRUE
        .IF MouseOver == 0
            Invoke MUIGetExtProperty, hSysButton, @SysButtonIco
        .ELSE
            Invoke MUIGetExtProperty, hSysButton, @SysButtonIcoAlt
            .IF rax == NULL ; try to get ordinary icon handle
                Invoke MUIGetExtProperty, hSysButton, @SysButtonIco
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
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr BackColor
    Invoke FillRect, hdcMem, Addr rect, hBrush

    ;----------------------------------------------------------
    ; Draw border
    ;----------------------------------------------------------   
   .IF BorderColor != 0
        .IF hOldBrush != 0
            Invoke SelectObject, hdcMem, hOldBrush
            Invoke DeleteObject, hOldBrush
        .ENDIF        
        Invoke GetStockObject, DC_BRUSH
        mov hBrush, rax
        Invoke SelectObject, hdcMem, rax
        mov hOldBrush, rax
        Invoke SetDCBrushColor, hdcMem, dword ptr BorderColor
        Invoke FrameRect, hdcMem, Addr rect, hBrush
    .ENDIF

    .IF UseIcons == FALSE || hIcon == NULL
    	;----------------------------------------------------------
    	; Draw Text
    	;----------------------------------------------------------
    	Invoke SelectObject, hdcMem, hFont
        mov hOldFont, rax
        ;PrintDec hFont
        ;PrintDec hOldFont
        Invoke GetWindowText, hSysButton, Addr szText, sizeof szText
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
    .IF hOldBrush != 0
        Invoke SelectObject, hdcMem, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    .IF hOldFont != 0
        Invoke SelectObject, hdcMem, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem
    
    Invoke EndPaint, hSysButton, Addr ps
    ret

_MUI_SysButtonPaint ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Applies the ModernUI style to a dialog to make it a captionless, borderless form. 
; User can manually change a form in a resource editor to have the following style
; flags: WS_POPUP or WS_VISIBLE and optionally with DS_CENTER /DS_CENTERMOUSE / 
; WS_CLIPCHILDREN / WS_CLIPSIBLINGS / WS_MINIMIZE / WS_MAXIMIZE
;------------------------------------------------------------------------------
_MUI_ApplyMUIStyleToDialog PROC FRAME hWin:QWORD, qwDropShadow:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwNewStyle:QWORD
    LOCAL qwBasicOldStyle:QWORD
    LOCAL qwClassStyle:QWORD
    
    mov qwNewStyle, WS_POPUP
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    mov qwBasicOldStyle, rax
    
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
    
    mov rax, qwStyle
    and rax, WS_CLIPCHILDREN
    .IF rax == WS_CLIPCHILDREN
        or qwNewStyle, WS_CLIPCHILDREN
    .ENDIF

	mov rax, qwNewStyle
    .IF rax == qwBasicOldStyle ; no major changes, so dont set new style
    .ELSE
        ;PrintText 'Setting New Style'
        Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwNewStyle
        ; Set WS_EX_COMPOSITED as well?
        Invoke SetWindowPos, hWin, NULL, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED or SWP_NOSENDCHANGING
    .ENDIF	
	
	
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

_MUI_ApplyMUIStyleToDialog ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICaptionBarLoadIcons
;------------------------------------------------------------------------------
MUICaptionBarLoadIcons PROC FRAME hControl:QWORD, idResMin:QWORD, idResMinAlt:QWORD, idResMax:QWORD, idResMaxAlt:QWORD, idResRes:QWORD, idResResAlt:QWORD, idResClose:QWORD, idResCloseAlt:QWORD 
    LOCAL hinstance:QWORD
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    
    Invoke MUIGetExtProperty, hControl, @CaptionBarDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax
    
    .IF idResMin != NULL || idResMinAlt != NULL
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonMin
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
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonMax
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
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonRes
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
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonClose
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


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICaptionBarLoadIcons - version for loading from DLL's that have the icon resources
;------------------------------------------------------------------------------
MUICaptionBarLoadIconsDll PROC FRAME hControl:QWORD, hInst:QWORD, idResMin:QWORD, idResMinAlt:QWORD, idResMax:QWORD, idResMaxAlt:QWORD, idResRes:QWORD, idResResAlt:QWORD, idResClose:QWORD, idResCloseAlt:QWORD 
    LOCAL hSysButtonClose:QWORD
    LOCAL hSysButtonMax:QWORD
    LOCAL hSysButtonRes:QWORD
    LOCAL hSysButtonMin:QWORD
    
    .IF idResMin != NULL || idResMinAlt != NULL
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonMin
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
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonMax
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
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonRes
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
        Invoke MUIGetIntProperty, hControl, @CaptionBar_hSysButtonClose
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


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarBackLoadBitmap - if succesful, loads specified bitmap resource into the specified
; external property and returns TRUE in eax, otherwise FALSE.
;------------------------------------------------------------------------------
_MUI_CaptionBarBackLoadBitmap PROC FRAME hWin:QWORD, qwProperty:QWORD, idResBitmap:QWORD
    LOCAL hinstance:QWORD

    .IF idResBitmap == NULL
        mov rax, FALSE
        ret
    .ENDIF

    Invoke MUIGetExtProperty, hWin, @CaptionBarDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax

    Invoke MUIGetExtProperty, hWin, qwProperty
    .IF rax != 0 ; image handle already in use, delete object?
        Invoke DeleteObject, rax
    .ENDIF

    Invoke LoadBitmap, hinstance, idResBitmap
    Invoke MUISetExtProperty, hWin, qwProperty, rax
    mov rax, TRUE

    ret
_MUI_CaptionBarBackLoadBitmap ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CaptionBarBackLoadIcon - if succesful, loads specified icon resource into the specified
; external property and returns TRUE in eax, otherwise FALSE.
;------------------------------------------------------------------------------
_MUI_CaptionBarBackLoadIcon PROC FRAME hWin:QWORD, qwProperty:QWORD, idResIcon:QWORD
    LOCAL hinstance:QWORD

    .IF idResIcon == NULL
        mov rax, FALSE
        ret
    .ENDIF
    Invoke MUIGetExtProperty, hWin, @CaptionBarDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax

    Invoke MUIGetExtProperty, hWin, qwProperty
    .IF rax != 0 ; image icon handle already in use, delete object?
        Invoke DeleteObject, rax
    .ENDIF

    Invoke LoadImage, hinstance, idResIcon, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
    Invoke MUISetExtProperty, hWin, qwProperty, rax

    mov eax, TRUE
    ret
_MUI_CaptionBarBackLoadIcon ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICaptionBarLoadBackImage - Loads images from resource ids and stores the handles in the
; appropriate property.
;------------------------------------------------------------------------------
MUICaptionBarLoadBackImage PROC FRAME hControl:QWORD, qwImageType:QWORD, qwResIDImage:QWORD

    .IF qwImageType == 0
        ret
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @CaptionBarBackImageType, qwImageType

    .IF qwResIDImage != 0
        mov rax, qwImageType
        .IF rax == MUICBIT_BMP ; bitmap
            Invoke _MUI_CaptionBarBackLoadBitmap, hControl, @CaptionBarBackImage, qwResIDImage
        .ELSEIF rax == MUICBIT_ICO ; icon
            Invoke _MUI_CaptionBarBackLoadIcon, hControl, @CaptionBarBackImage, qwResIDImage
        ;.ELSEIF eax == 3 ; png
        ;    IFDEF MUI_USEGDIPLUS
        ;    Invoke _MUI_ButtonLoadPng, hControl, @ButtonImage, qwResIDImage
        ;    ENDIF
        .ENDIF
    .ENDIF

    Invoke InvalidateRect, hControl, NULL, TRUE

    ret
MUICaptionBarLoadBackImage ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CreateCapButton - create a custom capbutton
;------------------------------------------------------------------------------
_MUI_CreateCapButton PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
    LOCAL hCapButton:QWORD

    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    Invoke GetClassInfoEx, hinstance, Addr szMUICapButtonClass, Addr wc 
    .IF eax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea eax, szMUICapButtonClass
        mov wc.lpszClassName, rax
        mov rax, hinstance
        mov wc.hInstance, rax
        lea rax, _MUI_CapButtonWndProc
        mov wc.lpfnWndProc, rax
        Invoke LoadCursor, NULL, IDC_ARROW
        mov wc.hCursor, rax
        mov wc.hIcon, 0
        mov wc.hIconSm, 0
        mov wc.lpszMenuName, NULL
        mov wc.hbrBackground, NULL
        mov wc.style, NULL
        mov wc.cbClsExtra, 0
        mov wc.cbWndExtra, 16
        Invoke RegisterClassEx, addr wc
    .ENDIF   
    Invoke CreateWindowEx, NULL, Addr szMUICapButtonClass, lpszText, WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
    mov hCapButton, rax
    .IF eax != 0
        Invoke MUISetExtProperty, hCapButton, @CapButtonResourceID, qwResourceID
        
    .ENDIF
    ;PrintDec hCapButton
    mov rax, hCapButton
    ret

_MUI_CreateCapButton ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CapButtonWndProc - Main processing window for custom capbuttons 
;------------------------------------------------------------------------------
_MUI_CapButtonWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    
    mov eax,uMsg
    .IF eax == WM_CREATE
        Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_CAPBUTTON_PROPERTIES ; internal properties
        Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_CAPBUTTON_PROPERTIES ; external properties
        Invoke _MUI_CapButtonInit, hWin
        mov rax, 0
        ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_CapButtonCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
        Invoke MUIFreeMemProperties, hWin, 8
        mov rax, 0
        ret          
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_CapButtonPaint, hWin
        mov rax, 0
        ret
   
    .ELSEIF eax == WM_LBUTTONUP
        Invoke GetDlgCtrlID, hWin
        mov rbx,rax
        Invoke GetParent, hWin
        Invoke PostMessage, rax, WM_COMMAND, rbx, hWin
   
   .ELSEIF eax == WM_MOUSEMOVE
        Invoke MUISetIntProperty, hWin, @CapButtonMouseOver, TRUE
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
        Invoke MUISetIntProperty, hWin, @CapButtonMouseOver, FALSE
        Invoke InvalidateRect, hWin, NULL, TRUE
        Invoke LoadCursor, NULL, IDC_ARROW
        Invoke SetCursor, rax

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @CapButtonMouseOver, FALSE
        Invoke InvalidateRect, hWin, NULL, TRUE
        Invoke LoadCursor, NULL, IDC_ARROW
        Invoke SetCursor, rax
        
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_CapButtonWndProc ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CapButtonInit - default intial values for properties for CapButton
;------------------------------------------------------------------------------
_MUI_CapButtonInit PROC FRAME hCapButton:QWORD
    LOCAL hParent:QWORD
    
    Invoke GetParent, hCapButton
    mov hParent, rax
    
    Invoke MUIGetExtProperty, hParent, @CaptionBarTextColor
    Invoke MUISetExtProperty, hCapButton, @CapButtonTextColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnTxtRollColor
    Invoke MUISetExtProperty, hCapButton, @CapButtonTextRollColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBackColor
    Invoke MUISetExtProperty, hCapButton, @CapButtonBackColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnBckRollColor
    Invoke MUISetExtProperty, hCapButton, @CapButtonBackRollColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnBorderColor
    Invoke MUISetExtProperty, hCapButton, @CapButtonBorderColor, rax
    Invoke MUIGetExtProperty, hParent, @CaptionBarBtnBorderRollColor
    Invoke MUISetExtProperty, hCapButton, @CapButtonBorderRollColor, rax

    .IF hMUICapButtonFont == 0
        Invoke CreateFont, -10, 0, 0, 0, FW_THIN, FALSE, FALSE, FALSE, SYMBOL_CHARSET, 0, 0, 0, 0, Addr szMUISysButtonFont
        mov hMUICapButtonFont, rax
    .ENDIF
    
    ; Set internal property for font for system buttons 
    Invoke MUISetIntProperty, hCapButton, @CapButtonFont, hMUICapButtonFont

    ret

_MUI_CapButtonInit ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CapButtonCleanup - cleanup some stuff on control being destroyed
;------------------------------------------------------------------------------
_MUI_CapButtonCleanup PROC FRAME hCapButton:QWORD
    
    Invoke GetParent, hCapButton
    Invoke GetWindowLongPtr, rax, GWL_STYLE
    and rax, MUICS_KEEPICONS
    .IF rax == MUICS_KEEPICONS
        ret
    .ENDIF
  
    Invoke MUIGetExtProperty, hCapButton, @CapButtonIco
    .IF rax != NULL
        Invoke DestroyIcon, rax
    .ENDIF
     Invoke MUIGetExtProperty, hCapButton, @CapButtonIcoAlt
    .IF rax != NULL
        Invoke DestroyIcon, rax
    .ENDIF

    ret

_MUI_CapButtonCleanup ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CapButtonPaint - Custom captionbutton painting
;------------------------------------------------------------------------------
_MUI_CapButtonPaint PROC FRAME USES RBX hCapButton:QWORD
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
    LOCAL BorderColor:QWORD
    LOCAL UseIcons:QWORD
    LOCAL hIcon:QWORD
    LOCAL nIcoWidth:QWORD
    LOCAL nIcoHeight:QWORD
    LOCAL nTextLength:QWORD
    LOCAL szText[MUI_CAPBUTTON_TEXT_MAX]:BYTE

    ; null some vars
    mov hFont, 0
    mov hOldFont, 0
    mov hBrush, 0
    mov hOldBrush, 0
    mov hIcon, 0
    mov nIcoWidth, 0
    mov nIcoHeight, 0

    Invoke BeginPaint, hCapButton, Addr ps
    mov hdc, rax
    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke GetClientRect, hCapButton, Addr rect
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
    mov hbmMem, rax
    Invoke SelectObject, hdcMem, hbmMem
    mov hOldBitmap, rax

    ;----------------------------------------------------------
    ; Get properties
    ;----------------------------------------------------------
    Invoke MUIGetIntProperty, hCapButton, @CapButtonMouseOver
    mov MouseOver, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hCapButton, @CapButtonTextColor        ; normal text color
    .ELSE
        Invoke MUIGetExtProperty, hCapButton, @CapButtonTextRollColor    ; mouseover text color
    .ENDIF
    mov TextColor, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hCapButton, @CapButtonBackColor        ; normal back color
    .ELSE
        Invoke MUIGetExtProperty, hCapButton, @CapButtonBackRollColor    ; mouseover back color
    .ENDIF
    mov BackColor, rax
    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hCapButton, @CapButtonBorderColor      ; normal border color
    .ELSE
        Invoke MUIGetExtProperty, hCapButton, @CapButtonBorderRollColor  ; mouseover border color
    .ENDIF
    mov BorderColor, rax
    
    Invoke MUIGetIntProperty, hCapButton, @CapButtonFont
    mov hFont, rax

    .IF MouseOver == 0
        Invoke MUIGetExtProperty, hCapButton, @CapButtonIco
    .ELSE
        Invoke MUIGetExtProperty, hCapButton, @CapButtonIcoAlt
        .IF rax == NULL ; try to get ordinary icon handle
            Invoke MUIGetExtProperty, hCapButton, @CapButtonIco
        .ENDIF
    .ENDIF
    mov hIcon, rax

    ;----------------------------------------------------------
    ; Fill background
    ;----------------------------------------------------------    
    Invoke SetBkMode, hdcMem, OPAQUE
    Invoke SetBkColor, hdcMem, dword ptr BackColor
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr BackColor
    Invoke FillRect, hdcMem, Addr rect, hBrush

    ;----------------------------------------------------------
    ; Draw border
    ;----------------------------------------------------------   
   .IF BorderColor != 0
        .IF hOldBrush != 0
            Invoke SelectObject, hdcMem, hOldBrush
            Invoke DeleteObject, hOldBrush
        .ENDIF        
        Invoke GetStockObject, DC_BRUSH
        mov hBrush, rax
        Invoke SelectObject, hdcMem, rax
        mov hOldBrush, rax
        Invoke SetDCBrushColor, hdcMem, dword ptr BorderColor
        Invoke FrameRect, hdcMem, Addr rect, hBrush
    .ENDIF

    Invoke GetWindowText, hCapButton, Addr szText, sizeof szText
    mov nTextLength, rax
    
    ;PrintDec nTextLength
    
    ;----------------------------------------------------------
    ; Draw Icon & Text
    ;----------------------------------------------------------
    .IF hIcon == NULL && nTextLength == 0 ; neither

    .ELSEIF hIcon != NULL && nTextLength != 0 ; both

        Invoke MUIGetImageSize, hIcon, MUIIT_ICO, Addr nIcoWidth, Addr nIcoHeight

        mov rax, MUI_CAPBUTTON_TEXT_PADDING
        mov pt.x, eax
        mov eax, rect.bottom
        shr rax, 1
        mov rbx, nIcoHeight
        shr rbx, 1
        sub rax, rbx
        mov pt.y, eax
        Invoke DrawIconEx, hdcMem, pt.x, pt.y, hIcon, 0, 0, NULL, NULL, DI_NORMAL
    
        Invoke SelectObject, hdcMem, hFont
        mov hOldFont, rax
        Invoke SetTextColor, hdcMem, dword ptr TextColor

        mov rax, nIcoWidth
        add rect.left, eax
        add rect.left, MUI_CAPBUTTON_TEXT_PADDING
        add rect.left, MUI_CAPBUTTON_IMAGETEXT_PADDING
        Invoke DrawText, hdcMem, Addr szText, -1, Addr rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER

        mov rax, nIcoWidth
        sub rect.left, eax
        sub rect.left, MUI_CAPBUTTON_TEXT_PADDING
        sub rect.left, MUI_CAPBUTTON_IMAGETEXT_PADDING

    .ELSEIF hIcon == NULL && nTextLength != 0 ; only text

        Invoke SelectObject, hdcMem, hFont
        mov hOldFont, rax
        Invoke SetTextColor, hdcMem, dword ptr TextColor
        add rect.left, MUI_CAPBUTTON_TEXT_PADDING
        Invoke DrawText, hdcMem, Addr szText, -1, Addr rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER
        sub rect.left, MUI_CAPBUTTON_TEXT_PADDING

    .ELSEIF hIcon != NULL && nTextLength == 0 ; only icon

        Invoke MUIGetImageSize, hIcon, MUIIT_ICO, Addr nIcoWidth, Addr nIcoHeight
        xor rax, rax
        mov eax, rect.right
        shr rax, 1
        mov rbx, nIcoWidth
        shr ebx, 1
        sub rax, rbx
        mov pt.x, eax
        
        xor rax, rax
        mov eax, rect.bottom
        shr rax, 1
        mov rbx, nIcoHeight
        shr rbx, 1
        sub rax, rbx
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
    .IF hOldBrush != 0
        Invoke SelectObject, hdcMem, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    .IF hOldFont != 0
        Invoke SelectObject, hdcMem, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem

    Invoke EndPaint, hCapButton, Addr ps
    ret
_MUI_CapButtonPaint ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Reposition the capbuttons if there is any
;------------------------------------------------------------------------------
_MUI_CapButtonsReposition PROC FRAME USES RBX hWin:QWORD, hDefer:QWORD, qwTopOffset:QWORD, qwLeftOffset:QWORD, qwClientWidth:QWORD
    LOCAL TotalButtons:QWORD
    LOCAL nCurrentButton:QWORD
    LOCAL hCapButton:QWORD
    LOCAL ptrButtonArray:QWORD
    LOCAL ptrButtonEntry:QWORD
    LOCAL qwTotalLeftOffset:QWORD
    LOCAL qwButtonWidth:QWORD
    LOCAL qwButtonHeight:QWORD
    LOCAL xpos:QWORD

    Invoke MUIGetIntProperty, hWin, @CaptionBarTotalButtons
    .IF rax == 0
        ret
    .ENDIF
    mov TotalButtons, rax
    
    Invoke MUIGetIntProperty, hWin, @CaptionBarButtonArray
    .IF rax == 0
        ret
    .ENDIF
    mov ptrButtonArray, rax
    mov ptrButtonEntry, rax

    Invoke MUIGetExtProperty, hWin, @CaptionBarBtnHeight
    mov qwButtonHeight, rax    
    
    mov rax, qwLeftOffset
    add rax, MUI_SYSCAPBUTTON_SPACING
    mov xpos, rax

    mov rax, 0
    mov nCurrentButton, 0
    .WHILE rax < TotalButtons
        mov rbx, ptrButtonEntry
        mov rax, [rbx]
        mov hCapButton, rax

        .IF hCapButton != NULL
            
            Invoke MUIGetIntProperty, hCapButton, @CapButtonWidth
            .IF rax == 0 ; use default if 0, != 0 is for text and icon buttons
                Invoke MUIGetExtProperty, hWin, @CaptionBarBtnWidth
            .ENDIF
            mov qwButtonWidth, rax
        
            mov rax, qwClientWidth
            sub rax, xpos
            sub rax, qwButtonWidth
            
            .IF hDefer == NULL
                Invoke SetWindowPos, hCapButton, NULL, rax, qwTopOffset, qwButtonWidth, qwButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE ;or SWP_NOSIZE ;or SWP_NOSENDCHANGING ;or SWP_NOCOPYBITS
            .ELSE
                Invoke DeferWindowPos, hDefer, hCapButton, NULL, rax, qwTopOffset, qwButtonWidth, qwButtonHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE ;or SWP_NOSIZE ;or SWP_NOSENDCHANGING
                mov hDefer, rax    
            .ENDIF
            mov rax, qwButtonWidth
            add rax, MUI_CAPBUTTONS_SPACING
            add xpos, rax ;32d
        .ENDIF            

        add ptrButtonEntry, SIZEOF QWORD
        inc nCurrentButton
        mov rax, nCurrentButton
    .ENDW

    Invoke MUISetIntProperty, hWin, @CaptionBarButtonsLeftOffset, xpos
    
    ret

_MUI_CapButtonsReposition ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_CapButtonSetPropertyEx - set capbtn props when captionbar props set
;------------------------------------------------------------------------------
_MUI_CapButtonSetPropertyEx PROC FRAME USES RBX hWin:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    LOCAL TotalButtons:QWORD
    LOCAL nCurrentButton:QWORD
    LOCAL hCapButton:QWORD
    LOCAL ptrButtonArray:QWORD
    LOCAL ptrButtonEntry:QWORD

    .IF qwProperty == @CaptionBarTextFont
        ret
    .ENDIF
    
    mov rax, qwProperty ; only interested in certain properties to forward on
    .IF rax != @CaptionBarTextColor || rax != @CaptionBarBtnTxtRollColor || rax != @CaptionBarBackColor || rax != @CaptionBarBtnBckRollColor || rax != @CaptionBarBtnBorderColor || rax != @CaptionBarBtnBorderRollColor
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @CaptionBarTotalButtons
    .IF rax == 0
        ret
    .ENDIF
    mov TotalButtons, rax    
    
    Invoke MUIGetIntProperty, hWin, @CaptionBarButtonArray
    .IF rax == 0
        ret
    .ENDIF
    mov ptrButtonArray, rax
    mov ptrButtonEntry, rax
    
    mov rax, 0
    mov nCurrentButton, 0
    .WHILE rax < TotalButtons    
        mov rbx, ptrButtonEntry
        mov rax, [rbx]
        mov hCapButton, rax

        mov rax, qwProperty
        .IF rax == @CaptionBarTextColor
            Invoke MUISetExtProperty, hCapButton, @CapButtonTextColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnTxtRollColor
            Invoke MUISetExtProperty, hCapButton, @CapButtonTextRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBackColor
            Invoke MUISetExtProperty, hCapButton, @CapButtonBackColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBckRollColor
            Invoke MUISetExtProperty, hCapButton, @CapButtonBackRollColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBorderColor
            Invoke MUISetExtProperty, hCapButton, @CapButtonBorderColor, qwPropertyValue
        .ELSEIF rax == @CaptionBarBtnBorderRollColor
            Invoke MUISetExtProperty, hCapButton, @CapButtonBorderRollColor, qwPropertyValue
        .ENDIF
        
        add ptrButtonEntry, SIZEOF QWORD
        inc nCurrentButton
        mov rax, nCurrentButton
    .ENDW
    ret
_MUI_CapButtonSetPropertyEx ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUICaptionBarAddButton - add custom button to caption bar
;------------------------------------------------------------------------------
MUICaptionBarAddButton PROC FRAME USES RBX hControl:QWORD, lpszButtonText:QWORD, qwResourceID:QWORD, qwResIDImage:QWORD, qwResIDImageAlt:QWORD
    LOCAL hinstance:QWORD
    LOCAL hCustomButton:QWORD
    LOCAL qwClientWidth:QWORD
    LOCAL qwButtonWidth:QWORD
    LOCAL qwButtonHeight:QWORD
    LOCAL qwNoButtons:QWORD
    LOCAL hParent:QWORD
    LOCAL hImage:QWORD
    LOCAL hImageAlt:QWORD
    LOCAL qwTopOffset:QWORD
    LOCAL qwLeftOffset:QWORD
    LOCAL xpos:QWORD
    LOCAL hdc:QWORD
    LOCAL nLenButtonText:QWORD
    LOCAL nIcoWidth:QWORD
    LOCAL hOldFont:QWORD
    LOCAL ptrButtonArray:QWORD
    LOCAL sz:POINT
    LOCAL rect:RECT

    
    .IF (qwResIDImage == 0 && qwResIDImageAlt == 0) || qwResourceID == NULL || hControl == NULL
        mov rax, NULL
        ret
    .ENDIF
    

    Invoke MUIGetExtProperty, hControl, @CaptionBarDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax
    .IF qwResIDImage != NULL
        Invoke LoadImage, hinstance, qwResIDImage, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
    .ELSE
        mov rax, 0
    .ENDIF
    mov hImage, rax
    .IF qwResIDImageAlt != NULL
        Invoke LoadImage, hinstance, qwResIDImageAlt, IMAGE_ICON, 0, 0, 0 ;LR_SHARED
    .ELSE
        .IF hImage != NULL
            mov rax, hImage
        .ELSE
            mov rax, 0
        .ENDIF
    .ENDIF
    mov hImageAlt, rax

    Invoke GetParent, hControl
    mov hParent, rax

    Invoke GetWindowRect, hParent, Addr rect
    mov eax, rect.right
    sub eax, rect.left
    mov qwClientWidth, rax

    ; calc left offset etc
    mov qwTopOffset, 0
    Invoke MUIGetIntProperty, hControl, @CaptionBarButtonsLeftOffset
    add eax, MUI_SYSCAPBUTTON_SPACING
    mov qwLeftOffset, rax

    Invoke MUIGetExtProperty, hControl, @CaptionBarBtnWidth
    mov qwButtonWidth, rax
    Invoke MUIGetExtProperty, hControl, @CaptionBarBtnHeight
    mov qwButtonHeight, rax
    Invoke MUIGetExtProperty, hControl, @CaptionBarBtnOffsetY
    .IF rax != 0
        .IF sqword ptr rax < 0
            neg eax
        .ENDIF    
        add qwTopOffset, rax
    .ENDIF

    
    ; calc width based on text content if text available
    .IF lpszButtonText != NULL 
    
        .IF hMUICapButtonFont == 0
            Invoke CreateFont, -10, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, 0, 0, 0, 0, 0, Addr szMUICapButtonFont
            mov hMUICapButtonFont, rax
        .ENDIF    
    
        ;Invoke szLen, lpszButtonText
        Invoke lstrlen, lpszButtonText
        mov nLenButtonText, rax
        Invoke GetDC, hControl
        mov hdc, rax
        Invoke SelectObject, hdc, hMUICapButtonFont
        mov hOldFont, rax
        Invoke GetTextExtentPoint32, hdc, lpszButtonText, dword ptr nLenButtonText, Addr sz
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
        Invoke ReleaseDC, hControl, hdc

        .IF hImage == NULL && hImageAlt == NULL
            xor rax, rax
            mov eax, sz.x
            add eax, MUI_CAPBUTTON_TEXT_PADDING
            add eax, MUI_CAPBUTTON_TEXT_PADDING
        .ELSE

            Invoke MUIGetImageSize, hImage, MUIIT_ICO, Addr nIcoWidth, 0
            xor rax, rax
            mov eax, sz.x
            add rax, MUI_CAPBUTTON_TEXT_PADDING
            add rax, nIcoWidth
            add rax, MUI_CAPBUTTON_IMAGETEXT_PADDING
            add rax, MUI_CAPBUTTON_TEXT_PADDING
        .ENDIF
        mov qwButtonWidth, rax
    
    .ENDIF
    mov rax, qwClientWidth
    sub rax, qwLeftOffset
    sub rax, qwButtonWidth
    mov xpos, rax
    
    Invoke _MUI_CreateCapButton, hControl, lpszButtonText, xpos, qwTopOffset, qwButtonWidth, qwButtonHeight, qwResourceID
    mov hCustomButton, rax
    .IF rax != 0
        Invoke MUISetExtProperty, hCustomButton, @SysButtonIco, hImage
        Invoke MUISetExtProperty, hCustomButton, @SysButtonIcoAlt, hImageAlt
        
        .IF lpszButtonText == 0
            Invoke MUISetIntProperty, hCustomButton, @CapButtonWidth, 0
        .ELSE
            Invoke MUISetIntProperty, hCustomButton, @CapButtonWidth, qwButtonWidth
        .ENDIF
        

        ; update leftoffset with qwButtonWidth
        mov rax, qwLeftOffset
        add rax, qwButtonWidth
        Invoke MUISetIntProperty, hControl, @CaptionBarButtonsLeftOffset, rax

        Invoke MUIGetIntProperty, hControl, @CaptionBarButtonArray ; something gone wrong if 0
        .IF rax == 0
            mov rax, NULL
            ret
        .ENDIF
        mov ptrButtonArray, rax
        
        Invoke MUIGetIntProperty, hControl, @CaptionBarTotalButtons
        mov qwNoButtons, rax
        inc rax
        
        Invoke MUISetIntProperty, hControl, @CaptionBarTotalButtons, rax
        mov rax, qwNoButtons
        mov rbx, SIZEOF DWORD
        mul rbx
        add rax, ptrButtonArray
        mov rbx, rax
        mov rax, hCustomButton
        mov [rbx], rax

    .ENDIF
    mov rax, hCustomButton
    ret
MUICaptionBarAddButton ENDP



MODERNUI_LIBEND
