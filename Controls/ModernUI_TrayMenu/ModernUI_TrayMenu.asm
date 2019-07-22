;==============================================================================
;
; ModernUI x64 Control - ModernUI_TrayMenu x64
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
includelib shell32.lib

include ModernUI.inc
includelib ModernUI.lib

include masm64.inc
includelib masm64.lib

include ModernUI_TrayMenu.inc


IFNDEF WM_SHELLNOTIFY
WM_SHELLNOTIFY              EQU WM_USER+5 ; Msg Event Sent Back When Tray Event Triggered
ENDIF
IFNDEF NIN_BALLOONSHOW
NIN_BALLOONSHOW             EQU WM_USER+2 ; Returned via WM_SHELLNOTIFY: wParam is resource id of tray icon, lParam is this value 
ENDIF
IFNDEF NIN_BALLOONHIDE
NIN_BALLOONHIDE             EQU WM_USER+3 ; Returned via WM_SHELLNOTIFY: wParam is resource id of tray icon, lParam is this value 
ENDIF
IFNDEF NIN_BALLOONTIMEOUT
NIN_BALLOONTIMEOUT          EQU WM_USER+4 ; Returned via WM_SHELLNOTIFY: wParam is resource id of tray icon, lParam is this value 
ENDIF
IFNDEF NIN_BALLOONUSERCLICK
NIN_BALLOONUSERCLICK        EQU WM_USER+5 ; Returned via WM_SHELLNOTIFY: wParam is resource id of tray icon, lParam is this value 
ENDIF

IFNDEF MUITMITEM
MUITMITEM           STRUCT
    MenuItemID      DQ 0
    MenuItemType    DQ 0
    MenuItemText    DQ 0
    MenuItemState   DQ 0
MUITMITEM           ENDS
ENDIF

IFNDEF NOTIFYICONDATAA
NOTIFYICONDATAA STRUCT
  cbSize            DWORD      ?
  hWnd              DWORD      ?
  uID               DWORD      ?
  uFlags            DWORD      ?
  uCallbackMessage  DWORD      ?
  hIcon             DWORD      ?
  szTip             BYTE       128 dup(?)
  dwState           DWORD      ?
  dwStateMask       DWORD      ?
  szInfo            BYTE       256 dup(?)
  union
      uTimeout      DWORD      ?
      uVersion      DWORD      ?
  ends
  szInfoTitle       BYTE       64 dup(?)
  dwInfoFlags       DWORD      ?
NOTIFYICONDATAA ENDS

NOTIFYICONDATA  equ  <NOTIFYICONDATAA>
ENDIF


;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_ModernUI_TrayMenuWndProc			PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_TrayMenuSetSubclass                PROTO :QWORD
_MUI_TrayMenuWindowSubClass_Proc        PROTO :HWND, :UINT, :WPARAM, :LPARAM, :UINT, :QWORD
_MUI_TrayMenuInit                       PROTO :QWORD
_MUI_TrayMenuCleanup                    PROTO :QWORD
_MUI_TM_AddIconAndTooltip               PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_TM_ShowTrayMenu                    PROTO :QWORD, :QWORD
_MUI_TM_RestoreFromTray                 PROTO :QWORD, :QWORD
_MUI_TM_MinimizeToTray                  PROTO :QWORD, :QWORD
_MUI_TM_IconText                        PROTO :QWORD, :QWORD, :QWORD
_MUI_TM_HideNotification                PROTO :QWORD


;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
IFNDEF MUI_TRAYMENU_PROPERTIES
MUI_TRAYMENU_PROPERTIES                 STRUCT
    qwTrayMenuIcon                      DQ ?
    qwTrayMenuTooltipText               DQ ?
    qwTrayMenuVisible                   DQ ?
    qwTrayMenuType                      DQ ?
    qwTrayMenuHandleMenu                DQ ?
    qwTrayMenuExtraWndHandle            DQ ?
MUI_TRAYMENU_PROPERTIES                 ENDS
ENDIF

; Internal properties
_MUI_TRAYMENU_PROPERTIES                STRUCT
    NID                                 DQ ? ; ptr to NOTIFYICONDATA struct
    qwTrayMenuIconVisible               DQ ?
    qwTrayIconVisible                   DQ ?
_MUI_TRAYMENU_PROPERTIES                ENDS


.CONST
WM_INITSUBCLASS                         EQU WM_USER + 99

TRAYMENU_SUBCLASS_ID                    EQU 0A0B0C0D0h

; Internal properties
@TrayMenuNID                            EQU 0
@TrayMenuIconVisible                    EQU 8
@TrayIconVisible                        EQU 16

; External public properties


.DATA
szMUITrayIconDisplayDC                  DB 'DISPLAY',0
szMUITrayMenuClass                      DB 'ModernUI_TrayMenu',0        ; Class name for creating our ModernUI_TrayMenu control
szMUITrayMenuFont                       DB 'Tahoma',0                   ; Font used for ModernUI_TrayMenu text

icoMUITrayBlankIcon       db 0,0,1,0,1,0,16,16,0,0,1,0,32,0,104,4
    db 0,0,22,0,0,0,40,0,0,0,16,0,0,0,32,0
    db 0,0,1,0,32,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255
    db 172,65,255,255,172,65,255,255,172,65,255,255,172,65,255,255
    db 172,65,255,255,172,65,255,255,172,65,255,255,172,65,255,255
    db 172,65,255,255,172,65,255,255,172,65,255,255,172,65,255,255
    db 172,65,255,255,172,65,255,255,172,65,255,255,172,65



.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for ModernUI_TrayMenu control
;------------------------------------------------------------------------------
MUITrayMenuSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUITrayMenuSetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for ModernUI_TrayMenu control
;------------------------------------------------------------------------------
MUITrayMenuGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUITrayMenuGetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUITrayMenuRegister - Registers the ModernUI_TrayMenu control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_TrayMenu
;------------------------------------------------------------------------------
MUITrayMenuRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUITrayMenuClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUITrayMenuClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_TrayMenuWndProc
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

MUITrayMenuRegister ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIModernUI_TrayMenuCreate - Returns handle in rax of newly created control
;------------------------------------------------------------------------------
MUITrayMenuCreate PROC FRAME hWndParent:QWORD, hTrayMenuIcon:QWORD, lpszTooltip:QWORD, qwMenuType:QWORD, qwMenu:QWORD, qwOptions:QWORD, hWndExtra:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUITrayMenuRegister
	
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN. Non visual prob dont need any of these.
	
    Invoke CreateWindowEx, NULL, Addr szMUITrayMenuClass, lpszTooltip, dword ptr qwOptions, 0, 0, 0, 0, hWndParent, NULL, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
        .IF hTrayMenuIcon != NULL
            Invoke MUISetExtProperty, hControl, @TrayMenuIcon, hTrayMenuIcon
        .ENDIF
        .IF lpszTooltip != NULL
            Invoke MUISetExtProperty, hControl, @TrayMenuTooltipText, lpszTooltip
        .ENDIF
        .IF hWndExtra != NULL
            Invoke MUISetExtProperty, hControl, @TrayMenuExtraWndHandle, hWndExtra
        .ENDIF
        
