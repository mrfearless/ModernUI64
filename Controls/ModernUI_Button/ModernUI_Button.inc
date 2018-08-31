;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_Button x64 v1.0.0.0
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
; ModernUI_Button Prototypes
;--------------------------------------------------------------------------------------------------------------------------------------
MUIButtonRegister		        PROTO																	; Use 'ModernUI_Button' as class in RadASM custom class control
MUIButtonCreate		            PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD	; hWndParent, lpszText, xpos, ypos, qwWidth, qwHeight, qwResourceID, qwStyle
MUIButtonSetProperty	        PROTO :QWORD, :QWORD, :QWORD											; hModernUI_Button, qwProperty, qwPropertyValue
MUIButtonGetProperty	        PROTO :QWORD, :QWORD													; hModernUI_Button, qwProperty
MUIButtonGetState               PROTO :QWORD                                                            ; hModernUI_Button
MUIButtonSetState               PROTO :QWORD, :QWORD                                                    ; hModernUI_Button, bState

MUIButtonLoadImages             PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD            ; hModernUI_Button, qwImageType, qwResIDImage, qwResIDImageAlt, qwResIDImageSel, qwResIDImageSelAlt, qwResIDImageDisabled
MUIButtonSetImages              PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD            ; hModernUI_Button, qwImageType, hImage, hImageAlt, hImageSel, hImageSelAlt, hImageDisabled

MUIButtonNotifySetText          PROTO :QWORD, :QWORD, :QWORD                                            ; hModernUI_Button, lpszNotifyText, bRedraw
MUIButtonNotifyLoadImage        PROTO :QWORD, :QWORD, :QWORD                                            ; hModernUI_Button, qwImageType, qwResIDNotifyImage
MUIButtonNotifySetImage         PROTO :QWORD, :QWORD, :QWORD                                            ; hModernUI_Button, qwImageType, hNotifyImage
MUIButtonNotifySetFont          PROTO :QWORD, :QWORD, :QWORD                                            ; hModernUI_Button, hFont, bRedraw
MUIButtonNotify                 PROTO :QWORD, :QWORD                                                    ; hModernUI_Button, bNotify

MUIButtonNoteSetText            PROTO :QWORD, :QWORD, :QWORD                                            ; hModernUI_Button, lpszNoteText, bRedraw
MUIButtonNoteSetFont            PROTO :QWORD, :QWORD, :QWORD                                            ; hModernUI_Button, hFont, bRedraw

MUIButtonSetAllProperties       PROTO :QWORD, :QWORD, :QWORD                                            ; hModernUI_Button, lpMUI_BUTTON_PROPERTIES structure, SIZEOF MUI_BUTTON_PROPERTIES






;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Button Structures
;--------------------------------------------------------------------------------------------------------------------------------------


