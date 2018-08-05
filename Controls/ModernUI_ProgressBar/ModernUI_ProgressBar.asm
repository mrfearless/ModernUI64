;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_ProgressBar x64 v1.0.0.0
;
; Copyright (c) 2016 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/ModernUI
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

;IFDEF DEBUG64
;    PRESERVEXMMREGS equ 1
;    includelib \JWasm\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'\Jwasm\bin\DbgWin.exe'>
;    include \JWasm\include\debug64.inc
;    .DATA
;    RDBG_DbgWin	DB DEBUGEXE,0
;    .CODE
;ENDIF

include windows.inc
includelib user32.lib
includelib kernel32.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_ProgressBar.inc

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
_MUI_ProgressBarWndProc					PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_ProgressBarInit					PROTO :QWORD
_MUI_ProgressBarPaint					PROTO :QWORD
_MUI_ProgressBarCalcWidth               PROTO :QWORD, :QWORD


;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; External public properties
MUI_PROGRESSBAR_PROPERTIES				STRUCT
	qwTextColor							DQ ?
	qwTextFont							DQ ?
	qwBackColor							DQ ?
    dwProgressColor 					DQ ?
    dwBorderColor   					DQ ?
    dwPercent       					DQ ?
    dwMin          					    DQ ?
    dwMax          					    DQ ?
    dwStep                              DQ ?	
MUI_PROGRESSBAR_PROPERTIES				ENDS

; Internal properties
_MUI_PROGRESSBAR_PROPERTIES				STRUCT
	qwEnabledState						DQ ?
	qwMouseOver							DQ ?
	dwProgressBarWidth                  DQ ?	
_MUI_PROGRESSBAR_PROPERTIES				ENDS


.CONST
; Internal properties
@ProgressBarEnabledState				EQU 0
@ProgressBarMouseOver					EQU 8
@ProgressBarWidth                       EQU 16

; External public properties


.DATA
szMUIProgressBarClass					DB 'ModernUI_ProgressBar',0 	; Class name for creating our ModernUI_ProgressBar control
szMUIProgressBarFont                    DB 'Segoe UI',0             	; Font used for ModernUI_ProgressBar text
hMUIProgressBarFont                     DQ 0                        	; Handle to ModernUI_ProgressBar font (segoe ui)


.CODE

ALIGN 8

;-------------------------------------------------------------------------------------
; Set property for ModernUI_ProgressBar control
;-------------------------------------------------------------------------------------
MUIProgressBarSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUIProgressBarSetProperty ENDP


;-------------------------------------------------------------------------------------
; Get property for ModernUI_ProgressBar control
;-------------------------------------------------------------------------------------
MUIProgressBarGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUIProgressBarGetProperty ENDP


;-------------------------------------------------------------------------------------
; MUIProgressBarRegister - Registers the ModernUI_ProgressBar control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_ProgressBar
;-------------------------------------------------------------------------------------
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


;-------------------------------------------------------------------------------------
; MUIProgressBarCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUIProgressBarCreate PROC FRAME hWndParent:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUIProgressBarRegister
	
    ; Modify styles appropriately - for visual controls no CS_HREDRAW CS_VREDRAW (causes flickering)
	; probably need WS_CHILD, WS_VISIBLE. Needs WS_CLIPCHILDREN. Non visual prob dont need any of these.
	
    Invoke CreateWindowEx, NULL, Addr szMUIProgressBarClass, NULL, WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUIProgressBarCreate ENDP



;-------------------------------------------------------------------------------------
; _MUI_ProgressBarWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_ProgressBarWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    
    mov eax,uMsg
    .IF eax == WM_NCCREATE
        mov rbx, lParam
		; sets text of our control, delete if not required.
        Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName	
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_PROGRESSBAR_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_PROGRESSBAR_PROPERTIES ; external properties
		Invoke _MUI_ProgressBarInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_ProgressBarPaint, hWin
        mov rax, 0
        ret

 	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
		mov rax, wParam
		.IF rax == @ProgressBarPercent
		    Invoke MUIProgressBarSetPercent, hWin, wParam
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


