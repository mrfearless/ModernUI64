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

;------------------------------------------------------------------------------
; ModernUI_TrayMenu Prototypes
;------------------------------------------------------------------------------
MUITrayMenuRegister         PROTO                                                                ; Use 'ModernUI_TrayMenu' as class in RadASM custom class control
MUITrayMenuCreate           PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD         ; hWndParent, hTrayMenuIcon, lpszTooltip, qwMenuType, qwMenu, qwOptions, hWndExtra
MUITrayMenuSetProperty      PROTO :QWORD, :QWORD, :QWORD                                         ; hModernUI_TrayMenu, qwProperty, qwPropertyValue
MUITrayMenuGetProperty      PROTO :QWORD, :QWORD                                                 ; hModernUI_TrayMenu, qwProperty
MUITrayMenuAssignMenu       PROTO :QWORD, :QWORD, :QWORD                                         ; hModernUI_TrayMenu, qwMenuType, qwMenu

; Tray Menu Item Functions
MUITrayMenuSetTrayIcon      PROTO :QWORD, :QWORD                                                 ; hModernUI_TrayMenu, hTrayIcon
MUITrayMenuSetTooltipText   PROTO :QWORD, :QWORD                                                 ; hModernUI_TrayMenu, lpszTooltip
MUITrayMenuEnableMenuItem   PROTO :QWORD, :QWORD                                                 ; hModernUI_TrayMenu, MenuItemID
MUITrayMenuDisableMenuItem  PROTO :QWORD, :QWORD                                                 ; hModernUI_TrayMenu, MenuItemID
MUITrayMenuChangeMenuItemState PROTO :QWORD, :QWORD, :QWORD                                      ; hModernUI_TrayMenu, MenuItemID, MenuItemState
MUITrayMenuSetMenuItemText  PROTO :QWORD, :QWORD, :QWORD                                         ; hModernUI_TrayMenu, MenuItemID, lpszMenuItemText
MUITrayMenuHideTrayIcon     PROTO :QWORD                                                         ; hModernUI_TrayMenu
MUITrayMenuShowTrayIcon     PROTO :QWORD                                                         ; hModernUI_TrayMenu
MUITrayMenuShowNotification PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD                         ; hModernUI_TrayMenu, lpszNotificationMessage, lpszNotificationTitle, qwTimeout, qwStyle
MUITrayMenuSetTrayIconText  PROTO :QWORD, :QWORD, :QWORD, :QWORD                                 ; hModernUI_TrayIcon, lpszText, lpszFont, qwTextColorRGB

; Tray Icon Functions (standalone - no menu)
MUITrayIconCreate           PROTO :QWORD, :QWORD, :QWORD, :QWORD                                 ; hWndParent, qwTrayIconResID, hTrayIcon, lpszTooltip - Returns in eax hModernUI_TrayIcon
MUITrayIconDestroy          PROTO :QWORD                                                         ; hModernUI_TrayIcon
MUITrayIconSetTrayIcon      PROTO :QWORD, :QWORD                                                 ; hModernUI_TrayIcon, hTrayIcon
MUITrayIconSetTooltipText   PROTO :QWORD, :QWORD                                                 ; hModernUI_TrayIcon, lpszTooltip
MUITrayIconShowNotification PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD                         ; hModernUI_TrayIcon, lpszNotificationMessage, lpszNotificationTitle, qwTimeout, qwStyle


;------------------------------------------------------------------------------
; ModernUI_TrayMenu Structures
;------------------------------------------------------------------------------
IFNDEF MUI_TRAYMENU_PROPERTIES
MUI_TRAYMENU_PROPERTIES     STRUCT
    qwTrayMenuIcon          DQ ?
    qwTrayMenuTooltipText   DQ ?
    qwTrayMenuVisible       DQ ?
    qwTrayMenuType          DQ ?
    qwTrayMenuHandleMenu    DQ ?
    qwTrayMenuExtraWndHandle DQ ?
MUI_TRAYMENU_PROPERTIES     ENDS
ENDIF

.CONST
;------------------------------------------------------------------------------
; ModernUI_TrayMenu Constants
;------------------------------------------------------------------------------

