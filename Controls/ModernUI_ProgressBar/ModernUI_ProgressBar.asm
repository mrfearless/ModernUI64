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

.686
.MMX
.XMM
.x64

option casemap : none
option win64 : 11
option frame : auto
option stackbase : rsp

_WIN64 EQU 1
WINVER equ 0501h

;DEBUG64 EQU 1
;IFDEF DEBUG64
;    PRESERVEXMMREGS equ 1
;    includelib M:\UASM\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'M:\UASM\bin\DbgWin.exe'>
;    include M:\UASM\include\debug64.inc
;    .DATA
;    RDBG_DbgWin DB DEBUGEXE,0
;    .CODE
;ENDIF

include windows.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_ProgressBar.inc

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_ProgressBarWndProc         PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_ProgressBarInit            PROTO :QWORD
_MUI_ProgressBarCleanup         PROTO :QWORD
_MUI_ProgressBarPaint           PROTO :QWORD
_MUI_ProgressBarPaintText       PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_ProgressBarCalcWidth       PROTO :QWORD, :QWORD
_MUI_ProgressBarPulse           PROTO :QWORD
_MUI_ProgressBarCalcPulse       PROTO :QWORD, :QWORD
_MUI_ProgressSetPulseColors     PROTO :QWORD
_MUI_ProgressGetPulseColor      PROTO :QWORD
_MUI_ProgressGetR2GColor        PROTO :QWORD
_MUI_ProgressBarQwordToAscii    PROTO :QWORD, :QWORD, :DWORD, :DWORD, :DWORD


;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
MUI_PROGRESSBAR_PROPERTIES      STRUCT
    qwTextColor                 DQ ?
    qwTextFont                  DQ ?
    qwBackColor                 DQ ?
    qwProgressColor             DQ ?
    qwBorderColor               DQ ?
    qwPercent                   DQ ?
    qwMin                       DQ ?
    qwMax                       DQ ?
    qwStep                      DQ ?
    qwPulse                     DQ ?
    qwPulseTime                 DQ ?
    qwTextType                  DQ ?
    qwSetTextPos                DQ ?
MUI_PROGRESSBAR_PROPERTIES      ENDS

; Internal properties
_MUI_PROGRESSBAR_PROPERTIES     STRUCT
    qwEnabledState              DQ ?
    qwMouseOver                 DQ ?
    qwProgressBarWidth          DQ ?
    qwPulseActive               DQ ?
    qwPulseStep                 DQ ?
    qwPulseWidth                DQ ?
    qwPulseColors               DQ ?
    qwHeartbeatTimer            DQ ?
_MUI_PROGRESSBAR_PROPERTIES     ENDS

RGBA        STRUCT
    Red     DB ?
    Green   DB ?
    Blue    DB ?
    Alpha   DB ?
RGBA        ENDS

.CONST
PROGRESS_TIMER_ID_HEARTBEAT     EQU 1
PROGRESS_TIMER_ID_PULSE         EQU 2
PROGRESS_HEARTBEAT_TIME         EQU 3000 ; every 5 seconds
PROGRESS_PULSE_TIME             EQU 30
PROGRESS_MAX_PULSE_STEP         EQU 30

; Internal properties
@ProgressBarEnabledState        EQU 0
@ProgressBarMouseOver           EQU 8
@ProgressBarWidth               EQU 16
@ProgressPulseActive            EQU 24
@ProgressPulseStep              EQU 32
@ProgressPulseWidth             EQU 40
@ProgressPulseColors            EQU 48
@ProgressHeartbeatTimer         EQU 56


.DATA
ALIGN 4
szMUIProgressBarClass           DB 'ModernUI_ProgressBar',0     ; Class name for creating our ModernUI_ProgressBar control
szMUIProgressBarFont            DB 'Segoe UI',0                 ; Font used for ModernUI_ProgressBar text
hMUIProgressBarFont             DQ 0                            ; Handle to ModernUI_ProgressBar font (segoe ui)

hextbl                          DB '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'