;        .IF qwMenuType != NULL
;            Invoke MUISetExtProperty, hControl, @TrayMenuType, qwMenuType
;        .ENDIF
;        .IF qwMenu != NULL
;            Invoke MUISetExtProperty, hControl, @TrayMenuHandleMenu, qwMenu
;        .ENDIF

        Invoke _MUI_TM_AddIconAndTooltip, hControl, hWndParent, hTrayMenuIcon, lpszTooltip
        
        .IF qwMenuType != NULL && qwMenu != NULL
            .IF qwMenuType != MUITMT_MENUDEFER && qwMenuType != MUITMT_NOMENUEVER
                Invoke MUITrayMenuAssignMenu, hControl, qwMenuType, qwMenu
            .ENDIF
        .ENDIF
	.ENDIF
	mov rax, hControl
    ret
MUITrayMenuCreate ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TrayMenuWndProc - Main processing window for our control
;------------------------------------------------------------------------------
_MUI_TrayMenuWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    LOCAL wp:WINDOWPLACEMENT
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_TRAYMENU_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_TRAYMENU_PROPERTIES ; external properties
		Invoke _MUI_TrayMenuInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_TrayMenuCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
        mov rax, 0
        ret   		
 
	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
    .ELSEIF eax == MUI_SETPROPERTY
        mov rax, wParam
        .IF rax == @TrayMenuType
            mov rax, lParam ; lParam == @TrayMenuType
            .IF rax != MUITMT_MENUDEFER && rax != MUITMT_NOMENUEVER
                Invoke MUIGetExtProperty, hWin, @TrayMenuHandleMenu
                mov rbx, rax
                .IF rbx != NULL ; ebx = @TrayMenuHandleMenu
                    Invoke MUITrayMenuAssignMenu, hWin, lParam, rbx
                .ENDIF
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, lParam

        .ELSEIF rax == @TrayMenuHandleMenu
            mov rax, lParam ; lParam == @TrayMenuHandleMenu
            .IF rax != NULL
                Invoke MUIGetExtProperty, hWin, @TrayMenuType
                mov rbx, rax ; ebx = @TrayMenuType
                .IF rbx != MUITMT_MENUDEFER && rbx != MUITMT_NOMENUEVER
                    Invoke MUITrayMenuAssignMenu, hWin, rbx, lParam
                .ENDIF
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, lParam
            
        .ELSEIF rax == @TrayMenuIcon
            .IF lParam != NULL
                Invoke MUIGetExtProperty, hWin, @TrayMenuTooltipText
                .IF rax != NULL
                    Invoke MUITrayMenuSetTrayIcon, hWin, lParam
                    ret
                .ENDIF
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, lParam

        .ELSEIF rax == @TrayMenuTooltipText
            .IF lParam != NULL
                Invoke MUIGetExtProperty, hWin, @TrayMenuIcon
                .IF rax != NULL
                    Invoke MUITrayMenuSetTooltipText, hWin, lParam
                    ret
                .ENDIF
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, lParam
        
        .ELSE
            Invoke MUISetExtProperty, hWin, wParam, lParam
        .ENDIF
        ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_TrayMenuWndProc ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TrayMenuSetSubclass - Set sublcass for TrayMenu control
;------------------------------------------------------------------------------
_MUI_TrayMenuSetSubclass PROC FRAME hControl:QWORD
    LOCAL hWndSubClass:QWORD
    LOCAL hParent:QWORD
    LOCAL TrayMenuType:QWORD
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuType
    mov TrayMenuType, rax
    
    .IF TrayMenuType == MUITMT_NOMENUEVER
        ret
    .ENDIF

    Invoke GetWindow, hControl, GW_OWNER
    mov hParent, rax
    
    ;PrintDec hParent
    ;PrintDec hControl
    
    Invoke GetWindowSubclass, hParent, Addr _MUI_TrayMenuWindowSubClass_Proc, TRAYMENU_SUBCLASS_ID, Addr hWndSubClass ;hControl
    .IF rax == TRUE
        ;mov rax, hWndSubClass
        ;.IF rax == hControl
            ;PrintText 'Subclass already installed'
            ; Subclass already installed
            ;Invoke RemoveWindowSubclass, hParent, Addr _MUI_TrayMenuWindowSubClass_Proc, hWin
            ;Invoke SetWindowSubclass, hParent, Addr _MUI_TrayMenuWindowSubClass_Proc, hWin, hWin
        ;.ENDIF
    .ELSE
        ;PrintDec hWndSubClass
        ;PrintText 'installing Subclass'
        Invoke SetWindowSubclass, hParent, Addr _MUI_TrayMenuWindowSubClass_Proc, TRAYMENU_SUBCLASS_ID, hControl ;hControl
        .IF rax == TRUE
            ;PrintText 'True'
        .ENDIF
    .ENDIF    
    ret

_MUI_TrayMenuSetSubclass ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TrayMenuWindowSubClass_Proc - sublcass main window to handle our WM_SHELLNOTIFY
;------------------------------------------------------------------------------
_MUI_TrayMenuWindowSubClass_Proc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM, uIdSubclass:UINT, qwRefData:QWORD
    LOCAL qwStyle:QWORD
    
    mov eax, uMsg
    .IF eax == WM_NCDESTROY
        Invoke RemoveWindowSubclass, hWin, Addr _MUI_TrayMenuWindowSubClass_Proc, uIdSubclass
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam 
        ret
    
    .ELSEIF eax == WM_SYSCOMMAND
        ;PrintText 'WM_SYSCOMMAND'
        .IF wParam == SC_CLOSE
            Invoke GetWindowLongPtr, qwRefData, GWL_STYLE
            mov qwStyle, rax
            ;PrintText 'MinOnClose'
            ;PrintDec qwStyle
            AND rax, MUITMS_MINONCLOSE
            .IF rax == MUITMS_MINONCLOSE ; MinimizeOnClose is ON
                mov rax, qwStyle
                AND rax, MUITMS_HIDEIFMIN
                .IF rax == MUITMS_HIDEIFMIN  
                    Invoke _MUI_TM_MinimizeToTray, hWin, TRUE
                .ELSE
                    Invoke _MUI_TM_MinimizeToTray, hWin, FALSE
                .ENDIF
                xor rax, rax
                ret
            .ENDIF
        .ENDIF
    
    .ELSEIF eax == WM_SIZE
        ;PrintText 'WM_SIZE'
        .IF wParam == SIZE_MINIMIZED
            Invoke GetWindowLongPtr, qwRefData, GWL_STYLE
            mov qwStyle, rax
            ;PrintText 'HideIfMin'
            ;PrintDec qwStyle
            AND rax, MUITMS_HIDEIFMIN
            .IF rax == MUITMS_HIDEIFMIN         
                Invoke _MUI_TM_MinimizeToTray, hWin, TRUE
            .ELSE
                Invoke _MUI_TM_MinimizeToTray, hWin, FALSE
            .ENDIF
        .ENDIF
    
    .ELSEIF eax == WM_SHELLNOTIFY
        .IF lParam == WM_RBUTTONDOWN
            Invoke _MUI_TM_ShowTrayMenu, hWin, qwRefData ;hTM
        .ELSEIF lParam == WM_LBUTTONDOWN
            Invoke _MUI_TM_RestoreFromTray, hWin, qwRefData
        .ELSEIF lParam == WM_RBUTTONDBLCLK
            Invoke _MUI_TM_ShowTrayMenu, hWin, qwRefData ;hTM
        .ELSEIF lParam == WM_LBUTTONDBLCLK
            Invoke _MUI_TM_RestoreFromTray, hWin, qwRefData
        .ENDIF
    .ENDIF
    
    Invoke DefSubclassProc, hWin, uMsg, wParam, lParam         
    ret

