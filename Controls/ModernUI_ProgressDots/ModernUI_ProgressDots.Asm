;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_ProgressDots x64 v1.0.0.0
;
; Copyright (c) 2018 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/ModernUI64
;
;======================================================================================================================================
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
;
;IFDEF DEBUG64
;    PRESERVEXMMREGS equ 1
;    includelib \UASM\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'M:\UASM64\bin\DbgWin.exe'>
;    include \UASM\include\debug64.inc
;    .DATA
;    RDBG_DbgWin	DB DEBUGEXE,0
;    .CODE
;ENDIF

include windows.inc
include commctrl.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib comctl32.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_ProgressDots.inc

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
_MUI_ProgressDotsWndProc			PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_ProgressDotsParentSubClassProc PROTO :HWND, :UINT, :WPARAM, :LPARAM, :UINT, :QWORD
_MUI_ProgressDotsInit               PROTO :QWORD
_MUI_ProgressDotsResize             PROTO :QWORD
_MUI_ProgressDotsPaint              PROTO :QWORD

_MUI_ProgressDotsPaintBackground    PROTO :QWORD, :QWORD, :QWORD 
_MUI_ProgressDotsPaintDots          PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_ProgressDotsCalcPositions      PROTO :QWORD
_MUI_ProgressDotsInitDots           PROTO :QWORD
_MUI_ProgressBarTimerProc           PROTO :QWORD, :QWORD


;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; External public properties
MUI_PROGRESSDOTS_PROPERTIES             STRUCT
    qwBackColor                         DQ ?
    qwDotColor                          DQ ?
    qwDotsShowInterval                  DQ ?
    qwDotsTimeInterval                  DQ ?
    qwDotsSpeed                         DQ ?
MUI_PROGRESSDOTS_PROPERTIES             ENDS

DOTS_USE_TIMERQUEUE                     EQU 1 ; comment out to use WM_SETIMER instead of TimerQueue

; Internal properties
_MUI_PROGRESSDOTS_PROPERTIES            STRUCT
    qwAnimateState                      DQ ?
    qwMarkerStart                       DQ ?
    qwMarkerFinish                      DQ ?
    pDotsArray                          DQ ?
    IFDEF DOTS_USE_TIMERQUEUE
    bUseTimerQueue                      DQ ?
    hQueue                              DQ ?
    hTimer                              DQ ?
    ENDIF    
_MUI_PROGRESSDOTS_PROPERTIES            ENDS


DOTINFO                                 STRUCT
    bVisible                            DQ 0
    xPos                                DQ 0
    ;qwSpeed                             DD 0
    ;qwMoveCountdown                     DD 0
    qwShowCountdown                     DQ 0
DOTINFO                                 ENDS


.CONST
MAX_DOTS                                EQU 5  ; No of dots to show - 5 or so looks ok
DOTS_SHOW_INTERVAL                      EQU 16 ; countdown til dot starts showing in animation
DOTS_TIME_INTERVAL                      EQU 10 ; Milliseconds for timer firing, 10 seems fine, increasing this will slow down animations
DOTS_SPEED                              EQU 2  ; Speed of the fastest dots before and after middle section
DOTS_DEFAULT_SIZE                       EQU 4  ; Default height and width of control and also dots


; Internal properties
@ProgressDotsAnimateState               EQU 0
@ProgressDotsMarkerStart                EQU 8
@ProgressDotsMarkerFinish               EQU 16
@ProgressDotsDotsArray                  EQU 24
IFDEF DOTS_USE_TIMERQUEUE
@ProgressDotsUseTimerQueue              EQU 32
@ProgressDotsQueue                      EQU 40
@ProgressDotsTimer                      EQU 48
ENDIF

; External public properties


.DATA
szMUIProgressDotsClass                  DB 'ModernUI_ProgressDots',0    ; Class name for creating our ProgressDots control



.CODE
;-------------------------------------------------------------------------------------
; Set property for ModernUI_ProgressDots control
;-------------------------------------------------------------------------------------
MUIProgressDotsSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUIProgressDotsSetProperty ENDP


;-------------------------------------------------------------------------------------
; Get property for ModernUI_ProgressDots control
;-------------------------------------------------------------------------------------
MUIProgressDotsGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUIProgressDotsGetProperty ENDP


;-------------------------------------------------------------------------------------
; MUIProgressDotsRegister - Registers the ModernUI_ProgressDots control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_ProgressDots
;-------------------------------------------------------------------------------------
MUIProgressDotsRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUIProgressDotsClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUIProgressDotsClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_ProgressDotsWndProc
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

MUIProgressDotsRegister ENDP


;-------------------------------------------------------------------------------------
; MUIProgressDotsCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUIProgressDotsCreate PROC FRAME hWndParent:QWORD, ypos:QWORD, controlheight:QWORD, qwResourceID:QWORD, dwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
    LOCAL rect:RECT
    LOCAL qwHeight:QWORD
    LOCAL qwWidth:QWORD	
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUIProgressDotsRegister
	
    Invoke GetWindowRect, hWndParent, Addr rect
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    dec eax
    dec eax
    mov qwWidth, rax
    
    mov rax, controlheight
    .IF rax == 0
        mov rax, DOTS_DEFAULT_SIZE
    .ENDIF
    mov qwHeight, rax
	
    Invoke CreateWindowEx, NULL, Addr szMUIProgressDotsClass, NULL, WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS, 1, dword ptr ypos, dword ptr qwWidth, dword ptr qwHeight, hWndParent, qwResourceID, hinstance, NULL
    mov hControl, rax
    .IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUIProgressDotsCreate ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    mov eax, uMsg
    .IF eax == WM_NCCREATE
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_PROGRESSDOTS_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_PROGRESSDOTS_PROPERTIES ; external properties
		Invoke _MUI_ProgressDotsInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
		mov rax, 0
		ret           
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_ProgressDotsPaint, hWin
        mov rax, 0
        ret

    .ELSEIF eax == WM_SIZE
        Invoke _MUI_ProgressDotsResize, hWin
        mov rax, 0
        ret      

    .ELSEIF eax == WM_TIMER
        mov rax, wParam
        .IF rax == hWin
            Invoke _MUI_ProgressDotsCalcPositions, hWin
            Invoke InvalidateRect, hWin, NULL, TRUE
            Invoke UpdateWindow, hWin
        .ENDIF
	
	; custom messages start here
    .ELSEIF eax == MUIPDM_ANIMATESTART
        Invoke MUIProgressDotsAnimateStart, hWin
        ret

    .ELSEIF eax == MUIPDM_ANIMATESTOP
        Invoke MUIProgressDotsAnimateStop, hWin
        ret

	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
		Invoke MUISetExtProperty, hWin, wParam, lParam
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_ProgressDotsWndProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsParentSubClassProc - Subclass for progressdots parent window 
; qwRefData is the handle to our progressdots control in this subclass proc
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsParentSubClassProc PROC FRAME hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM, uIdSubclass:UINT, qwRefData:QWORD

    mov eax, uMsg
    .IF eax == WM_NCDESTROY
        Invoke RemoveWindowSubclass, hWin, Addr _MUI_ProgressDotsParentSubClassProc, uIdSubclass ; remove subclass before control destroyed.
        Invoke DefSubclassProc, hWin, uMsg, wParam, lParam
        ret

    .ELSEIF eax == WM_SIZE
        Invoke SendMessage, qwRefData, WM_SIZE, 0, 0 ; force resize of progressdots

    .ENDIF
    
    Invoke DefSubclassProc, hWin, uMsg, wParam, lParam 
    ret        
_MUI_ProgressDotsParentSubClassProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsInit PROC FRAME USES RBX RDX hWin:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    LOCAL pDotsArray:QWORD
    LOCAL rect:RECT
    LOCAL qwWidth:QWORD
    LOCAL qwMarkerStart:QWORD
    LOCAL qwMarkerFinish:QWORD    
    
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

    ; Set default initial internal property values
    Invoke MUISetIntProperty, hWin, @ProgressDotsAnimateState, FALSE
    IFDEF DOTS_USE_TIMERQUEUE
        Invoke MUISetIntProperty, hWin, @ProgressDotsUseTimerQueue, TRUE
        Invoke MUISetIntProperty, hWin, @ProgressDotsQueue, 0
        Invoke MUISetIntProperty, hWin, @ProgressDotsTimer, 0
    ENDIF
    
    ; Set default initial external property values
    Invoke MUIGetParentBackgroundColor, hWin
    .IF rax == -1 ; if background was NULL then try a color as default
        Invoke GetSysColor, COLOR_WINDOW
    .ENDIF
    Invoke MUISetExtProperty, hWin, @ProgressDotsBackColor, rax ;MUI_RGBCOLOR(48,48,48) ;eax    
    Invoke MUISetExtProperty, hWin, @ProgressDotsDotColor, MUI_RGBCOLOR(53,133,211)
    Invoke MUISetExtProperty, hWin, @ProgressDotsShowInterval, DOTS_SHOW_INTERVAL
    Invoke MUISetExtProperty, hWin, @ProgressDotsTimeInterval, DOTS_TIME_INTERVAL
    Invoke MUISetExtProperty, hWin, @ProgressDotsSpeed, DOTS_SPEED    

    ; Calc makers for middle section of control, where dots are slowest
    Invoke GetClientRect, hWin, Addr rect
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    mov qwWidth, rax
    ; magic no by qword to div by 3
    mov rbx, qwWidth
    mov rax, 05555555555555556h
    imul rbx
    shr rbx,63d
    add rdx, rbx
    ; quotient now in edx
    mov qwMarkerStart, rdx
    add rdx, rdx
    mov qwMarkerFinish, rdx

    Invoke MUISetIntProperty, hWin, @ProgressDotsMarkerStart, qwMarkerStart
    Invoke MUISetIntProperty, hWin, @ProgressDotsMarkerFinish, qwMarkerFinish

    ; Calc space for allocating no of dots to show
    mov rbx, MAX_DOTS
    mov rax, SIZEOF DOTINFO
    mul rbx
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    .IF rax == NULL
        mov rax, 1
        ret
    .ENDIF
    mov pDotsArray, rax
    Invoke MUISetIntProperty, hWin, @ProgressDotsDotsArray, pDotsArray
    
    ; subclass parent to react to resize notifications, to reset our controls animation and internal markers etc
    Invoke SetWindowSubclass, hParent, Addr _MUI_ProgressDotsParentSubClassProc, hWin, hWin

    mov rax, 0
    ret

_MUI_ProgressDotsInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsResize
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsResize PROC FRAME USES RBX RDX hWin:QWORD
    LOCAL hParent:QWORD
    LOCAL rect:RECT
    LOCAL parentrect:RECT
    LOCAL qwWidth:QWORD
    LOCAL qwHeight:QWORD
    LOCAL qwMarkerStart:QWORD
    LOCAL qwMarkerFinish:QWORD
    LOCAL hDefer:QWORD
    LOCAL AnimateState:QWORD

    Invoke MUIGetIntProperty, hWin, @ProgressDotsAnimateState
    mov AnimateState, rax
    .IF AnimateState == TRUE
        Invoke MUIProgressDotsAnimateStop, hWin ; stop animation whilst resize occurs
    .ENDIF    

    Invoke GetClientRect, hWin, Addr rect
    xor rax, rax
    mov eax, rect.bottom
    sub eax, rect.top
    mov qwHeight, rax

    Invoke GetParent, hWin
    mov hParent, rax
    
    Invoke GetWindowRect, hParent, Addr parentrect
    xor rax, rax
    mov eax, parentrect.right
    sub eax, parentrect.left
    dec eax
    dec eax
    mov qwWidth, rax
    
    Invoke BeginDeferWindowPos, 1
    mov hDefer, rax
    .IF hDefer == NULL
        Invoke SetWindowPos, hWin, NULL, 0, 0, qwWidth, qwHeight, SWP_NOZORDER or SWP_NOOWNERZORDER  or SWP_NOACTIVATE or SWP_NOMOVE ;or SWP_NOSENDCHANGING ;or SWP_NOCOPYBITS
    .ELSE
        Invoke DeferWindowPos, hDefer, hWin, NULL, 0, 0, qwWidth, qwHeight, SWP_NOZORDER or SWP_NOOWNERZORDER or SWP_NOACTIVATE or SWP_NOMOVE ;or SWP_NOSENDCHANGING
        mov hDefer, rax
    .ENDIF
    .IF hDefer != NULL
        Invoke EndDeferWindowPos, hDefer
    .ENDIF    

    ;Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke GetClientRect, hWin, Addr rect
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    mov qwWidth, rax
    ; div by 3
    mov rbx,qwWidth
    mov rax, 05555555555555556h
    imul rbx
    shr rbx,63d
    add rdx, rbx
    ; quotient now in edx
    mov qwMarkerStart, rdx
    add rdx, rdx
    mov qwMarkerFinish, rdx    
    Invoke MUISetIntProperty, hWin, @ProgressDotsMarkerStart, qwMarkerStart
    Invoke MUISetIntProperty, hWin, @ProgressDotsMarkerFinish, qwMarkerFinish    
    
    ; reset everything otherwise graphically it looks odd
    Invoke _MUI_ProgressDotsInitDots, hWin
    
    .IF AnimateState == TRUE
        Invoke MUIProgressDotsAnimateStart, hWin ; restart animation if it was started previously
    .ENDIF        
    
    ret