R2GProgress \
    RGBA <186,069,033,0>,<186,072,033,0>,<186,075,033,0>,<186,078,033,0>,<186,081,033,0>,<186,084,033,0>,<186,087,033,0>,<186,090,033,0>,<186,093,033,0>,<186,096,033,0>
    RGBA <186,099,033,0>,<186,102,033,0>,<186,105,033,0>,<186,108,033,0>,<186,111,033,0>,<186,114,033,0>,<186,117,033,0>,<186,120,033,0>,<186,123,033,0>,<186,126,033,0>
    RGBA <186,129,033,0>,<186,132,033,0>,<186,135,033,0>,<186,138,033,0>,<186,141,033,0>,<186,144,033,0>,<186,147,033,0>,<186,150,033,0>,<186,153,033,0>,<186,156,033,0>
    RGBA <186,159,033,0>,<186,162,033,0>,<186,165,033,0>,<186,168,033,0>,<186,171,033,0>,<186,174,033,0>,<186,177,033,0>,<186,180,033,0>,<186,183,033,0>,<186,186,033,0>
    RGBA <183,186,033,0>,<180,186,033,0>,<177,186,033,0>,<174,186,033,0>,<171,186,033,0>,<168,186,033,0>,<165,186,033,0>,<162,186,033,0>,<159,186,033,0>,<156,186,033,0>
    RGBA <153,186,033,0>,<150,186,033,0>,<147,186,033,0>,<144,186,033,0>,<141,186,033,0>,<138,186,033,0>,<135,186,033,0>,<132,186,033,0>,<129,186,033,0>,<126,186,033,0>
    RGBA <123,186,033,0>,<120,186,033,0>,<117,186,033,0>,<114,186,033,0>,<111,186,033,0>,<108,186,033,0>,<105,186,033,0>,<102,186,033,0>,<099,186,033,0>,<096,186,033,0>
    RGBA <093,186,033,0>,<090,186,033,0>,<087,186,033,0>,<084,186,033,0>,<081,186,033,0>,<078,186,033,0>,<075,186,033,0>,<072,186,033,0>,<069,186,033,0>,<066,186,033,0>
    RGBA <063,186,033,0>,<060,186,033,0>,<057,186,033,0>,<054,186,033,0>,<051,186,033,0>,<048,186,033,0>,<045,186,033,0>,<042,186,033,0>,<039,186,033,0>,<036,186,033,0>
    RGBA <033,186,033,0>,<033,186,036,0>,<033,186,039,0>,<033,186,042,0>,<033,186,045,0>,<033,186,048,0>,<033,186,051,0>,<033,186,054,0>,<033,186,057,0>,<033,186,060,0>
    RGBA <033,186,063,0>


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for ModernUI_ProgressBar control
;------------------------------------------------------------------------------
MUIProgressBarSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUIProgressBarSetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for ModernUI_ProgressBar control
;------------------------------------------------------------------------------
MUIProgressBarGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUIProgressBarGetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIProgressBarRegister - Registers the ModernUI_ProgressBar control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_ProgressBar
;------------------------------------------------------------------------------
MUIProgressBarRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
    
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUIProgressBarClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUIProgressBarClass
        mov wc.lpszClassName, rax
        mov rax, hinstance
        mov wc.hInstance, rax
        lea rax, _MUI_ProgressBarWndProc
        mov wc.lpfnWndProc, rax
        Invoke LoadCursor, NULL, IDC_ARROW
        mov wc.hCursor, rax
        mov wc.hIcon, 0
        mov wc.hIconSm, 0
        mov wc.lpszMenuName, NULL
        mov wc.hbrBackground, NULL
        mov wc.style, NULL
        mov wc.cbClsExtra, 0
        mov wc.cbWndExtra, 16 ; cbWndExtra +0 = QWORD ptr to internal properties memory block, cbWndExtra +8 = QWORD ptr to external properties memory block
        Invoke RegisterClassEx, addr wc
    .ENDIF  
    ret

MUIProgressBarRegister ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIProgressBarCreate - Returns handle in rax of newly created control
;------------------------------------------------------------------------------
MUIProgressBarCreate PROC FRAME hWndParent:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
    LOCAL hControl:QWORD
    LOCAL qwNewStyle:QWORD
    
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    Invoke MUIProgressBarRegister
    
    mov rax, qwStyle
    mov qwNewStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        or qwNewStyle, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .ENDIF
    
    Invoke CreateWindowEx, NULL, Addr szMUIProgressBarClass, NULL, dword ptr qwNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
    mov hControl, rax
    .IF rax != NULL
        
    .ENDIF
    mov rax, hControl
    ret
