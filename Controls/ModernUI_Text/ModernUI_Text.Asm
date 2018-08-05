;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_Text x64 v1.0.0.0
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
;    DEBUGEXE textequ <'\UASM\bin\DbgWin.exe'>
;    include \UASM\include\debug64.inc
;    .DATA
;    RDBG_DbgWin	DB DEBUGEXE,0
;    .CODE
;ENDIF

include windows.inc
includelib user32.lib
includelib kernel32.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_Text.inc

;--------------------------------------------------------------------------------------------------------------------------------------
; Prototypes for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
_MUI_TextWndProc				PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_TextInit                   PROTO :QWORD
_MUI_TextPaint                  PROTO :QWORD
_MUI_TextPaintBackground        PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_TextPaintText              PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_TextCheckMultiline         PROTO :QWORD, :QWORD
_MUI_TextSetFontFamilySize      PROTO :QWORD, :QWORD


;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; External public properties
MUI_TEXT_PROPERTIES             STRUCT
    qwTextFont                  DQ ?
    qwTextColor                 DQ ?
    qwTextColorAlt              DQ ?
    qwTextColorDisabled         DQ ?
    qwTextBackColor             DQ ?
    qwTextBackColorAlt          DQ ?
    qwTextBackColorDisabled     DQ ?
MUI_TEXT_PROPERTIES             ENDS

; Internal properties
_MUI_TEXT_PROPERTIES            STRUCT
    qwEnabledState              DQ ?
    qwMouseOver                 DQ ?
_MUI_TEXT_PROPERTIES            ENDS


.CONST
MUI_TEXT_MAX_CHARS              EQU 2048
MUI_TEXT_NO_FONTTYPES           EQU 6
MUI_TEXT_NO_FONTSIZES           EQU 8


; Internal properties
@TextEnabledState				EQU 0
@TextMouseOver					EQU 8



.DATA
szLorumIpsumText                DB "Lorem ipsum dolor sit amet, cu meis summo platonem ius. Est solet abhorreant constituto id, minim nominavi appetere at qui. "
                                DB "Sed ea feugait officiis. Cu commodo persecuti nam, et minimum omittam prodesset mei. Usu ei duis feugiat platonem.",13,10,13,10
                                DB "Autem antiopam eam et. Qui omnesque concludaturque no, duo ad accusam philosophia. Graeci convenire theophrastus ea has, "
                                DB "eu mei paulo forensibus concludaturque. Ad sea ignota habemus adipiscing.",13,10,13,10
                                DB "Duo iusto minimum id, eos animal graecis et, eu mel tota minimum corpora. Te vix latine conclusionemque, cu eam brute posse primis. "
                                DB "Has an cibo elitr voluptatum, legere tritani te his. Consul libris gloriatur in nam, unum meliore sea an, graeci gloriatur id has. "
                                DB "Justo ornatus mnesarchum ius eu, ex suscipit voluptua incorrupte vim.",0,0,0,0     

szMUITextClass                  DB 'ModernUI_Text',0            ; Class name for creating our ModernUI_Text control
szMUITextFont                   DB 'Segoe UI',0                 ; Font used for ModernUI_Text text


szMUITextFontSegoe              DB 'Segoe UI',0 
szMUITextFontTahoma             DB 'Tahoma',0
szMUITextFontArial              DB 'Arial',0
szMUITextFontTimes              DB 'Times New Roman',0
szMUITextFontCourier            DB 'Courier New',0
szMUITextFontVerdana            DB 'Verdana',0

MUITextFontSegoeHandles         DQ MUI_TEXT_NO_FONTSIZES DUP (0)
MUITextFontTahomaHandles        DQ MUI_TEXT_NO_FONTSIZES DUP (0)
MUITextFontArialHandles         DQ MUI_TEXT_NO_FONTSIZES DUP (0)
MUITextFontTimesHandles         DQ MUI_TEXT_NO_FONTSIZES DUP (0)
MUITextFontCourierHandles       DQ MUI_TEXT_NO_FONTSIZES DUP (0)
MUITextFontVerdanaHandles       DQ MUI_TEXT_NO_FONTSIZES DUP (0)


.CODE

align 8

;-------------------------------------------------------------------------------------
; Set property for ModernUI_Text control
;-------------------------------------------------------------------------------------
MUITextSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUITextSetProperty ENDP


;-------------------------------------------------------------------------------------
; Get property for ModernUI_Text control
;-------------------------------------------------------------------------------------
MUITextGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUITextGetProperty ENDP


;-------------------------------------------------------------------------------------
; MUITextRegister - Registers the ModernUI_Text control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Text
;-------------------------------------------------------------------------------------
MUITextRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUITextClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUITextClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_TextWndProc
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