;-------------------------------------------------------------------------------------
; _MUI_ProgressBarInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_ProgressBarInit PROC FRAME hControl:QWORD
    LOCAL ncm:NONCLIENTMETRICS
    LOCAL lfnt:LOGFONT
    LOCAL hFont:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    
    Invoke GetParent, hControl
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hControl, GWL_STYLE
    mov qwStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, qwStyle
        or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov qwStyle, rax
        Invoke SetWindowLongPtr, hControl, GWL_STYLE, qwStyle
    .ENDIF
    ;PrintDec qwStyle
    
    ; Set default initial external property values     
    Invoke MUISetExtProperty, hControl, @ProgressBarTextColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hControl, @ProgressBarBackColor, MUI_RGBCOLOR(193,193,193)
    Invoke MUISetExtProperty, hControl, @ProgressBarBorderColor, 0 ; MUI_RGBCOLOR(163,163,163)
    Invoke MUISetExtProperty, hControl, @ProgressBarProgressColor, MUI_RGBCOLOR(27,161,226)

    Invoke MUISetExtProperty, hControl, @ProgressBarPercent, 0
    Invoke MUISetExtProperty, hControl, @ProgressBarMin, 0
    Invoke MUISetExtProperty, hControl, @ProgressBarMax, 100
    Invoke MUISetIntProperty, hControl, @ProgressBarWidth, 0
    
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
    Invoke MUISetExtProperty, hControl, @ProgressBarTextFont, hMUIProgressBarFont

    ret

_MUI_ProgressBarInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_ProgressBarPaint
;-------------------------------------------------------------------------------------
_MUI_ProgressBarPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rectprogress:RECT
    LOCAL rect:RECT
    LOCAL pt:POINT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBrush:QWORD
    LOCAL hPen:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL hOldPen:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL Percent:QWORD
    LOCAL MouseOver:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL BorderColor:QWORD
    LOCAL ProgressColor:QWORD    
    LOCAL hParent:QWORD
	LOCAL qwStyle:QWORD

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke GetClientRect, hWin, Addr rect
	Invoke CreateCompatibleDC, hdc
	mov hdcMem, rax
	Invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
	mov hbmMem, rax
	Invoke SelectObject, hdcMem, hbmMem
	mov hOldBitmap, rax
	
	;----------------------------------------------------------
	; Get some property values
	;----------------------------------------------------------	
	; Use Invoke _MUIGetProperty, hWin, 4, @Property 
	; to get property required: text, back, border colors etc
	; save them to local vars for processing later in function
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax

    Invoke MUIGetExtProperty, hWin, @ProgressBarTextColor        ; normal text color
    mov TextColor, rax
    Invoke MUIGetExtProperty, hWin, @ProgressBarBackColor        ; normal back color
    mov BackColor, rax
    Invoke MUIGetExtProperty, hWin, @ProgressBarBorderColor        ; normal back color
    mov BorderColor, rax
    Invoke MUIGetExtProperty, hWin, @ProgressBarTextFont        
    mov hFont, rax	
    Invoke MUIGetExtProperty, hWin, @ProgressBarPercent        
    mov Percent, rax	
    Invoke MUIGetExtProperty, hWin, @ProgressBarProgressColor
	mov ProgressColor, rax
	
	Invoke CopyRect, Addr rectprogress, Addr rect
	
	;----------------------------------------------------------
	; Fill background
	;----------------------------------------------------------
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr BackColor
    Invoke FillRect, hdcMem, Addr rect, hBrush


	;----------------------------------------------------------
	; Draw Progress
	;----------------------------------------------------------
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    .IF hOldBrush != 0
        Invoke DeleteObject, hOldBrush
    .ENDIF 
    
    
    Invoke MUIGetIntProperty, hWin, @ProgressBarWidth
    mov rectprogress.right, eax

    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdcMem, dword ptr ProgressColor
    Invoke FillRect, hdcMem, Addr rectprogress, hBrush

	;----------------------------------------------------------
	; Border
	;----------------------------------------------------------
    .IF BorderColor != 0
        .IF hBrush != 0
            Invoke DeleteObject, hBrush
        .ENDIF
        .IF hOldBrush != 0
            Invoke DeleteObject, hOldBrush
        .ENDIF    
        Invoke GetStockObject, DC_BRUSH
        mov hBrush, rax
        Invoke SelectObject, hdcMem, rax
        mov hOldBrush, rax
        Invoke SetDCBrushColor, hdcMem, dword ptr BorderColor
        Invoke FrameRect, hdcMem, Addr rect, hBrush
    .ENDIF

    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Cleanup
    ;----------------------------------------------------------
    Invoke DeleteDC, hdcMem
    Invoke DeleteObject, hbmMem
    .IF hOldBitmap != 0
        Invoke DeleteObject, hOldBitmap
    .ENDIF		
    .IF hOldFont != 0
        Invoke DeleteObject, hOldFont
    .ENDIF
    .IF hOldPen != 0
        Invoke DeleteObject, hOldPen
    .ENDIF
    .IF hOldBrush != 0
        Invoke DeleteObject, hOldBrush
    .ENDIF        
    .IF hPen != 0
        Invoke DeleteObject, hPen
    .ENDIF
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF
    
    Invoke EndPaint, hWin, Addr ps

    ret
_MUI_ProgressBarPaint ENDP