MUIProgressBarCreate ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarWndProc - Main processing window for our control
;------------------------------------------------------------------------------
_MUI_ProgressBarWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        mov rbx, lParam
        ; sets text of our control, delete if not required.
        ;Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName  
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
        Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_PROGRESSBAR_PROPERTIES ; internal properties
        Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_PROGRESSBAR_PROPERTIES ; external properties
        Invoke _MUI_ProgressBarInit, hWin
        mov rax, 0
        ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_ProgressBarCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
        Invoke MUIFreeMemProperties, hWin, 8
        mov rax, 0
        ret
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_ProgressBarPaint, hWin
        mov rax, 0
        ret
        
    .ELSEIF eax == WM_SIZE
        ; Check if _MUI_PROGRESS_PROPERTIES ; internal properties available
        Invoke GetWindowLongPtr, hWin, 0
        .IF rax != 0 ; Yes they are
            Invoke InvalidateRect, hWin, NULL, TRUE
        .ENDIF
        mov rax, 0
        ret

    .ELSEIF eax == WM_TIMER
        mov rax, wParam
        .IF rax == PROGRESS_TIMER_ID_HEARTBEAT
            IFDEF DEBUG32
            ;PrintText 'WM_TIMER::PROGRESS_TIMER_ID_HEARTBEAT'
            ENDIF
            Invoke KillTimer, hWin, PROGRESS_TIMER_ID_PULSE
            Invoke SetTimer, hWin, PROGRESS_TIMER_ID_PULSE, PROGRESS_PULSE_TIME, NULL
        .ELSEIF rax == PROGRESS_TIMER_ID_PULSE
            Invoke _MUI_ProgressBarPulse, hWin
        .ENDIF
        ret

    ; custom messages start here
    
    .ELSEIF eax == MUI_GETPROPERTY
        Invoke MUIGetExtProperty, hWin, wParam
        ret
        
    .ELSEIF eax == MUI_SETPROPERTY  
        mov rax, wParam
        .IF rax == @ProgressBarPercent
            Invoke MUIProgressBarSetPercent, hWin, wParam
        .ELSEIF rax == @ProgressBarProgressColor
            Invoke MUISetExtProperty, hWin, wParam, lParam
            Invoke _MUI_ProgressSetPulseColors, hWin
        .ELSEIF rax == @ProgressBarPulse
            .IF lParam == FALSE ; if setting to false and already active kill timers etc
                Invoke MUIGetIntProperty, hWin, @ProgressHeartbeatTimer
                .IF rax == TRUE
                    Invoke MUISetIntProperty, hWin, @ProgressHeartbeatTimer, FALSE
                    Invoke MUISetIntProperty, hWin, @ProgressPulseActive, FALSE
                    Invoke KillTimer, hWin, PROGRESS_TIMER_ID_HEARTBEAT
                    Invoke KillTimer, hWin, PROGRESS_TIMER_ID_PULSE
                .ENDIF
            .ELSE
                Invoke GetWindowLongPtr, hWin, GWL_STYLE
                and rax, MUIPBS_R2G
                .IF rax == MUIPBS_R2G
                    Invoke MUISetExtProperty, hWin, wParam, FALSE
                    ret
                .ENDIF
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, lParam
        .ELSE
            Invoke MUISetExtProperty, hWin, wParam, lParam
        .ENDIF
        ret

    .ELSEIF eax == MUIPBM_STEP
        Invoke MUIProgressBarStep, hWin
        ret
    
    .ELSEIF eax == MUIPBM_SETPERCENT
        Invoke MUIProgressBarSetPercent, hWin, wParam
        ret

    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret
_MUI_ProgressBarWndProc ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarInit - set initial default values
;------------------------------------------------------------------------------
_MUI_ProgressBarInit PROC FRAME hWin:QWORD
    LOCAL ncm:NONCLIENTMETRICS
    LOCAL lfnt:LOGFONT
    LOCAL hFont:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    
    Invoke GetParent, hWin
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, qwStyle
        or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov qwStyle, rax
        Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwStyle
    .ENDIF
    ;PrintDec qwStyle
    
    ; Set default initial external property values     
    Invoke MUISetExtProperty, hWin, @ProgressBarTextColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hWin, @ProgressBarBackColor, MUI_RGBCOLOR(193,193,193)
    Invoke MUISetExtProperty, hWin, @ProgressBarBorderColor, MUI_RGBCOLOR(163,163,163)
    Invoke MUISetExtProperty, hWin, @ProgressBarProgressColor, MUI_RGBCOLOR(27,161,226)

    Invoke MUISetExtProperty, hWin, @ProgressBarPercent, 0
    Invoke MUISetExtProperty, hWin, @ProgressBarMin, 0
    Invoke MUISetExtProperty, hWin, @ProgressBarMax, 100

    
    .IF hMUIProgressBarFont == 0
        mov ncm.cbSize, SIZEOF NONCLIENTMETRICS
        Invoke SystemParametersInfo, SPI_GETNONCLIENTMETRICS, SIZEOF NONCLIENTMETRICS, Addr ncm, 0
        Invoke CreateFontIndirect, Addr ncm.lfMessageFont
        mov hFont, rax
        Invoke GetObject, hFont, SIZEOF lfnt, Addr lfnt
        mov lfnt.lfHeight, -12d
        mov lfnt.lfWeight, FW_BOLD
        Invoke CreateFontIndirect, Addr lfnt
        mov hMUIProgressBarFont, rax
        Invoke DeleteObject, hFont
    .ENDIF
    Invoke MUISetExtProperty, hWin, @ProgressBarTextFont, hMUIProgressBarFont

    ; Create array for pulse colors
    mov rax, PROGRESS_MAX_PULSE_STEP
    add rax, 2
    mov rbx, SIZEOF QWORD
    mul rbx
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    Invoke MUISetIntProperty, hWin, @ProgressPulseColors, rax
    
    Invoke _MUI_ProgressSetPulseColors, hWin
    
    mov rax, qwStyle
    and rax, MUIPBS_NOPULSE
    .IF rax == MUIPBS_NOPULSE
        Invoke MUISetExtProperty, hWin, @ProgressBarPulse, FALSE
    .ELSE
        Invoke MUISetExtProperty, hWin, @ProgressBarPulse, TRUE
    .ENDIF
    
    Invoke MUISetExtProperty, hWin, @ProgressBarPulseTime, PROGRESS_HEARTBEAT_TIME
    
    mov rax, qwStyle
    and rax, MUIPBS_TEXT_CENTRE or MUIPBS_TEXT_FOLLOW
    .IF rax == MUIPBS_TEXT_CENTRE or MUIPBS_TEXT_FOLLOW
        Invoke MUISetExtProperty, hWin, @ProgressBarTextType, MUIPBTT_CENTRE
    .ELSEIF rax == MUIPBS_TEXT_CENTRE
        Invoke MUISetExtProperty, hWin, @ProgressBarTextType, MUIPBTT_CENTRE
    .ELSEIF rax == MUIPBS_TEXT_FOLLOW
        Invoke MUISetExtProperty, hWin, @ProgressBarTextType, MUIPBTT_FOLLOW
    .ENDIF

    mov rax, qwStyle
    and rax, MUIPBS_R2G
    .IF rax == MUIPBS_R2G
        Invoke MUISetExtProperty, hWin, @ProgressBarPulse, FALSE
    .ENDIF

    mov rax, TRUE
    ret
