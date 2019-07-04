;==============================================================================
;
; ModernUI x64 Control - ModernUI_SmartPanel x64
;
; Copyright (c) 2019 by fearless
;
; All Rights Reserved
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

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_SmartPanel.inc

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_SmartPanelWndProc          PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_SmartPanelInit             PROTO :QWORD
_MUI_SmartPanelCleanup          PROTO :QWORD
_MUI_SmartPanelGetPanelHandle   PROTO :QWORD, :QWORD
_MUI_SmartPanelNavNotify        PROTO :QWORD, :QWORD, :QWORD
_MUI_SmartPanelSlidePanels      PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_SmartPanelSlidePanelsLeft  PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_SmartPanelSlidePanelsRight PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_SP_ResizePanels            PROTO :QWORD
_MUI_SP_DialogSubClassProc      PROTO :HWND, :UINT, :WPARAM, :LPARAM, :UINT, :QWORD
_MUI_SP_DialogPaintBackground   PROTO :QWORD, :QWORD


;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
MUI_SMARTPANEL_PROPERTIES       STRUCT
    qwPanelsColor               DQ ?
    qwBorderColor               DQ ?    
    qwNotifications             DQ ?    ; BOOL. Allow notifications via WM_NOTIFY. Default is TRUE
    qwNotifyCallback            DQ ?    ; QWORD. Address of custom notifications callback function (MUISmartPanelNotifyCallback)
    qwDllInstance               DQ ?
    qwParam                     DQ ?
MUI_SMARTPANEL_PROPERTIES       ENDS

; Internal properties
_MUI_SMARTPANEL_PROPERTIES      STRUCT
    qwEnabledState              DQ ?
    qwMouseOver                 DQ ?
    qwCurrentPanel              DQ ?
    qwTotalPanels               DQ ?
    qwPanelsArray               DQ ?    ; array of MUISP_ITEM
    lpqwIsDlgMsgVar             DQ ?
    hBitmap                     DQ ?
    uIdSubclassCounter          DQ ?
    qwNotifyData                DQ ?    ; QWORD. Pointer to NM_MUISMARTPANEL notification structure data
_MUI_SMARTPANEL_PROPERTIES      ENDS

IFNDEF MUISP_ITEM ; SmartPanel Notification Item
MUISP_ITEM                      STRUCT
    iItem                       DQ 0 ; index of dialog in array
    lParam                      DQ 0
    hPanel                      DQ 0; handle to dialog panel
    clrRGB                      DQ -1 ; RGBCOLOR of panel background, -1 = not using 
MUISP_ITEM                      ENDS
ENDIF

IFNDEF NM_MUISMARTPANEL         ; Notification Message Structure for SmartPanel
NM_MUISMARTPANEL                STRUCT
    hdr                         NMHDR <>
    itemOld                     MUISP_ITEM <>
    itemNew                     MUISP_ITEM <>
NM_MUISMARTPANEL                ENDS
ENDIF


.CONST
IFNDEF MUISPN_SELCHANGED
MUISPN_SELCHANGED               EQU 0 ; Used with WM_NOTIFY. wParam is a NM_MUISMARTPANEL struct
ENDIF

SlideSlow                       EQU 0
SlideNormal                     EQU 1
SlideFast                       EQU 2
SlideVFast                      EQU 3


; Internal properties
@SmartPanelEnabledState         EQU 0
@SmartPanelMouseOver            EQU 8
@SmartPanelCurrentPanel         EQU 16
@SmartPanelTotalPanels          EQU 24
@SmartPanelPanelsArray          EQU 32
@SmartPanellpqwIsDlgMsgVar      EQU 40
@SmartPanelBitmap               EQU 48
@SPSubclassCounter              EQU 56
@SmartPanelNotifyData           EQU 64



.DATA
szMUISmartPanelClass            DB 'ModernUI_SmartPanel',0  ; Class name for creating our ModernUI_SmartPanel control