.CONST
;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Button Constants
;--------------------------------------------------------------------------------------------------------------------------------------
IFNDEF MUI_BUTTON_PROPERTIES
MUI_BUTTON_PROPERTIES           STRUCT
    qwTextFont                  DQ ?       ; hFont
    qwTextColor                 DQ ?       ; Colorref
    qwTextColorAlt              DQ ?       ; Colorref
    qwTextColorSel              DQ ?       ; Colorref
    qwTextColorSelAlt           DQ ?       ; Colorref
    qwTextColorDisabled         DQ ?       ; Colorref
    qwBackColor                 DQ ?       ; Colorref
    qwBackColorAlt              DQ ?       ; Colorref
    qwBackColorSel              DQ ?       ; Colorref
    qwBackColorSelAlt           DQ ?       ; Colorref
    qwBackColorDisabled         DQ ?       ; Colorref
    qwBorderColor               DQ ?       ; Colorref
    qwBorderColorAlt            DQ ?       ; Colorref
    qwBorderColorSel            DQ ?       ; Colorref
    qwBorderColorSelAlt         DQ ?       ; Colorref
    qwBorderColorDisabled       DQ ?       ; Colorref
    qwBorderStyle               DQ ?       ; Button Border Styles
    qwAccentColor               DQ ?       ; Colorref
    qwAccentColorAlt            DQ ?       ; Colorref
    qwAccentColorSel            DQ ?       ; Colorref
    qwAccentColorSelAlt         DQ ?       ; Colorref
    qwAccentStyle               DQ ?       ; Button Accent Styles
    qwAccentStyleAlt            DQ ?       ; Button Accent Styles
    qwAccentStyleSel            DQ ?       ; Button Accent Styles
    qwAccentStyleSelAlt         DQ ?       ; Button Accent Styles
    qwImageType                 DQ ?       ; hImage
    qwImage                     DQ ?       ; hImage - Left or center image
    qwImageAlt                  DQ ?       ; hImage - Left or center image
    qwImageSel                  DQ ?       ; hImage - Left or center image
    qwImageSelAlt               DQ ?       ; hImage - Left or center image
    qwImageDisabled             DQ ?       ; hImage - Left or center image
	qwRightImage                DQ ?       ; hImage - Right side image
	qwRightImageAlt             DQ ?       ; hImage - Right side image
	qwRightImageSel             DQ ?       ; hImage - Right side image
	qwRightImageSelAlt          DQ ?       ; hImage - Right side image
	qwRightImageDisabled        DQ ?       ; hImage - Right side image
    qwNotifyTextFont            DQ ?       ; hFont
    qwNotifyTextColor           DQ ?       ; Colorref
    qwNotifyBackColor           DQ ?       ; Colorref
    qwNotifyRound               DQ ?       ; Roundrect x,y value
    qwNotifyImageType           DQ ?       ; Button Image Types
    qwNotifyImage               DQ ?       ; hImage
    qwButtonNoteTextFont        DQ ?       ; hFont
    qwButtonNoteTextColor       DQ ?       ; Colorref
    qwButtonNoteTextColorDisabled DQ ?     ; Colorref
    qwButtonPaddingLeftIndent   DQ ?       ; 
    qwButtonPaddingGeneral      DQ ?       ; 
    qwButtonPaddingStyle        DQ ?       ; 
    qwButtonPaddingTextImage    DQ ?       ; 
    qwButtonDllInstance         DQ ?
MUI_BUTTON_PROPERTIES			ENDS
ENDIF

.CONST
;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Button Constants
;--------------------------------------------------------------------------------------------------------------------------------------

; ModernUI_Button Messages
MUIBM_GETSTATE                  EQU WM_USER + 1779 ; wParam = NULL, lParam = NULL. EAX contains state (TRUE/FALSE)
MUIBM_SETSTATE                  EQU WM_USER + 1778 ; wParam = TRUE/FALSE, lParam = NULL

MUIBM_NOTIFYSETTEXT             EQU WM_USER + 1777 ; wParam = lpszNotifyText, lParam = Redraw TRUE/FALSE
MUIBM_NOTIFYSETIMAGE            EQU WM_USER + 1776 ; wParam = qwImageType, lParam = Handle of Image
MUIBM_NOTIFYLOADIMAGE           EQU WM_USER + 1775 ; wParam = qwImageType, lParam = ResourceID
MUIBM_NOTIFYSETFONT             EQU WM_USER + 1774 ; wParam = hFont, lParam = TRUE/FALSE to redraw control
MUIBM_NOTIFY                    EQU WM_USER + 1773 ; wParam = TRUE/FALSE to notify or clear notification, lParam = NULL

MUIBM_NOTESETTEXT               EQU WM_USER + 1772 ; wParam = lpszNoteText, lParam = TRUE/FALSE to redraw control
MUIBM_NOTESETFONT               EQU WM_USER + 1771 ; wParam = hFont, lParam = TRUE/FALSE to redraw control

; ModernUI_Button Styles
MUIBS_LEFT                      EQU 1       ; Align text to the left of the button
MUIBS_BOTTOM                    EQU 2       ; Place image at the top, and text below
MUIBS_CENTER                    EQU 4       ; Align text centerally.
MUIBS_AUTOSTATE                 EQU 8       ; Automatically toggle between TRUE/FALSE state when clicked. TRUE = Selected.
MUIBS_PUSHBUTTON                EQU 10h     ; Simulate button movement down slightly when mouse click and movement up again when mouse is released.
MUIBS_HAND                      EQU 20h     ; Show a hand instead of an arrow when mouse moves over button.
MUIBS_KEEPIMAGES                EQU 40h     ; Dont delete image handles when control is destoyed. Essential if image handles are used in multiple controls.
MUIBS_DROPDOWN                  EQU 80h     ; Show dropdown arrow right side of control