_MUI_ProgressBarInit ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarCleanup
;------------------------------------------------------------------------------
_MUI_ProgressBarCleanup PROC FRAME hWin:QWORD
    
    Invoke KillTimer, hWin, PROGRESS_TIMER_ID_PULSE
    Invoke KillTimer, hWin, PROGRESS_TIMER_ID_HEARTBEAT
    
    Invoke MUIGetIntProperty, hWin, @ProgressPulseColors
    .IF rax != NULL
        Invoke GlobalFree, rax
    .ENDIF
    ret
_MUI_ProgressBarCleanup ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarPaint
;------------------------------------------------------------------------------
_MUI_ProgressBarPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rectprogress:RECT
    LOCAL rect:RECT
    LOCAL hdc:QWORD
    LOCAL hdcMem:QWORD
    LOCAL hBufferBitmap:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL Percent:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL BorderColor:QWORD
    LOCAL ProgressColor:QWORD
    LOCAL bPulseActive:QWORD
    LOCAL PulseColor:QWORD
    LOCAL ProgressWidth:QWORD

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke MUIGDIDoubleBufferStart, hWin, hdc, Addr hdcMem, Addr rect, Addr hBufferBitmap
    
    ;----------------------------------------------------------
    ; Get some property values
    ;---------------------------------------------------------- 
    Invoke MUIGetExtProperty, hWin, @ProgressBarTextColor
    mov TextColor, rax
    Invoke MUIGetExtProperty, hWin, @ProgressBarBackColor
    mov BackColor, rax
    Invoke MUIGetExtProperty, hWin, @ProgressBarBorderColor
    mov BorderColor, rax
    Invoke MUIGetExtProperty, hWin, @ProgressBarPercent        
    mov Percent, rax    
    Invoke MUIGetExtProperty, hWin, @ProgressBarProgressColor
    mov ProgressColor, rax
    Invoke MUIGetIntProperty, hWin, @ProgressPulseActive
    mov bPulseActive, rax
    Invoke CopyRect, Addr rectprogress, Addr rect
    
    ;----------------------------------------------------------
    ; Fill background
    ;----------------------------------------------------------
    Invoke MUIGDIPaintFill, hdcMem, Addr rect, BackColor

    ;----------------------------------------------------------
    ; Draw Progress
    ;----------------------------------------------------------
    Invoke MUIGetIntProperty, hWin, @ProgressBarWidth
    mov ProgressWidth, rax
    mov rectprogress.right, eax
    ;PrintDec ProgressColor
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    and rax, MUIPBS_R2G
    .IF rax == MUIPBS_R2G
        Invoke _MUI_ProgressGetR2GColor, hWin
        mov ProgressColor, rax
        ;PrintDec ProgressColor
    .ENDIF
    Invoke MUIGDIPaintFill, hdcMem, Addr rectprogress, ProgressColor

    ;----------------------------------------------------------
    ; Draw Pulse
    ;----------------------------------------------------------
    .IF bPulseActive == TRUE
        Invoke MUIGetIntProperty, hWin, @ProgressPulseWidth
        .IF rax >= ProgressWidth
            mov rax, ProgressWidth
        .ENDIF
        mov rectprogress.right, eax
        Invoke _MUI_ProgressGetPulseColor, hWin
        mov PulseColor, rax
        Invoke MUIGDIPaintFill, hdcMem, Addr rectprogress, PulseColor
    .ENDIF

    ;----------------------------------------------------------
    ; Paint Percentage Text
    ;----------------------------------------------------------
    Invoke MUIGetExtProperty, hWin, @ProgressBarTextType
    .IF rax != MUIPBTT_NONE
        Invoke _MUI_ProgressBarPaintText, hWin, hdcMem, Addr rect, TextColor
    .ENDIF

    ;----------------------------------------------------------
    ; Border
    ;----------------------------------------------------------
    Invoke MUIGDIPaintFrame, hdcMem, Addr rect, BorderColor, MUIPFS_ALL

    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Finish Double Buffering & Cleanup
    ;----------------------------------------------------------
    Invoke MUIGDIDoubleBufferFinish, hdcMem, hBufferBitmap, 0, 0, hBrush, 0 
    
    Invoke EndPaint, hWin, Addr ps

    ret