.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for ModernUI_SmartPanel control
;------------------------------------------------------------------------------
MUISmartPanelSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUISmartPanelSetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for ModernUI_SmartPanel control
;------------------------------------------------------------------------------
MUISmartPanelGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUISmartPanelGetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelRegister - Registers the ModernUI_SmartPanel control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_SmartPanel
;------------------------------------------------------------------------------
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

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelCreate - Returns handle in rax of newly created control
;------------------------------------------------------------------------------
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

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SmartPanelWndProc - Main processing window for our control
;------------------------------------------------------------------------------
_MUI_SmartPanelWndProc PROC FRAME hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    
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
        Invoke _MUI_SmartPanelCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
        Invoke MUIFreeMemProperties, hWin, 8
        mov eax, 0
        ret     

    .ELSEIF eax == WM_SIZE
        ; Check if _MUI_SMARTPANEL_PROPERTIES ; internal properties available
        Invoke GetWindowLongPtr, hWin, 0
        .IF rax != 0 ; Yes they are
            Invoke _MUI_SP_ResizePanels, hWin ; resize all panel dialogs to same size as smartpanel
        .ENDIF
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
        
    .ELSEIF eax == MUISPM_GETPANELPARAM
        Invoke MUISmartPanelGetPanelParam, hWin, wParam
        ret
    
    .ELSEIF eax == MUISPM_SETPANELPARAM
        Invoke MUISmartPanelSetPanelParam, hWin, wParam, lParam
        ret
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret
_MUI_SmartPanelWndProc ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SmartPanelInit - set initial default values
;------------------------------------------------------------------------------
_MUI_SmartPanelInit PROC FRAME hWin:QWORD
    LOCAL qwStyle:QWORD
    LOCAL qwExStyle:QWORD
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, qwStyle
        or rax, DS_CONTROL or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov qwStyle, rax
        Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwStyle
    .ENDIF
    
    Invoke GetWindowLongPtr, hWin, GWL_EXSTYLE
    mov qwExStyle, rax
    and rax, WS_EX_CONTROLPARENT
    .IF rax != WS_EX_CONTROLPARENT
        mov rax, qwExStyle
        or rax, WS_EX_CONTROLPARENT
        mov qwExStyle, rax
        Invoke SetWindowLongPtr, hWin, GWL_EXSTYLE, qwExStyle
    .ENDIF
    ;PrintDec dwStyle
    
    ; Set default initial internal property values     
    Invoke MUISetIntProperty, hWin, @SmartPanelCurrentPanel, -1
    Invoke MUISetIntProperty, hWin, @SmartPanelTotalPanels, 0
    Invoke MUISetIntProperty, hWin, @SmartPanelPanelsArray, 0
    Invoke MUISetIntProperty, hWin, @SmartPanellpqwIsDlgMsgVar, 0
    
    ; Set default initial external property values
    Invoke MUISetExtProperty, hWin, @SmartPanelPanelsColor, -1
    Invoke MUISetExtProperty, hWin, @SmartPanelBorderColor, -1
    Invoke MUISetExtProperty, hWin, @SmartPanelDllInstance, 0

    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF NM_MUISMARTPANEL
    .IF rax != NULL
        Invoke MUISetIntProperty, hWin, @SmartPanelNotifyData, rax
        Invoke MUISetExtProperty, hWin, @SmartPanelNotifications, TRUE
    .ENDIF

    ret
_MUI_SmartPanelInit ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SmartPanelCleanup - cleanup a few things before control is destroyed
;------------------------------------------------------------------------------
_MUI_SmartPanelCleanup PROC FRAME hWin:QWORD
    LOCAL TotalItems:QWORD

    Invoke MUIGetIntProperty, hWin, @SmartPanelTotalPanels
    mov TotalItems, rax

    .IF TotalItems != 0
        Invoke MUIGetIntProperty, hWin, @SmartPanelPanelsArray
        ;mov pItemData, eax
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @SmartPanelNotifyData
    .IF rax != NULL
        Invoke GlobalFree, rax
    .ENDIF
    
    mov rax, 0
    ret

