;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_SmartPanel x64 v1.0.0.0
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

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_SmartPanel.inc

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
_MUI_SmartPanelWndProc			        PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_SmartPanelInit					    PROTO :QWORD
_MUI_SmartPanelGetPanelHandle           PROTO :QWORD, :QWORD
_MUI_SmartPanelNavNotify                PROTO :QWORD, :QWORD, :QWORD
_MUI_SmartPanelSlidePanels              PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_SmartPanelSlidePanelsLeft          PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_SmartPanelSlidePanelsRight         PROTO :QWORD, :QWORD, :QWORD, :QWORD


;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; External public properties
MUI_SMARTPANEL_PROPERTIES				STRUCT
	qwlDllInstance                      DQ ?
MUI_SMARTPANEL_PROPERTIES				ENDS

; Internal properties
_MUI_SMARTPANEL_PROPERTIES				STRUCT
	qwEnabledState						DQ ?
	qwMouseOver							DQ ?
	qwCurrentPanel                      DQ ?
    qwTotalPanels                       DQ ?
    qwPanelsArray                       DQ ?
    lpqwIsDlgMsgVar                     DQ ?
_MUI_SMARTPANEL_PROPERTIES				ENDS

IFNDEF MUISP_ITEM ; SmartPanel Notification Item
MUISP_ITEM                 	            STRUCT
    iItem               	            DQ 0
    lParam              	            DQ 0
    hPanel                              DQ 0
MUISP_ITEM                 	            ENDS
ENDIF

IFNDEF NM_MUISMARTPANEL ; Notification Message Structure for SmartPanel
NM_MUISMARTPANEL      	                STRUCT
    hdr                 	            NMHDR <>
    itemOld             	            MUISP_ITEM <>
    itemNew             	            MUISP_ITEM <>
NM_MUISMARTPANEL      	                ENDS
ENDIF


.CONST
IFNDEF MUISPN_SELCHANGED
MUISPN_SELCHANGED                       EQU 0 ; Used with WM_NOTIFY. wParam is a NM_MUISMARTPANEL struct
ENDIF

SlideSlow                               EQU 0
SlideNormal                             EQU 1
SlideFast                               EQU 2
SlideVFast                              EQU 3


; Internal properties
@SmartPanelEnabledState				    EQU 0
@SmartPanelMouseOver					EQU 8
@SmartPanelCurrentPanel                 EQU 16
@SmartPanelTotalPanels                  EQU 24
@SmartPanelPanelsArray                  EQU 32
@SmartPanellpqwIsDlgMsgVar              EQU 40
; External public properties


.DATA
szMUISmartPanelClass					DB 'ModernUI_SmartPanel',0 	; Class name for creating our ModernUI_SmartPanel control
SPNM                    	            NM_MUISMARTPANEL <> ; Notification data passed via WM_NOTIFY


.CODE

ALIGN 8

;-------------------------------------------------------------------------------------
; Set property for ModernUI_SmartPanel control
;-------------------------------------------------------------------------------------
MUISmartPanelSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUISmartPanelSetProperty ENDP


;-------------------------------------------------------------------------------------
; Get property for ModernUI_SmartPanel control
;-------------------------------------------------------------------------------------
MUISmartPanelGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUISmartPanelGetProperty ENDP


;-------------------------------------------------------------------------------------
; MUISmartPanelRegister - Registers the ModernUI_SmartPanel control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_SmartPanel
;-------------------------------------------------------------------------------------
MUISmartPanelRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUISmartPanelClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUISmartPanelClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_SmartPanelWndProc
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

MUISmartPanelRegister ENDP


;-------------------------------------------------------------------------------------
; MUISmartPanelCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUISmartPanelCreate PROC FRAME hWndParent:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL qwNewStyle:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUISmartPanelRegister
	
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN. Non visual prob dont need any of these.
	
    mov rax, qwStyle
    mov qwNewStyle, rax
    and rax, DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        or qwNewStyle, DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .ENDIF	
	
    Invoke CreateWindowEx, WS_EX_CONTROLPARENT, Addr szMUISmartPanelClass, NULL, dword ptr qwNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUISmartPanelCreate ENDP


