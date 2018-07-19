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

include ModernUI_Checkbox.inc
includelib ModernUI_Checkbox.lib


;-----------------------------------------------------------------------------------------
; MUICheckbox Prototypes
;-----------------------------------------------------------------------------------------



.CONST
;-----------------------------------------------------------------------------------------
; MUICheckbox Constants
;-----------------------------------------------------------------------------------------


ICO_MUI                 EQU 100
ICO_NOCHECKMARK         EQU 101
ICO_CHECKMARK           EQU 102

; Main Dialog
IDD_DIALOG              EQU 1000
IDC_CAPTIONBAR          EQU 1001
IDC_CHECKBOX1           EQU 1002
IDC_CHECKBOX2           EQU 1003
IDC_CHECKBOX3           EQU 1004

; Main Menu 
IDM_MENU				EQU 10000
IDM_FILE_EXIT			EQU 10001
IDM_HELP_ABOUT			EQU 10101


.DATA
;-----------------------------------------------------------------------------------------
; MUICheckbox Initialized Data
;-----------------------------------------------------------------------------------------
align 01
ClassName				DB 'DLGCLASS',0
AppName					DB 'MUICheckbox',0
AboutMsg				DB 'www.LetTheLight.in',13,10,'Copyright © fearless 2018',0
szCheckbox1Text         DB 'Checkbox option 1',0
szCheckbox2Text         DB 'Checkbox option 2',0
szCheckbox3Text         DB 'Checkbox option 3',0




.DATA?
;-----------------------------------------------------------------------------------------
; MUICheckbox Uninitialized Data
;-----------------------------------------------------------------------------------------
align 08
icc 					INITCOMMONCONTROLSEX <>
hInstance				HINSTANCE ?
CommandLine				LPSTR ?
hWnd					HWND ?
hCaptionBar             DQ ?
hIcoMain                DQ ?
hChk1                   DQ ?
hChk2                   DQ ?
hChk3                   DQ ?