_MUI_SmartPanelCleanup ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelRegisterPanel - Creates the panel dialog and saves the handle in the
; MUISP_ITEM. Returns handle of dialog in eax
;------------------------------------------------------------------------------
MUISmartPanelRegisterPanel PROC FRAME USES RBX hControl:QWORD, idPanelDlg:QWORD, lpqwPanelProc:QWORD
    LOCAL hinstance:QWORD
    LOCAL hPanelDlg:QWORD
    LOCAL rect:RECT
    LOCAL pItemData:QWORD
    LOCAL pItemDataEntry:QWORD
    LOCAL TotalItems:QWORD
    LOCAL uIdSubclass:QWORD    

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

    Invoke MUIGetIntProperty, hControl, @SPSubclassCounter
    mov uIdSubclass, rax
    Invoke SetWindowSubclass, hPanelDlg, Addr _MUI_SP_DialogSubClassProc, uIdSubclass, hControl
    inc uIdSubclass
    Invoke MUISetIntProperty, hControl, @SPSubclassCounter, uIdSubclass

    mov rax, hPanelDlg
    ret

MUISmartPanelRegisterPanel endp

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SP_DialogSubClassProc - SUBCLASS of Registered panel (Dialog) for painting panel back color
;------------------------------------------------------------------------------
_MUI_SP_DialogSubClassProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM, uIdSubclass:UINT, qwRefData:QWORD
    LOCAL qwBackColor:QWORD
    
    mov eax, uMsg
    .IF eax == WM_NCDESTROY
        Invoke RemoveWindowSubclass, hWin, Addr _MUI_SP_DialogSubClassProc, uIdSubclass
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam 
        ret

    .ELSEIF eax == WM_ERASEBKGND
        Invoke MUIGetExtProperty, qwRefData, @SmartPanelPanelsColor
        .IF rax == -1
            Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
            ret
        .ELSE
            mov rax, 1
            ret
        .ENDIF

    .ELSEIF eax == WM_PAINT
        Invoke MUIGetExtProperty, qwRefData, @SmartPanelPanelsColor
        .IF rax == -1
            Invoke DefSubclassProc, hWin, uMsg, wParam, lParam         
            ret
        .ELSE
            mov qwBackColor, rax
            Invoke _MUI_SP_DialogPaintBackground, hWin, qwBackColor
            ret
        .ENDIF    

    .ELSE
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
    .ENDIF

    ret    

_MUI_SP_DialogSubClassProc ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SP_DialogPaintBackground
;------------------------------------------------------------------------------
_MUI_SP_DialogPaintBackground PROC FRAME hWin:QWORD, qwBackColor:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD    

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    ;----------------------------------------------------------
    ; Get some property values
    ;---------------------------------------------------------- 
    Invoke GetClientRect, hWin, Addr rect

    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
    mov hbmMem, rax
    Invoke SelectObject, hdcMem, hbmMem
    mov hOldBitmap, rax

    ;----------------------------------------------------------
    ; Fill background
    ;----------------------------------------------------------
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr qwBackColor
    Invoke FillRect, hdcMem, Addr rect, hBrush

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
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem          
    
    Invoke EndPaint, hWin, Addr ps
    ret
_MUI_SP_DialogPaintBackground ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelGetCurrentPanel - Returns in eax the handle of the current panel or NULL
;------------------------------------------------------------------------------
MUISmartPanelGetCurrentPanel PROC FRAME hControl:QWORD
    Invoke MUIGetIntProperty, hControl, @SmartPanelCurrentPanel
    Invoke _MUI_SmartPanelGetPanelHandle, hControl, eax
    ret