;-------------------------------------------------------------------------------------
; _MUI_SmartPanelWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_SmartPanelWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    LOCAL wp:WINDOWPLACEMENT
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_SMARTPANEL_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_SMARTPANEL_PROPERTIES ; external properties
		Invoke _MUI_SmartPanelInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
		mov eax, 0
		ret		
        
	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
		Invoke MUISetExtProperty, hWin, wParam, lParam
		ret

    .ELSEIF eax == MUISPM_REGISTERPANEL
        Invoke MUISmartPanelRegisterPanel, hWin, wParam, lParam
        ret
		
    .ELSEIF eax == MUISPM_SETCURRENTPANEL
        Invoke MUISmartPanelSetCurrentPanel, hWin, wParam, lParam
        ret
    
    .ELSEIF eax == MUISPM_GETCURRENTPANEL
        Invoke MUIGetIntProperty, hWin, @SmartPanelCurrentPanel
		ret
		
	.ELSEIF eax == MUISPM_SETISDLGMSGVAR ; wParam is addr of variable to use to specify current selected panel
	    Invoke MUISetIntProperty, hWin, @SmartPanellpqwIsDlgMsgVar, wParam
	    ret	
	    
	.ELSEIF eax == MUISPM_GETTOTALPANELS
	    Invoke MUIGetIntProperty, hWin, @SmartPanelTotalPanels
	    ret
	
	.ELSEIF eax == MUISPM_NEXTPANEL
	    Invoke MUISmartPanelNextPanel, hWin, wParam
	    ret
	    
	.ELSEIF eax == MUISPM_PREVPANEL
	    Invoke MUISmartPanelPrevPanel, hWin, wParam
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_SmartPanelWndProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_SmartPanelInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_SmartPanelInit PROC FRAME hControl:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwExStyle:QWORD
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov qwStyle, rax
    and rax, DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, qwStyle
        or rax, DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov qwStyle, rax
        Invoke SetWindowLongPtr, hControl, GWL_STYLE, qwStyle
    .ENDIF
    
    Invoke GetWindowLongPtr, hControl, GWL_EXSTYLE
    mov qwExStyle, rax
    and rax, WS_EX_CONTROLPARENT
    .IF rax != WS_EX_CONTROLPARENT
        mov rax, qwExStyle
        or rax, WS_EX_CONTROLPARENT
        mov qwExStyle, rax
        Invoke SetWindowLongPtr, hControl, GWL_EXSTYLE, qwExStyle
    .ENDIF
    ;PrintDec dwStyle
    
    ; Set default initial external property values     
    Invoke MUISetIntProperty, hControl, @SmartPanelCurrentPanel, -1
    Invoke MUISetIntProperty, hControl, @SmartPanelTotalPanels, 0
    Invoke MUISetIntProperty, hControl, @SmartPanelPanelsArray, 0
    Invoke MUISetIntProperty, hControl, @SmartPanellpqwIsDlgMsgVar, 0
    Invoke MUISetExtProperty, hControl, @SmartPanelDllInstance, 0

    ret

_MUI_SmartPanelInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_SmartPanelCleanup - cleanup a few things before control is destroyed
;-------------------------------------------------------------------------------------
_MUI_SmartPanelCleanup PROC FRAME hControl:QWORD
    LOCAL TotalItems:QWORD

    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    mov TotalItems, rax

    .IF TotalItems != 0
        Invoke MUIGetIntProperty, hControl, @SmartPanelPanelsArray
        ;mov pItemData, eax
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
    .ENDIF
    
    mov rax, 0
    ret

_MUI_SmartPanelCleanup ENDP