;-------------------------------------------------------------------------------------
; _MUI_ProgressBarCalcWidth
;-------------------------------------------------------------------------------------
_MUI_ProgressBarCalcWidth PROC FRAME USES RBX hControl:QWORD, qwPercent:QWORD
    LOCAL rect:RECT
    LOCAL qwProgressWidth:QWORD
    LOCAL qwWidth:QWORD
    LOCAL nTmp:QWORD

    Invoke GetWindowRect, hControl, Addr rect
    
    mov eax, rect.right
    mov ebx, rect.left
    sub eax, ebx
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


;-------------------------------------------------------------------------------------
; MUIProgressBarSetMinMax
;-------------------------------------------------------------------------------------
MUIProgressBarSetMinMax PROC FRAME hControl:QWORD, qwMin:QWORD, qwMax:QWORD
    Invoke MUISetExtProperty, hControl, @ProgressBarMin, qwMin
    Invoke MUISetExtProperty, hControl, @ProgressBarMax, qwMax
    ret
MUIProgressBarSetMinMax ENDP



;-------------------------------------------------------------------------------------
; MUIProgressBarSetPercent
;-------------------------------------------------------------------------------------
MUIProgressBarSetPercent PROC FRAME hControl:QWORD, qwPercent:QWORD
    LOCAL qwOldPercent:QWORD
    LOCAL qwNewPercent:QWORD
    LOCAL qwOldWidth:QWORD
    LOCAL qwNewWidth:QWORD
    LOCAL qwCurrentWidth:QWORD

    Invoke MUIGetExtProperty, hControl, @ProgressBarPercent
    mov qwOldPercent, rax
    
    mov rax, qwPercent
    mov qwNewPercent, rax
    
    

    
    .IF sqword ptr qwNewPercent >= 0 && sqword ptr qwNewPercent <= 100
        ;Invoke MUISetExtProperty, hControl, @ProgressBarPercent, dwPercent
        ;Invoke InvalidateRect, hControl, NULL, TRUE
        
    ;PrintDec dwOldPercent
    ;PrintDec dwNewPercent
        
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
            mov rax, qwCurrentWidth
            .WHILE sqword ptr rax >= qwNewWidth
            
                Invoke MUISetIntProperty, hControl, @ProgressBarWidth, qwCurrentWidth
                Invoke InvalidateRect, hControl, NULL, FALSE
                Invoke UpdateWindow, hControl
                ;Invoke Sleep, 1
                
                ;PrintDec dwCurrentWidth
                dec qwCurrentWidth
                mov rax, qwCurrentWidth
            .ENDW
        
        .ENDIF
        
        Invoke MUISetExtProperty, hControl, @ProgressBarPercent, qwNewPercent        
        Invoke UpdateWindow, hControl
    .ENDIF
    
    mov rax, qwNewPercent
    
    ret
MUIProgressBarSetPercent ENDP


;-------------------------------------------------------------------------------------
; MUIProgressBarGetPercent
;-------------------------------------------------------------------------------------
MUIProgressBarGetPercent PROC FRAME hControl:QWORD
    Invoke MUIGetExtProperty, hControl, @ProgressBarPercent
    ret
MUIProgressBarGetPercent ENDP



;-------------------------------------------------------------------------------------
; MUIProgressBarStep
;-------------------------------------------------------------------------------------
MUIProgressBarStep PROC FRAME hControl:QWORD
    LOCAL qwOldPercent:QWORD
    LOCAL qwNewPercent:QWORD
    LOCAL qwOldWidth:QWORD
    LOCAL qwNewWidth:QWORD
    LOCAL qwCurrentWidth:QWORD
    
    ;PrintText 'MUIProgressBarStep'
    
    Invoke MUIGetExtProperty, hControl, @ProgressBarPercent
    mov qwOldPercent, rax
    inc rax
    mov qwNewPercent, rax
    .IF sqword ptr qwNewPercent >= 0 && sqword ptr qwNewPercent <= 100
        
        
        Invoke _MUI_ProgressBarCalcWidth, hControl, qwOldPercent
        mov qwOldWidth, rax
        mov qwCurrentWidth, rax

        Invoke _MUI_ProgressBarCalcWidth, hControl, qwNewPercent
        mov qwNewWidth, rax
        
        mov rax, qwCurrentWidth
        .WHILE sqword ptr rax <= qwNewWidth
        
            Invoke MUISetIntProperty, hControl, @ProgressBarWidth, qwCurrentWidth
            Invoke InvalidateRect, hControl, NULL, FALSE
            Invoke UpdateWindow, hControl
            Invoke Sleep, 1
            
            ;PrintDec dwCurrentWidth
            inc qwCurrentWidth
            mov rax, qwCurrentWidth
        .ENDW

        Invoke MUISetExtProperty, hControl, @ProgressBarPercent, qwNewPercent

    .ENDIF
    mov rax, qwNewPercent
    ;PrintDec dwNewPercent
    
    ret
MUIProgressBarStep ENDP



END
