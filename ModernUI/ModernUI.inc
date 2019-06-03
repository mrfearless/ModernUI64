;==============================================================================
;
; ModernUI Library x64 v0.0.0.5
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
; ModernUI64 Prototypes for users of controls
;------------------------------------------------------------------------------
; ModernUI Base Functions:
MUIGetExtProperty               PROTO :QWORD,:QWORD                             ; hControl, qwProperty
MUISetExtProperty               PROTO :QWORD,:QWORD,:QWORD                      ; hControl, qwProperty, qwPropertyValue
MUIGetIntProperty               PROTO :QWORD,:QWORD                             ; hControl, qwProperty
MUISetIntProperty               PROTO :QWORD,:QWORD,:QWORD                      ; hControl, qwProperty, qwPropertyValue

; ModernUI Memory Functions:
MUIAllocMemProperties           PROTO :QWORD,:QWORD,:QWORD                      ; hControl, cbWndExtraOffset, qwSizeToAllocate
MUIFreeMemProperties            PROTO :QWORD,:QWORD                             ; hControl, cbWndExtraOffset
MUIAllocStructureMemory         PROTO :QWORD,:QWORD,:QWORD                      ; qwPtrStructMem, TotalItems, ItemSize

; ModernUI GDI DoubleBuffer Functions:
MUIGDIDoubleBufferStart         PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD ; hWin, hdcSource, lpHDCBuffer, lpClientRect, lpBufferBitmap, lpPreBufferBitamp
MUIGDIDoubleBufferFinish        PROTO :QWORD,:QWORD,:QWORD                      ; hdcBuffer, hBufferBitmap, hPreBufferBitamp

; ModernUI GDIPlus Functions:
MUIGDIPlusStart                 PROTO                                           ; Wrapper for GDIPlus startup
MUIGDIPlusFinish                PROTO                                           ; Wrapper for GDIPlus shutdown

; ModernUI Painting & Color Functions:
MUIPaintBackground              PROTO :QWORD,:QWORD,:QWORD                      ; hDialogWindow, qwBackColor, qwBorderColor
MUIPaintBackgroundImage         PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD ; hDialogWindow, qwBackColor, qwBorderColor, hImage, qwImageType, qwImageLocation
MUIGetParentBackgroundColor     PROTO :QWORD                                    ; hControl
MUIGetParentBackgroundBitmap    PROTO :QWORD                                    ; hControl

; ModernUI Window/Dialog Functions:
MUIApplyToDialog                PROTO :QWORD,:QWORD,:QWORD                      ; hDialogWindow, qwDropShadow (true to set drop shadow), qwClipping (true to set clipping on)
MUICenterWindow                 PROTO :QWORD,:QWORD                             ; hWndChild, hWndParent

; ModernUI Region Functions:
MUILoadRegionFromResource       PROTO :QWORD,:QWORD,:QWORD,:QWORD               ; hInstance, idRgnRes, lpRegion, lpqwSizeRegion
MUISetRegionFromResource        PROTO :QWORD,:QWORD,:QWORD,:QWORD               ; hWin, idRgnRes, lpqwCopyRgn, bRedraw

; ModernUI Font Functions:
MUIPointSizeToLogicalUnit       PROTO :QWORD,:QWORD                             ; hControl, qwPointSize

; ModernUI Image Functions:
MUIGetImageSize                 PROTO :QWORD,:QWORD,:QWORD,:QWORD               ; hImage, qwImageType, lpqwImageWidth, lpqwImageHeight
MUICreateIconFromMemory         PROTO :QWORD,:QWORD                             ; pIconData, iIcon
MUICreateCursorFromMemory       PROTO :QWORD                                    ; pCursorData
MUICreateBitmapFromMemory       PROTO :QWORD                                    ; pBitmapData