;-------------------------------------------------------------------------------------
; MUISmartPanelRegisterPanel - Creates the panel dialog and saves the handle in the
; MUISP_ITEM. Returns handle of dialog in eax
;-------------------------------------------------------------------------------------
MUISmartPanelRegisterPanel PROC FRAME USES RBX hControl:QWORD, idPanelDlg:QWORD, lpqwPanelProc:QWORD
    LOCAL hinstance:QWORD
    LOCAL hPanelDlg:QWORD
    LOCAL rect:RECT
    LOCAL pItemData:QWORD
    LOCAL pItemDataEntry:QWORD
    LOCAL TotalItems:QWORD

    Invoke MUIGetExtProperty, hControl, @SmartPanelDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax

    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    mov TotalItems, rax
    Invoke MUIGetIntProperty, hControl, @SmartPanelPanelsArray
    mov pItemData, rax
    
	Invoke CreateDialogParam, hinstance, idPanelDlg, hControl, lpqwPanelProc, 0
	.IF rax == NULL
	    mov rax, NULL
	    ret
	.ENDIF
	mov hPanelDlg, rax
	
    Invoke MUIAllocStructureMemory, Addr pItemData, TotalItems, SIZEOF MUISP_ITEM
    .IF rax == -1
        mov rax, NULL
        ret
    .ENDIF
    mov pItemDataEntry, rax
    
    mov rbx, pItemDataEntry
    mov rax, hPanelDlg
    mov [rbx].MUISP_ITEM.hPanel, rax
    mov rax, TotalItems
    mov [rbx].MUISP_ITEM.iItem, rax
    ;mov eax, lParam
    ;mov [ebx].MUISP_ITEM.lParam, eax	
	
    inc TotalItems
    Invoke MUISetIntProperty, hControl, @SmartPanelTotalPanels, TotalItems
    Invoke MUISetIntProperty, hControl, @SmartPanelPanelsArray, pItemData
	    
    Invoke SetWindowLongPtr, hPanelDlg, GWL_EXSTYLE, WS_EX_CONTROLPARENT	
    Invoke SetWindowLongPtr, hPanelDlg, GWL_STYLE, WS_CHILD + DS_CONTROL + WS_CLIPCHILDREN;+ WS_TABSTOP ; 40000000d ; WS_CHILD
    Invoke SetWindowPos, hPanelDlg, NULL, 0, 0, 0, 0, SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER + SWP_FRAMECHANGED ; 
    Invoke GetClientRect, hControl, Addr rect
    ;sub rect.right, 2d
    ;sub rect.bottom, 2d
    Invoke SetWindowPos, hPanelDlg, HWND_TOP, 0, 0, rect.right, rect.bottom, SWP_NOZORDER ;+ SWP_NOMOVE

    mov rax, hPanelDlg
    ret

MUISmartPanelRegisterPanel endp


;-------------------------------------------------------------------------------------
; MUISmartPanelGetCurrentPanel
;-------------------------------------------------------------------------------------
MUISmartPanelGetCurrentPanel PROC FRAME hControl:QWORD
    Invoke MUIGetExtProperty, hControl, @SmartPanelCurrentPanel
    ret
MUISmartPanelGetCurrentPanel ENDP


;-------------------------------------------------------------------------------------
; MUISmartPanelSetCurrentPanel - Returns the index of the previously selected panel 
; if successful or - 1 otherwise.
;-------------------------------------------------------------------------------------
MUISmartPanelSetCurrentPanel PROC FRAME USES RBX hControl:QWORD, NewSelection:QWORD, qwNotify:QWORD
    LOCAL OldSelection:QWORD
    LOCAL TotalItems:QWORD
    LOCAL hNewSelection:QWORD
    LOCAL hOldSelection:QWORD
    LOCAL rect:RECT

    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    mov TotalItems, rax
    .IF TotalItems == 0
        mov rax, -1
        ret
    .ENDIF
    
    mov rax, NewSelection
    mov rbx, TotalItems
    dec rbx
    .IF sqword ptr rax < 0 || rax > rbx
        mov rax, -1
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelCurrentPanel
    mov OldSelection, rax
    .IF OldSelection == -1 ; no current item set yet, so select new item regardless
        Invoke _MUI_SmartPanelGetPanelHandle, hControl, NewSelection
        mov hNewSelection, rax
        Invoke GetClientRect, hControl, Addr rect
        ;sub rect.right, 2d
        ;sub rect.bottom, 2d
        Invoke SetWindowPos, hNewSelection, HWND_TOP, 0, 0, rect.right, rect.bottom, SWP_NOZORDER ;+ SWP_NOMOVE		                    
        Invoke ShowWindow, hNewSelection, SW_SHOWDEFAULT
        
        Invoke MUISetIntProperty, hControl, @SmartPanelCurrentPanel, NewSelection

        Invoke MUIGetIntProperty, hControl, @SmartPanellpqwIsDlgMsgVar
        .IF rax != NULL
            mov rbx, hNewSelection
            mov [rax], rbx
        .ENDIF        
        mov rax, NewSelection
        ret
    .ENDIF
    
    mov rax, OldSelection
    mov rbx, NewSelection
    .IF rax != rbx
    
        Invoke _MUI_SmartPanelGetPanelHandle, hControl, OldSelection
        mov hOldSelection, rax

        Invoke _MUI_SmartPanelGetPanelHandle, hControl, NewSelection
        mov hNewSelection, rax
        
        
        ; call slide panels function if specified
        Invoke GetWindowLong, hControl, GWL_STYLE
        ;mov dwStyle, eax
        AND rax, MUISPS_SLIDEPANELS_SLOW + MUISPS_SLIDEPANELS_NORMAL + MUISPS_SLIDEPANELS_FAST + MUISPS_SLIDEPANELS_VFAST
        .IF rax == MUISPS_SLIDEPANELS_SLOW
            Invoke _MUI_SmartPanelSlidePanels, hControl, OldSelection, NewSelection, SlideSlow

        .ELSEIF rax == MUISPS_SLIDEPANELS_NORMAL
            Invoke _MUI_SmartPanelSlidePanels, hControl, OldSelection, NewSelection, SlideNormal
        
        .ELSEIF rax == MUISPS_SLIDEPANELS_FAST
            Invoke _MUI_SmartPanelSlidePanels, hControl, OldSelection, NewSelection, SlideFast
            
        .ELSEIF rax == MUISPS_SLIDEPANELS_VFAST
            Invoke _MUI_SmartPanelSlidePanels, hControl, OldSelection, NewSelection, SlideVFast
            
        .ELSE ; if style is not animation
            .IF hOldSelection != NULL
                Invoke ShowWindow, hOldSelection, SW_HIDE
            .ENDIF        
            .IF hNewSelection != NULL
                ; resize panel if container size has changed since last selection
                Invoke GetClientRect, hControl, Addr rect
                ;sub rect.right, 2d
                ;sub rect.bottom, 2d
                Invoke SetWindowPos, hNewSelection, HWND_TOP, 0, 0, rect.right, rect.bottom, SWP_NOZORDER ;+ SWP_NOMOVE		                    
                
                Invoke ShowWindow, hNewSelection, SW_SHOWDEFAULT
                Invoke SetFocus, hNewSelection
            .ENDIF
        .ENDIF
        
        ; update current panel internally AND externally if user provided a var to hold this.
        Invoke MUISetIntProperty, hControl, @SmartPanelCurrentPanel, NewSelection

        Invoke MUIGetIntProperty, hControl, @SmartPanellpqwIsDlgMsgVar
        .IF rax != NULL
            mov rbx, hNewSelection
            mov [rax], rbx
        .ENDIF
        
        ; Notify if user has specified so
        .IF qwNotify == TRUE
            Invoke _MUI_SmartPanelNavNotify, hControl, OldSelection, NewSelection
        .ENDIF
        
        mov rax, OldSelection    
    .ELSE
        mov rax, -1
    .ENDIF
    ret