MUISmartPanelGetCurrentPanel ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelSetCurrentPanel - Returns the index of the previously selected panel 
; if successful or - 1 otherwise.
;------------------------------------------------------------------------------
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
        Invoke GetWindowLongPtr, hControl, GWL_STYLE
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

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelSetPanelParam - sets lParam of panel
; Returns: NULL or lParam as set
;------------------------------------------------------------------------------
MUISmartPanelSetPanelParam PROC FRAME USES RBX hControl:QWORD, PanelIndex:QWORD, lParam:QWORD
    LOCAL TotalPanels:QWORD
    LOCAL pItemData:QWORD
    LOCAL pItemDataEntry:QWORD
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    .IF rax == 0
        xor eax, eax
        ret
    .ENDIF
    .IF PanelIndex >= rax
        xor eax, eax
        ret
    .ENDIF 
    mov TotalPanels, rax
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelPanelsArray
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov pItemData, rax
    
    mov rax, PanelIndex
    mov rbx, SIZEOF MUISP_ITEM
    mul rbx
    add rax, pItemData
    mov pItemDataEntry, rax
    
    mov rbx, pItemDataEntry
    mov rax, lParam
    mov [rbx].MUISP_ITEM.lParam, rax
 
    ret
MUISmartPanelSetPanelParam ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelGetPanelParam - Get lParam of panel
; Returns: lParam of panel or NULL
;------------------------------------------------------------------------------
MUISmartPanelGetPanelParam PROC FRAME USES RBX hControl:QWORD, PanelIndex:QWORD
    LOCAL TotalPanels:QWORD
    LOCAL pItemData:QWORD
    LOCAL pItemDataEntry:QWORD
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelTotalPanels
    .IF rax == 0
        xor eax, eax
        ret
    .ENDIF
    .IF PanelIndex >= rax
        xor eax, eax
        ret
    .ENDIF 
    mov TotalPanels, rax
    
    Invoke MUIGetIntProperty, hControl, @SmartPanelPanelsArray
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov pItemData, rax
    
    mov rax, PanelIndex
    mov rbx, SIZEOF MUISP_ITEM
    mul rbx
    add rax, pItemData
    mov pItemDataEntry, rax
    
    mov rbx, pItemDataEntry
    mov rax, [rbx].MUISP_ITEM.lParam
    
    ret
MUISmartPanelGetPanelParam ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SmartPanelNavNotify
;------------------------------------------------------------------------------
_MUI_SmartPanelNavNotify PROC FRAME USES RBX RDX hWin:QWORD, OldSelection:QWORD, NewSelection:QWORD
    LOCAL pItemData:QWORD
    LOCAL pOldItemDataEntry:QWORD
    LOCAL pNewItemDataEntry:QWORD
    LOCAL TotalItems:QWORD
    LOCAL hItem:QWORD
    LOCAL ItemIndex:QWORD
    LOCAL hParent:QWORD
    LOCAL idControl:QWORD
    LOCAL NotifyData:QWORD
    LOCAL NotifyCallback:QWORD
    
    Invoke MUIGetExtProperty, hWin, @SmartPanelNotifications
    .IF rax == FALSE
        mov rax, TRUE
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @SmartPanelNotifyData
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov NotifyData, rax
    
    Invoke MUIGetIntProperty, hWin, @SmartPanelPanelsArray
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov pItemData, rax
    
    ; fill notify NMHDR
    mov rbx, NotifyData
    mov rax, hWin
    mov [rbx].NM_MUISMARTPANEL.hdr.hwndFrom, rax
    mov rax, MUISPN_SELCHANGED
    mov [rbx].NM_MUISMARTPANEL.hdr.code, eax

    ; get new and old item data
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
        
    ; Fill notify data structure with info
    mov rdx, NotifyData
    mov rbx, pOldItemDataEntry
    mov rax, [rbx].MUISP_ITEM.iItem
    mov [rdx].NM_MUISMARTPANEL.itemOld.iItem, rax
    mov rax, [rbx].MUISP_ITEM.lParam
    mov [rdx].NM_MUISMARTPANEL.itemOld.lParam, rax
    mov rax, [rbx].MUISP_ITEM.hPanel
    mov [rdx].NM_MUISMARTPANEL.itemNew.hPanel, rax    
    
    mov rbx, pNewItemDataEntry
    mov rax, [rbx].MUISP_ITEM.iItem
    mov [rdx].NM_MUISMARTPANEL.itemNew.iItem, rax
    mov rax, [rbx].MUISP_ITEM.lParam
    mov [rdx].NM_MUISMARTPANEL.itemNew.lParam, rax
    mov rax, [rbx].MUISP_ITEM.hPanel
    mov [rdx].NM_MUISMARTPANEL.itemNew.hPanel, rax

    Invoke MUIGetExtProperty, hWin, @SmartPanelNotifyCallback
    .IF eax == NULL
        Invoke GetParent, hWin
        mov hParent, rax
        Invoke GetDlgCtrlID, hWin
        mov idControl, rax
        
        ;Invoke GetParent, hParent
        .IF hParent != NULL
            Invoke PostMessage, hParent, WM_NOTIFY, idControl, NotifyData;Addr SPNM
            mov rax, TRUE
        .ELSE
            mov rax, FALSE
        .ENDIF
    .ELSE
        ; Custom user callback for notifications instead of WM_NOTIFY
        mov NotifyCallback, rax
        mov rcx, NotifyData
        mov rdx, hWin
        call rax ;NotifyCallback
    .ENDIF

    ret