;--------------------------------------------------------------------------------------------------------------------------------------
; ModernUI_Button Properties: Use with MUIButtonSetProperty / MUIButtonGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
;--------------------------------------------------------------------------------------------------------------------------------------


@ButtonTextFont                 EQU 0       ; hFont
@ButtonTextColor                EQU 8       ; Colorref
@ButtonTextColorAlt             EQU 16      ; Colorref
@ButtonTextColorSel             EQU 24      ; Colorref
@ButtonTextColorSelAlt          EQU 32      ; Colorref
@ButtonTextColorDisabled        EQU 40      ; Colorref
@ButtonBackColor                EQU 48      ; Colorref
@ButtonBackColorAlt             EQU 56      ; Colorref
@ButtonBackColorSel             EQU 64      ; Colorref
@ButtonBackColorSelAlt          EQU 72      ; Colorref
@ButtonBackColorDisabled        EQU 80      ; Colorref
@ButtonBorderColor              EQU 88      ; Colorref
@ButtonBorderColorAlt           EQU 96      ; Colorref
@ButtonBorderColorSel           EQU 104     ; Colorref
@ButtonBorderColorSelAlt        EQU 112     ; Colorref
@ButtonBorderColorDisabled      EQU 120     ; Colorref
@ButtonBorderStyle              EQU 128     ; Button Border Styles - Either MUIBBS_NONE, MUIBBS_ALL or a combination of MUIBBS_LEFT, MUIBBS_TOP, MUIBBS_BOTTOM, MUIBBS_RIGHT
@ButtonAccentColor              EQU 136     ; Colorref
@ButtonAccentColorAlt           EQU 144     ; Colorref
@ButtonAccentColorSel           EQU 152     ; Colorref
@ButtonAccentColorSelAlt        EQU 160     ; Colorref
@ButtonAccentStyle              EQU 168     ; Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
@ButtonAccentStyleAlt           EQU 176     ; Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
@ButtonAccentStyleSel           EQU 184     ; Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
@ButtonAccentStyleSelAlt        EQU 192      ; Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
@ButtonImageType                EQU 200     ; Button Image Types - One of the following: MUIBIT_NONE, MUIBIT_BMP, MUIBIT_ICO or MUIBIT_PNG
@ButtonImage                    EQU 208     ; hImage
@ButtonImageAlt                 EQU 216     ; hImage
@ButtonImageSel                 EQU 224     ; hImage
@ButtonImageSelAlt              EQU 232     ; hImage
@ButtonImageDisabled            EQU 240     ; hImage
@ButtonRightImage               EQU 248     ; hImage - Right side image
@ButtonRightImageAlt            EQU 256     ; hImage - Right side image
@ButtonRightImageSel            EQU 264     ; hImage - Right side image
@ButtonRightImageSelAlt         EQU 272     ; hImage - Right side image
@ButtonRightImageDisabled       EQU 280     ; hImage - Right side image
@ButtonNotifyTextFont           EQU 288     ; hFont
@ButtonNotifyTextColor          EQU 296     ; Colorref
@ButtonNotifyBackColor          EQU 304     ; Colorref
@ButtonNotifyRound              EQU 312     ; qwPixels - Roundrect x,y value
@ButtonNotifyImageType          EQU 320     ; Button Image Types - One of the following: MUIBIT_NONE, MUIBIT_BMP, MUIBIT_ICO or MUIBIT_PNG
@ButtonNotifyImage              EQU 328     ; hImage
@ButtonNoteTextFont             EQU 336     ; hFont
@ButtonNoteTextColor            EQU 344     ; Colorref
@ButtonNoteTextColorDisabled    EQU 352     ; Colorref
@ButtonPaddingLeftIndent        EQU 360     ; qwPixels - No of pixels to indent images + text (or just text if no images). Defaults to 0 when control is created
@ButtonPaddingGeneral           EQU 368     ; qwPixels - No of pixels of padding to apply based on @ButtonPaddingStyle: Defaults to 4px when control is created.
@ButtonPaddingStyle             EQU 376     ; Button Padding Style - Where to apply @ButtonPaddingGeneral: defaults to MUIBPS_ALL when control is created
@ButtonPaddingTextImage         EQU 384     ; qwPixels - No of pixels between left images and text. Defaults to 8 when control is created
@ButtonDllInstance              EQU 392     ; Set to hInstance of dll before calling MUIButtonLoadImages or MUIButtonNotifyLoadImage if used within a dll
@ButtonParam                    EQU 400     ; Custom user data