MUISmartPanelSetCurrentPanel ENDP


;-------------------------------------------------------------------------------------
; _MUI_SmartPanelNavNotify
;-------------------------------------------------------------------------------------
_MUI_SmartPanelNavNotify PROC FRAME USES RBX hControl:QWORD, OldSelection:QWORD, NewSelection:QWORD
    LOCAL pItemData:QWORD
    LOCAL pOldItemDataEntry:QWORD
    LOCAL pNewItemDataEntry:QWORD
    LOCAL TotalItems:QWORD
    LOCAL hItem:QWORD
    LOCAL ItemIndex:QWORD
    LOCAL hParent:QWORD
    LOCAL idControl:QWORD
    
    Invoke GetParent, hControl
    mov hParent, rax

    mov rax, hControl
    mov SPNM.hdr.hwndFrom, rax
    mov rax, MUISPN_SELCHANGED
    mov SPNM.hdr.code, eax
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelPanelsArray
    mov pItemData, rax
    
    mov rax, OldSelection
    mov rbx, SIZEOF MUISP_ITEM
    mul rbx
    mov rbx, pItemData
    add rax, rbx
    mov pOldItemDataEntry, rax
    
    mov rax, NewSelection
    mov rbx, SIZEOF MUISP_ITEM
    mul rbx
    mov rbx, pItemData
    add rax, rbx
    mov pNewItemDataEntry, rax    
        
    mov rbx, pOldItemDataEntry
    mov rax, [rbx].MUISP_ITEM.iItem
    mov SPNM.itemOld.iItem, rax
    mov rax, [rbx].MUISP_ITEM.lParam
    mov SPNM.itemOld.lParam, rax
    mov rax, [rbx].MUISP_ITEM.hPanel
    mov SPNM.itemNew.hPanel, rax    
    
    mov rbx, pNewItemDataEntry
    mov rax, [rbx].MUISP_ITEM.iItem
    mov SPNM.itemNew.iItem, rax
    mov rax, [rbx].MUISP_ITEM.lParam
    mov SPNM.itemNew.lParam, rax
    mov rax, [rbx].MUISP_ITEM.hPanel
    mov SPNM.itemNew.hPanel, rax
    
    Invoke GetDlgCtrlID, hControl
    mov idControl, rax
    
    Invoke GetParent, hParent
    .IF rax != NULL
        Invoke PostMessage, hParent, WM_NOTIFY, idControl, Addr SPNM
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    ret

