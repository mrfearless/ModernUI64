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

include ModernUI_SmartPanel.inc
includelib ModernUI_SmartPanel.lib

include ModernUI_ProgressDots.inc
includelib ModernUI_ProgressDots.lib

;-----------------------------------------------------------------------------------------
; MUIExample1 Prototypes
;-----------------------------------------------------------------------------------------
InitGUI                 PROTO :QWORD
PreInstallation         PROTO 
PreInstallationThread   PROTO :QWORD


.CONST
;-----------------------------------------------------------------------------------------
; MUIExample1 Constants
;-----------------------------------------------------------------------------------------

ICO_MAIN                EQU 100
BMP_RSLOGO              EQU 200    

; Main Dialog
IDD_DIALOG				EQU 1000
IDC_TEXTRSHEADER        EQU 1001
IDC_SMARTPANEL          EQU 1018
IDC_CAPTIONBAR          EQU 1019


.DATA
;-----------------------------------------------------------------------------------------
; MUIExample1 Initialized Data
;-----------------------------------------------------------------------------------------
align 01
ClassName				DB 'DLGCLASS',0
AppName					DB 'Radasm Studio Installer',0
AboutMsg				DB 'www.LetTheLight.in',13,10,'Copyright © fearless 2018',0

szRSHeader              DB "Community Edition 2018",0 

hCurrentPanel           DQ 0 ; Handle for currently selected panel in ModernUI_SmartPanel: hSP1

hPreThread              DQ 0
lpThreadID              DQ 0



.DATA?
;-----------------------------------------------------------------------------------------
; MUIExample1 Uninitialized Data
;-----------------------------------------------------------------------------------------
align 08
icc 					INITCOMMONCONTROLSEX <>
hInstance				HINSTANCE ?
CommandLine				LPSTR ?
hWnd					HWND ?
hIcoMain                DQ ?
hMUICaptionBar          DQ ?
hMUISmartPanel          DQ ?
hMUITextRSHeader        DQ ?