_MUI_TrayMenuWindowSubClass_Proc endp


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TrayMenuInit - set initial default values
;------------------------------------------------------------------------------
_MUI_TrayMenuInit PROC FRAME hControl:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    

    Invoke GetParent, hControl
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov qwStyle, rax
    
    Invoke _MUI_TrayMenuSetSubclass, hControl

    ret

_MUI_TrayMenuInit ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TrayMenuCleanup - Frees memory used by control
;------------------------------------------------------------------------------
_MUI_TrayMenuCleanup PROC FRAME hControl:QWORD
    LOCAL NID:QWORD
    
    Invoke MUIGetIntProperty, hControl, @TrayMenuNID
    mov NID, rax
    
    .IF NID != NULL
        Invoke Shell_NotifyIcon, NIM_DELETE, NID ; Remove tray icon
        Invoke GlobalFree, NID
    .ENDIF
    
    ret
_MUI_TrayMenuCleanup ENDP


;==============================================================================
; TRAY MENU Functions
;==============================================================================


MUI_ALIGN
;------------------------------------------------------------------------------
; Assigns a menu to the ModernUI_TrayMenu control, using a popup menu created with 
; CreatePopupMenu or by building a menu from a block of MUITRAYMENUITEM structures
; qwMenuType determines which qwMenu contains
; if qwMenuType == MUITMT_POPUPMENU, qwMenu is a handle to a popup menu
; if qwMenuType == MUITMT_MENUITEMS, qwMenu is pointer to array of structures
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuAssignMenu PROC FRAME USES RBX hControl:QWORD, qwMenuType:QWORD, qwMenu:QWORD
    LOCAL mi:MENUITEMINFO
    LOCAL hTrayMenu:QWORD
    LOCAL CurrentItem:QWORD
    LOCAL CurrentItemOffset:QWORD
    LOCAL pTrayMenuItem:QWORD
    LOCAL MenuItemID:QWORD
    LOCAL MenuItemType:QWORD
    LOCAL MenuItemText:QWORD
    LOCAL MenuItemState:QWORD
    
    IFDEF DEBUG64
        PrintText 'TrayMenuAssignMenu'
    ENDIF

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    ; check menu doesnt exist already, if so destroy it before assigning new one
    Invoke MUIGetExtProperty, hControl, @TrayMenuHandleMenu
    mov hTrayMenu, rax
    .IF hTrayMenu != 0
        Invoke DestroyMenu, hTrayMenu
        Invoke MUISetExtProperty, hControl, @TrayMenuHandleMenu, 0
    .ENDIF
    
    .IF qwMenuType == MUITMT_POPUPMENU
        .IF qwMenu != NULL
            Invoke MUISetExtProperty, hControl, @TrayMenuHandleMenu, qwMenu
            mov rax, TRUE
        .ELSE
            Invoke MUISetExtProperty, hControl, @TrayMenuHandleMenu, 0
            mov rax, FALSE
        .ENDIF
        ret        
    .ENDIF
    
    .IF qwMenuType == MUITMT_MENUITEMS
        .IF qwMenu == NULL
            mov rax, FALSE
            ret
        .ENDIF

        mov rbx, qwMenu
        mov rax, [rbx]
        ;PrintQWORD rax
        .IF rax != 0xfFfFfFfFf0f0f0f0
            mov rax, FALSE
            ret 
        .ENDIF
        
        mov rbx, qwMenu
        add rbx, 8d
        mov pTrayMenuItem, rbx
        
        invoke CreatePopupMenu  ; Create Tray Icon Popup Menu
        mov hTrayMenu, rax ; Save Tray Menu Popup Handle
        
        mov CurrentItem, 1
        
        mov rax, TRUE
        .WHILE rax == TRUE
            
            ; Fetch all items for menu item
            mov rbx, pTrayMenuItem
            mov rax, [rbx].MUITMITEM.MenuItemID
            mov MenuItemID, rax
            .IF MenuItemID == 0xfFfFfFfFf0f0f0f0
                IFDEF DEBUG64
                    PrintText 'Reached End of Menu Definition'
                ENDIF    
                .BREAK
            .ENDIF
            
            mov rax, [rbx].MUITMITEM.MenuItemType
            mov MenuItemType, rax
            mov rax, [rbx].MUITMITEM.MenuItemText
            mov MenuItemText, rax
            mov rax, [rbx].MUITMITEM.MenuItemState
            mov MenuItemState, rax
    
            mov mi.cbSize, SIZEOF MENUITEMINFO
            mov mi.fMask, MIIM_STRING + MIIM_FTYPE + MIIM_ID + MIIM_STATE
            mov mi.hSubMenu, NULL
            mov mi.hbmpChecked, NULL
            mov mi.hbmpUnchecked, NULL
            mov rax, MenuItemID
            mov mi.wID, eax
            ;PrintDec mi.wID
            mov rax, MenuItemType
            mov mi.fType, eax
            mov mi.cch, 0h
    
            ; decide how to create menu item based on the content found
            .IF MenuItemType == MF_STRING
                mov mi.fMask, MIIM_STRING + MIIM_FTYPE + MIIM_ID + MIIM_STATE
                mov rax, MenuItemState
                mov mi.fState, eax
                mov rax, MenuItemText
                mov mi.dwTypeData, rax
                Invoke InsertMenuItem, hTrayMenu, dword ptr MenuItemID, FALSE, Addr mi
                
            .ELSEIF MenuItemType == MF_SEPARATOR
                mov mi.fMask, MIIM_FTYPE + MIIM_STATE
                mov mi.fState, MFS_ENABLED
                mov mi.dwTypeData, 0
                Invoke InsertMenuItem, hTrayMenu, dword ptr CurrentItem, TRUE, Addr mi
                ;PrintDec CurrentItem
            .ENDIF
            
            add pTrayMenuItem, SIZEOF MUITMITEM
            inc CurrentItem
            mov rax, TRUE
        .ENDW
        
        .IF CurrentItem != 0
            IFDEF DEBUG64
                PrintText 'Set Menu Handle'
            ENDIF            
            Invoke MUISetExtProperty, hControl, @TrayMenuHandleMenu, hTrayMenu
        .ELSE
            IFDEF DEBUG64
                PrintText 'No Menu Handle'
            ENDIF          
            Invoke DestroyMenu, hTrayMenu
            Invoke MUISetExtProperty, hControl, @TrayMenuHandleMenu, 0
        .ENDIF
    .ENDIF
    mov rax, TRUE
    ret
MUITrayMenuAssignMenu ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Changes a menu item's state
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuChangeMenuItemState PROC FRAME hControl:QWORD, MenuItemID:QWORD, MenuItemState:QWORD
    LOCAL mi:MENUITEMINFO
    LOCAL hTrayMenu:QWORD

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuHandleMenu
    mov hTrayMenu, rax

    .IF hTrayMenu != NULL       
        mov mi.cbSize, SIZEOF MENUITEMINFO
        mov mi.fMask, MIIM_STATE
        mov rax, MenuItemState
        mov mi.fState, eax
        Invoke SetMenuItemInfo, hTrayMenu, dword ptr MenuItemID, FALSE, Addr mi
        .IF rax != 0
            mov rax, TRUE
        .ELSE
            mov rax, FALSE
        .ENDIF
    .ELSE
        mov rax, FALSE
    .ENDIF  
    ret

MUITrayMenuChangeMenuItemState endp