MUITextRegister ENDP


;-------------------------------------------------------------------------------------
; MUITextCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUITextCreate PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
    LOCAL qwNewStyle:QWORD
    
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUITextRegister
	
    mov rax, qwStyle
    mov qwNewStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        or qwNewStyle, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .ENDIF
	
    Invoke CreateWindowEx, NULL, Addr szMUITextClass, lpszText, dword ptr qwNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUITextCreate ENDP


;-------------------------------------------------------------------------------------
; _MUI_TextWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_TextWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT

    mov eax, uMsg
    .IF eax == WM_NCCREATE
        mov rbx, lParam
        Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName	
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_TEXT_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_TEXT_PROPERTIES ; external properties
		Invoke _MUI_TextInit, hWin
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
        Invoke _MUI_TextPaint, hWin
        mov rax, 0
        ret
        
    .ELSEIF eax== WM_SETCURSOR
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUITS_HAND
        .IF rax == MUITS_HAND
            invoke LoadCursor, NULL, IDC_HAND
        .ELSE
            invoke LoadCursor, NULL, IDC_ARROW
        .ENDIF
        Invoke SetCursor, rax
        mov rax, 0
        ret  

    .ELSEIF eax == WM_LBUTTONUP
		; simulates click on our control, delete if not required.
		Invoke GetDlgCtrlID, hWin
		mov rbx,rax
		Invoke GetParent, hWin
		Invoke PostMessage, rax, WM_COMMAND, rbx, hWin

   .ELSEIF rax == WM_MOUSEMOVE
        Invoke MUIGetIntProperty, hWin, @TextEnabledState
        .IF rax == TRUE   
    		Invoke MUISetIntProperty, hWin, @TextMouseOver , TRUE
    		.IF rax != TRUE
    		    ;Invoke ShowWindow, hWin, SW_HIDE
    		    Invoke InvalidateRect, hWin, NULL, TRUE
    		    ;Invoke ShowWindow, hWin, SW_SHOW
    		    mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
    		    mov TE.dwFlags, TME_LEAVE
    		    mov rax, hWin
    		    mov TE.hwndTrack, rax
    		    mov TE.dwHoverTime, NULL
    		    Invoke TrackMouseEvent, Addr TE
    		.ENDIF
        .ENDIF

    .ELSEIF eax == WM_MOUSELEAVE
        Invoke MUISetIntProperty, hWin, @TextMouseOver , FALSE
		;Invoke ShowWindow, hWin, SW_HIDE
		Invoke InvalidateRect, hWin, NULL, TRUE
		;Invoke ShowWindow, hWin, SW_SHOW
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, rax

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @TextMouseOver , FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, rax

    .ELSEIF eax == WM_SETTEXT
        Invoke _MUI_TextCheckMultiline, hWin, lParam
        Invoke DefWindowProc, hWin, uMsg, wParam, lParam
        Invoke ShowWindow, hWin, SW_HIDE
        Invoke InvalidateRect, hWin, NULL, TRUE
        Invoke ShowWindow, hWin, SW_SHOW
        ret

    .ELSEIF eax == WM_SETFONT
        ;PrintText '_MUI_TextWndProc::WM_SETFONT'
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, 0F0h
        .IF rax == 0 || rax == MUITS_FONT_DIALOG || rax == MUITS_FONT_SETFONT
            ;PrintDec wParam
            Invoke MUISetExtProperty, hWin, @TextFont, wParam
            .IF lParam == TRUE
                Invoke InvalidateRect, hWin, NULL, TRUE
            .ENDIF            
        .ELSE
            ret
        .ENDIF

	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
        mov rax, wParam
        .IF rax == @TextFont
            Invoke MUIGetExtProperty, hWin, @TextFont
            .IF rax != NULL
                Invoke DeleteObject, rax
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, lParam
            Invoke InvalidateRect, hWin, NULL, TRUE
        .ELSE
            Invoke MUISetExtProperty, hWin, wParam, lParam
        .ENDIF
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret
_MUI_TextWndProc ENDP