_MUI_ProgressDotsResize ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsPaint
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:QWORD
    LOCAL hdcMem:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL AnimateState:QWORD

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    Invoke IsWindowVisible, hWin
    .IF rax == 0
        Invoke EndPaint, hWin, Addr ps
        ret
    .ENDIF
    
    ;----------------------------------------------------------
    ; Get some property values
    ;---------------------------------------------------------- 
    Invoke MUIGetIntProperty, hWin, @ProgressDotsAnimateState
    mov AnimateState, rax    

    Invoke GetClientRect, hWin, Addr rect    

    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax
    Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
    mov hbmMem, rax
    Invoke SelectObject, hdcMem, hbmMem
    mov hOldBitmap, rax

    ;----------------------------------------------------------
    ; Background
    ;----------------------------------------------------------
    Invoke _MUI_ProgressDotsPaintBackground, hWin, hdcMem, Addr rect

    .IF AnimateState == TRUE

        ;----------------------------------------------------------
        ; Dots
        ;----------------------------------------------------------
        Invoke _MUI_ProgressDotsPaintDots, hWin, hdc, hdcMem, Addr rect
    
    .ENDIF

    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke SelectObject, hdcMem, hbmMem
    Invoke DeleteObject, hbmMem
    Invoke DeleteDC, hdcMem

    Invoke EndPaint, hWin, Addr ps

    ret
_MUI_ProgressDotsPaint ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsPaintBackground
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    
    Invoke MUIGetExtProperty, hWin, @ProgressDotsBackColor
    mov BackColor, rax
    
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdc, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdc, dword ptr BackColor
    Invoke FillRect, hdc, lpRect, hBrush
    
    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF      
    ret