MUI_ALIGN
;------------------------------------------------------------------------------
; Enables a menu item on the tray menu
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuEnableMenuItem PROC FRAME hControl:QWORD, MenuItemID:QWORD
    LOCAL mi:MENUITEMINFO
    LOCAL hTrayMenu:QWORD

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuHandleMenu
    mov hTrayMenu, rax
    
    .IF hTrayMenu != NULL   
        mov mi.cbSize, SIZEOF MENUITEMINFO
        mov mi.fMask, MIIM_STATE
        mov mi.fState, MFS_ENABLED
        Invoke SetMenuItemInfo, hTrayMenu, dword ptr MenuItemID, FALSE, Addr mi
        .IF rax != 0
            mov rax, TRUE
        .ELSE
            mov rax, FALSE
        .ENDIF
    .ELSE
        mov rax, FALSE
    .ENDIF         
    ret
MUITrayMenuEnableMenuItem ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Disables (greys out) a menu item on the tray menu. 
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuDisableMenuItem PROC FRAME hControl:QWORD, MenuItemID:QWORD
    LOCAL mi:MENUITEMINFO
    LOCAL hTrayMenu:QWORD

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuHandleMenu
    mov hTrayMenu, rax
    .IF hTrayMenu != NULL
        mov mi.cbSize, SIZEOF MENUITEMINFO
        mov mi.fMask, MIIM_STATE
        mov mi.fState, MFS_GRAYED
        Invoke SetMenuItemInfo, hTrayMenu, dword ptr MenuItemID, FALSE, Addr mi
        .IF rax != 0
            mov rax, TRUE
        .ELSE
            mov rax, FALSE
        .ENDIF
    .ELSE
        mov rax, FALSE
    .ENDIF        
    ret
MUITrayMenuDisableMenuItem ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets the icon of the tray menu
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuSetTrayIcon PROC FRAME USES RBX hControl:QWORD, hTrayIcon:QWORD
    LOCAL NID:QWORD
    LOCAL lpszTooltip:QWORD

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @TrayMenuNID
    mov NID, rax
    .IF NID == NULL
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF NOTIFYICONDATA
        .IF rax == NULL
            mov rax, FALSE ; if we cant alloc mem, we return false and control isnt created.
            ret
        .ENDIF
        mov NID, rax
        
        Invoke MUISetIntProperty, hControl, @TrayMenuNID, NID       
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuTooltipText
    mov lpszTooltip, rax
    
    ; Fill NID structure with required info
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax    
    mov rax, WM_SHELLNOTIFY
    mov [rbx].NOTIFYICONDATA.uCallbackMessage, eax
    .IF hTrayIcon == NULL
        Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, FALSE
        Invoke GlobalFree, NID
        Invoke MUISetIntProperty, hControl, @TrayMenuNID, 0
        mov rax, FALSE
        ret
    .ENDIF
    Invoke MUISetExtProperty, hControl, @TrayMenuIcon, hTrayIcon
    
    mov rax, hTrayIcon
    mov [rbx].NOTIFYICONDATA.hIcon, rax
    .IF lpszTooltip != NULL
        mov rax,  NIF_ICON + NIF_MESSAGE + NIF_TIP
        mov [rbx].NOTIFYICONDATA.uFlags, eax    
        mov rax, lpszTooltip
        Invoke szLen, rax
        .IF rax != 0
            mov rbx, NID
            lea rbx, [rbx].NOTIFYICONDATA.szTip
            mov rax, lpszTooltip
            invoke szCopy, rax, rbx
        .ENDIF
    .ELSE
        mov rax,  NIF_ICON + NIF_MESSAGE
        mov [rbx].NOTIFYICONDATA.uFlags, eax    
    .ENDIF
    invoke Shell_NotifyIcon, NIM_MODIFY, NID ; Send msg to show icon in tray
    .IF rax != 0
        Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, TRUE
        mov rax, TRUE
    .ELSE
        Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, FALSE
        Invoke GlobalFree, NID
        Invoke MUISetIntProperty, hControl, @TrayMenuNID, 0
        mov rax, FALSE
    .ENDIF
    ret
MUITrayMenuSetTrayIcon endp


MUI_ALIGN
;------------------------------------------------------------------------------
; Set tooltip of the tray menu
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuSetTooltipText PROC FRAME USES RBX hControl:QWORD, lpszTooltip:QWORD
    LOCAL NID:QWORD
    LOCAL hTrayIcon:QWORD

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @TrayMenuNID
    mov NID, rax
    .IF NID == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuIcon
    mov hTrayIcon, rax
    
    ; Fill NID structure with required info
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax    
    mov rax, WM_SHELLNOTIFY
    mov [rbx].NOTIFYICONDATA.uCallbackMessage, eax
    .IF hTrayIcon == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    mov rax, hTrayIcon
    mov [rbx].NOTIFYICONDATA.hIcon, rax
    .IF lpszTooltip != NULL
        mov rax,  NIF_ICON + NIF_MESSAGE + NIF_TIP
        mov [rbx].NOTIFYICONDATA.uFlags, eax    
        mov rax, lpszTooltip
        Invoke szLen, rax
        .IF rax != 0        
            mov rbx, NID
            lea rbx, [rbx].NOTIFYICONDATA.szTip
            mov rax, lpszTooltip
            invoke szCopy, rax, rbx
        .ENDIF
        Invoke MUISetExtProperty, hControl, @TrayMenuTooltipText, lpszTooltip
    .ELSE
        mov rax,  NIF_ICON + NIF_MESSAGE
        mov [rbx].NOTIFYICONDATA.uFlags, eax    
    .ENDIF
    invoke Shell_NotifyIcon, NIM_MODIFY, NID ; Send msg to show icon in tray
    .IF rax != 0
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    ret

MUITrayMenuSetTooltipText ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Returns in rax icon created and set as the tray menu icon. Use DeleteObject once finished
; using this icon, and before calling this function again (if icon was previously created
; with this function)
; Returns in rax hIcon or NULL
;------------------------------------------------------------------------------
MUITrayMenuSetTrayIconText PROC FRAME hControl:QWORD, lpszText:QWORD, hFontIconText:QWORD, qwTextColorRGB:QWORD
    LOCAL hTrayIcon:QWORD

    .IF hControl == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke _MUI_TM_IconText, lpszText, hFontIconText, qwTextColorRGB
    mov hTrayIcon, rax
    
    .IF hTrayIcon == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke MUITrayMenuSetTrayIcon, hControl, hTrayIcon
    
    mov rax, hTrayIcon
    ret
MUITrayMenuSetTrayIconText ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
;
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuHideTrayIcon PROC FRAME hControl:QWORD
    LOCAL NID:QWORD

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @TrayMenuIconVisible
    .IF rax == TRUE
        Invoke MUIGetIntProperty, hControl, @TrayMenuNID
        mov NID, rax
        .IF NID != NULL
            Invoke Shell_NotifyIcon, NIM_DELETE, NID ; Remove tray icon
            Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, FALSE
            Invoke GlobalFree, NID
            Invoke MUISetIntProperty, hControl, @TrayMenuNID, 0
            mov rax, TRUE
            ret
        .ENDIF
        mov rax, FALSE
    .ELSE
        mov rax, TRUE
    .ENDIF
    ret
