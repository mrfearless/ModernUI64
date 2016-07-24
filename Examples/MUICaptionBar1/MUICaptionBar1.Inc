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

;-----------------------------------------------------------------------------------------
; MUICaptionBar1 Prototypes
;-----------------------------------------------------------------------------------------
WinMain					PROTO :HINSTANCE,:HINSTANCE,:LPSTR,:DWORD
WndProc					PROTO :HWND,:UINT,:WPARAM,:LPARAM


.CONST
;-----------------------------------------------------------------------------------------
; MUICaptionBar1 Constants
;-----------------------------------------------------------------------------------------
; Main Dialog
IDD_DIALOG				EQU 1000
IDC_CAPTIONBAR          EQU 1001

; Main Menu 
IDM_MENU				EQU 10000
IDM_FILE_EXIT			EQU 10001
IDM_HELP_ABOUT			EQU 10101



.DATA
;-----------------------------------------------------------------------------------------
; MUICaptionBar1 Initialized Data
;-----------------------------------------------------------------------------------------
align 01
szClass					db 'DLGCLASS', 0
szAppName				db 'First Window', 0

ClassName				DB 'DLGCLASS',0
AppName					DB 'LTLI Dialog',0
AboutMsg				DB 'www.LetTheLight.in',13,10,'Copyright © fearless 2016',0





.DATA?
;-----------------------------------------------------------------------------------------
; MUICaptionBar1 Uninitialized Data
;-----------------------------------------------------------------------------------------
align 08
icc 					INITCOMMONCONTROLSEX <>
hInstance				DQ ?
CommandLine				DQ ?
hWnd					DQ ?
hCaptionBar             DQ ?