_MUI_ProgressDotsPaintBackground ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsCalcPositions - calculate x, y positions of images, text etc
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsCalcPositions PROC FRAME USES RBX hWin:QWORD
    LOCAL rect:RECT
    LOCAL qwWidth:QWORD
    LOCAL qwMarkerStart:QWORD
    LOCAL qwMarkerFinish:QWORD
    LOCAL pDotsArray:QWORD
    LOCAL pCurrentDot:QWORD
    LOCAL xPos:QWORD
    LOCAL bVisible:QWORD
    LOCAL qwSpeed:QWORD
    LOCAL nDot:QWORD
    LOCAL qwShowCountdown:QWORD
    LOCAL qwDefaultShowInterval:QWORD

    Invoke GetClientRect, hWin, Addr rect
    xor rax, rax
    mov eax, rect.right
    sub eax, rect.left
    mov qwWidth, rax

    Invoke MUIGetExtProperty, hWin, @ProgressDotsSpeed
    mov qwSpeed, rax
    Invoke MUIGetExtProperty, hWin, @ProgressDotsShowInterval
    mov qwDefaultShowInterval, rax
    Invoke MUIGetIntProperty, hWin, @ProgressDotsMarkerStart
    mov qwMarkerStart, rax
    Invoke MUIGetIntProperty, hWin, @ProgressDotsMarkerFinish
    mov qwMarkerFinish, rax
    Invoke MUIGetIntProperty, hWin, @ProgressDotsDotsArray
    mov pDotsArray, rax
    mov pCurrentDot, rax

    mov nDot, 0
    mov rax, 0
    .WHILE rax < MAX_DOTS
        mov rbx, pCurrentDot
        mov rax, [rbx].DOTINFO.bVisible
        mov bVisible, rax
        mov rax, [rbx].DOTINFO.xPos
        mov xPos, rax
        mov rax, [rbx].DOTINFO.qwShowCountdown
        mov qwShowCountdown, rax

        .IF bVisible == FALSE
            .IF qwShowCountdown == 0 ; time to show dot and start it moving
                mov rbx, pCurrentDot
                mov [rbx].DOTINFO.bVisible, TRUE
                mov [rbx].DOTINFO.xPos, 0
            .ELSE ; otherwise continue countdown till it shows
                mov rax, qwShowCountdown
                dec rax
                mov rbx, pCurrentDot
                mov [rbx].DOTINFO.qwShowCountdown, rax
            .ENDIF
        
        .ELSE ; VISIBLE
            
            mov rax, xPos
            .IF rax >= qwMarkerStart && rax < qwMarkerFinish ; between markers - slowest

                mov rax, xPos
                inc rax
                mov rbx, pCurrentDot
                mov [rbx].DOTINFO.xPos, rax

            .ELSEIF rax >= 0 && rax < qwMarkerStart ; before first marker
                
                mov rax, qwSpeed
                shl rax, 1 ; times 2 to make it faster
                add rax, xPos
                mov rbx, pCurrentDot
                mov [rbx].DOTINFO.xPos, rax

            .ELSEIF rax >= qwMarkerFinish && rax <= qwWidth ; between last marker and end of control

                mov rax, qwSpeed
                shl rax, 1 ; times 2 to make it faster
                add rax, xPos
                mov rbx, pCurrentDot
                mov [rbx].DOTINFO.xPos, rax

            .ELSEIF rax > qwWidth ; reached end, so reset dot to continue for next cycle of dots

                mov rbx, pCurrentDot
                mov [rbx].DOTINFO.bVisible, FALSE
                mov [rbx].DOTINFO.xPos, 0
                mov rax, qwDefaultShowInterval;DOTS_SHOW_INTERVAL
                shl rax, 2
                mov [rbx].DOTINFO.qwShowCountdown, rax

            .ENDIF

        .ENDIF

        add pCurrentDot, SIZEOF DOTINFO
        inc nDot
        mov rax, nDot
    .ENDW    

    ret
_MUI_ProgressDotsCalcPositions ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsPaintDots
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsPaintDots PROC FRAME USES RBX hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD
    LOCAL pDotsArray:QWORD
    LOCAL pCurrentDot:QWORD
    LOCAL xPos:QWORD
    LOCAL bVisible:QWORD
    LOCAL nDot:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL rect:RECT
    LOCAL qwDotColor:QWORD
    LOCAL qwSize:QWORD
    
    Invoke MUIGetExtProperty, hWin, @ProgressDotsDotColor
    mov qwDotColor, rax
    
    Invoke MUIGetIntProperty, hWin, @ProgressDotsDotsArray
    mov pDotsArray, rax
    mov pCurrentDot, rax
    
    Invoke CopyRect, Addr rect, lpRect
    xor rax, rax
    mov eax, rect.bottom
    sub eax, rect.top
    mov qwSize, rax

    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcDest, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdcDest, dword ptr qwDotColor

    mov nDot, 0
    mov rax, 0
    .WHILE rax < MAX_DOTS
        mov rbx, pCurrentDot
        mov rax, [rbx].DOTINFO.bVisible
        mov bVisible, rax

        ; Paint dot
        .IF bVisible == TRUE

            mov rax, [rbx].DOTINFO.xPos
            mov xPos, rax
            mov rect.left, eax
            mov rect.right, eax
            mov rax, qwSize
            add rect.right, eax
            Invoke FillRect, hdcDest, Addr rect, hBrush
            ;Invoke FrameRect, hdcDest, Addr dotrect, hBrush            

        .ENDIF
        
        add pCurrentDot, SIZEOF DOTINFO
        inc nDot
        mov rax, nDot
    .ENDW

    .IF hOldBrush != 0
        Invoke SelectObject, hdcDest, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF  

    ret