MUITrayMenuHideTrayIcon ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
;
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuShowTrayIcon PROC FRAME hControl:QWORD
    LOCAL hParent:QWORD
    LOCAL hTrayIcon:QWORD
    LOCAL lpszTooltip:QWORD

    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hControl, @TrayMenuIconVisible
    .IF rax == FALSE
    
        Invoke MUIGetExtProperty, hControl, @TrayMenuIcon
        mov hTrayIcon, rax
        .IF hTrayIcon == NULL
            mov rax, FALSE
            ret
        .ENDIF
    
        Invoke MUIGetExtProperty, hControl, @TrayMenuTooltipText
        mov lpszTooltip, rax
        .IF lpszTooltip == NULL
            mov rax, FALSE
            ret
        .ENDIF
        
        ;Invoke GetParent, hControl
        ;mov hParent, rax
        Invoke _MUI_TM_AddIconAndTooltip, hControl, hParent, hTrayIcon, lpszTooltip
        
        Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, TRUE
    .ENDIF

    mov eax, TRUE
    ret
MUITrayMenuShowTrayIcon ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Show a balloon style tooltip over tray menu with custom information
;
; MUITMNI_NONE           EQU 0 ; No icon.
; MUITMNI_INFO           EQU 1 ; An information icon.
; MUITMNI_WARNING        EQU 2 ; A warning icon.
; MUITMNI_ERROR          EQU 3 ; An error icon.
; TMUIMNI_USER           EQU 4 ; Windows XP: Use the icon identified in hIcon as the notification balloon's title icon
;
;
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayMenuShowNotification PROC FRAME USES RBX hControl:QWORD, lpszNotificationMessage:QWORD, lpszNotificationTitle:QWORD, qwTimeout:QWORD, qwStyle:QWORD
    LOCAL hTrayIcon:QWORD
    LOCAL NID:QWORD
    
    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuIcon
    mov hTrayIcon, rax
    .IF hTrayIcon == NULL
        mov rax, FALSE
        ret
    .ENDIF  
    
    Invoke MUIGetIntProperty, hControl, @TrayMenuNID
    mov NID, rax
    .IF NID == NULL
        mov rax, FALSE ; if we cant alloc mem, we return false and control isnt created.
        ret
    .ENDIF
    
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax
    mov rax,  NIF_ICON + NIF_MESSAGE + NIF_INFO + NIF_TIP
    mov [rbx].NOTIFYICONDATA.uFlags, eax
    mov rax, WM_SHELLNOTIFY
    mov [rbx].NOTIFYICONDATA.uCallbackMessage, eax
    .IF qwTimeout == NULL
        mov rax, 3000d
    .ELSE
        mov rax, qwTimeout
    .ENDIF
    mov [rbx].NOTIFYICONDATA.uTimeout, eax
    mov rax, NOTIFYICON_VERSION
    mov [rbx].NOTIFYICONDATA.uVersion, eax
    .IF qwStyle == NULL
        mov rax, MUITMNI_INFO
    .ELSE
        mov rax, qwStyle
    .ENDIF
    mov [rbx].NOTIFYICONDATA.dwInfoFlags, eax ;TMNI_INFO ; Balloon Style
    
    mov rax, hTrayIcon
    mov [rbx].NOTIFYICONDATA.hIcon, rax ; Save handle of icon
    
    .IF lpszNotificationMessage != NULL
        Invoke szLen, lpszNotificationMessage
        .IF rax != 0
            mov rbx, NID
            mov rax, lpszNotificationMessage
            lea rbx, [rbx].NOTIFYICONDATA.szInfo
            ;invoke szCopy, eax, ebx       
            Invoke lstrcpyn, rbx, rax, 256d     
        .ENDIF
    .ENDIF
    
    .IF lpszNotificationTitle != NULL
        Invoke szLen, lpszNotificationTitle
        .IF rax != 0
            mov rbx, NID
            mov rax, lpszNotificationTitle
            lea rbx, [rbx].NOTIFYICONDATA.szInfoTitle
            ;invoke szCopy, eax, ebx     
            Invoke lstrcpyn, rbx, rax, 64d       
        .ENDIF        
    .ENDIF

    invoke Shell_NotifyIcon, NIM_MODIFY, NID ; Send msg to show icon in tray
    
    .IF qwTimeout == NULL
        Invoke KillTimer, hControl, hControl
        Invoke SetTimer, hControl, hControl, 3000d, NULL
    .ELSE
        Invoke KillTimer, hControl, hControl
        Invoke SetTimer, hControl, hControl, dword ptr qwTimeout, NULL
    .ENDIF
    
    mov rax, TRUE
    ret

MUITrayMenuShowNotification ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Minimize to tray
;------------------------------------------------------------------------------
MUITrayMenuMinimizeToTray PROC FRAME hControl:QWORD
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    AND rax, MUITMS_HIDEIFMIN
    .IF rax == MUITMS_HIDEIFMIN         
        Invoke _MUI_TM_MinimizeToTray, hControl, TRUE
    .ELSE
        Invoke _MUI_TM_MinimizeToTray, hControl, FALSE
    .ENDIF
    ret
MUITrayMenuMinimizeToTray ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
MUITrayMenuRestoreFromTray PROC FRAME hControl:QWORD
    Invoke _MUI_TM_RestoreFromTray, hControl, hControl
    ret
MUITrayMenuRestoreFromTray ENDP


;==============================================================================
; TRAY ICON Functions
;==============================================================================


MUI_ALIGN
;------------------------------------------------------------------------------
; Creates a tray icon and tooltip text. Standalone without any menu
; Returns in rax hTI (handle of TrayIcon = NID)
;------------------------------------------------------------------------------
MUITrayIconCreate PROC FRAME USES RBX hWndParent:QWORD, qwTrayIconResID:QWORD, hTrayIcon:QWORD, lpszTooltip:QWORD
    LOCAL NID:QWORD

    IFDEF DEBUG32
        PrintText 'TrayIconCreate'
    ENDIF
    mov rax, SIZEOF NOTIFYICONDATA
    add rax, 8d
    
    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, rax ;SIZEOF NOTIFYICONDATA
    .IF rax == NULL
        mov rax, NULL ; if we cant alloc mem, we return null and icon isnt created.
        ret
    .ENDIF
    mov NID, rax
    
    mov rbx, NID
    add rbx, SIZEOF NOTIFYICONDATA
    mov rax, hWndParent
    mov [rbx], rax
    
    ; Fill NID structure with required info
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax
    mov rax, hWndParent
    mov [rbx].NOTIFYICONDATA.hWnd, rax  
    

    mov rax, qwTrayIconResID ; use hControl has unique id for each tryamenu icon ; qwTrayMenuResID
    mov [rbx].NOTIFYICONDATA.uID, eax ; Tray ID
    mov rax,  NIF_ICON + NIF_TIP
    mov [rbx].NOTIFYICONDATA.uFlags, eax
    ;mov eax, WM_SHELLNOTIFY
    ;mov [ebx].NOTIFYICONDATA.uCallbackMessage, eax
    ;.IF hTrayIcon == NULL
    ;    .IF NID != NULL
    ;        Invoke GlobalFree, NID
    ;    .ENDIF    
    ;    mov rax, NULL
    ;    ret
    ;.ENDIF
    
    .IF hTrayIcon == NULL
        Invoke MUICreateIconFromMemory, Addr icoMUITrayBlankIcon, 0
    .ELSE
        mov rax, hTrayIcon
    .ENDIF    
    
    ;PrintText 'hTrayMenuIcon'
    mov rax, hTrayIcon
    mov [rbx].NOTIFYICONDATA.hIcon, rax
    mov rax, lpszTooltip
    .IF rax != NULL
        ;PrintText 'szLen'
        Invoke szLen, rax
        .IF rax != 0
            ;PrintText 'szCopy'
            mov rbx, NID
            lea rbx, [rbx].NOTIFYICONDATA.szTip
            mov rax, lpszTooltip
            invoke szCopy, rax, rbx
        .ENDIF
    .ENDIF
    
    ;PrintText 'Shell_NotifyIcon'
    invoke Shell_NotifyIcon, NIM_ADD, NID ; Send msg to show icon in tray
    .IF rax != 0
        mov rax, NID
    .ELSE
        .IF NID != NULL
            Invoke GlobalFree, NID
        .ENDIF
        mov rax, NULL
    .ENDIF
    ret