_MUI_ProgressBarPaint ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarPaintText - paint percentage text
;------------------------------------------------------------------------------
_MUI_ProgressBarPaintText PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, qwTextColor:QWORD
    LOCAL hFont:HFONT
    LOCAL hFontOld:HFONT
    LOCAL ProgressWidth:QWORD
    LOCAL qwWidth:QWORD
    LOCAL qwTextType:QWORD
    LOCAL qwTextStyle:QWORD
    LOCAL qwPercent:QWORD
    LOCAL qwLenPercentText:QWORD
    LOCAL szPercentText[8]:BYTE
    LOCAL szDisplayText[128]:BYTE
    LOCAL sz:SIZE_
    LOCAL szspace:SIZE_
    LOCAL rect:RECT

    Invoke MUIGetExtProperty, hWin, @ProgressBarTextType
    mov qwTextType, rax
    .IF rax != MUIPBTT_CENTRE && rax != MUIPBTT_FOLLOW
        ret
    .ENDIF

    Invoke CopyRect, Addr rect, lpRect
    mov eax, rect.right
    sub eax, rect.left
    mov qwWidth, rax
    
    Invoke MUIGetIntProperty, hWin, @ProgressBarWidth
    mov ProgressWidth, rax
    Invoke MUIGetExtProperty, hWin, @ProgressBarPercent
    mov qwPercent, rax
    Invoke _MUI_ProgressBarQwordToAscii, qwPercent, Addr szPercentText, 10d, FALSE, FALSE
    Invoke lstrcat, Addr szPercentText, CTEXT("%")
    Invoke lstrlen, Addr szPercentText
    mov qwLenPercentText, rax
    
;    Invoke GetWindowText, hWin, Addr szDisplayText, (SIZEOF szDisplayText) - 8
;    .IF rax == 0
;        Invoke lstrcpy, Addr szDisplayText, Addr szPercentText
;    .ELSE
;        Invoke MUIGetExtProperty, hWin, @ProgressBarSetTextPos
;    .ENDIF
    
    Invoke MUIGetExtProperty, hWin, @ProgressBarTextFont
    mov hFont, rax
    Invoke SelectObject, hdc, hFont
    mov hFontOld, rax
    
    Invoke GetTextExtentPoint32, hdc, CTEXT(" "), 1, Addr szspace
    Invoke GetTextExtentPoint32, hdc, Addr szPercentText, dword ptr qwLenPercentText, Addr sz
    mov eax, sz.cx_
    .IF rax <= qwWidth

        ;Invoke SetBkMode, hdc, OPAQUE
        ;Invoke SetBkColor, hdc, BackColor
        Invoke SetBkMode, hdc, TRANSPARENT
        Invoke SetTextColor, hdc, dword ptr qwTextColor
    
        mov qwTextStyle, DT_SINGLELINE or DT_VCENTER or DT_CENTER

        .IF qwTextType == MUIPBTT_CENTRE
            Invoke DrawText, hdc, Addr szPercentText, dword ptr qwLenPercentText, Addr rect, dword ptr qwTextStyle
        .ELSE ; MUIPBTT_FOLLOW
            mov eax, sz.cx_
            add eax, szspace.cx_
            .IF rax <= ProgressWidth
                mov rax, ProgressWidth;rect.right
                mov rect.right, eax
                sub eax, sz.cx_
                sub eax, szspace.cx_
                mov rect.left, eax
                Invoke DrawText, hdc, Addr szPercentText, dword ptr qwLenPercentText, Addr rect, dword ptr qwTextStyle
            .ENDIF
        .ENDIF
    .ENDIF
    
    Invoke SelectObject, hdc, hFontOld
    Invoke DeleteObject, hFontOld
    
    ret
_MUI_ProgressBarPaintText ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarCalcWidth
;------------------------------------------------------------------------------
_MUI_ProgressBarCalcWidth PROC FRAME hControl:QWORD, qwPercent:QWORD
    LOCAL rect:RECT
    LOCAL qwProgressWidth:QWORD
    LOCAL qwWidth:QWORD
    LOCAL nTmp:QWORD

    Invoke GetWindowRect, hControl, Addr rect
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    mov qwWidth, rax

    mov nTmp, 100

    finit
    fild qwWidth
    fild nTmp
    fdiv
    fld st
    fild qwPercent ;dword ptr 
    fmul
    fistp qwProgressWidth
    
    ;PrintDec dwPercent
    ;PrintDec dwProgressWidth
    
    mov rax, qwProgressWidth
    ret

_MUI_ProgressBarCalcWidth ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarCalcPulse
;------------------------------------------------------------------------------
_MUI_ProgressBarCalcPulse PROC FRAME hWin:QWORD, qwPulseStep:QWORD
    LOCAL rect:RECT
    LOCAL qwPulseWidth:QWORD
    LOCAL qwWidth:QWORD
    LOCAL nTmp:QWORD
    
    Invoke GetWindowRect, hWin, Addr rect
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    mov qwWidth, rax

    mov nTmp, PROGRESS_MAX_PULSE_STEP

    finit
    fild qwWidth
    fild nTmp
    fdiv
    fld st
    fild qwPulseStep
    fmul
    fistp qwPulseWidth
    
    ;PrintDec dwPulse
    ;PrintDec dwPulseWidth
    
    mov rax, qwPulseWidth
    
    ret
