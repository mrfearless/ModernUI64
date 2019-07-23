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

include ModernUI_Animation.inc
includelib ModernUI_Animation.lib

;-----------------------------------------------------------------------------------------
; MUIAnim1 Prototypes
;-----------------------------------------------------------------------------------------



.CONST
;-----------------------------------------------------------------------------------------
; MUIAnim1 Constants
;-----------------------------------------------------------------------------------------
ICO_MAIN        EQU 100
PNG_FCCB        EQU 200 ; png/jpg for facebook clickbait animation - from a facebook clickbait gif i found online
PNG_ONOFF       EQU 201 ; png/jpg for onoff animation - made from https://www.sanwebe.com/2014/02/css3-buttons-examples-with-effects-animations

; Main Dialog
IDD_DIALOG      EQU 1000
IDC_CAPTIONBAR  EQU 1001 ; ModernUI_CaptionBar control resource id
IDC_ANIM1       EQU 1101 ; ModernUI_Animation control resource id for facebook clickbait animation
IDC_ONOFF       EQU 1102 ; ModernUI_Animation control resource id for onoff animation

; Main Menu 
IDM_MENU        EQU 10000
IDM_FILE_EXIT   EQU 10001
IDM_HELP_ABOUT  EQU 10101


.DATA
;-----------------------------------------------------------------------------------------
; MUIAnim1 Initialized Data
;-----------------------------------------------------------------------------------------
align 01
ClassName		DB 'DLGCLASS',0
AppName         DB 'ModernUI_Animation Demo',0
AboutMsg        DB 'github.com/mrfearless',13,10,'Copyright © fearless 2019',0

;-----------------------------------------------------------------------------------------
; Facebook click bait animation
; Demonstrates either option of using array to assign frame times, full array or compact
;-----------------------------------------------------------------------------------------
; For MUIAFT_COMPACT, sets only a few frames times, all others are default value
;
;                   ID  Time
;                   --  ----
FrameTimes \
                DQ  00, 1760
                DQ  13, 2560
                DQ  24, 2560
                DQ  35, 3480
                DQ  48, 2760
                DQ  62, 2320
                DQ  74,  440

FrameTimesSize equ $-FrameTimes


; For MUIAFT_FULL - an array of all frame times
;
;        FrameID:     0     1     2     3     4     5     6     7     8     9
;                  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----
FCCBFrameTimes \ 
                DQ 1760,   40,   40,   40,   40,   40,   40,   40,   40,   40 ; 0x
                DQ   40,   40,   40, 2560,   40,   40,   40,   40,   40,   40 ; 1x
                DQ   40,   40,   40,   40, 2560,   40,   40,   40,   40,   40 ; 2x
                DQ   40,   40,   40,   40,   40, 3480,   40,   40,   40,   40 ; 3x
                DQ   40,   40,   40,   40,   40,   40,   40,   40, 2760,   40 ; 4x
                DQ   40,   40,   40,   40,   40,   40,   40,   40,   40,   40 ; 5x
                DQ   40,   40, 2320,   40,   40,   40,   40,   40,   40,   40 ; 6x
                DQ   40,   40,   40,   40,  440                               ; 7x

FCCBFrameTimesSize equ $-FCCBFrameTimes

FCCBFrameCount  DQ 75 ; total no of individual image frames in the animation
;-----------------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------------
; OnOff control animation
;-----------------------------------------------------------------------------------------
; For MUIAFT_FULL. Frame times of -1 = pause animation. 
; Use with MUIAS_CONTROL style so clicking during animation doesnt pause
;
;        FrameID:     0     1     2     3     4     5     6     7     8     9
;                  ----  ----  ----  ----  ----  ----  ----  ----  ----  ----
OnOffFrameTimes  \
                DQ   33,   33,   33,   33,   33,   33,   33,   33,   33,   33 ; 0x
                DQ   33,   33,   33,   33,   33,   33,   33,   33,   33,   33 ; 1x
                DQ   -1,   66,   33,   33,   33,   33,   33,   33,   33,   33 ; 2x
                DQ   33,   33,   33,   33,   33,   33,   33,   -1             ; 3x
                
OnOffFrameTimesSize equ $-OnOffFrameTimes

OnOffFrameCount DQ 38 ; total no of individual image frames in the animation
;-----------------------------------------------------------------------------------------

OnOffState      DQ FALSE ; store onoff toggle state



.DATA?
;-----------------------------------------------------------------------------------------
; MUIAnim1 Uninitialized Data
;-----------------------------------------------------------------------------------------
align 08
icc 					INITCOMMONCONTROLSEX <>
hInstance				HINSTANCE ?
CommandLine				LPSTR ?
hWnd					HWND ?
hCaptionBar             DQ ? ; handle ModernUI_CaptionBar control
hAnim1                  DQ ? ; handle to fccb ModernUI_Animation control
hOnOff                  DQ ? ; handle to onoff ModernUI_Animation control