MUITrayIconCreate ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; TrayIconDestroy
;------------------------------------------------------------------------------
MUITrayIconDestroy PROC FRAME hTI:QWORD
    LOCAL NID:QWORD
    
    mov rax, hTI
    mov NID, rax
    
    .IF NID != NULL
        Invoke Shell_NotifyIcon, NIM_DELETE, NID ; Remove tray icon
    .ENDIF

    .IF NID != NULL
        Invoke GlobalFree, NID
    .ENDIF    

    mov rax, TRUE
    ret

MUITrayIconDestroy ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; TrayIconSetTrayIcon
;------------------------------------------------------------------------------
MUITrayIconSetTrayIcon PROC FRAME USES RBX hTI:QWORD, hTrayIcon:QWORD
    LOCAL NID:QWORD
    LOCAL hWndParent:QWORD
    
    .IF hTI == NULL
        mov rax, FALSE
        ret
    .ENDIF
    .IF hTrayIcon == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    mov rax, hTI
    mov NID, rax

    mov rbx, NID
    add rbx, SIZEOF NOTIFYICONDATA
    mov rax, [rbx]  
    mov hWndParent, rax

    ; Fill NID structure with required info
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax    
    mov rax, hWndParent
    mov [rbx].NOTIFYICONDATA.hWnd, rax      
    mov rax, hTrayIcon
    mov [rbx].NOTIFYICONDATA.hIcon, rax
    mov rax, NIF_ICON
    mov [rbx].NOTIFYICONDATA.uFlags, eax    
    invoke Shell_NotifyIcon, NIM_MODIFY, NID ; Send msg to show icon in tray
    .IF rax != 0
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    ret

MUITrayIconSetTrayIcon ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; TrayIconSetTooltipText
;------------------------------------------------------------------------------
MUITrayIconSetTooltipText PROC FRAME USES RBX hTI:QWORD, lpszTooltip:QWORD
    LOCAL NID:QWORD
    LOCAL hWndParent:QWORD
    
    .IF hTI == NULL
        mov rax, FALSE
        ret
    .ENDIF
    .IF lpszTooltip == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    mov rax, hTI
    mov NID, rax

    mov rbx, NID
    add rbx, SIZEOF NOTIFYICONDATA
    mov rax, [rbx]  
    mov hWndParent, rax

    ; Fill NID structure with required info
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax    
    mov rax, hWndParent
    mov [rbx].NOTIFYICONDATA.hWnd, rax      
    mov rax, NIF_TIP
    mov [rbx].NOTIFYICONDATA.uFlags, eax    
        
    .IF lpszTooltip != NULL
        mov rax, lpszTooltip
        Invoke szLen, rax
        .IF rax != 0        
            mov rbx, NID
            lea rbx, [rbx].NOTIFYICONDATA.szTip
            mov rax, lpszTooltip
            invoke szCopy, rax, rbx
        .ELSE
            mov rax, FALSE
            ret
        .ENDIF
    .ENDIF
    
    invoke Shell_NotifyIcon, NIM_MODIFY, NID ; Send msg to show icon in tray
    .IF rax != 0
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    
    ret

MUITrayIconSetTooltipText ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Show a balloon style tooltip over tray icon with custom information
;
; MUITMNI_NONE           EQU 0 ; No icon.
; MUITMNI_INFO           EQU 1 ; An information icon.
; MUITMNI_WARNING        EQU 2 ; A warning icon.
; MUITMNI_ERROR          EQU 3 ; An error icon.
; MUITMNI_USER           EQU 4 ; Windows XP: Use the icon identified in hIcon as the notification balloon's title icon
;
;
; Returns in rax TRUE of succesful or FALSE otherwise.
;------------------------------------------------------------------------------
MUITrayIconShowNotification PROC FRAME USES RBX hTI:QWORD, lpszNotificationMessage:QWORD, lpszNotificationTitle:QWORD, qwTimeout:QWORD, qwStyle:QWORD
    LOCAL NID:QWORD
    LOCAL hWndParent:QWORD
    LOCAL lenMessage:QWORD
    
    .IF hTI == NULL
        mov rax, FALSE
        ret
    .ENDIF
    .IF lpszNotificationMessage == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    mov rax, hTI
    mov NID, rax
    
    mov rbx, NID
    add rbx, SIZEOF NOTIFYICONDATA
    mov rax, [rbx]  
    mov hWndParent, rax
    
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax
    mov rax, hWndParent
    mov [rbx].NOTIFYICONDATA.hWnd, rax  
    mov rax, NIF_INFO + NIF_TIP
    mov [rbx].NOTIFYICONDATA.uFlags, eax

    .IF qwTimeout == NULL
        mov rax, 3000d
    .ELSE
        mov rax, qwTimeout
    .ENDIF
    mov [rbx].NOTIFYICONDATA.uTimeout, eax
    mov rax, NOTIFYICON_VERSION
    mov [rbx].NOTIFYICONDATA.uVersion, eax
    .IF qwStyle == NULL
        mov rax, MUITMNI_INFO
    .ELSE
        mov rax, qwStyle
    .ENDIF
    mov [rbx].NOTIFYICONDATA.dwInfoFlags, eax ;TMNI_INFO ; Balloon Style
    
    .IF lpszNotificationMessage != NULL
        Invoke szLen, lpszNotificationMessage
        mov lenMessage, rax
        .IF rax != 0
            mov rbx, NID
            mov rax, lpszNotificationMessage
            lea rbx, [rbx].NOTIFYICONDATA.szInfo
            ;invoke szCopy, eax, ebx          
            Invoke lstrcpyn, rbx, rax, 256d  
            
            .IF lenMessage > 252d
                mov rbx, NID
                lea rax, [ebx].NOTIFYICONDATA.szInfo
                add rax, 252d
                mov byte ptr [rax], "."
                mov byte ptr [rax+1], "."
                mov byte ptr [rax+2], "."
                mov byte ptr [rax+3], 0
            .ENDIF
            
        .ENDIF
    .ENDIF
    
    .IF lpszNotificationTitle != NULL
        Invoke szLen, lpszNotificationTitle
        .IF rax != 0
            mov rbx, NID
            mov rax, lpszNotificationTitle
            lea rbx, [rbx].NOTIFYICONDATA.szInfoTitle
            ;invoke szCopy, eax, ebx     
            Invoke lstrcpyn, rbx, rax, 64d       
        .ENDIF        
    .ENDIF

    invoke Shell_NotifyIcon, NIM_MODIFY, NID ; Send msg to show icon in tray
    
    mov rax, TRUE
    ret