;-------------------------------------------------------------------------------------
; _MUI_TextInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_TextInit PROC FRAME hWin:QWORD
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
     
    ; Set default initial external property values  
    Invoke MUISetIntProperty, hWin, @TextEnabledState, TRUE   
    Invoke MUISetExtProperty, hWin, @TextColor, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hWin, @TextColorAlt, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hWin, @TextColorDisabled, MUI_RGBCOLOR(204,204,204)
    
    Invoke MUIGetParentBackgroundColor, hWin
    .IF rax == -1 ; if background was NULL then try a color as default
        Invoke GetSysColor, COLOR_WINDOW
    .ENDIF
    Invoke MUISetExtProperty, hWin, @TextBackColor, rax ;MUI_RGBCOLOR(255,255,255)   
    ;Invoke MUISetExtProperty, hWin, @TextBackColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hWin, @TextBackColorAlt, rax ;MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hWin, @TextBackColorDisabled, rax ;MUI_RGBCOLOR(192,192,192)
    
    Invoke _MUI_TextSetFontFamilySize, hWin, qwStyle

    mov rax, qwStyle
    and rax, MUITS_LORUMIPSUM
    .IF rax == MUITS_LORUMIPSUM
        Invoke SetWindowText, hWin, Addr szLorumIpsumText
    .ENDIF
    ret
_MUI_TextInit ENDP


;-------------------------------------------------------------------------------------
; _MUI_TextPaint
;-------------------------------------------------------------------------------------
_MUI_TextPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:QWORD
    LOCAL hdcMem:QWORD
    LOCAL hbmMem:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL EnabledState:QWORD
    LOCAL MouseOver:QWORD
    LOCAL BackColor:QWORD

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    ;----------------------------------------------------------
    ; Get some property values
    ;----------------------------------------------------------
    Invoke GetClientRect, hWin, Addr rect
    Invoke MUIGetIntProperty, hWin, @TextEnabledState
    mov EnabledState, rax
    Invoke MUIGetIntProperty, hWin, @TextMouseOver
    mov MouseOver, rax
    Invoke MUIGetExtProperty, hWin, @TextBackColor
    mov BackColor, rax

    .IF BackColor != -1 ; Not Transparent, background color is specified

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
        Invoke _MUI_TextPaintBackground, hWin, hdcMem, Addr rect, EnabledState, MouseOver
    
        ;----------------------------------------------------------
        ; Text
        ;----------------------------------------------------------
        Invoke _MUI_TextPaintText, hWin, hdcMem, Addr rect, EnabledState, MouseOver
    
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

    .ELSE ; Text on Transparent Background
    
        ;----------------------------------------------------------
        ; Text
        ;----------------------------------------------------------    
        Invoke _MUI_TextPaintText, hWin, hdc, Addr rect, EnabledState, MouseOver
    
    .ENDIF
    
    Invoke EndPaint, hWin, Addr ps
    ret
_MUI_TextPaint ENDP


;-------------------------------------------------------------------------------------
; _MUI_TextPaintBackground
;-------------------------------------------------------------------------------------
_MUI_TextPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD

    .IF bEnabledState == TRUE
        .IF bMouseOver == FALSE
            Invoke MUIGetExtProperty, hWin, @TextBackColor              ; Normal back color
        .ELSE
            Invoke MUIGetExtProperty, hWin, @TextBackColorAlt           ; Mouse over back color
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @TextBackColorDisabled          ; Disabled back color
    .ENDIF
    .IF eax == 0 ; try to get default back color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @TextBackColor                  ; fallback to default Normal back color
    .ENDIF
    mov BackColor, rax
    
    .IF BackColor == -1 ; transparent
        ret
    .ENDIF

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
_MUI_TextPaintBackground ENDP