_MUI_SmartPanelNavNotify endp


;-------------------------------------------------------------------------------------
; _MUI_SmartPanelSlidePanels - SlideSpeed 0 slow, 1 fast, 2 very fast
;-------------------------------------------------------------------------------------
_MUI_SmartPanelSlidePanels PROC FRAME USES RBX hControl:QWORD, OldSelection:QWORD, NewSelection:QWORD, SlideSpeed:QWORD 
    LOCAL hCurrentPanel:QWORD
    LOCAL hNextPanel:QWORD
    LOCAL nPanel:QWORD
   
    mov rax, NewSelection
    .IF rax < OldSelection ; moving down = left, so slide right till we get to it
        
        mov rax, OldSelection
        mov nPanel, rax
        .WHILE rax > NewSelection
    
            Invoke _MUI_SmartPanelGetPanelHandle, hControl, nPanel
            mov hCurrentPanel, rax
            mov rax, nPanel
            dec rax
            Invoke _MUI_SmartPanelGetPanelHandle, hControl, rax
            mov hNextPanel, rax
            
            Invoke _MUI_SmartPanelSlidePanelsRight, hControl, hCurrentPanel, hNextPanel, SlideSpeed
            dec nPanel
            mov rax, nPanel
        .ENDW
    
    .ELSE ; moving up = right, so slide left till we get to it
        
        mov rax, OldSelection     
        mov nPanel, rax
        .WHILE rax < NewSelection
    
            Invoke _MUI_SmartPanelGetPanelHandle, hControl, nPanel
            mov hCurrentPanel, rax
            mov rax, nPanel
            inc rax
            Invoke _MUI_SmartPanelGetPanelHandle, hControl, rax
            mov hNextPanel, rax
            
            Invoke _MUI_SmartPanelSlidePanelsLeft, hControl, hCurrentPanel, hNextPanel, SlideSpeed
            inc nPanel
            mov rax, nPanel
        .ENDW
        
    .ENDIF
    ret

_MUI_SmartPanelSlidePanels endp


;-------------------------------------------------------------------------------------
; _MUI_SmartPanelSlidePanelsLeft - Slides current and next panel left till we show next panel only
;-------------------------------------------------------------------------------------
_MUI_SmartPanelSlidePanelsLeft PROC FRAME hControl:QWORD, hCurrentPanel:QWORD, hNextPanel:QWORD, SlideSpeed:QWORD
    LOCAL rect:RECT
    LOCAL xposnextpanel:SQWORD
    LOCAL xposcurrentpanel:SQWORD    
    
    IFDEF DEBUG32
    PrintText 'SP_SlidePanelsLeft'
    ENDIF
    Invoke GetClientRect, hControl, Addr rect
    mov eax, rect.right
    mov xposnextpanel, rax
    mov xposcurrentpanel, 1
    Invoke SetWindowPos, hNextPanel, HWND_TOP, xposnextpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOCOPYBITS +SWP_SHOWWINDOW + SWP_NOSENDCHANGING+ SWP_NOACTIVATE ;+SWP_NOCOPYBITS +

    mov rax, xposnextpanel
    .WHILE sqword ptr rax > 0
        Invoke SetWindowPos, hNextPanel, HWND_TOP, xposnextpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER  + SWP_NOSENDCHANGING + SWP_NOACTIVATE;+ SWP_NOMOVE +SWP_NOCOPYBITS
        Invoke SetWindowPos, hCurrentPanel, HWND_TOP, xposcurrentpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER  + SWP_NOSENDCHANGING + SWP_NOACTIVATE;+ SWP_NOMOVE +SWP_NOCOPYBITS
        ;Invoke InvalidateRect, hNextPanel, NULL, TRUE
        
        Invoke UpdateWindow, hNextPanel
        ;Invoke UpdateWindow, hCurrentPanel            
        .IF SlideSpeed == SlideVFast
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
        .ELSEIF SlideSpeed == SlideFast
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
        .ELSEIF SlideSpeed == SlideNormal
            dec xposcurrentpanel
            dec xposnextpanel
            dec xposcurrentpanel
            dec xposnextpanel
        .ELSE
            dec xposcurrentpanel
            dec xposnextpanel
        .ENDIF
        ;dec xposcurrentpanel
        ;dec xposnextpanel
        ;PrintDec xposnextpanel
        mov rax, xposnextpanel
    .ENDW
    
    ;PrintText 'SP_SlidePanelsLeft End'
    
    Invoke ShowWindow, hCurrentPanel, SW_HIDE
    Invoke SetWindowPos, hNextPanel, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOSENDCHANGING + SWP_NOACTIVATE ;+ SWP_NOMOVE  +SWP_NOCOPYBITS
    Invoke ShowWindow, hNextPanel, SW_SHOWDEFAULT
    Invoke SetFocus, hNextPanel    
    
    ret

