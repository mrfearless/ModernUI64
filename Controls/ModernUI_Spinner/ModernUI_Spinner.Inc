;==============================================================================
;
; ModernUI x64 Control - ModernUI_Spinner x64
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

;------------------------------------------------------------------------------
; ModernUI_Spinner Prototypes
;------------------------------------------------------------------------------
MUISpinnerRegister		    PROTO								                    ; Use 'ModernUI_Spinner' as class in RadASM custom class control
MUISpinnerCreate		    PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD  ; hWndParent, xpos, ypos, qwWidth, qwHeight, qwResourceID, qwStyle
MUISpinnerSetProperty	    PROTO :QWORD,:QWORD,:QWORD						        ; hModernUI_Spinner, qwProperty, qwPropertyValue
MUISpinnerGetProperty	    PROTO :QWORD,:QWORD					                    ; hModernUI_Spinner, qwProperty

; Add image handle (bitmap, icon or png) as a spinner frame image
MUISpinnerAddFrame          PROTO :QWORD,:QWORD,:QWORD						        ; hModernUI_Spinner, qwImageType, hImage
MUISpinnerAddFrames         PROTO :QWORD,:QWORD,:QWORD,:QWORD                       ; hModernUI_Spinner, qwCount, qwImageType, lpArrayImageHandles
; Load an image resource id (bitmap, icon or png) as a spinner frame image
MUISpinnerLoadFrame         PROTO :QWORD,:QWORD,:QWORD						        ; hModernUI_Spinner, qwImageType, idResImage
MUISpinnerLoadFrames        PROTO :QWORD,:QWORD,:QWORD,:QWORD                       ; hModernUI_Spinner, qwCount, qwImageType, lpArrayResourceIDs
; Create a series of spinner frame images from an individual png handle/resid
MUISpinnerAddImage          PROTO :QWORD,:QWORD,:QWORD,:QWORD                       ; hModernUI_Spinner, hImage, qwNoFramesToCreate, bReverse
MUISpinnerLoadImage         PROTO :QWORD,:QWORD,:QWORD,:QWORD                       ; hModernUI_Spinner, idResImage, qwNoFramesToCreate, bReverse
; Create a series of spinner frame images from a sprite sheet
MUISpinnerAddSpriteSheet    PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD                ; hModernUI_Spinner, qwSpriteCount, qwImageType, hImageSpriteSheet, bReverse
MUISpinnerLoadSpriteSheet   PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD                ; hModernUI_Spinner, qwSpriteCount, qwImageType, idResSpriteSheet, bReverse

; Spinner animation control
MUISpinnerEnable            PROTO :QWORD                                            ; hModernUI_Spinner
MUISpinnerDisable           PROTO :QWORD                                            ; hModernUI_Spinner
MUISpinnerReset             PROTO :QWORD                                            ; hModernUI_Spinner
MUISpinnerPause             PROTO :QWORD                                            ; hModernUI_Spinner
MUISpinnerResume            PROTO :QWORD                                            ; hModernUI_Spinner
MUISpinnerSpeed             PROTO :QWORD,:QWORD                                     ; hModernUI_Spinner, qwMillisecSpeed


;------------------------------------------------------------------------------
; ModernUI_Spinner Messages
;------------------------------------------------------------------------------
MUISPNM_ADDFRAME            EQU WM_USER+1752 ; wParam = qwImageType, lParam = hImage
MUISPNM_LOADFRAME           EQU WM_USER+1751 ; wParam = qwImageType, lParam = idResImage
MUISPNM_ENABLE              EQU WM_USER+1750 ; wParam & lParam = NULL
MUISPNM_DISABLE             EQU WM_USER+1749 ; wParam & lParam = NULL
MUISPNM_RESET               EQU WM_USER+1748 ; wParam & lParam = NULL
MUISPNM_PAUSE               EQU WM_USER+1747 ; wParam & lParam = NULL
MUISPNM_RESUME              EQU WM_USER+1746 ; wParam & lParam = NULL
MUISPNM_SPEED               EQU WM_USER+1745 ; wParam = qwMillisecSpeed

.CONST
;------------------------------------------------------------------------------
; ModernUI_Spinner Constants
;------------------------------------------------------------------------------

; ModernUI_Spinner Styles
MUISPNS_HAND                EQU 20h     ; Show a hand instead of an arrow when mouse moves over spinner.

;------------------------------------------------------------------------------
; ModernUI_Spinner Properties: Use with MUISpinnerSetProperty / 
; MUISpinnerGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
;------------------------------------------------------------------------------
@SpinnerBackColor           EQU 0   ; Background color of spinner
@SpinnerSpeed               EQU 8   ; milliseconds until next spin stage or rotation occurs
@SpinnerDllInstance         EQU 16

; Spinner Image Type:
MUISPIT_NONE                EQU 0
MUISPIT_BMP                 EQU 1
MUISPIT_ICO                 EQU 2
MUISPIT_PNG                 EQU 3





