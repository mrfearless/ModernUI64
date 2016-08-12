include windows.inc
include CommCtrl.inc
include shellapi.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib shell32.lib

include Masm64.inc
includelib Masm64.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_CaptionBar.inc
includelib ModernUI_CaptionBar.lib

include ModernUI_Button.inc
includelib ModernUI_Button.lib

include ModernUI_ProgressBar.inc
includelib ModernUI_ProgressBar.lib

;-----------------------------------------------------------------------------------------
; MUIProgressBar Prototypes
;-----------------------------------------------------------------------------------------



.CONST
;-----------------------------------------------------------------------------------------
; MUIProgressBar Constants
;-----------------------------------------------------------------------------------------
; Main Dialog
IDD_DIALOG				EQU 1000
IDC_CAPTIONBAR          EQU 1001
IDC_STARTBUTTON         EQU 1002
IDC_EXITBUTTON          EQU 1003
IDC_PB                  EQU 1004

; Main Menu 
IDM_MENU				EQU 10000
IDM_FILE_EXIT			EQU 10001
IDM_HELP_ABOUT			EQU 10101



.DATA
;-----------------------------------------------------------------------------------------
; MUIProgressBar Initialized Data
;-----------------------------------------------------------------------------------------
align 01
szClass					db 'Win64class', 0
;szAppName				db 'First Window', 0

ClassName				DB 'DLGCLASS',0
AppName					DB 'MUIProgressBar x64 Example',0
AboutMsg				DB 'www.LetTheLight.in',13,10,'Copyright © fearless 2016',0

szStartButtonText       db "Start",0
szExitButtonText        db "Exit",0



.DATA?
;-----------------------------------------------------------------------------------------
; MUIProgressBar Uninitialized Data
;-----------------------------------------------------------------------------------------
align 08
icc 					INITCOMMONCONTROLSEX <>
hInstance				HINSTANCE ?
CommandLine				LPSTR ?
hWnd					HWND ?
hCaptionBar             DQ ?
hStartBtn               DQ ?
hExitBtn                DQ ?
hPB                     DQ ?