_MUI_SmartPanelSlidePanelsLeft endp


;-------------------------------------------------------------------------------------
; _MUI_SmartPanelSlidePanelsRight - Slides current and next panel right till we show next panel only
;-------------------------------------------------------------------------------------
_MUI_SmartPanelSlidePanelsRight PROC FRAME hControl:QWORD, hCurrentPanel:QWORD, hNextPanel:QWORD, SlideSpeed:QWORD
    LOCAL rect:RECT
    LOCAL xposnextpanel:SQWORD
    LOCAL xposcurrentpanel:SQWORD
    
    IFDEF DEBUG32
    PrintText 'SP_SlidePanelsRight'
    ENDIF
    Invoke GetClientRect, hControl, Addr rect
    mov rax, 0
    sub eax, rect.right ;sdword ptr sdword ptr 
    mov xposnextpanel, rax ;-570
    mov xposcurrentpanel, 1
    Invoke SetWindowPos, hNextPanel, HWND_TOP, xposnextpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOCOPYBITS +SWP_SHOWWINDOW + SWP_NOSENDCHANGING+ SWP_NOACTIVATE ; +SWP_NOCOPYBITS + 
    
    mov rax, xposnextpanel
    .WHILE sqword ptr rax < 1
        Invoke SetWindowPos, hNextPanel, HWND_TOP, xposnextpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOSENDCHANGING + SWP_NOACTIVATE ;+ SWP_NOMOVE  +SWP_NOCOPYBITS
        Invoke SetWindowPos, hCurrentPanel, HWND_TOP, xposcurrentpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER  + SWP_NOSENDCHANGING + SWP_NOACTIVATE;+ SWP_NOMOVE +SWP_NOCOPYBITS
        ;Invoke InvalidateRect, hNextPanel, NULL, TRUE

        Invoke UpdateWindow, hNextPanel
        ;Invoke UpdateWindow, hCurrentPanel
        .IF SlideSpeed == SlideVFast
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel                    
        .ELSEIF SlideSpeed == SlideFast
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel
        .ELSEIF SlideSpeed == SlideNormal
            inc xposcurrentpanel
            inc xposnextpanel
            inc xposcurrentpanel
            inc xposnextpanel
        .ELSE
            inc xposcurrentpanel
            inc xposnextpanel
        .ENDIF
        ;PrintDec xposnextpanel
        mov rax, xposnextpanel
    .ENDW
    
    ;PrintText 'SP_SlidePanelsRight End'
    
    Invoke ShowWindow, hCurrentPanel, SW_HIDE
    Invoke SetWindowPos, hNextPanel, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOSENDCHANGING + SWP_NOACTIVATE ;+ SWP_NOMOVE  +SWP_NOCOPYBITS  
    Invoke ShowWindow, hNextPanel, SW_SHOWDEFAULT
    Invoke SetFocus, hNextPanel 
    ret

_MUI_SmartPanelSlidePanelsRight endp