_MUI_SmartPanelNavNotify endp

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SmartPanelSlidePanels - SlideSpeed 0 slow, 1 fast, 2 very fast
;------------------------------------------------------------------------------
_MUI_SmartPanelSlidePanels PROC FRAME USES RBX hWin:QWORD, OldSelection:QWORD, NewSelection:QWORD, SlideSpeed:QWORD 
    LOCAL hCurrentPanel:QWORD
    LOCAL hNextPanel:QWORD
    LOCAL nPanel:QWORD
    LOCAL qwStyle:QWORD
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, MUISPS_SPS_SKIPBETWEEN
    .IF rax == MUISPS_SPS_SKIPBETWEEN    
        
        Invoke _MUI_SmartPanelGetPanelHandle, hWin, OldSelection
        mov hCurrentPanel, rax
        
        Invoke _MUI_SmartPanelGetPanelHandle, hWin, NewSelection
        mov hNextPanel, rax

        mov rax, NewSelection
        .IF rax < OldSelection ; moving down = left, so slide right 
            Invoke _MUI_SmartPanelSlidePanelsRight, hWin, hCurrentPanel, hNextPanel, SlideSpeed
        .ELSE ; moving up = right, so slide left   
            Invoke _MUI_SmartPanelSlidePanelsLeft, hWin, hCurrentPanel, hNextPanel, SlideSpeed
        .ENDIF        

    .ELSE
    
        mov rax, NewSelection
        .IF rax < OldSelection ; moving down = left, so slide right till we get to it
            
            mov rax, OldSelection
            mov nPanel, rax
            .WHILE rax > NewSelection
        
                Invoke _MUI_SmartPanelGetPanelHandle, hWin, nPanel
                mov hCurrentPanel, rax
                mov rax, nPanel
                dec rax
                Invoke _MUI_SmartPanelGetPanelHandle, hWin, rax
                mov hNextPanel, rax
                
                Invoke _MUI_SmartPanelSlidePanelsRight, hWin, hCurrentPanel, hNextPanel, SlideSpeed
                dec nPanel
                mov rax, nPanel
            .ENDW
        
        .ELSE ; moving up = right, so slide left till we get to it
            
            mov rax, OldSelection     
            mov nPanel, rax
            .WHILE rax < NewSelection
        
                Invoke _MUI_SmartPanelGetPanelHandle, hWin, nPanel
                mov hCurrentPanel, rax
                mov rax, nPanel
                inc rax
                Invoke _MUI_SmartPanelGetPanelHandle, hWin, rax
                mov hNextPanel, rax
                
                Invoke _MUI_SmartPanelSlidePanelsLeft, hWin, hCurrentPanel, hNextPanel, SlideSpeed
                inc nPanel
                mov rax, nPanel
            .ENDW
            
        .ENDIF
    
    .ENDIF
    ret