_MUI_ProgressDotsPaintDots ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressDotsInitDots
;-------------------------------------------------------------------------------------
_MUI_ProgressDotsInitDots PROC FRAME USES RBX hWin:QWORD
    LOCAL pDotsArray:QWORD
    LOCAL pCurrentDot:QWORD
    LOCAL nDot:QWORD
    LOCAL qwShowInterval:QWORD
    LOCAL qwDefaultShowInterval:QWORD
    LOCAL rect:RECT
    LOCAL qwSize:QWORD

    Invoke MUIGetExtProperty, hWin, @ProgressDotsShowInterval
    mov qwDefaultShowInterval, rax

    Invoke MUIGetIntProperty, hWin, @ProgressDotsDotsArray
    mov pDotsArray, rax
    mov pCurrentDot, rax
    
    Invoke GetClientRect, hWin, Addr rect
    xor rax, rax
    mov eax, rect.bottom
    sub eax, rect.top
    mov qwSize, rax

    mov qwShowInterval, 0

    mov nDot, 0
    mov rax, 0
    .WHILE rax < MAX_DOTS
        mov rbx, pCurrentDot
        
        mov [rbx].DOTINFO.bVisible, FALSE
        mov rax, 0
        sub rax, qwSize
        mov [rbx].DOTINFO.xPos, rax
        mov rax, qwShowInterval
        mov [rbx].DOTINFO.qwShowCountdown, rax

        ;mov [ebx].DOTINFO.dwSpeed, 0
        ;mov [ebx].DOTINFO.dwMoveCountdown, 0

        mov rax, qwShowInterval
        add rax, qwDefaultShowInterval
        mov qwShowInterval, rax
        
        add pCurrentDot, SIZEOF DOTINFO
        inc nDot
        mov rax, nDot
    .ENDW

    ret

_MUI_ProgressDotsInitDots ENDP


;-------------------------------------------------------------------------------------
; MUIProgressDotsAnimateStart
;-------------------------------------------------------------------------------------
MUIProgressDotsAnimateStart PROC FRAME hControl:QWORD
    LOCAL qwTimeInterval:QWORD
    IFDEF DOTS_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    LOCAL hTimer:QWORD
    ENDIF
    
    Invoke ShowWindow, hControl, SW_SHOWNA
    Invoke _MUI_ProgressDotsInitDots, hControl
    Invoke MUISetIntProperty, hControl, @ProgressDotsAnimateState, TRUE
    Invoke MUIGetExtProperty, hControl, @ProgressDotsTimeInterval
    .IF rax == 0
        Invoke MUISetIntProperty, hControl, @ProgressDotsTimeInterval, DOTS_TIME_INTERVAL
        mov rax, DOTS_TIME_INTERVAL
    .ENDIF
    mov qwTimeInterval, rax

    Invoke InvalidateRect, hControl, NULL, TRUE
    
    IFDEF DOTS_USE_TIMERQUEUE
    
        Invoke MUIGetIntProperty, hControl, @ProgressDotsUseTimerQueue
        .IF rax == TRUE
            Invoke MUIGetIntProperty, hControl, @ProgressDotsQueue
            mov hQueue, rax
            Invoke MUIGetIntProperty, hControl, @ProgressDotsTimer
            mov hTimer, rax
            .IF hQueue != NULL ; re-use existing hQueue
                Invoke ChangeTimerQueueTimer, hQueue, hTimer, dword ptr qwTimeInterval, dword ptr qwTimeInterval
                .IF rax == 0 ; failed 
                    Invoke DeleteTimerQueueEx, hQueue, FALSE
                    Invoke MUISetIntProperty, hControl, @ProgressDotsQueue, 0
                    Invoke MUISetIntProperty, hControl, @ProgressDotsTimer, 0
                    Invoke MUISetIntProperty, hControl, @ProgressDotsUseTimerQueue, FALSE
                    Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
                .ENDIF
            .ELSE ; Try to create TimerQueue 
                Invoke CreateTimerQueue
                .IF rax != NULL
                    mov hQueue, rax
                    Invoke CreateTimerQueueTimer, Addr hTimer, hQueue, Addr _MUI_ProgressBarTimerProc, hControl, dword ptr qwTimeInterval, dword ptr qwTimeInterval, 0
                    .IF rax == 0 ; failed, so fall back to WM_TIMER usage
                        Invoke DeleteTimerQueueEx, hQueue, FALSE
                        Invoke MUISetIntProperty, hControl, @ProgressDotsQueue, 0
                        Invoke MUISetIntProperty, hControl, @ProgressDotsTimer, 0
                        Invoke MUISetIntProperty, hControl, @ProgressDotsUseTimerQueue, FALSE
                        Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
                    .ELSE ; Success! - so save TimerQueue handles for re-use
                        IFDEF DEBUG32
                        PrintText 'Using QueueTimer'
                        ENDIF
                        Invoke MUISetIntProperty, hControl, @ProgressDotsQueue, hQueue
                        Invoke MUISetIntProperty, hControl, @ProgressDotsTimer, hTimer
                    .ENDIF
                .ELSE ; failed, so fall back to WM_TIMER usage
                    Invoke MUISetIntProperty, hControl, @ProgressDotsUseTimerQueue, FALSE
                    Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
                .ENDIF
            .ENDIF
        .ELSE  ; Not using TimerQueue, previous failure?, so fall back to WM_TIMER usage
            Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
        .ENDIF
    
    ELSE ; compiled define says to use WM_TIMER instead
    
        Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
        
    ENDIF
    ret