; ModernUI_TrayMenu Styles
; Tray Menu Type: qwMenuType of TrayMenuCreate and TrayMenuAssignMenu functions
MUITMT_MENUDEFER            EQU 0 ; Specified that qwMenu is ignored.
MUITMT_POPUPMENU            EQU 1 ; Specifies that qwMenu is a handle to a menu created with CreatePopupMenu
MUITMT_MENUITEMS            EQU 2 ; Specifies that qwMenu is a pointer to a list of TMITEM structures used to build menu from
MUITMT_NOMENUEVER           EQU 3 ; Specified that no menu is ever added to the icon at any point.

; Tray Menu Style
MUITMS_DEFAULT              EQU 0 ; default 
MUITMS_MINONCLOSE           EQU 1 ; minimizes window when close clicked
MUITMS_HIDEIFMIN            EQU 2 ; hide window when minimized


; Tray Menu Notification Icon
MUITMNI_NONE                EQU 0 ; No icon.
MUITMNI_INFO                EQU 1 ; An information icon.
MUITMNI_WARNING             EQU 2 ; A warning icon.
MUITMNI_ERROR               EQU 3 ; An error icon.

;------------------------------------------------------------------------------
; ModernUI_TrayMenu Properties: Use with MUIrayMenuSetProperty / 
;MUITrayMenuGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
;------------------------------------------------------------------------------
@TrayMenuIcon               EQU 0   ; hIcon to display in tray
@TrayMenuTooltipText        EQU 8   ; lpszText to display over icon in tray
@TrayMenuVisible            EQU 16  ; bool visible = TRUE/FALSE
@TrayMenuType               EQU 24  ; Tray Menu Type: TMT_MENUDEFER, TMT_POPUPMENU, TMT_MENUITEMS, TMT_NOMENUEVER
@TrayMenuHandleMenu         EQU 32  ; hMenu
@TrayMenuExtraWndHandle     EQU 40  ; hWnd Extra window handle to use for restoring a main window that isnt parent to current child window that hTM is based on



IFNDEF MUITMITEM
MUITMITEM                   STRUCT
    MenuItemID              DQ 0
    MenuItemType            DQ 0
    MenuItemText            DQ 0
    MenuItemState           DQ 0
MUITMITEM                   ENDS
ENDIF

IFNDEF MUITRAYMENU             ; Used with TrayMenuCreate and/or TrayMenuAssignMenu functions
MUITRAYMENU MACRO menulabel:REQ
    align 01
    .DATA
menulabel                   DQ 0xfFfFfFfFf0f0f0f0 ;0F0h,0F0h,0F0h,0F0h,0F0h,0F0h,0F0h,0F0h
    ;% echo menulabel
    ;% EXITM <menulabel  >
ENDM
ENDIF

IFNDEF MUITRAYMENU_ITEM       ; Used with TrayMenuCreate and/or TrayMenuAssignMenu functions
MUITRAYMENU_ITEM MACRO menutext:REQ, menuid:=<NULL>, menustate:=<MFS_ENABLED>
    LOCAL menustatetext, DashLines
    
    IFIDNI <menustate>, <ENABLED>
        menustatetext TEXTEQU <MFS_ENABLED>
    ELSE
        IFIDNI <menustate>, <DISABLED>
            menustatetext TEXTEQU <MFS_DISABLED>
        ELSE    
            menustatetext TEXTEQU <menustate>
        ENDIF
    ENDIF
    
    IF menuid eq 0
        MUITMITEM <0, MF_SEPARATOR, 0, MFS_ENABLED>
    ELSE
        IFIDNI <menutext>, <SEPARATOR>
            MUITMITEM <0, MF_SEPARATOR, 0, MFS_ENABLED>
        ELSE
            DashLines = @InStr(1, <menutext>, <->)
            IF DashLines gt 0
                MUITMITEM <0, MF_SEPARATOR, 0, MFS_ENABLED>
            ELSE
                MUITMITEM <menuid, MF_STRING, Offset menutext, menustatetext>
            ENDIF
        ENDIF
    ENDIF
ENDM
ENDIF

IFNDEF MUITRAYMENU_END         ; Used with TrayMenuCreate and/or TrayMenuAssignMenu functions
align 01
MUITRAYMENU_END                TEXTEQU <DQ 0xfFfFfFfFf0f0f0f0> ;0F0h,0F0h,0F0h,0F0h,0F0h,0F0h,0F0h,0F0h
ENDIF





