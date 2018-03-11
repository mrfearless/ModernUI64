;======================================================================================================================================
;
; ModernUI Control - ModernUI_Checkbox x64 v1.0.0.0
;
; Copyright (c) 2017 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/ModernUI64
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
; ModernUI_Checkbox Prototypes
;--------------------------------------------------------------------------------------------------------------------------------------
MUICheckboxRegister		        PROTO																	; Use 'ModernUI_Checkbox' as class in RadASM custom class control
MUICheckboxCreate		        PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD	; hWndParent, lpszText, xpos, ypos, dqWidth, dqHeight, dqResourceID, dqStyle
MUICheckboxSetProperty	        PROTO :QWORD, :QWORD, :QWORD											; hModernUI_Checkbox, dqProperty, dqPropertyValue
MUICheckboxGetProperty	        PROTO :QWORD, :QWORD													; hModernUI_Checkbox, dqProperty
MUICheckboxGetState             PROTO :QWORD                                                            ; hModernUI_Checkbox
MUICheckboxSetState             PROTO :QWORD, :QWORD                                                    ; hModernUI_Checkbox, bState

MUICheckboxLoadImages           PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD    ; hModernUI_Checkbox, dqImageType, dqResIDImage, dqResIDImageAlt, dqResIDImageSel, dqResIDImageSelAlt, dqResIDImageDisabled, dqResIDImageDisabledSel
MUICheckboxSetImages            PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD    ; hModernUI_Checkbox, dqImageType, hImage, hImageAlt, hImageSel, hImageSelAlt, hImageDisabled, hImageDisabledSel


;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Checkbox Structures
;--------------------------------------------------------------------------------------------------------------------------------------
IFNDEF MUI_CHECKBOX_PROPERTIES
MUI_CHECKBOX_PROPERTIES         STRUCT
    dqTextFont                  DQ ?       ; hFont
    dqTextColor                 DQ ?       ; Colorref
    dqTextColorAlt              DQ ?       ; Colorref
    dqTextColorSel              DQ ?       ; Colorref
    dqTextColorSelAlt           DQ ?       ; Colorref
    dqTextColorDisabled         DQ ?       ; Colorref
    dqBackColor                 DQ ?       ; Colorref
    dqImageType                 DQ ?       ; image type
    dqImage                     DQ ?       ; hImage for empty checkbox
    dqImageAlt                  DQ ?       ; hImage for empty checkbox when mouse moves over checkbox
    dqImageSel                  DQ ?       ; hImage for checkbox with checkmark
    dqImageSelAlt               DQ ?       ; hImage for checkbox with checkmark when mouse moves over checkbox
    dqImageDisabled             DQ ?       ; hImage for disabled empty checkbox
    dqImageDisabledSel          DQ ?       ; hImage for disabled checkbox with checkmark
    dqCheckboxDllInstance       DQ ?
MUI_CHECKBOX_PROPERTIES			ENDS
ENDIF

.CONST
;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Checkbox Constants
;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Checkbox Messages
MUICM_GETSTATE                  EQU WM_USER + 1779 ; wParam = NULL, lParam = NULL. EAX contains state (TRUE/FALSE)
MUICM_SETSTATE                  EQU WM_USER + 1778 ; wParam = TRUE/FALSE, lParam = NULL

; ModernUI_Checkbox Styles
MUICS_CHECK                     EQU 00h     ;
MUICS_RADIO                     EQU 01h     ;
MUICS_HAND                      EQU 20h     ; Show a hand instead of an arrow when mouse moves over checkbox.

;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Checkbox Properties: Use with MUICheckboxSetProperty / MUICheckboxGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
;--------------------------------------------------------------------------------------------------------------------------------------
@CheckboxTextFont	            EQU 0       ; Font for checkbox text
@CheckboxTextColor              EQU 8       ; Colorref Text color for checkbox
@CheckboxTextColorAlt           EQU 16       ; Colorref
@CheckboxTextColorSel           EQU 24      ; Colorref
@CheckboxTextColorSelAlt        EQU 32      ; Colorref
@CheckboxTextColorDisabled      EQU 40      ; Colorref
@CheckboxBackColor              EQU 48      ; Colorref
@CheckboxImageType              EQU 56     ; Button Image Types - One of the following: MUICIT_NONE, MUICIT_BMP, MUICIT_ICO or MUICIT_PNG
@CheckboxImage                  EQU 64     ; hImage
@CheckboxImageAlt               EQU 72     ; hImage
@CheckboxImageSel               EQU 80     ; hImage
@CheckboxImageSelAlt            EQU 88     ; hImage
@CheckboxImageDisabled          EQU 96     ; hImage
@CheckboxImageDisabledSel       EQU 104     ; hImage
@CheckboxDllInstance            EQU 112     ; Set to hInstance of dll before calling MUICheckboxLoadImages if used within a dll


; Checkbox Image Types
MUICIT_NONE                     EQU 0
MUICIT_BMP                      EQU 1
MUICIT_ICO                      EQU 2
MUICIT_PNG                      EQU 3