_MUI_SmartPanelSlidePanels endp

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SmartPanelSlidePanelsLeft - Slides current and next panel left till we show next panel only
;------------------------------------------------------------------------------
_MUI_SmartPanelSlidePanelsLeft PROC FRAME hWin:QWORD, hCurrentPanel:QWORD, hNextPanel:QWORD, SlideSpeed:QWORD
    LOCAL rect:RECT
    LOCAL xposnextpanel:SDWORD
    LOCAL xposcurrentpanel:SDWORD    
    
    IFDEF DEBUG64
    PrintText 'SP_SlidePanelsLeft'
    ENDIF
    Invoke GetClientRect, hWin, Addr rect
    xor rax, rax
    mov eax, rect.right
    mov xposnextpanel, eax
    mov xposcurrentpanel, 1
    Invoke SetWindowPos, hNextPanel, HWND_TOP, xposnextpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOCOPYBITS +SWP_SHOWWINDOW + SWP_NOSENDCHANGING+ SWP_NOACTIVATE ;+SWP_NOCOPYBITS +

    mov eax, xposnextpanel
    .WHILE sdword ptr eax > 0
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
        mov eax, xposnextpanel
    .ENDW
    
    ;PrintText 'SP_SlidePanelsLeft End'
    
    Invoke ShowWindow, hCurrentPanel, SW_HIDE
    Invoke SetWindowPos, hNextPanel, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOSENDCHANGING + SWP_NOACTIVATE ;+ SWP_NOMOVE  +SWP_NOCOPYBITS
    Invoke ShowWindow, hNextPanel, SW_SHOWDEFAULT
    Invoke SetFocus, hNextPanel    
    
    ret

_MUI_SmartPanelSlidePanelsLeft endp

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SmartPanelSlidePanelsRight - Slides current and next panel right till we show next panel only
;------------------------------------------------------------------------------
_MUI_SmartPanelSlidePanelsRight PROC FRAME hWin:QWORD, hCurrentPanel:QWORD, hNextPanel:QWORD, SlideSpeed:QWORD
    LOCAL rect:RECT
    LOCAL xposnextpanel:SDWORD
    LOCAL xposcurrentpanel:SDWORD
    
    IFDEF DEBUG64
    PrintText 'SP_SlidePanelsRight'
    ENDIF
    Invoke GetClientRect, hWin, Addr rect
    xor rax, rax
    sub eax, rect.right ;sdword ptr sdword ptr 
    mov xposnextpanel, eax ;-570
    mov xposcurrentpanel, 1
    Invoke SetWindowPos, hNextPanel, HWND_TOP, xposnextpanel, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOCOPYBITS +SWP_SHOWWINDOW + SWP_NOSENDCHANGING+ SWP_NOACTIVATE ; +SWP_NOCOPYBITS + 
    
    mov eax, xposnextpanel
    .WHILE sdword ptr eax < 1
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
        mov eax, xposnextpanel
    .ENDW
    
    ;PrintText 'SP_SlidePanelsRight End'
    
    Invoke ShowWindow, hCurrentPanel, SW_HIDE
    Invoke SetWindowPos, hNextPanel, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOZORDER + SWP_NOSENDCHANGING + SWP_NOACTIVATE ;+ SWP_NOMOVE  +SWP_NOCOPYBITS  
    Invoke ShowWindow, hNextPanel, SW_SHOWDEFAULT
    Invoke SetFocus, hNextPanel 
    ret

_MUI_SmartPanelSlidePanelsRight endp

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelNextPanel - returns previous panel selected in eax or -1 if nothing happening
;------------------------------------------------------------------------------
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

    Invoke GetWindowLongPtr, hControl, GWL_STYLE
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

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelPrevPanel - returns previous panel selected in eax or -1 if nothing happening
;------------------------------------------------------------------------------
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
    
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
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

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISmartPanelSetIsDlgMsgVar
;------------------------------------------------------------------------------
MUISmartPanelSetIsDlgMsgVar PROC FRAME hControl:QWORD, lpqwIsDlgMsgVar:QWORD
    Invoke MUISetIntProperty, hControl, @SmartPanellpqwIsDlgMsgVar, lpqwIsDlgMsgVar
    ret