;-------------------------------------------------------------------------------------
; _MUI_TextPaintText
;-------------------------------------------------------------------------------------
_MUI_TextPaintText PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL LenText:QWORD    
    LOCAL qwTextStyle:QWORD
    LOCAL qwStyle:QWORD
    LOCAL rect:RECT
    LOCAL szMUITextBuffer[MUI_TEXT_MAX_CHARS]:BYTE
    
    Invoke CopyRect, Addr rect, lpRect

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    
    Invoke MUIGetExtProperty, hWin, @TextFont        
    mov hFont, rax

    .IF bEnabledState == TRUE
        .IF bMouseOver == FALSE
            Invoke MUIGetExtProperty, hWin, @TextBackColor        ; Normal back color
        .ELSE
            Invoke MUIGetExtProperty, hWin, @TextBackColorAlt     ; Mouse over back color
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @TextBackColorDisabled        ; Disabled back color
    .ENDIF
    .IF rax == 0 ; try to get default back color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @TextBackColor                ; fallback to default Normal back color
    .ENDIF    
    mov BackColor, rax    

    .IF bEnabledState == TRUE
        .IF bMouseOver == FALSE
            Invoke MUIGetExtProperty, hWin, @TextColor        ; Normal text color
        .ELSE
            Invoke MUIGetExtProperty, hWin, @TextColorAlt     ; Mouse over text color
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @TextColorDisabled        ; Disabled text color
    .ENDIF
    .IF rax == 0 ; try to get default text color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @TextColor                ; fallback to default Normal text color
    .ENDIF  
    mov TextColor, rax
    
    Invoke GetWindowText, hWin, Addr szMUITextBuffer, MUI_TEXT_MAX_CHARS;SIZEOF szText
    
    Invoke lstrlen, Addr szMUITextBuffer ;szText
    mov LenText, rax
    
    Invoke SelectObject, hdc, hFont
    mov hOldFont, rax

    .IF BackColor != -1 ; transaprent
        Invoke SetBkMode, hdc, OPAQUE
        Invoke SetBkColor, hdc, dword ptr BackColor
    .ELSE
        Invoke SetBkMode, hdc, TRANSPARENT
    .ENDIF
    Invoke SetTextColor, hdc, dword ptr TextColor

    mov rax, qwStyle
    and rax, MUITS_SINGLELINE
    .IF rax == MUITS_SINGLELINE
        mov qwTextStyle, DT_SINGLELINE
    .ELSE
        mov qwTextStyle, DT_WORDBREAK or DT_EDITCONTROL
    .ENDIF
    mov rax, qwStyle
    and rax, (MUITS_ALIGN_CENTER or MUITS_ALIGN_RIGHT)
    .IF rax == MUITS_ALIGN_CENTER
        or qwTextStyle, DT_CENTER
    .ELSEIF rax == MUITS_ALIGN_RIGHT
        or qwTextStyle, DT_RIGHT
    .ELSE
        or qwTextStyle, DT_LEFT
    .ENDIF

    Invoke DrawText, hdc, Addr szMUITextBuffer, dword ptr LenText, Addr rect, dword ptr qwTextStyle
    
    .IF hOldFont != 0
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF

    ret
_MUI_TextPaintText ENDP


;-------------------------------------------------------------------------------------
; Returns TRUE if CR LF found in string, otherwise returns FALSE
;-------------------------------------------------------------------------------------
_MUI_TextCheckMultiline PROC FRAME USES RBX hWin:QWORD, lpszText:QWORD
    LOCAL lenText:QWORD
    LOCAL Cnt:QWORD
    LOCAL bMultiline:QWORD
    LOCAL qwStyle:QWORD
    
    ;PrintText '_MUI_TextCheckMultiline'
    
    .IF lpszText == 0
        ret
    .ENDIF
    Invoke lstrlen, lpszText
    mov lenText, rax
    
    mov bMultiline, FALSE
    mov rbx, lpszText
    mov Cnt, 0
    mov rax, 0
    .WHILE rax < lenText
        movzx rax, byte ptr [rbx]
        .IF al == 0
            mov bMultiline, FALSE
            .BREAK
        .ELSEIF al == 10 || al == 13
            mov bMultiline, TRUE
            .BREAK 
        .ENDIF
        inc rbx
        inc Cnt
        mov rax, Cnt
    .ENDW

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax  
    mov rax, qwStyle
    .IF bMultiline == FALSE
        or rax, MUITS_SINGLELINE
    .ELSE
        and rax, (-1 xor MUITS_SINGLELINE)
    .ENDIF
    mov qwStyle, rax
    Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwStyle

    mov rax, bMultiline
    ret

_MUI_TextCheckMultiline ENDP


