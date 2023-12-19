include windows.inc
include CommCtrl.inc
include shellapi.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib shell32.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_CaptionBar.inc
includelib ModernUI_CaptionBar.lib

include ModernUI_Button.inc
includelib ModernUI_Button.lib

include ModernUI_Text.inc
includelib ModernUI_Text.lib

include ModernUI_ProgressDots.inc
includelib ModernUI_ProgressDots.lib

;-----------------------------------------------------------------------------------------
; MUIPDTest Prototypes
;-----------------------------------------------------------------------------------------



.CONST
;-----------------------------------------------------------------------------------------
; MUIPDTest Constants
;-----------------------------------------------------------------------------------------

ICO_MAIN                EQU 100
BMP_RSLOGO              EQU 200                


; Main Dialog
IDD_DIALOG				EQU 1000
IDC_BTNCANCEL           EQU 1001
IDC_TEXT1               EQU 1003
IDC_CAPTIONBAR          EQU 1019
IDC_MUIPD               EQU 1020


.DATA
;-----------------------------------------------------------------------------------------
; MUIPDTest Initialized Data
;-----------------------------------------------------------------------------------------
align 01
ClassName				DB 'DLGCLASS',0
AppName					DB 'Radasm Studio Installer',0
AboutMsg				DB 'www.LetTheLight.in',13,10,'Copyright © fearless 2018',0

szBtnCancelText         DB "Cancel",0
szInstalling            DB "Installing...",0



.DATA?
;-----------------------------------------------------------------------------------------
; MUIPDTest Uninitialized Data
;-----------------------------------------------------------------------------------------
align 08
icc 					INITCOMMONCONTROLSEX <>
hInstance				HINSTANCE ?
CommandLine				LPSTR ?
hWnd					HWND ?
hCaptionBar             DQ ?
hIcoMain                DQ ?
hText1                  DQ ?
hMUIPD                  DQ ?
hBtnCancel              DQ ?