; ModernUI DPI & Scaling Functions:
MUIDPI                          PROTO :QWORD,:QWORD                             ; lpqwDPIX, lpqwDPIY
MUIDPIScaleX                    PROTO :QWORD                                    ; qwValueX
MUIDPIScaleY                    PROTO :QWORD                                    ; qwValueY
MUIDPIScaleRect                 PROTO :QWORD                                    ; lpRect
MUIDPIScaleControl              PROTO :QWORD,:QWORD,:QWORD,:QWORD               ; lpqwLeft, lpqwTop, lpqwWidth, lpqwHeight
MUIDPIScaleFontSize             PROTO :QWORD                                    ; qwPointSize
MUIDPIScaleFont                 PROTO :QWORD                                    ; hFont
MUIDPIScaledScreen              PROTO :QWORD,:QWORD                             ; lpqwScreenWidth, lpqwScreenHeight
MUIDPISetDPIAware               PROTO


.CONST
IFDEF MODERNUI_DLL
    MODERNUI_LIBEND TEXTEQU <>
ELSE
    MODERNUI_LIBEND TEXTEQU <END>
ENDIF

;------------------------------------------
; Define MUI_USEGDIPLUS to compile
; gdiplus support into ModernUI library 
; Other controls can force this off by
; defining MUI_DONTUSEGDIPLUS if they
; wish to exclude gdiplus support
;------------------------------------------
IFNDEF MUI_DONTUSEGDIPLUS
MUI_USEGDIPLUS                  EQU 1
ENDIF

;------------------------------------------
; Global constants used by all ModernUI
; controls. 
;------------------------------------------
MUI_INTERNAL_PROPERTIES         EQU 0
MUI_EXTERNAL_PROPERTIES         EQU 8
MUI_INTERNAL_PROPERTIES_EXTRA   EQU 16              ; cbWndExtra offset for extra internal properties pointer
MUI_EXTERNAL_PROPERTIES_EXTRA   EQU 24              ; cbWndExtra offset for extra external properties pointer
MUI_PROPERTY_ADDRESS            EQU 80000000h       ; OR with dwProperty in MUIGetIntProperty/MUIGetExtProperty to return address of property

MUI_ALIGN                       TEXTEQU <ALIGN 16>

;------------------------------------------
; ModernUI Custom Messages - each control 
; should handle these
;------------------------------------------
MUI_GETPROPERTY                 EQU WM_USER + 1800  ; wParam = qwProperty, lParam = NULL
MUI_SETPROPERTY                 EQU WM_USER + 1799  ; wParam = qwProperty, lParam = qwPropertyValue
;MUI_GETTHEME                   EQU WM_USER + 1798  ; wParam = NULL, lParam = NULL. Returns in rax lpMUITHEMEStructure
;MUI_SETTHEME                   EQU WM_USER + 1797  ; wParam = lpMUITHEMEStructure, lParam = NULL

;------------------------------------------
; Image Types
;------------------------------------------
MUIIT_NONE                      EQU 0
MUIIT_BMP                       EQU 1
MUIIT_ICO                       EQU 2
MUIIT_PNG                       EQU 3

;------------------------------------------
; Image Locations
;------------------------------------------
MUIIL_CENTER                    EQU 0
MUIIL_BOTTOMLEFT                EQU 1
MUIIL_BOTTOMRIGHT               EQU 2
MUIIL_TOPLEFT                   EQU 3
MUIIL_TOPRIGHT                  EQU 4
MUIIL_TOPCENTER                 EQU 5
MUIIL_BOTTOMCENTER              EQU 6


;------------------------------------------
; ModernUI Macros
;------------------------------------------
MUI_ARGBCOLOR MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

AlphaRGB MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

MUI_RGBCOLOR MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM

RGB MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM

;------------------------------------------
; Notes
;------------------------------------------
; Custom controls: qwStyle parameter of 
; CreateWindowEx.
;
; The low 16 bits of the qwStyle parameter 
; are defined by the implementor of the 
; window class (by the person who calls 
; RegisterClass) - Raymond Chen
;
; 0x0h - 0xFFFFh reserved for user creating
; the control to define styles
;------------------------------------------


;------------------------------------------
; Remove comment to include debug64 macros
;------------------------------------------
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
;------------------------------------------


;------------------------------------------
; Remove comment to include unicode support
;------------------------------------------
;MUI_UNICODE TEXTEQU <__UNICODE__>
;IFDEF MUI_UNICODE
;__UNICODE__ EQU 1
;ECHO MUI_UNICODE BUILD
;ENDIF
;------------------------------------------



