_MUI_ProgressBarCalcPulse ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarPulse
;------------------------------------------------------------------------------
_MUI_ProgressBarPulse PROC FRAME hWin:QWORD
    LOCAL qwPulseStep:QWORD
    LOCAL qwPulseWidth:QWORD
    LOCAL qwProgressWidth:QWORD
    
    Invoke MUISetIntProperty, hWin, @ProgressPulseActive, TRUE
    
    Invoke MUIGetIntProperty, hWin, @ProgressPulseStep
    mov qwPulseStep, rax
    Invoke _MUI_ProgressBarCalcPulse, hWin, qwPulseStep
    mov qwPulseWidth, rax
    Invoke MUISetIntProperty, hWin, @ProgressPulseWidth, qwPulseWidth
    
    Invoke MUIGetIntProperty, hWin, @ProgressBarWidth
    mov qwProgressWidth, rax
    
    Invoke InvalidateRect, hWin, NULL, FALSE
    Invoke UpdateWindow, hWin
    
    mov rax, qwPulseWidth
    .IF rax > qwProgressWidth
        mov qwPulseStep, 0
        Invoke KillTimer, hWin, PROGRESS_TIMER_ID_PULSE
        Invoke MUISetIntProperty, hWin, @ProgressPulseActive, FALSE
    .ELSE
        inc qwPulseStep
        .IF qwPulseStep >= PROGRESS_MAX_PULSE_STEP
            mov qwPulseStep, 0
            Invoke KillTimer, hWin, PROGRESS_TIMER_ID_PULSE
            Invoke MUISetIntProperty, hWin, @ProgressPulseActive, FALSE
        .ENDIF
    .ENDIF
    
    Invoke MUISetIntProperty, hWin, @ProgressPulseStep, qwPulseStep
    Invoke InvalidateRect, hWin, NULL, FALSE
    Invoke UpdateWindow, hWin
    
    ret
_MUI_ProgressBarPulse ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressSetPulseColors
;------------------------------------------------------------------------------
_MUI_ProgressSetPulseColors PROC FRAME USES RBX RCX hWin:QWORD
    LOCAL ProgressBarColor:QWORD
    LOCAL pProgressPulseColors:QWORD
    LOCAL nPulseColor:QWORD
    LOCAL PulseColor:QWORD
    LOCAL clrRed:QWORD
    LOCAL clrGreen:QWORD
    LOCAL clrBlue:QWORD
    
    Invoke MUIGetIntProperty, hWin, @ProgressPulseColors
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov pProgressPulseColors, rax
    
;    ; Calc last entry
;    mov eax, PROGRESS_MAX_PULSE_STEP
;    mov ebx, SIZEOF DWORD
;    mul ebx
;    add pProgressPulseColors, eax
    
    Invoke MUIGetExtProperty, hWin, @ProgressBarProgressColor
    mov ProgressBarColor, rax
    
    ; Split DWORD to individual RGB
    mov rax, ProgressBarColor
    xor rbx, rbx
    mov bl, al
    mov clrRed, rbx
    xor rbx, rbx
    mov bl, ah
    mov clrGreen, rbx
    xor rbx, rbx
    shr rax, 16d
    mov bl, al
    mov clrBlue, rbx    
    
    add clrRed, PROGRESS_MAX_PULSE_STEP+8
    add clrGreen, PROGRESS_MAX_PULSE_STEP+8
    add clrBlue, PROGRESS_MAX_PULSE_STEP+8
    .IF clrRed >= 255
        mov clrRed, 255
    .ENDIF
    .IF clrGreen >= 255
        mov clrGreen, 255
    .ENDIF
    .IF clrBlue >= 255
        mov clrBlue, 255
    .ENDIF
    
    mov rax, 0
    mov nPulseColor, 0
    .WHILE rax < PROGRESS_MAX_PULSE_STEP
        
        ; combine individual RGB back to QWORD
        xor rcx, rcx
        mov rcx, clrBlue
        shl rcx, 16d
        xor rbx, rbx
        mov rbx, clrGreen
        mov rax, clrRed
        mov ch, bl
        mov cl, al
        mov PulseColor, rcx
        
;        IFDEF DEBUG32
;        PrintDec clrRed
;        PrintDec clrGreen
;        PrintDec clrBlue
;        PrintDec PulseColor
;        ENDIF
        
        mov rbx, pProgressPulseColors
        mov [rbx], rcx
        
        dec clrRed
        dec clrGreen
        dec clrBlue
        
        add pProgressPulseColors, SIZEOF QWORD
        inc nPulseColor
        mov rax, nPulseColor
    .ENDW
    
    ; Add extra safety buffers
    mov rbx, pProgressPulseColors
    mov rax, ProgressBarColor
    mov [rbx], rax
    
    add pProgressPulseColors, SIZEOF QWORD
    mov rbx, pProgressPulseColors
    mov rax, ProgressBarColor
    mov [rbx], rax
    
    ret