;-------------------------------------------------------------------------------------
; MUISmartPanelNextPanel - returns previous panel selected in eax or -1 if nothing happening
;-------------------------------------------------------------------------------------
MUISmartPanelNextPanel PROC FRAME USES RBX hControl:QWORD, qwNotify:QWORD
    LOCAL OldSelection:QWORD
    LOCAL NewSelection:QWORD
    LOCAL TotalItems:QWORD
    LOCAL hItem:QWORD
    LOCAL hNewSelection:QWORD
    LOCAL hOldSelection:QWORD
    LOCAL rect:RECT
    LOCAL SlideSpeed:QWORD
    LOCAL qwStyle:QWORD
    
    ;PrintText 'SP_NextPanel'
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    mov TotalItems, rax
    .IF TotalItems < 2 ; == 0
        mov rax, -1
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelCurrentPanel
    mov OldSelection, rax

    Invoke GetWindowLong, hControl, GWL_STYLE
    mov qwStyle, rax
    
    inc rax ; for adjust of 0 based index
    .IF rax == TotalItems
        mov rax, qwStyle
        AND rax, MUISPS_SPS_WRAPAROUND
        .IF rax == MUISPS_SPS_WRAPAROUND
            mov NewSelection, 0
        .ELSE
            mov rax, OldSelection
            ret
        .ENDIF
    .ELSE
        mov rax, OldSelection
        inc rax
        mov NewSelection, rax
    .ENDIF
    
    Invoke _MUI_SmartPanelGetPanelHandle, hControl, OldSelection
    mov hOldSelection, rax

    Invoke _MUI_SmartPanelGetPanelHandle, hControl, NewSelection
    mov hNewSelection, rax
    
    ; call slide panels function if specified
    mov rax, qwStyle
    AND rax, MUISPS_SLIDEPANELS_SLOW + MUISPS_SLIDEPANELS_NORMAL + MUISPS_SLIDEPANELS_FAST + MUISPS_SLIDEPANELS_VFAST
    .IF rax == 0 ; if style is not animation
        .IF hOldSelection != NULL
            Invoke ShowWindow, hOldSelection, SW_HIDE
        .ENDIF        
        .IF hNewSelection != NULL
            ; resize panel if container size has changed since last selection
            Invoke GetClientRect, hControl, Addr rect
            Invoke SetWindowPos, hNewSelection, HWND_TOP, 0, 0, rect.right, rect.bottom, SWP_NOZORDER ;+ SWP_NOMOVE		                    
            Invoke ShowWindow, hNewSelection, SW_SHOWDEFAULT
        .ENDIF
    .ELSE
        mov rax, qwStyle
        AND rax, MUISPS_SLIDEPANELS_SLOW + MUISPS_SLIDEPANELS_NORMAL + MUISPS_SLIDEPANELS_FAST + MUISPS_SLIDEPANELS_VFAST
        .IF rax == MUISPS_SLIDEPANELS_SLOW
            mov rax, SlideSlow
        .ENDIF    
        .IF rax == MUISPS_SLIDEPANELS_NORMAL
            mov rax, SlideNormal
        .ENDIF
        .IF rax == MUISPS_SLIDEPANELS_FAST
            mov rax, SlideFast
        .ENDIF    
        .IF rax == MUISPS_SLIDEPANELS_VFAST
            mov rax, SlideVFast
        .ENDIF
         mov SlideSpeed, rax
         
         Invoke _MUI_SmartPanelSlidePanelsLeft, hControl, hOldSelection, hNewSelection, SlideSpeed

    .ENDIF
    
    ; update current panel internally AND externally if user provided a var to hold this.
    Invoke MUISetIntProperty, hControl, @SmartPanelCurrentPanel, NewSelection

    Invoke MUIGetIntProperty, hControl, @SmartPanellpqwIsDlgMsgVar
    .IF rax != NULL
        mov rbx, hNewSelection
        mov [rax], rbx
    .ENDIF
   
    ; Notify if user has specified so
    .IF qwNotify == TRUE
        Invoke _MUI_SmartPanelNavNotify, hControl, OldSelection, NewSelection
    .ENDIF
    mov rax, OldSelection
    ret
MUISmartPanelNextPanel ENDP