MUIProgressDotsAnimateStart ENDP


;-------------------------------------------------------------------------------------
; MUIProgressDotsAnimateStop
;-------------------------------------------------------------------------------------
MUIProgressDotsAnimateStop PROC FRAME hControl:QWORD
    IFDEF DOTS_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    LOCAL hTimer:QWORD
    ENDIF
    
    Invoke ShowWindow, hControl, SW_HIDE
    IFDEF DOTS_USE_TIMERQUEUE
    
        Invoke MUIGetIntProperty, hControl, @ProgressDotsUseTimerQueue
        .IF rax == TRUE
            Invoke MUIGetIntProperty, hControl, @ProgressDotsQueue
            mov hQueue, rax
            Invoke MUIGetIntProperty, hControl, @ProgressDotsTimer
            mov hTimer, rax
            .IF hQueue != NULL
                Invoke ChangeTimerQueueTimer, hQueue, hTimer, INFINITE, 0
                .IF rax == 0 ; failed, fall back to use KillTimer for WM_TIMER usage
                    Invoke DeleteTimerQueueEx, hQueue, FALSE
                    Invoke MUISetIntProperty, hControl, @ProgressDotsQueue, 0
                    Invoke MUISetIntProperty, hControl, @ProgressDotsTimer, 0
                    Invoke MUISetIntProperty, hControl, @ProgressDotsUseTimerQueue, FALSE
                    Invoke KillTimer, hControl, hControl
                .ENDIF
            .ELSE ; fall back to use KillTimer for WM_TIMER usage
                Invoke MUISetIntProperty, hControl, @ProgressDotsUseTimerQueue, FALSE
                Invoke KillTimer, hControl, hControl
            .ENDIF
        .ELSE ; Not using TimerQueue, previous failure? back to use KillTimer for WM_TIMER usage
            Invoke KillTimer, hControl, hControl
        .ENDIF
        
    ELSE ; compiled define says to use WM_TIMER instead
    
        Invoke KillTimer, hControl, hControl
        
    ENDIF
    
    Invoke MUISetIntProperty, hControl, @ProgressDotsAnimateState, FALSE
    Invoke InvalidateRect, hControl, NULL, TRUE
    ret
MUIProgressDotsAnimateStop ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressBarTimerProc for TimerQueue
;-------------------------------------------------------------------------------------
IFDEF DOTS_USE_TIMERQUEUE
_MUI_ProgressBarTimerProc PROC FRAME USES RBX lpParam:QWORD, TimerOrWaitFired:QWORD
    ; lpParam is hControl
    Invoke _MUI_ProgressDotsCalcPositions, lpParam
    Invoke InvalidateRect, lpParam, NULL, TRUE
    Invoke UpdateWindow, lpParam
    ret
_MUI_ProgressBarTimerProc ENDP
ENDIF






END
