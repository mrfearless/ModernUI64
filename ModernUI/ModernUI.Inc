;======================================================================================================================================
;
; ModernUI x64 Library v0.0.0.5
;
; Copyright (c) 2016 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/ModernUI
;
;
; This software is provided 'as-is', without any express or implied warranty. In no event will the author be held liable for any 
; damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any non-commercial program. If you use the library in an application, an 
; acknowledgement in the application or documentation is appreciated but not required. 
;
; You are allowed to make modifications to the source code, but you must leave the original copyright notices intact and not 
; misrepresent the origin of the software. It is not allowed to claim you wrote the original software. Modified files must have a clear 
; notice that the files are modified, and not in the original state. This includes the name of the person(s) who modified the code. 
;
; If you want to distribute or redistribute any portion of this package, you will need to include the full package in it's original 
; state, including this license and all the copyrights. 
;
; While distributing this package (in it's original state) is allowed, it is not allowed to charge anything for this. You may not sell
; or include the package in any commercial package without having permission of the author. Neither is it allowed to redistribute any 
; of the package's components with commercial applications.
;
;======================================================================================================================================



;--------------------------------------------------------------------------------------------------------------------------------------
; PUBLIC ModernUI Prototypes for users of controls
;--------------------------------------------------------------------------------------------------------------------------------------
MUIGetExtProperty               PROTO :QWORD, :QWORD                   ; hControl, dqProperty
MUISetExtProperty               PROTO :QWORD, :QWORD, :QWORD           ; hControl, dqProperty, dqPropertyValue
MUIGetIntProperty               PROTO :QWORD, :QWORD                   ; hControl, dqProperty
MUISetIntProperty               PROTO :QWORD, :QWORD, :QWORD           ; hControl, dqProperty, dqPropertyValue

MUIPointSizeToLogicalUnit       PROTO :QWORD, :QWORD                   ; hControl, dqPointSize
MUIApplyToDialog                PROTO :QWORD, :QWORD                   ; hDialogWindow, dqDropShadow (true to set drop shadow)
MUICenterWindow                 PROTO :QWORD, :QWORD                   ; hWndChild, hWndParent
MUIPaintBackground              PROTO :QWORD, :QWORD, :QWORD           ; hDialogWindow, dqBackColor, dqBorderColor
MUIPaintBackgroundImage         PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD ; hDialogWindow, dqBackColor, dqBorderColor, hImage, dqImageType, dqImageLocation
MUIGetParentBackgroundColor     PROTO :QWORD                           ; hControl
MUIGetImageSize                 PROTO :QWORD, :QWORD, :QWORD, :QWORD   ; hImage, dqImageType, lpdqImageWidth, lpdqImageHeight

MUILoadRegionFromResource       PROTO :QWORD, :QWORD, :QWORD, :QWORD   ; hInstance, idRgnRes, lpRegion, lpqwSizeRegion
MUISetRegionFromResource        PROTO :QWORD, :QWORD, :QWORD, :QWORD   ; hWin, idRgnRes, lpqwCopyRgn, bRedraw

;--------------------------------------------------------------------------------------------------------------------------------------
; PRIVATE ModernUI Prototypes for control creators to use with their controls
;--------------------------------------------------------------------------------------------------------------------------------------
MUIGDIPlusStart                 PROTO                                  ; Wrapper for GDIPlus startup
MUIGDIPlusFinish                PROTO                                  ; Wrapper for GDIPlus shutdown

MUIAllocMemProperties           PROTO :QWORD, :QWORD, :QWORD           ; hControl, cbWndExtraOffset, dqSizeToAllocate
MUIFreeMemProperties            PROTO :QWORD, :QWORD                   ; hControl, cbWndExtraOffset

MUIAllocStructureMemory         PROTO :QWORD, :QWORD, :QWORD           ; dqPtrStructMem, TotalItems, ItemSize
MUICreateIconFromMemory         PROTO :QWORD, :QWORD                   ; pIconData, iIcon

;--------------------------------------------------------------------------------------------------------------------------------------
; LTLI ModernUI Structures
;--------------------------------------------------------------------------------------------------------------------------------------


.CONST
;--------------------------------------------------------------------------------------------------------------------------------------
; LTLI ModernUI Constants
;--------------------------------------------------------------------------------------------------------------------------------------
MUI_INTERNAL_PROPERTIES         EQU 0
MUI_EXTERNAL_PROPERTIES         EQU 8


; ModernUI Custom Messages - each control should handle these
MUI_GETPROPERTY                 EQU WM_USER + 1800                      ; wParam = dqProperty, lParam = NULL
MUI_SETPROPERTY                 EQU WM_USER + 1799                      ; wParam = dqProperty, lParam = dqPropertyValue
;MUI_GETTHEME                    EQU WM_USER + 1798                      ; wParam = NULL, lParam = NULL. Returns in eax lpMUITHEMEStructure
;MUI_SETTHEME                    EQU WM_USER + 1797                      ; wParam = lpMUITHEMEStructure, lParam = NULL


; Image Types
MUIIT_NONE                      EQU 0
MUIIT_BMP                       EQU 1
MUIIT_ICO                       EQU 2
MUIIT_PNG                       EQU 3

; Image Locations
MUIIL_CENTER                    EQU 0
MUIIL_BOTTOMLEFT                EQU 1
MUIIL_BOTTOMRIGHT               EQU 2
MUIIL_TOPLEFT                   EQU 3
MUIIL_TOPRIGHT                  EQU 4
MUIIL_TOPCENTER                 EQU 5
MUIIL_BOTTOMCENTER              EQU 6



; ModernUI Alpha Red Green Blue Macro
MUI_ARGBCOLOR MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

AlphaRGB MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

; ModernUI Red Green Blue Macro
MUI_RGBCOLOR MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM

RGB MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM





