MUITrayIconShowNotification ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Returns in rax icon created and set as the tray menu icon. Use DestroyIcon once finished
; using this icon, and before calling this function again (if icon was previously created
; with this function)
; Returns in rax hIcon or NULL
;------------------------------------------------------------------------------
MUITrayIconSetTrayIconText PROC FRAME hControl:QWORD, lpszText:QWORD, hFontIconText:QWORD, qwTextColorRGB:QWORD
    LOCAL hTrayIcon:QWORD

    .IF hControl == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke _MUI_TM_IconText, lpszText, hFontIconText, qwTextColorRGB
    mov hTrayIcon, rax
    
    .IF hTrayIcon == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke MUITrayIconSetTrayIcon, hControl, hTrayIcon
    
    mov rax, hTrayIcon
    ret
MUITrayIconSetTrayIconText ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUITrayCreateIconText - Create Transparent Text Icon - use DestroyIcon to free
;------------------------------------------------------------------------------
MUITrayCreateIconText PROC FRAME lpszText:QWORD, hFontIconText:QWORD, qwTextColorRGB:QWORD
    Invoke _MUI_TM_IconText, lpszText, hFontIconText, qwTextColorRGB
    ret
MUITrayCreateIconText ENDP

;==============================================================================
; Internal Functions
;==============================================================================


MUI_ALIGN
;------------------------------------------------------------------------------
; Adds tray menu icon and tooltip text. Called from TrayMenuCreate
;------------------------------------------------------------------------------
_MUI_TM_AddIconAndTooltip PROC FRAME USES RBX hControl:QWORD, hWndParent:QWORD, hTrayMenuIcon:QWORD, lpszTooltip:QWORD
    LOCAL NID:QWORD

    IFDEF DEBUG32
        PrintText 'TM_AddIconAndTooltip'
    ENDIF

    Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, SIZEOF NOTIFYICONDATA
    .IF rax == NULL
        mov rax, FALSE ; if we cant alloc mem, we return false and control isnt created.
        ret
    .ENDIF
    mov NID, rax
    
    
    Invoke MUISetIntProperty, hControl, @TrayMenuNID, NID
    
    ;PrintText '_SetNID'
    
    ; Fill NID structure with required info
    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax
    mov rax, hWndParent
    mov [rbx].NOTIFYICONDATA.hWnd, rax
;   .IF qwTrayMenuResID == NULL
;       mov eax, FALSE
;       ret
;   .ENDIF
    ;PrintText 'qwTrayMenuResID'
    mov rax, hControl ; use hControl has unique id for each tryamenu icon ; qwTrayMenuResID
    mov [rbx].NOTIFYICONDATA.uID, eax ; Tray ID
    mov rax,  NIF_ICON + NIF_MESSAGE + NIF_TIP
    mov [rbx].NOTIFYICONDATA.uFlags, eax
    mov rax, WM_SHELLNOTIFY
    mov [rbx].NOTIFYICONDATA.uCallbackMessage, eax
    
;    .IF hTrayMenuIcon == NULL
;        Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, FALSE
;        Invoke GlobalFree, NID
;        Invoke MUISetIntProperty, hControl, @TrayMenuNID, 0
;        mov rax, FALSE
;        ret
;    .ENDIF
    
    .IF hTrayMenuIcon == NULL
        Invoke MUICreateIconFromMemory, Addr icoMUITrayBlankIcon, 0
    .ELSE
        mov rax, hTrayMenuIcon
    .ENDIF    
    
    ;PrintText 'hTrayMenuIcon'
    mov rax, hTrayMenuIcon
    mov [rbx].NOTIFYICONDATA.hIcon, rax
    mov rax, lpszTooltip
    .IF rax != NULL
        ;PrintText 'szLen'
        Invoke szLen, rax
        .IF rax != 0
            ;PrintText 'szCopy'
            mov rbx, NID
            lea rbx, [rbx].NOTIFYICONDATA.szTip
            mov rax, lpszTooltip
            invoke szCopy, rax, rbx
        .ENDIF
    .ENDIF
    ;PrintText 'Shell_NotifyIcon'
    
    invoke Shell_NotifyIcon, NIM_ADD, NID ; Send msg to show icon in tray
    .IF rax != 0
        Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, TRUE
        mov rax, TRUE
    .ELSE
        Invoke MUISetIntProperty, hControl, @TrayMenuIconVisible, FALSE
        Invoke GlobalFree, NID
        Invoke MUISetIntProperty, hControl, @TrayMenuNID, 0
        mov rax, FALSE
    .ENDIF
    ret

_MUI_TM_AddIconAndTooltip ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Shows the main window if minimized when right clicking on tray menu icon
;------------------------------------------------------------------------------
_MUI_TM_ShowTrayMenu PROC FRAME hWin:QWORD, hControl:QWORD
    LOCAL TrayMenuPoint:POINT
    LOCAL hTrayMenu:QWORD

    IFDEF DEBUG32
        PrintText 'TM_ShowTrayMenu'
    ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TrayMenuHandleMenu
    mov hTrayMenu, rax
    
    .IF hTrayMenu == NULL
        ret
    .ENDIF
    
    ;Invoke _MUI_TM_RestoreFromTray, hWin, hControl
    
    Invoke GetCursorPos, Addr TrayMenuPoint ;lpqwTrayMenuPoint
    ; Focus Main Window - ; Fix for shortcut menu not popping up right
    Invoke SetForegroundWindow, hWin
    Invoke TrackPopupMenu, hTrayMenu, TPM_RIGHTALIGN + TPM_LEFTBUTTON + TPM_RIGHTBUTTON, TrayMenuPoint.x, TrayMenuPoint.y, NULL, hWin, NULL
    Invoke PostMessage, hWin, WM_NULL, 0, 0 ; Fix for shortcut menu not popping up right
    ret
_MUI_TM_ShowTrayMenu ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Restore the application from the tray when left clicking on tray menu icon
;------------------------------------------------------------------------------
_MUI_TM_RestoreFromTray PROC FRAME hWin:QWORD, hControl:QWORD
    LOCAL hParent:QWORD
    LOCAL hWndExtra:QWORD
    LOCAL qwStyle:QWORD
    LOCAL wp:WINDOWPLACEMENT
    IFDEF DEBUG32
        PrintText 'TM_RestoreFromTray'
    ENDIF

    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov qwStyle, rax

    Invoke MUIGetExtProperty, hControl, @TrayMenuExtraWndHandle
    .IF eax != NULL
        mov hParent, rax
        mov hWndExtra, rax
    .ELSE
        mov hParent, 0
        mov hWndExtra, 0
    .ENDIF

    ; 20/02/2018 - added to process only hwndextra handle as the main window to process for show/hide only
    mov rax, qwStyle
    and rax, MUITMS_HWNDEXTRA
    .IF rax == MUITMS_HWNDEXTRA
        ;PrintText 'MUITMS_HWNDEXTRA'
        .IF hWndExtra != 0
            ;PrintText 'Show Window'
            Invoke ShowWindow, hWndExtra, SW_SHOW 
        .ENDIF
    .ELSE

        ; 22/07/2016 - added to show parent window first if TM is used with a child dialog (x64dbg plugins Snapshot UpdateChecker as an example)
        .IF hParent != 0
            Invoke GetWindowPlacement, hParent, Addr wp
            mov eax, wp.showCmd
            .IF eax == SW_SHOWMINIMIZED
                invoke ShowWindow, hParent, SW_RESTORE
            
            .ELSEIF eax == SW_HIDE
                Invoke ShowWindow, hParent, SW_SHOW
            
            .ENDIF
            Invoke SetForegroundWindow, hParent ; Focus main window
            Invoke SetWindowPos, hParent, HWND_TOP,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW
        .ENDIF
    
        Invoke IsWindowVisible, hWin
        .IF rax == 0
            Invoke ShowWindow, hWin, SW_SHOW    
            Invoke ShowWindow, hWin, SW_SHOWNORMAL  
            Invoke SetForegroundWindow, hWin ; Focus main window
            ret
        .ENDIF
        Invoke IsIconic, hWin
        .IF rax != 0
            Invoke ShowWindow, hWin, SW_SHOW    
            Invoke ShowWindow, hWin, SW_SHOWNORMAL  
            Invoke SetForegroundWindow, hWin ; Focus main window
        .ENDIF
    .ENDIF   
    ret