; Button Border Styles
MUIBBS_NONE                     EQU 0
MUIBBS_LEFT                     EQU 1
MUIBBS_TOP                      EQU 2
MUIBBS_BOTTOM                   EQU 4
MUIBBS_RIGHT                    EQU 8
MUIBBS_ALL                      EQU MUIBBS_LEFT + MUIBBS_TOP + MUIBBS_BOTTOM + MUIBBS_RIGHT


; Button Accent Styles
MUIBAS_NONE                     EQU 0
MUIBAS_LEFT                     EQU 1
MUIBAS_TOP                      EQU 2
MUIBAS_BOTTOM                   EQU 4
MUIBAS_RIGHT                    EQU 8
MUIBAS_ALL                      EQU MUIBAS_LEFT + MUIBAS_TOP + MUIBAS_BOTTOM + MUIBAS_RIGHT

; Button Image Types
MUIBIT_NONE                     EQU 0
MUIBIT_BMP                      EQU 1
MUIBIT_ICO                      EQU 2
MUIBIT_PNG                      EQU 3

; Button Padding Styles
MUIBPS_NONE                     EQU 0
MUIBPS_LEFT                     EQU 1
MUIBPS_TOP                      EQU 2
MUIBPS_BOTTOM                   EQU 4
MUIBPS_RIGHT                    EQU 8
MUIBPS_ALL                      EQU MUIBPS_LEFT + MUIBPS_TOP + MUIBPS_BOTTOM + MUIBPS_RIGHT


.DATA
; Button All Properties Themes
;                               ; MUI_BUTTON_PROPERTIES
MUI_BUTTON_DEFAULT_THEME        DQ 0                                                    ; Font 
                                DQ 0333333h, 0333333h, 0333333h, 0333333h, 0CCCCCCh     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0FFFFFFh, 0DDDDDDh, 0FFFFFFh, 0DDDDDDh, 0C0C0C0h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0CCCCCCh, 0CCCCCCh, 0E2A11Bh, 0E2A11Bh, 0CCCCCCh     ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_ALL                                           ; BorderStyle
                                DQ 0000000h, 0000000h, 0000000h, 0000000h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0333333h, 0FFFFFFh, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0333333h, 0CCCCCCh                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0                                                    ; DllInstance
                                
MUI_BUTTON_LIGHT_THEME          TEXTEQU <MUI_BUTTON_DEFAULT_THEME>

MUI_BUTTON_DARK_THEME           DQ 0                                                    ; Font 
                                DQ 0333333h, 0333333h, 0333333h, 0333333h, 0CCCCCCh     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0FFFFFFh, 0DDDDDDh, 0FFFFFFh, 0DDDDDDh, 0C0C0C0h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0CCCCCCh, 0CCCCCCh, 0E2A11Bh, 0E2A11Bh, 0CCCCCCh     ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_ALL                                           ; BorderStyle
                                DQ 0000000h, 0000000h, 0000000h, 0000000h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0333333h, 0FFFFFFh, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0333333h, 0CCCCCCh                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0                                                    ; DllInstance

MUI_CHECKBOX_LIGHT_THEME        DQ 0                                                    ; Font 
                                DQ 0333333h, 0333333h, 0333333h, 0333333h, 0333333h     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0F0F0F0h, 0F0F0F0h, 0F0F0F0h, 0F0F0F0h, 0F0F0F0h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0, 0, 0, 0, 0                                        ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_NONE                                          ; BorderStyle
                                DQ 0000000h, 0000000h, 0000000h, 0000000h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0000000h, 0000000h, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0000000h, 0000000h                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0                                                    ; DllInstance

MUI_CHECKBOX_DARK_THEME         DQ 0                                                    ; Font 
                                DQ 0F0F0F0h, 0F0F0F0h, 0F0F0F0h, 0F0F0F0h, 0F0F0F0h     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0333333h, 0333333h, 0333333h, 0333333h, 0333333h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0, 0, 0, 0, 0                                        ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_NONE                                          ; BorderStyle
                                DQ 0000000h, 0000000h, 0000000h, 0000000h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0000000h, 0000000h, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0000000h, 0000000h                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0                                                    ; DllInstance