MUISmartPanelSetIsDlgMsgVar ENDP

MUI_ALIGN
;-------------------------------------------------------------------------------------------------------------
; _MUI_SmartPanelGetPanelHandle
;-------------------------------------------------------------------------------------------------------------
_MUI_SmartPanelGetPanelHandle PROC FRAME USES RBX hWin:QWORD, nItem:QWORD
    LOCAL TotalItems:QWORD
    LOCAL pItemData:QWORD
    LOCAL pItemDataEntry:QWORD

    Invoke MUIGetIntProperty, hWin, @SmartPanelTotalPanels
    mov TotalItems, rax
    .IF TotalItems == 0
        mov rax, NULL
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @SmartPanelPanelsArray
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

MUI_ALIGN
;-------------------------------------------------------------------------------------------------------------
; MUISmartPanelCurrentPanelIndex - returns current selected panel as a numerical index in eax, or -1 if error.
;-------------------------------------------------------------------------------------------------------------
MUISmartPanelCurrentPanelIndex PROC FRAME hControl:QWORD
    Invoke MUIGetIntProperty, hControl, @SmartPanelCurrentPanel
    ret
MUISmartPanelCurrentPanelIndex ENDP

MUI_ALIGN
;-------------------------------------------------------------------------------------------------------------
; _MUI_SP_ResizePanels - Resize panels to match SmartPanel size
;-------------------------------------------------------------------------------------------------------------
_MUI_SP_ResizePanels PROC FRAME USES RBX hWin:QWORD
    LOCAL rect:RECT
    LOCAL hPanelDlg:QWORD
    LOCAL qwTotalPanels:QWORD
    LOCAL pItemData:QWORD
    LOCAL pItemDataEntry:QWORD
    LOCAL hDefer:QWORD
    LOCAL nCurrentPanel:QWORD
    
    ; check if size hasnt been sent at init, before properties can be checked?
    ; check if sliding currently?
    
    Invoke MUIGetIntProperty, hWin, @SmartPanelTotalPanels
    mov qwTotalPanels, rax
    .IF qwTotalPanels == 0
        xor rax, rax
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @SmartPanelPanelsArray
    mov pItemData, rax
    mov pItemDataEntry, rax
    
    Invoke GetClientRect, hWin, Addr rect

    Invoke BeginDeferWindowPos, qwTotalPanels
    mov hDefer, rax
    
    mov nCurrentPanel, 0
    mov rax, 0
    .WHILE rax < qwTotalPanels
        mov rbx, pItemDataEntry
        mov rax, [rbx].MUISP_ITEM.hPanel
        mov hPanelDlg, rax
        
        .IF hDefer == NULL
            Invoke SetWindowPos, hPanelDlg, NULL, 0, 0, rect.right, rect.bottom, SWP_NOZORDER or SWP_NOOWNERZORDER  or SWP_NOACTIVATE or SWP_NOMOVE ;or SWP_NOSENDCHANGING ;or SWP_NOCOPYBITS
        .ELSE
            Invoke DeferWindowPos, hDefer, hPanelDlg, NULL, 0, 0, rect.right, rect.bottom, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE ;or SWP_NOSENDCHANGING
            mov hDefer, rax
        .ENDIF
        
        add pItemDataEntry, SIZEOF MUISP_ITEM
        inc nCurrentPanel
        mov rax, nCurrentPanel
    .ENDW
    
    .IF hDefer != NULL
        Invoke EndDeferWindowPos, hDefer
    .ENDIF      

    xor rax, rax
    ret

_MUI_SP_ResizePanels ENDP














MODERNUI_LIBEND