;-------------------------------------------------------------------------------------
; MUISmartPanelPrevPanel - returns previous panel selected in eax or -1 if nothing happening
;-------------------------------------------------------------------------------------
MUISmartPanelPrevPanel PROC FRAME USES RBX hControl:QWORD, qwNotify:QWORD
    LOCAL OldSelection:QWORD
    LOCAL NewSelection:QWORD
    LOCAL TotalItems:QWORD
    LOCAL hItem:QWORD
    LOCAL hNewSelection:QWORD
    LOCAL hOldSelection:QWORD
    LOCAL rect:RECT
    LOCAL SlideSpeed:QWORD
    LOCAL qwStyle:QWORD

    ;PrintText 'SP_PrevPanel'

    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    mov TotalItems, rax
    .IF TotalItems < 2 ; == 0
        mov rax, -1
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelCurrentPanel
    mov OldSelection, rax
    
    Invoke GetWindowLong, hControl, GWL_STYLE
    mov qwStyle, rax    
    
    .IF rax == 0
        mov rax, qwStyle
        AND rax, MUISPS_SPS_WRAPAROUND
        .IF rax == MUISPS_SPS_WRAPAROUND
            mov rax, TotalItems     
            dec rax ; for adjust of 0 based index
            mov NewSelection, rax
        .ELSE
            mov rax, 0 ;OldSelection
            ret
        .ENDIF
    .ELSE
        mov rax, OldSelection
        dec rax
        mov NewSelection, rax
    .ENDIF
    
    Invoke _MUI_SmartPanelGetPanelHandle, hControl, OldSelection
    mov hOldSelection, rax

    Invoke _MUI_SmartPanelGetPanelHandle, hControl, NewSelection
    mov hNewSelection, rax
   
    ; call slide panels function if specified
    mov rax, qwStyle
    AND rax, MUISPS_SLIDEPANELS_SLOW + MUISPS_SLIDEPANELS_NORMAL + MUISPS_SLIDEPANELS_FAST + MUISPS_SLIDEPANELS_VFAST
    .IF rax == 0 ; if style is not animation
        .IF hOldSelection != NULL
            Invoke ShowWindow, hOldSelection, SW_HIDE
        .ENDIF        
        .IF hNewSelection != NULL
            ; resize panel if container size has changed since last selection
            Invoke GetClientRect, hControl, Addr rect
            Invoke SetWindowPos, hNewSelection, HWND_TOP, 0, 0, rect.right, rect.bottom, SWP_NOZORDER ;+ SWP_NOMOVE		                    
            Invoke ShowWindow, hNewSelection, SW_SHOWDEFAULT
        .ENDIF
    .ELSE
        mov rax, qwStyle
        AND rax, MUISPS_SLIDEPANELS_SLOW + MUISPS_SLIDEPANELS_NORMAL + MUISPS_SLIDEPANELS_FAST + MUISPS_SLIDEPANELS_VFAST
        .IF rax == MUISPS_SLIDEPANELS_SLOW
            mov rax, SlideSlow
        .ENDIF    
        .IF rax == MUISPS_SLIDEPANELS_NORMAL
            mov rax, SlideNormal
        .ENDIF
        .IF rax == MUISPS_SLIDEPANELS_FAST
            mov rax, SlideFast
        .ENDIF    
        .IF rax == MUISPS_SLIDEPANELS_VFAST
            mov rax, SlideVFast
        .ENDIF
         mov SlideSpeed, rax
         
         Invoke _MUI_SmartPanelSlidePanelsRight, hControl, hOldSelection, hNewSelection, SlideSpeed

    .ENDIF
    
    ; update current panel internally AND externally if user provided a var to hold this.
    Invoke MUISetIntProperty, hControl, @SmartPanelCurrentPanel, NewSelection

    Invoke MUIGetIntProperty, hControl, @SmartPanellpqwIsDlgMsgVar
    .IF rax != NULL
        mov rbx, hNewSelection
        mov [rax], rbx
    .ENDIF
   
    ; Notify if user has specified so
    .IF qwNotify == TRUE
        Invoke _MUI_SmartPanelNavNotify, hControl, OldSelection, NewSelection
    .ENDIF
    mov rax, OldSelection
    ret

MUISmartPanelPrevPanel ENDP


;-------------------------------------------------------------------------------------
; MUISmartPanelSetIsDlgMsgVar
;-------------------------------------------------------------------------------------
MUISmartPanelSetIsDlgMsgVar PROC FRAME hControl:QWORD, lpqwIsDlgMsgVar:QWORD
    Invoke MUISetIntProperty, hControl, @SmartPanellpqwIsDlgMsgVar, lpqwIsDlgMsgVar
    ret
MUISmartPanelSetIsDlgMsgVar ENDP




;--------------------------------------------------------------------------------------------------------------------
; _MUI_SmartPanelGetPanelHandle
;--------------------------------------------------------------------------------------------------------------------
_MUI_SmartPanelGetPanelHandle PROC FRAME USES RBX hControl:QWORD, nItem:QWORD
    LOCAL TotalItems:QWORD
    LOCAL pItemData:QWORD
    LOCAL pItemDataEntry:QWORD

    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    mov TotalItems, rax
    .IF TotalItems == 0
        mov rax, NULL
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hControl, @SmartPanelPanelsArray
    mov pItemData, rax

    mov rax, nItem
    mov rbx, SIZEOF MUISP_ITEM
    mul rbx
    mov rbx, pItemData
    add rax, rbx
    mov pItemDataEntry, rax
    mov rbx, pItemDataEntry
    mov rax, [rbx].MUISP_ITEM.hPanel
    ret

_MUI_SmartPanelGetPanelHandle endp
















END