;-------------------------------------------------------------------------------------
; Create Text size and font family based on style flags passed to control
;-------------------------------------------------------------------------------------
_MUI_TextSetFontFamilySize PROC FRAME USES RBX hWin:QWORD, qwStyle:QWORD
    LOCAL MUITextFont:QWORD
    LOCAL hFont:QWORD
    LOCAL qwFontHeight:QWORD
    LOCAL qwFontWeight:QWORD
    LOCAL qwFontFamily:QWORD
    LOCAL qwFontSize:QWORD
    LOCAL ptrFontHandles:QWORD
    LOCAL qwFontSizeIndex:QWORD

    Invoke MUIGetExtProperty, hWin, @TextFont
    mov hFont, rax
    .IF hFont != NULL
        Invoke DeleteObject, hFont
    .ENDIF

    mov rax, qwStyle
    and rax, 0F0h
    mov qwFontFamily, rax
 
    .IF rax == 0 || rax == MUITS_FONT_DIALOG || rax == MUITS_FONT_SETFONT
        Invoke GetParent, hWin
        Invoke SendMessage, rax, WM_GETFONT, 0, 0 ; hope parent is the dialog or container that has a font being used.
        mov hFont, rax
        Invoke MUISetExtProperty, hWin, @TextFont, hFont
    .ELSE

        .IF rax == MUITS_FONT_SEGOE
            lea rax, szMUITextFontSegoe
            lea rbx, MUITextFontSegoeHandles
        .ELSEIF rax == MUITS_FONT_TAHOMA
            lea rax, szMUITextFontTahoma
            lea rbx, MUITextFontTahomaHandles
        .ELSEIF rax == MUITS_FONT_ARIAL
            lea rax, szMUITextFontArial
            lea rbx, MUITextFontArialHandles
        .ELSEIF rax == MUITS_FONT_TIMES
            lea rax, szMUITextFontTimes
            lea rbx, MUITextFontTimesHandles
        .ELSEIF rax == MUITS_FONT_COURIER
            lea rax, szMUITextFontCourier
            lea rbx, MUITextFontCourierHandles
        .ELSEIF rax == MUITS_FONT_VERDANA    
            lea rax, szMUITextFontVerdana
            lea rbx, MUITextFontVerdanaHandles
        .ELSE
            lea rax, szMUITextFontSegoe
            lea rbx, MUITextFontSegoeHandles
        .ENDIF
        mov MUITextFont, rax
        mov ptrFontHandles, rbx
        
        mov rax, qwStyle
        and rax, 15d
        mov qwFontSize, rax

        .IF rax == MUITS_8PT ; 8pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 8
            mov qwFontHeight, rax
            mov qwFontWeight, FW_NORMAL
            mov qwFontSizeIndex, 0
        .ELSEIF eax == MUITS_9PT_BOLD ; 9pt bold
            Invoke MUIPointSizeToLogicalUnit, hWin, 9
            mov qwFontHeight, rax
            mov qwFontWeight, FW_BOLD
            mov qwFontSizeIndex, 1
        .ELSEIF eax == MUITS_10PT ; 10pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 10
            mov qwFontHeight, rax
            mov qwFontWeight, FW_NORMAL
            mov qwFontSizeIndex, 2
        .ELSEIF eax == MUITS_11PT_BOLD; 11pt bold
            Invoke MUIPointSizeToLogicalUnit, hWin, 11
            mov qwFontHeight, rax
            mov qwFontWeight, FW_BOLD
            mov qwFontSizeIndex, 3
        .ELSEIF eax == MUITS_12PT; 12pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 12
            mov qwFontHeight, rax
            mov qwFontWeight, FW_NORMAL
            mov qwFontSizeIndex, 4
        .ELSEIF eax == MUITS_13PT_BOLD; 13pt bold
            Invoke MUIPointSizeToLogicalUnit, hWin, 13
            mov qwFontHeight, rax
            mov qwFontWeight, FW_BOLD
            mov qwFontSizeIndex, 5
        .ELSEIF eax == MUITS_14PT ; 14pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 14
            mov qwFontHeight, rax
            mov qwFontWeight, FW_NORMAL
            mov qwFontSizeIndex, 6
        .ELSEIF eax == MUITS_15PT_BOLD ; 15pt bold
            Invoke MUIPointSizeToLogicalUnit, hWin, 15
            mov qwFontHeight, rax
            mov qwFontWeight, FW_BOLD
            mov qwFontSizeIndex, 7
        .ELSE
            Invoke MUIPointSizeToLogicalUnit, hWin, 8
            mov qwFontHeight, rax
            mov qwFontWeight, FW_NORMAL
            mov qwFontSizeIndex, 0
        .ENDIF
        
        ; check if font already created, if so use that, instead of creating another font
        
        mov rbx, ptrFontHandles
        mov rax, qwFontSizeIndex
        lea rbx, [rbx+rax*SIZEOF QWORD]
        mov rax, [rbx]
        mov hFont, rax
        .IF rax == 0
            ;PrintText 'New Font'
            Invoke CreateFont, dword ptr qwFontHeight, 0,0,0, dword ptr qwFontWeight, 0,0,0,0,0,0, PROOF_QUALITY, FF_SWISS, MUITextFont
            mov hFont, rax
            ; save handle to fonthandles
            mov rbx, ptrFontHandles
            mov rax, qwFontSizeIndex
            lea rbx, [rbx+rax*SIZEOF QWORD]
            mov rax, hFont
            mov [rbx], rax
            ;PrintDec hFont
        .ELSE
            ;PrintText 'reusing an existing font handle'
            ;PrintDec ptrFontHandles
            ;PrintDec dwFontSizeIndex
            ;PrintDec hFont
        .ENDIF
        Invoke MUISetExtProperty, hWin, @TextFont, hFont
    .ENDIF
    mov rax, hFont
    ret

_MUI_TextSetFontFamilySize ENDP












END