_MUI_ProgressSetPulseColors ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressGetPulseColor
;------------------------------------------------------------------------------
_MUI_ProgressGetPulseColor PROC FRAME USES RBX hWin:QWORD
    LOCAL ProgressBarColor:QWORD
    LOCAL pProgressPulseColors:QWORD
    LOCAL ProgressBarWidth:QWORD
    LOCAL SinglePulseWidth:QWORD
    LOCAL maxpulse:QWORD
    LOCAL qwPulseStep:QWORD
    
    Invoke MUIGetExtProperty, hWin, @ProgressBarProgressColor
    mov ProgressBarColor, rax
    
    Invoke MUIGetIntProperty, hWin, @ProgressPulseColors
    .IF rax == NULL
        mov rax, ProgressBarColor
        ret
    .ENDIF
    mov pProgressPulseColors, rax
    
    Invoke MUIGetIntProperty, hWin, @ProgressPulseStep
    mov qwPulseStep, rax
    
    Invoke MUIGetIntProperty, hWin, @ProgressBarWidth
    mov ProgressBarWidth, rax
    
    Invoke _MUI_ProgressBarCalcPulse, hWin, 1
    mov SinglePulseWidth, rax
    
    ;PrintDec ProgressBarWidth
    ;PrintDec SinglePulseWidth
    
    finit
    fild ProgressBarWidth
    fild SinglePulseWidth
    fdiv
    fistp maxpulse
    
    Invoke MUIGetIntProperty, hWin, @ProgressPulseStep
    mov rax, PROGRESS_MAX_PULSE_STEP
    dec rax ; for 0 based index
    sub rax, maxpulse
    add rax, qwPulseStep
    .IF sqword ptr rax < 0
        mov rax, 0
    .ENDIF
    .IF rax >= PROGRESS_MAX_PULSE_STEP
        mov rax, PROGRESS_MAX_PULSE_STEP
        dec rax
    .ENDIF
    mov rbx, SIZEOF QWORD
    mul rbx
    add rax, pProgressPulseColors
    mov rbx, rax
    mov rax, [rbx]

    ret
_MUI_ProgressGetPulseColor ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressGetR2GColor
;------------------------------------------------------------------------------
_MUI_ProgressGetR2GColor PROC FRAME USES RBX hWin:QWORD
    Invoke MUIGetExtProperty, hWin, @ProgressBarPercent
    mov rbx, SIZEOF DWORD
    mul rbx
    lea rbx, R2GProgress
    add rax, rbx
    mov rbx, rax
    xor rax, rax
    mov eax, dword ptr [rbx] ; RGBCOLOR in eax
    ret
_MUI_ProgressGetR2GColor ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIProgressBarSetMinMax
;------------------------------------------------------------------------------
MUIProgressBarSetMinMax PROC FRAME hControl:QWORD, qwMin:QWORD, qwMax:QWORD
    Invoke MUISetExtProperty, hControl, @ProgressBarMin, qwMin
    Invoke MUISetExtProperty, hControl, @ProgressBarMax, qwMax
    ret
MUIProgressBarSetMinMax ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUIProgressBarSetPercent
;------------------------------------------------------------------------------
MUIProgressBarSetPercent PROC FRAME hControl:QWORD, qwPercent:QWORD
    LOCAL qwOldPercent:QWORD
    LOCAL qwNewPercent:QWORD
    LOCAL qwOldWidth:QWORD
    LOCAL qwNewWidth:QWORD
    LOCAL qwCurrentWidth:QWORD
    LOCAL qwTime:QWORD

    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl

    Invoke MUIGetExtProperty, hControl, @ProgressBarPercent
    mov qwOldPercent, rax
    .IF rax == qwPercent
        ret
    .ENDIF
    mov rax, qwPercent
    .IF sqword ptr rax > 100
        mov rax, 100
    .ENDIF
    .IF sqword ptr rax < 0
        mov rax, 0
    .ENDIF
    mov qwNewPercent, rax

    sub rax, qwOldPercent
    .IF sqword ptr rax > 1 ; if lots of steps to draw between old and new percent
        .IF sqword ptr qwNewPercent >= 0 && sqword ptr qwNewPercent <= 100
            Invoke _MUI_ProgressBarCalcWidth, hControl, qwOldPercent
            mov qwOldWidth, rax
            mov qwCurrentWidth, rax
    
            Invoke _MUI_ProgressBarCalcWidth, hControl, qwNewPercent
            mov qwNewWidth, rax
            
            mov rax, qwCurrentWidth
            .IF sqword ptr rax < qwNewWidth ; going up
                mov rax, qwCurrentWidth
                .WHILE sqword ptr rax <= qwNewWidth
                
                    Invoke MUISetIntProperty, hControl, @ProgressBarWidth, qwCurrentWidth
                    Invoke InvalidateRect, hControl, NULL, FALSE
                    Invoke UpdateWindow, hControl
                    ;Invoke Sleep, 1
                    
                    ;PrintDec dwCurrentWidth
                    inc qwCurrentWidth
                    mov rax, qwCurrentWidth
                .ENDW
            
            .ELSE ; going down
                Invoke MUISetIntProperty, hControl, @ProgressBarWidth, qwNewWidth
