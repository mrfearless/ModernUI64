;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_CaptionBar x64 v1.0.0.0
;
; Copyright (c) 2016 by fearless
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
; ModernUI_CaptionBar Prototypes for users of controls
;--------------------------------------------------------------------------------------------------------------------------------------
MUICaptionBarRegister       PROTO                                           ; Use 'ModernUICaptionBar' as class in RadASM custom class control
MUICaptionBarCreate		    PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD    ; hWndParent, lpszCaptionText, qwCaptionHeight, qwResourceID, qwStyle
MUICaptionBarSetProperty    PROTO :QWORD, :QWORD, :QWORD                    ; hCaptionBar, qwProperty, qwPropertyValue
MUICaptionBarGetProperty    PROTO :QWORD, :QWORD                            ; hCaptionBar, qwProperty
MUICaptionBarLoadIcons      PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD ; hCaptionBar, idResMin, idResMinAlt, idResMax, idResMaxAlt, idResRes, idResResAlt, idResClose, idResCloseAlt
MUICaptionBarLoadIconsDll   PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD ; hCaptionBar, hInstance, idResMin, idResMinAlt, idResMax, idResMaxAlt, idResRes, idResResAlt, idResClose, idResCloseAlt
MUICaptionBarLoadBackImage  PROTO :QWORD, :QWORD, :QWORD                    ; hCaptionBar, qwImageType, qwResIDImage

;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Caption Structures
;--------------------------------------------------------------------------------------------------------------------------------------


.CONST
;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Caption Constants
;--------------------------------------------------------------------------------------------------------------------------------------

; CaptionBar Styles
MUICS_LEFT                  EQU 0h   ; left align caption bar text
MUICS_CENTER                EQU 1h   ; center align caption bar text
MUICS_NOMINBUTTON           EQU 2h   ; no minimize button
MUICS_NOMAXBUTTON           EQU 4h   ; no maximize/restore button
MUICS_NOCLOSEBUTTON         EQU 8h   ; no close button
MUICS_REDCLOSEBUTTON        EQU 10h  ; close button uses win8+ red background color
MUICS_NOMOVEWINDOW          EQU 20h  ; Dont allow window to move when caption bar is clicked and dragged, if not specified will allow this.
MUICS_WINNOMUISTYLE         EQU 40h  ; Dont apply MUI borderless frame style to window/dialog, if not specified will apply MUI style.
MUICS_WINNODROPSHADOW       EQU 80h  ; Dont apply drop shadow to window/dialog. If not specified will apply dropshadow if MUICS_WINDOWNOMUISTYLE not specified.
MUICS_USEICONSFORBUTTONS    EQU 100h ; Use icons instead of text for the min/max/res/close buttons: Load icons via the MUICaptionBarLoadIcons functions or set handles via @CaptionBarBtnIcoXXX properties
MUICS_KEEPICONS             EQU 200h ; Dont delete icons handles when control is destoyed. Essential if icon handles are used in multiple controls or where set directly with properties 
MUICS_NOCAPTIONTITLETEXT    EQU 400h ; Dont draw a title text value, use lpszCaptionText for taskbar name of app only.

;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Caption Properties: Use with MUICaptionBarSetProperty / MUICaptionBarGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
;--------------------------------------------------------------------------------------------------------------------------------------
@CaptionBarTextColor        EQU 0   ; Text color for caption text and system buttons (min/max/restore/close)
@CaptionBarTextFont	        EQU 8   ; Font for caption text
@CaptionBarBackColor        EQU 16  ; Background color of caption and system buttons
@CaptionBarBackImageType    EQU 24  ; Image Type - One of the following: MUICBIT_NONE,MUICBIT_BMP, MUICBIT_ICO, MUICBIT_PNG
@CaptionBarBackImage        EQU 32  ; hImage
@CaptionBarBtnTxtRollColor  EQU 40  ; Text color for system buttons when mouse moves over button
@CaptionBarBtnBckRollColor  EQU 48  ; Background color for system buttons when mouse moves over button
@CaptionBarBtnWidth         EQU 56  ; System buttons width, defaults to 32px
@CaptionBarBtnHeight        EQU 64  ; System buttons height, defaults to 24px
@CaptionBarBtnIcoMin        EQU 72  ; hIcon for minimize button
@CaptionBarBtnIcoMinAlt     EQU 80  ; hIcon for minimize button when mouse moves over button
@CaptionBarBtnIcoMax        EQU 88  ; hIcon for maximize button
@CaptionBarBtnIcoMaxAlt     EQU 96  ; hIcon for maximize button when mouse moves over button
@CaptionBarBtnIcoRes        EQU 104 ; hIcon for restore button
@CaptionBarBtnIcoResAlt     EQU 112 ; hIcon for restore button when mouse moves over button
@CaptionBarBtnIcoClose      EQU 120 ; hIcon for close button
@CaptionBarBtnIcoCloseAlt   EQU 128 ; hIcon for close button when mouse moves over button
@CaptionBarDllInstance      EQU 136 ; hInstance for loading resources (icons) - normally set to 0 (current module) but when resources are in a dll set this before calling MUICaptionBarLoadIcons
@CaptionBarParam            EQU 144 ; Custom user data

; CaptionBar Back Image Types
MUICBIT_NONE                EQU 0
MUICBIT_BMP                 EQU 1
MUICBIT_ICO                 EQU 2
MUICBIT_PNG                 EQU 3