MUI_MENUITEM_LIGHT_THEME        DQ 0                                                    ; Font 
                                DQ 0333333h, 03D3D3Dh, 0474747h, 0474747h, 0333333h     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0B9B9B9h, 0C3C3C3h, 0FFFFFFh, 0FFFFFFh, 0676767h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0696969h, 0696969h, 0696969h, 0696969h, 0696969h     ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_BOTTOM + MUIBBS_TOP                           ; BorderStyle
                                DQ 0000000h, 0917947h, 0C19539h, 0C19539h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_LEFT, MUIBAS_LEFT, MUIBAS_LEFT, MUIBAS_LEFT   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0333333h, 0B9B9B9h, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0333333h, 0CCCCCCh                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0   

MUI_MENUITEM_DARK_THEME         DQ 0                                                    ; Font 
                                DQ 0B9B9B9h, 0C3C3C3h, 0FFFFFFh, 0FFFFFFh, 0676767h     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0333333h, 03D3D3Dh, 0474747h, 0474747h, 0333333h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0696969h, 0696969h, 0696969h, 0696969h, 0696969h     ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_BOTTOM + MUIBBS_TOP                           ; BorderStyle
                                DQ 0000000h, 0917947h, 0C19539h, 0C19539h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_LEFT, MUIBAS_LEFT, MUIBAS_LEFT, MUIBAS_LEFT   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0B9B9B9h, 0333333h, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0B9B9B9h, 0CCCCCCh                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0                                                    ; DllInstance


MUI_MENUITEM_DARK_THEME_2       DQ 0                                                    ; Font 
                                DQ 0B9B9B9h, 0C3C3C3h, 0FFFFFFh, 0FFFFFFh, 0676767h     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0333333h, 03D3D3Dh, 0474747h, 0474747h, 0333333h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0000000h, 0000000h, 0000000h, 0000000h, 0000000h     ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_BOTTOM + MUIBBS_TOP                           ; BorderStyle
                                DQ 0000000h, 0917947h, 0C19539h, 0C19539h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_LEFT, MUIBAS_LEFT, MUIBAS_LEFT, MUIBAS_LEFT   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0B9B9B9h, 0333333h, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0B9B9B9h, 0CCCCCCh                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0   

MUI_MENUITEM_DARK_THEME_BLANK_2 DQ 0                                                    ; Font 
                                DQ 0B9B9B9h, 0B9B9B9h, 0B9B9B9h, 0B9B9B9h, 0676767h     ; TextColor, TextColorAlt, TxtColorSelected, TxtColorSelectedAlt, TxtColorDisabled   
                                DQ 0333333h, 0333333h, 0333333h, 0333333h, 0333333h     ; BackColor, BackColorAlt, BackColorSelected, BackColorSelectedAlt, BackColorDisabled
                                DQ 0000000h, 0000000h, 0000000h, 0000000h, 0000000h     ; BorderColor, BorderColorAlt, BorderColorSelected, BorderColorSelectedAlt, BorderColorDisabled
                                DQ MUIBBS_BOTTOM + MUIBBS_TOP                           ; BorderStyle
                                DQ 0000000h, 0000000h, 0000000h, 0000000h               ; AccentColor, AccentColorAlt, AccentColorSel, AccentColorSelAlt
                                DQ MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE, MUIBAS_NONE   ; AccentStyle, AccentStyleAlt, AccentStyleSel, AccentStyleSelAlt
                                DQ MUIBIT_NONE                                          ; ImageType
                                DQ 0, 0, 0, 0, 0                                        ; Image, ImageAlt, ImageSel, ImageSelAlt, ImageDisabled
                                DQ 0, 0, 0, 0, 0                                        ; RightImage, RightImageAlt, RightImageSel, RightImageSelAlt, RightImageDisabled
                                DQ 0, 0B9B9B9h, 0333333h, 4, MUIBIT_NONE, 0             ; NotifyTextFont, NotifyTextColor, NotifyBackColor, NotifyRound, NotifyImageType, NotifyImage
                                DQ 0, 0B9B9B9h, 0CCCCCCh                                ; NoteTextFont, NoteTextColor, NoteTextColorDisabled
                                DQ 0, 4, MUIBPS_ALL, 8                                  ; PaddingLeftIndent, PaddingGeneral, PaddingStyle, PaddingTextImage
                                DQ 0 