;                mov rax, qwCurrentWidth
;                .WHILE sqword ptr rax >= qwNewWidth
;                
;                    Invoke MUISetIntProperty, hControl, @ProgressBarWidth, qwCurrentWidth
;                    Invoke InvalidateRect, hControl, NULL, FALSE
;                    Invoke UpdateWindow, hControl
;                    ;Invoke Sleep, 1
;                    
;                    ;PrintDec dwCurrentWidth
;                    dec qwCurrentWidth
;                    mov rax, qwCurrentWidth
;                .ENDW
            
            .ENDIF
        .ENDIF
    .ELSE
        Invoke _MUI_ProgressBarCalcWidth, hControl, qwNewPercent
        Invoke MUISetIntProperty, hControl, @ProgressBarWidth, rax
    .ENDIF
    
    Invoke MUISetExtProperty, hControl, @ProgressBarPercent, qwNewPercent
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    
    Invoke MUIGetExtProperty, hControl, @ProgressBarPulse
    .IF rax == TRUE
        .IF qwNewPercent == 0 || qwNewPercent >= 100
            ; check if heartbeat timer is stopped, if not we stop it
            Invoke MUIGetIntProperty, hControl, @ProgressHeartbeatTimer
            .IF rax == TRUE
                Invoke MUISetIntProperty, hControl, @ProgressHeartbeatTimer, FALSE
                Invoke KillTimer, hControl, PROGRESS_TIMER_ID_HEARTBEAT
            .ENDIF
        .ELSE
            ; check if heartbeat timer is already started, if not we start it
            Invoke MUIGetIntProperty, hControl, @ProgressHeartbeatTimer
            .IF rax == FALSE
                Invoke MUISetIntProperty, hControl, @ProgressHeartbeatTimer, TRUE
                Invoke MUIGetExtProperty, hControl, @ProgressBarPulseTime
                .IF rax == 0
                    mov rax, PROGRESS_HEARTBEAT_TIME
                .ENDIF
                mov qwTime, rax
                Invoke SetTimer, hControl, PROGRESS_TIMER_ID_HEARTBEAT, dword ptr qwTime, NULL
            .ENDIF
        .ENDIF
    .ENDIF
    
    mov rax, qwNewPercent
    ret
MUIProgressBarSetPercent ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIProgressBarGetPercent
;------------------------------------------------------------------------------
MUIProgressBarGetPercent PROC FRAME hControl:QWORD
    Invoke MUIGetExtProperty, hControl, @ProgressBarPercent
    ret
MUIProgressBarGetPercent ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIProgressBarStep
;------------------------------------------------------------------------------
MUIProgressBarStep PROC FRAME hControl:QWORD
    Invoke MUIGetExtProperty, hControl, @ProgressBarPercent
    inc eax
    Invoke MUIProgressBarSetPercent, hControl, eax
    ret
MUIProgressBarStep ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_ProgressBarQwordToAscii - Habran's 64bit utoa_ex
;------------------------------------------------------------------------------
_MUI_ProgressBarQwordToAscii PROC FRAME USES rbx value:QWORD, buffer:QWORD, radix:DWORD, sign:DWORD, addzero:DWORD
    LOCAL tmpbuf[34]:BYTE 
    mov rbx,rdx      ;buffer
    mov r10,rdx      ;buffer
    .if (!rcx)
        mov rax,rdx
        mov byte ptr[rax],'0'
        jmp done
    .endif 
    .if (r9b)
        mov byte ptr [rdx],2Dh           
        lea r10,[rdx+1]       
        neg rcx
    .endif
    lea r9, tmpbuf[33]                     
    mov byte ptr tmpbuf[33],0
    lea r11, hextbl
    .repeat
        xor edx,edx                      ;clear rdx               
        mov rax,rcx                      ;value into rax
        dec r9                           ;make space for next char
        div r8                           ;div value with radix (2, 8, 10, 16)
        mov rcx,rax                      ;mod is in rdx, save result back in rcx
        movzx eax,byte ptr [rdx+r11]     ;put char from hextbl pointed by rdx
        mov byte ptr [r9], al            ;store char from al to tmpbuf pointed by r9
    .until (!rcx)                        ;repeat if rcx not clear
    .if (addzero && al > '9')            ;add a leading '0' if first digit is alpha
        mov word ptr[r10],'x0'
        add r10, 2
        ;mov byte ptr[r10],'0'
        ;inc r10
    .endif
    lea r8, tmpbuf[34]                   ;start of the buffer in r8
    sub r8, r9                           ;that will give a count of chars to be copied
    invoke RtlMoveMemory, r10, r9, r8    ;call routine to copy
    mov rax,rbx                          ;return the address of the buffer in rax
done: ret
_MUI_ProgressBarQwordToAscii ENDP


MODERNUI_LIBEND




