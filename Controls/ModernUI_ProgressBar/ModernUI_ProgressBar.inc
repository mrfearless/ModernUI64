;==============================================================================
;
; ModernUI x64 Control - ModernUI_ProgressBar x64
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

;------------------------------------------------------------------------------
; ModernUI_ProgressBar Prototypes
;------------------------------------------------------------------------------
MUIProgressBarRegister      PROTO                                                   ; Use 'ModernUI_ProgressBar' as class in RadASM custom class control
MUIProgressBarCreate        PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD  ; hWndParent, lpszText, xpos, ypos, qwWidth, qwHeight, qwResourceID, qwStyle
MUIProgressBarSetProperty   PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_ProgressBar, qwProperty, qwPropertyValue
MUIProgressBarGetProperty   PROTO :QWORD,:QWORD                                     ; hModernUI_ProgressBar, qwProperty

MUIProgressBarSetMinMax     PROTO :QWORD,:QWORD,:QWORD
MUIProgressBarSetPercent    PROTO :QWORD,:QWORD
MUIProgressBarGetPercent    PROTO :QWORD
MUIProgressBarStep          PROTO :QWORD


.CONST
;------------------------------------------------------------------------------
; ModernUI_ProgressBar Messages
;------------------------------------------------------------------------------
MUIPBM_STEP                 EQU WM_USER + 1750
MUIPBM_SETPERCENT           EQU WM_USER + 1749


;------------------------------------------------------------------------------
; ModernUI_ProgressBar Styles
;------------------------------------------------------------------------------
MUIPBS_PULSE                EQU 0   ; Show pulse hearbeat on progress (default)
MUIPBS_NOPULSE              EQU 1   ; Dont show pulse heartbeat on progress
MUIPBS_TEXT_NONE            EQU 0   ; Dont show % text (default)
MUIPBS_TEXT_CENTRE          EQU 2   ; Show % text in centre of progress control
MUIPBS_TEXT_FOLLOW          EQU 4   ; Show % text and follow progress bar 
MUIPBS_R2G                  EQU 8   ; Show a fading red to green progress bar


;------------------------------------------------------------------------------
; ModernUI_ProgressBar Properties: Use with MUIProgressBarSetProperty / 
; MUIProgressBarGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
;------------------------------------------------------------------------------
@ProgressBarTextColor       EQU 0   ; RGBCOLOR. Text color
@ProgressBarTextFont        EQU 8   ; HFONT. Font
@ProgressBarBackColor       EQU 16  ; RGBCOLOR. Background color
@ProgressBarProgressColor   EQU 24  ; RGBCOLOR. Progress bar color
@ProgressBarBorderColor     EQU 32  ; RGBCOLOR. Border color
@ProgressBarPercent         EQU 40  ; QWORD. Current percent - get or set
@ProgressBarMin             EQU 48  ; QWORD. Set min value (not used currently)
@ProgressBarMax             EQU 56  ; QWORD. Set max value (not used currently)
@ProgressBarStep            EQU 64  ; QWORD. Amount to step by (default 1) (not used currently)
@ProgressBarPulse           EQU 72  ; BOOL. Use pulse glow on bar. (default TRUE)
@ProgressBarPulseTime       EQU 80  ; QWORD. Milliseconds until pulse (default 3000ms)
@ProgressBarTextType        EQU 88  ; QWORD. (Default 0) dont show. 1=show centre, 2=follow progress
@ProgressBarSetTextPos      EQU 96  ; QWORD. (Default 0) 0 = preppend WM_SETTEXT text, 1 = append WM_SETTEXT text (not used currently)

; ProgressBar Text Type:
MUIPBTT_NONE                EQU 0   ; No percentage text in progress bar (default)
MUIPBTT_CENTRE              EQU 1   ; Percentage text in center of progress bar
MUIPBTT_FOLLOW              EQU 2   ; Percentage text follows progress as it draws