_MUI_TM_RestoreFromTray ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Minimize to Tray - Called from WM_SIZE (wParam==SIZE_MINIMIZED) in sublclass
;------------------------------------------------------------------------------
_MUI_TM_MinimizeToTray PROC FRAME hWin:QWORD, qwHideWindow:QWORD
    Invoke ShowWindow, hWin, SW_MINIMIZE
    
    .IF qwHideWindow == TRUE   
        invoke ShowWindow, hWin, SW_HIDE ; Hide main window
    .ENDIF
    ret
_MUI_TM_MinimizeToTray  ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Hides Notification After Timeout value has passed
;------------------------------------------------------------------------------
_MUI_TM_HideNotification PROC FRAME USES RBX hControl:QWORD
    LOCAL NID:QWORD
    
    .IF hControl == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @TrayMenuNID
    mov NID, rax
    .IF NID == NULL
        mov rax, FALSE ; if we cant alloc mem, we return false and control isnt created.
        ret
    .ENDIF

    mov rbx, NID
    mov rax, sizeof NOTIFYICONDATA
    mov [rbx].NOTIFYICONDATA.cbSize, eax
    mov rax,  NIF_INFO
    mov [rbx].NOTIFYICONDATA.uFlags, eax
    lea eax, [rbx].NOTIFYICONDATA.szInfo
    mov byte ptr [rax], 0h
    invoke Shell_NotifyIcon, NIM_MODIFY, NID ; Send msg to show icon in tray
    
    mov rax, TRUE
    ret

_MUI_TM_HideNotification ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Create Transparent Text Icon For Traybar
; Original sourcecode: http://www.techpowerup.com/forums/showthread.php?t=141783
;
; Returns handle to an icon (cursor) in eax, use DeleteObject to free this when you have
; finished with it
;------------------------------------------------------------------------------
_MUI_TM_IconText PROC FRAME lpszText:QWORD, hFontIconText:QWORD, qwTextColorRGB:QWORD
    ;// Creates a DC for use in multithreaded programs (works in single threaded as well)
    LOCAL hdc:HDC
    LOCAL hMemDC:HDC
    LOCAL hdcMem2:HDC
    LOCAL hBitmap:QWORD
    LOCAL hBitmapOld:QWORD    
    LOCAL hbmMask:QWORD
    LOCAL hbmMaskOld:QWORD
    LOCAL hAphaCursor:HICON
    LOCAL cbox:RECT
    LOCAL hbrBkgnd:HBRUSH
    LOCAL lentext:DWORD
    LOCAL ii:ICONINFO
    LOCAL hAlphaCursor:QWORD
    LOCAL hFont:QWORD
    LOCAL hFontOld:QWORD

    Invoke lstrlen, lpszText
    mov lentext, eax
    
    ;// Only safe way I could find to make a DC for multithreading
    Invoke CreateDC, Addr szMUITrayIconDisplayDC, NULL,NULL,NULL
    mov hdc, rax

    ;// Makes it easier to center the text
    mov cbox.left, 0
    mov cbox.top, 0
    mov cbox.right, 16
    mov cbox.bottom, 16
    
    ;// Create the text bitmap.
    Invoke CreateCompatibleBitmap, hdc, cbox.right, cbox.bottom
    mov hBitmap, rax
    Invoke CreateCompatibleDC, hdc
    mov hMemDC, rax
    Invoke SelectObject, hMemDC, hBitmap
    mov hBitmapOld, rax

    ;// Draw the text bitmap
    Invoke CreateSolidBrush, MUI_RGBCOLOR(72,72,72) ;RGBCOLOR(0,0,0) 
    mov hbrBkgnd, rax
    Invoke FillRect, hMemDC, Addr cbox, hbrBkgnd
    Invoke DeleteObject, hbrBkgnd

    .IF hFontIconText == NULL
        Invoke CreateFont, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Addr szMUITrayMenuFont
    .ELSE
        mov rax, hFontIconText
    .ENDIF
    mov hFont, rax
    Invoke SelectObject, hMemDC, hFont
    mov hFontOld, rax 

    Invoke SetBkColor, hMemDC, MUI_RGBCOLOR(72,72,72) ;RGBCOLOR(0,0,0)
    Invoke SetTextColor, hMemDC, dword ptr qwTextColorRGB ;RGBCOLOR(118,198,238) ;RGBCOLOR(255,255,255)
    Invoke DrawText, hMemDC, lpszText, lentext, Addr cbox, DT_SINGLELINE or DT_VCENTER or DT_CENTER
    
    ;// Create monochrome (1 bit) mask bitmap.
    Invoke CreateBitmap, cbox.right, cbox.bottom, 1, 1, NULL
    mov hbmMask, rax
    Invoke CreateCompatibleDC, 0
    mov hdcMem2, rax
    Invoke SelectObject, hdcMem2, hbmMask
    mov hbmMaskOld, rax

    ;// Draw transparent color and create the mask
    Invoke SetBkColor, hMemDC, MUI_RGBCOLOR(72,72,72) ;RGBCOLOR(0,0,0)
    Invoke BitBlt, hdcMem2, 0, 0, cbox.right, cbox.bottom, hMemDC, 0, 0, SRCCOPY
    
    ;// Clean up
    Invoke SelectObject, hdcMem2, hbmMaskOld
    Invoke DeleteObject, hbmMaskOld
    Invoke DeleteDC, hdcMem2
    
    mov ii.fIcon, TRUE
    mov ii.xHotspot, 0
    mov ii.yHotspot, 0
    mov rax, hbmMask
    mov ii.hbmMask, rax
    mov rax, hBitmap
    mov ii.hbmColor, rax

    ;// Create the icon with transparent background
    Invoke CreateIconIndirect, Addr ii
    mov hAlphaCursor, rax

    Invoke SelectObject, hMemDC, hBitmapOld
    Invoke DeleteObject, hBitmapOld
    Invoke DeleteObject, hBitmap
    
    Invoke SelectObject, hMemDC, hFontOld
    Invoke DeleteObject, hFontOld
    .IF hFontIconText == NULL
        Invoke DeleteObject, hFont
    .ENDIF
    
    ;Invoke SelectObject, hdcMem2, hbmMaskOld
    ;Invoke DeleteObject, hbmMaskOld
    Invoke DeleteObject, hbmMask
    
    Invoke DeleteDC, hMemDC
    Invoke DeleteDC, hdc

    mov rax, hAlphaCursor
    ret

_MUI_TM_IconText ENDP












MODERNUI_LIBEND
