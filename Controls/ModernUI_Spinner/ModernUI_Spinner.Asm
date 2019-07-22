;======================================================================================================================================
;
; ModernUI x64 Control - ModernUI_Spinner x64 v1.0.0.0
;
; Copyright (c) 2018 by fearless
;
; All Rights Reserved
;
; http://www.LetTheLight.in
;
; http://github.com/mrfearless/ModernUI64
;
;
; NOTE: GDI+ in x64 shows some fuzzyness with images and image manipulation and results in loaded png images being cut off or slightly
; mishaped. Recommend any use of spinners uses BMP or ICO for frames and Spritesheets. Avoid png spritesheets and single image rotate
; spinners that use GDI+ and rotation to achive spinner look
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

IFDEF MUI_USEGDIPLUS
ECHO MUI_USEGDIPLUS
include gdiplus.inc
includelib gdiplus.lib
includelib ole32.lib
ELSE
ECHO MUI_DONTUSEGDIPLUS
ENDIF

include ModernUI_Spinner.inc

SPINNER_USE_TIMERQUEUE                 EQU 1 ; comment out to use WM_SETIMER instead of TimerQueue
;SPINNER_USE_MMTIMER                    EQU 1 ; comment out to use WM_SETIMER or TimerQueue - otherwise overrides WM_SETIMER and TimerQueue

IFDEF SPINNER_USE_MMTIMER
;include winmm.inc
includelib winmm.lib
ECHO *** ModernUI_Spinner - Using Multimedia Timer ***
ELSE
IFDEF SPINNER_USE_TIMERQUEUE
ECHO *** ModernUI_Spinner - Using TimerQueue ***
ELSE
ECHO *** ModernUI_Spinner - Using WM_TIMER ***
ENDIF
ENDIF

;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_SpinnerWndProc					PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_SpinnerInit					PROTO :QWORD
_MUI_SpinnerCleanup					PROTO :QWORD
_MUI_SpinnerPaint					PROTO :QWORD
_MUI_SpinnerPaintBackground         PROTO :QWORD, :QWORD, :QWORD
_MUI_SpinnerPaintImages             PROTO :QWORD, :QWORD, :QWORD, :QWORD
;_MUI_SpinnerPaintBorder             PROTO :QWORD, :QWORD, :QWORD
_MUI_SpinnerFrame                   PROTO :QWORD
_MUI_SpinnerNextFrameIndex          PROTO :QWORD
IFDEF MUI_USEGDIPLUS
_MUI_SpinnerLoadPng                 PROTO :QWORD, :QWORD
ENDIF
_MUI_SpinnerRotateCenterImage       PROTO :QWORD,:REAL4 ; hImage, fAngle
IFDEF SPINNER_USE_MMTIMER
_MUI_SpinnerMMTimerProc             PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
ELSE
IFDEF SPINNER_USE_TIMERQUEUE
_MUI_SpinnerTimerProc               PROTO :QWORD, :QWORD
ENDIF
ENDIF
;--------------------------------------------------------------------------------------------------------------------------------------
; Structures for internal use
;--------------------------------------------------------------------------------------------------------------------------------------
; External public properties
MUI_SPINNER_PROPERTIES				STRUCT
	qwSpinnerBackColor				DQ ?
	qwSpinnerSpeed                  DQ ?
    qwSpinnerDllInstance            DQ ?
MUI_SPINNER_PROPERTIES				ENDS

; Internal properties
_MUI_SPINNER_PROPERTIES				STRUCT
	qwMouseOver						DQ ?
    qwSpinnerTotalFrames            DQ ?
    qwSpinnerFrameIndex             DQ ?
    qwSpinnerFramesArray            DQ ?  ; points to array of SPINNER_FRAME structures for handle to each spinner step image
    qwSpinnerImageType              DQ ?  ; BMP, ICO or PNG
    IFDEF SPINNER_USE_MMTIMER
    hTimer                          DQ ?
    ELSE
    IFDEF SPINNER_USE_TIMERQUEUE
    bUseTimerQueue                  DQ ?
    hQueue                          DQ ?
    hTimer                          DQ ?
    ENDIF
    ENDIF
_MUI_SPINNER_PROPERTIES				ENDS

SPINNER_FRAME                       STRUCT
    hImage                          DQ ?
SPINNER_FRAME                       ENDS

IFDEF MUI_USEGDIPLUS
IFNDEF UNKNOWN
UNKNOWN STRUCT
   QueryInterface   QWORD ?
   AddRef           QWORD ?
   Release          QWORD ?
UNKNOWN ENDS
ENDIF

IFNDEF IStream
IStream STRUCT
IUnknown            UNKNOWN <>
Read                QWORD ?
Write               QWORD ?
Seek                QWORD ?
SetSize             QWORD ?
CopyTo              QWORD ?
Commit              QWORD ?
Revert              QWORD ?
LockRegion          QWORD ?
UnlockRegion        QWORD ?
Stat                QWORD ?
Clone               QWORD ?
IStream ENDS
ENDIF
ENDIF


.CONST
SPINNER_MAX_FRAMES                  EQU 60
SPINNER_TIME_INTERVAL_MIN           EQU 10
SPINNER_TIME_INTERVAL               EQU 80 ; Milliseconds for timer firing

; Internal properties
@SpinnerMouseOver					EQU 0
@SpinnerTotalFrames                 EQU 8
@SpinnerFrameIndex                  EQU 16
@SpinnerFramesArray                 EQU 24
@SpinnerImageType                   EQU 32
IFDEF SPINNER_USE_MMTIMER
@SpinnerTimer                       EQU 40
ELSE
IFDEF SPINNER_USE_TIMERQUEUE
@SpinnerUseTimerQueue               EQU 40
@SpinnerQueue                       EQU 48
@SpinnerTimer                       EQU 56
ENDIF
ENDIF

.DATA
szMUISpinnerClass					DB 'ModernUI_Spinner',0 	    ; Class name for creating our Spinner control

.CODE
MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for ModernUI_Spinner control
;------------------------------------------------------------------------------
MUISpinnerSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUISpinnerSetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for ModernUI_Spinner control
;------------------------------------------------------------------------------
MUISpinnerGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUISpinnerGetProperty ENDP

MUI_ALIGN
;-------------------------------------------------------------------------------------
; MUISpinnerRegister - Registers the ModernUI_Spinner control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Spinner
;-------------------------------------------------------------------------------------
MUISpinnerRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUISpinnerClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUISpinnerClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_SpinnerWndProc
    	mov wc.lpfnWndProc, rax
    	;Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, NULL ;rax
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
MUISpinnerRegister ENDP

MUI_ALIGN
;-------------------------------------------------------------------------------------
; MUISpinnerCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUISpinnerCreate PROC FRAME hWndParent:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL qwNewStyle:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUISpinnerRegister
	
    mov rax, qwStyle
    mov qwNewStyle, rax
    and rax, WS_CHILD or WS_CLIPCHILDREN or WS_VISIBLE
    .IF rax != WS_CHILD or WS_CLIPCHILDREN or WS_VISIBLE
        or qwNewStyle, WS_CHILD or WS_CLIPCHILDREN or WS_VISIBLE
    .ENDIF
    
    Invoke CreateWindowEx, NULL, Addr szMUISpinnerClass, NULL, dword ptr qwNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUISpinnerCreate ENDP

MUI_ALIGN
;-------------------------------------------------------------------------------------
; _MUI_SpinnerWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_SpinnerWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    
    mov eax, uMsg
    .IF eax == WM_NCCREATE
        ;mov rbx, lParam
		; sets text of our control, delete if not required.
        ;Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName	
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, 0, SIZEOF _MUI_SPINNER_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, 8, SIZEOF MUI_SPINNER_PROPERTIES ; external properties
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGDIPlusStart ; for png resources if used
        ENDIF
		Invoke _MUI_SpinnerInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke _MUI_SpinnerCleanup, hWin
        Invoke MUIFreeMemProperties, hWin, 0
		Invoke MUIFreeMemProperties, hWin, 8
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGDIPlusFinish
        ENDIF
		mov rax, 0
		ret           
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_SpinnerPaint, hWin
        mov rax, 0
        ret

    .ELSEIF eax== WM_SETCURSOR
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUISPNS_HAND
        .IF rax == MUISPNS_HAND
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

   .ELSEIF eax == WM_MOUSEMOVE
		Invoke MUISetIntProperty, hWin, @SpinnerMouseOver, TRUE
		.IF rax != TRUE
		    Invoke InvalidateRect, hWin, NULL, TRUE
		    mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
		    mov TE.dwFlags, TME_LEAVE
		    mov rax, hWin
		    mov TE.hwndTrack, rax
		    mov TE.dwHoverTime, NULL
		    Invoke TrackMouseEvent, Addr TE
		.ENDIF

    .ELSEIF eax == WM_MOUSELEAVE
        Invoke MUISetIntProperty, hWin, @SpinnerMouseOver, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		;Invoke LoadCursor, NULL, IDC_ARROW
		;Invoke SetCursor, rax

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @SpinnerMouseOver, FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		;Invoke LoadCursor, NULL, IDC_ARROW
		;Invoke SetCursor, rax
	
	.ELSEIF eax == WM_TIMER
	    mov rax, wParam
	    .IF rax == hWin
	        Invoke _MUI_SpinnerNextFrameIndex, hWin
            Invoke InvalidateRect, hWin, NULL, TRUE
            Invoke UpdateWindow, hWin
	    .ENDIF
    
	; custom messages start here
	.ELSEIF eax == MUISPNM_ADDFRAME ; wParam = dwImageType, lParam = hImage
	    Invoke MUISpinnerAddFrame, hWin, wParam, lParam
	    ret
	.ELSEIF eax == MUISPNM_LOADFRAME; wParam = qwImageType, lParam = idResImage
	    Invoke MUISpinnerLoadFrame, hWin, wParam, lParam
	    ret
	.ELSEIF eax == MUISPNM_ENABLE   ; wParam & lParam = NULL
	    Invoke MUISpinnerEnable, hWin
	    ret
	.ELSEIF eax == MUISPNM_DISABLE  ; wParam & lParam = NULL
	    Invoke MUISpinnerDisable, hWin
	    ret
	.ELSEIF eax == MUISPNM_RESET    ; wParam & lParam = NULL
	    Invoke MUISpinnerReset, hWin
	    ret
	.ELSEIF eax == MUISPNM_PAUSE    ; wParam & lParam = NULL
	    Invoke MUISpinnerPause, hWin
	    ret
	.ELSEIF eax == MUISPNM_RESUME   ; wParam & lParam = NULL
	    Invoke MUISpinnerResume, hWin
	    ret
	.ELSEIF eax == MUISPNM_SPEED    ; wParam = qwMillisecSpeed	
	    Invoke MUISpinnerSpeed, hWin, wParam
	    ret
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
	.ELSEIF eax == MUI_SETPROPERTY
	    mov rax, wParam
	    .IF rax == @SpinnerSpeed
            .IF lParam == 0
                mov rax, SPINNER_TIME_INTERVAL
            .ELSEIF sqword ptr lParam < 10
                mov rax, SPINNER_TIME_INTERVAL_MIN
            .ELSE
                mov rax, lParam
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, rax	
	    .ELSE
		    Invoke MUISetExtProperty, hWin, wParam, lParam
		.ENDIF
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_SpinnerWndProc ENDP

MUI_ALIGN
;-------------------------------------------------------------------------------------
; _MUI_SpinnerInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_SpinnerInit PROC FRAME hWin:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    
    Invoke GetParent, hWin
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_VISIBLE
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_VISIBLE
        mov rax, qwStyle
        or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_VISIBLE
        mov qwStyle, rax
        Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwStyle
    .ENDIF
    ;PrintDec qwStyle
    
    ; Set default initial external property values     
    Invoke MUIGetParentBackgroundColor, hWin
    .IF rax == -1 ; if background was NULL then try a color as default
        Invoke GetSysColor, COLOR_WINDOW
    .ENDIF
    Invoke MUISetExtProperty, hWin, @SpinnerBackColor, eax ;MUI_RGBCOLOR(255,255,255)
    ;Invoke MUISetExtProperty, hWin, @SpinnerBackColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hWin, @SpinnerSpeed, SPINNER_TIME_INTERVAL
    
    IFDEF SPINNER_USE_MMTIMER
    Invoke MUISetIntProperty, hWin, @SpinnerTimer, 0
    ELSE
    IFDEF SPINNER_USE_TIMERQUEUE
    Invoke MUISetIntProperty, hWin, @SpinnerUseTimerQueue, TRUE
    Invoke MUISetIntProperty, hWin, @SpinnerQueue, 0
    Invoke MUISetIntProperty, hWin, @SpinnerTimer, 0
    ENDIF
    ENDIF
    
    ; Alloc memory for max frames
    mov rax, SPINNER_MAX_FRAMES
    mov rbx, SIZEOF SPINNER_FRAME
    mul rbx
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    .IF rax != NULL
        Invoke MUISetIntProperty, hWin, @SpinnerFramesArray, rax
    .ENDIF

    mov rax, TRUE
    ret
_MUI_SpinnerInit ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SpinnerCleanup - cleanup
;------------------------------------------------------------------------------
_MUI_SpinnerCleanup PROC FRAME USES RBX hWin:QWORD
    LOCAL pSpinnerFramesArray:QWORD
    LOCAL pCurrentFrame:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL qwImageType:QWORD
    LOCAL hImage:QWORD
    
    Invoke KillTimer, hWin, hWin
    
    Invoke MUIGetIntProperty, hWin, @SpinnerImageType
    mov qwImageType, rax    
    
    Invoke MUIGetIntProperty, hWin, @SpinnerFramesArray
    .IF eax != NULL
        mov pSpinnerFramesArray, rax
        mov pCurrentFrame, rax
        
        Invoke MUIGetIntProperty, hWin, @SpinnerTotalFrames
        mov TotalFrames, rax
        
        mov FrameIndex, 0
        mov rax, 0
        .WHILE rax < TotalFrames
            mov rbx, pCurrentFrame
            
            mov rax, [rbx].SPINNER_FRAME.hImage ; get bitmap handle and delete object if it exists
            
            .IF rax != NULL
                mov hImage, rax
                
                mov rax, qwImageType
                .IF rax == MUISPIT_BMP
                    ;PrintText 'Deleteing bitmap'
                    .IF hImage != NULL
                        Invoke DeleteObject, hImage
                    .ENDIF
                .ELSEIF rax == MUISPIT_ICO
                    .IF hImage != NULL
                        Invoke DestroyIcon, hImage
                    .ENDIF
                .ELSEIF rax == MUISPIT_PNG
                    IFDEF MUI_USEGDIPLUS
                    .IF hImage != NULL
                        Invoke GdipDisposeImage, hImage
                    .ENDIF
                    ENDIF
                .ENDIF
            .ENDIF
            
            add pCurrentFrame, SIZEOF SPINNER_FRAME
            inc FrameIndex
            mov rax, FrameIndex
        .ENDW
    
        Invoke GlobalFree, pSpinnerFramesArray
    
    .ENDIF
    ret
_MUI_SpinnerCleanup ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SpinnerNextFrameIndex - sets the next frame index to use for painting
;------------------------------------------------------------------------------
_MUI_SpinnerNextFrameIndex PROC FRAME USES RBX hWin:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL NextFrame:QWORD

    Invoke MUIGetIntProperty, hWin, @SpinnerTotalFrames
    .IF rax == 0
        ret
    .ENDIF
    mov TotalFrames, rax
    
;    IFDEF DEBUG64
;    PrintText '_MUI_SpinnerNextFrameIndex'
;    PrintText 'TotalFrames'
;    mov rax, TotalFrames
;    PrintQWORD rax
;    ENDIF
    
    Invoke MUIGetIntProperty, hWin, @SpinnerFrameIndex
    inc rax
    .IF rax >= TotalFrames
        mov rax, 0
    .ENDIF
    mov NextFrame, rax
    
;    IFDEF DEBUG64
;    PrintText 'NextFrame'
;    mov rax, NextFrame
;    PrintQWORD rax
;    ENDIF
    
    Invoke MUISetIntProperty, hWin, @SpinnerFrameIndex, NextFrame
    
    ret
_MUI_SpinnerNextFrameIndex ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SpinnerPaint
;------------------------------------------------------------------------------
_MUI_SpinnerPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hbmMem:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax

    ;----------------------------------------------------------
    ; Get some property values
    ;---------------------------------------------------------- 
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
    Invoke _MUI_SpinnerPaintBackground, hWin, hdcMem, Addr rect
    
    ;----------------------------------------------------------
    ; Images
    ;----------------------------------------------------------
    Invoke _MUI_SpinnerPaintImages, hWin, hdc, hdcMem, Addr rect

    ;----------------------------------------------------------
    ; Border
    ;----------------------------------------------------------
    ;Invoke _MUI_SpinnerPaintBorder, hWin, hdcMem, Addr rect
    
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
_MUI_SpinnerPaint ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SpinnerPaintBackground
;------------------------------------------------------------------------------
_MUI_SpinnerPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL rect:RECT

    Invoke CopyRect, Addr rect, lpRect
    inc rect.bottom ; rect needs to be increased for FillRect call
    inc rect.right ; rect needs to be increased for FillRect call
    
    Invoke MUIGetExtProperty, hWin, @SpinnerBackColor
    mov BackColor, rax
    
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdc, rax
    mov hOldBrush, rax
    Invoke SetDCBrushColor, hdc, dword ptr BackColor
    Invoke FillRect, hdc, Addr rect, hBrush
    
    .IF hOldBrush != 0
        Invoke SelectObject, hdc, hOldBrush
        Invoke DeleteObject, hOldBrush
    .ENDIF     
    .IF hBrush != 0
        Invoke DeleteObject, hBrush
    .ENDIF      
    
    ret
_MUI_SpinnerPaintBackground ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SpinnerPaintImages
;------------------------------------------------------------------------------
_MUI_SpinnerPaintImages PROC FRAME USES RBX hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD
    LOCAL hdcMem:HDC
    LOCAL hbmOld:QWORD
    LOCAL hImage:QWORD
    LOCAL qwImageType:QWORD
    LOCAL pGraphics:QWORD
    LOCAL pGraphicsBuffer:QWORD
    LOCAL pBitmap:QWORD
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    LOCAL ImageWidth:REAL4
    LOCAL ImageHeight:REAL4
    LOCAL fx:REAL4
    LOCAL fy:REAL4
    LOCAL rect:RECT
    LOCAL pt:POINT
    
    IFDEF DEBUG64
    ;PrintText '_MUI_SpinnerPaintImages'
    ENDIF
    
    Invoke MUIGetIntProperty, hWin, @SpinnerImageType
    .IF rax == 0
        ret
    .ENDIF
    mov qwImageType, rax
    
    Invoke _MUI_SpinnerFrame, hWin
    .IF rax == 0
        .IF rax == 0
            IFDEF DEBUG64
            PrintText 'frame image is null'
            ENDIF
        .ENDIF
        ret
    .ENDIF
    mov hImage, rax
    ;PrintQWORD rax
    
    Invoke CopyRect, Addr rect, lpRect
    Invoke MUIGetImageSize, hImage, qwImageType, Addr qwImageWidth, Addr qwImageHeight
    
    xor rax, rax
    xor rbx, rbx
    mov eax, rect.right
    shr rax, 1
    mov rbx, qwImageWidth
    shr rbx, 1
    sub rax, rbx
    .IF sqword ptr rax < 0
        mov rax, 0
    .ENDIF
    mov pt.x, eax
    
    xor rax, rax
    xor rbx, rbx
    mov eax, rect.bottom
    shr rax, 1
    mov rbx, qwImageHeight
    shr rbx, 1
    sub rax, rbx
    .IF sqword ptr rax < 0
        mov rax, 0
    .ENDIF
    mov pt.y, eax
    
    ;mov eax, pt.x
    ;PrintQWORD rax
    ;mov eax, pt.y
    ;PrintQWORD rax
    ;mov rax, ImageWidth
    ;PrintQWORD rax
    ;mov rax, ImageHeight
    ;PrintQWORD rax
    
    mov rax, qwImageType
    .IF rax == MUISPIT_BMP ; bitmap
        
        Invoke CreateCompatibleDC, hdcMain
        mov hdcMem, rax
        Invoke SelectObject, hdcMem, hImage
        mov hbmOld, rax
        
        Invoke SetBrushOrgEx, hdcMem, 0, 0, NULL
        
        Invoke BitBlt, hdcDest, pt.x, pt.y, dword ptr qwImageWidth, dword ptr qwImageHeight, hdcMem, 0, 0, SRCCOPY

        Invoke SelectObject, hdcMem, hbmOld
        Invoke DeleteDC, hdcMem
        .IF hbmOld != 0
            Invoke DeleteObject, hbmOld
        .ENDIF
        
    .ELSEIF rax == MUISPIT_ICO ; icon
        Invoke DrawIconEx, hdcDest, pt.x, pt.y, hImage, 0, 0, 0, 0, DI_NORMAL
    
    .ELSEIF rax == MUISPIT_PNG ; png
        IFDEF MUI_USEGDIPLUS
        Invoke GdipCreateFromHDC, hdcDest, Addr pGraphics
        Invoke GdipCreateBitmapFromGraphics, qwImageWidth, qwImageHeight, pGraphics, Addr pBitmap
        Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer
        
        Invoke GdipSetPixelOffsetMode, pGraphics, PixelOffsetModeHighQuality
        Invoke GdipSetPixelOffsetMode, pGraphicsBuffer, PixelOffsetModeHighQuality
        Invoke GdipSetPageUnit, pGraphics, UnitPixel
        Invoke GdipSetPageUnit, pGraphicsBuffer, UnitPixel
        Invoke GdipSetSmoothingMode, pGraphics, SmoothingModeAntiAlias
        Invoke GdipSetSmoothingMode, pGraphicsBuffer, SmoothingModeAntiAlias
        Invoke GdipSetInterpolationMode, pGraphics, InterpolationModeHighQualityBicubic
        Invoke GdipSetInterpolationMode, pGraphicsBuffer, InterpolationModeHighQualityBicubic

        Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0 ;FP4(0.0), FP4(0.0)
        Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, dword ptr qwImageWidth, dword ptr qwImageHeight
        
        .IF pBitmap != NULL
            Invoke GdipDisposeImage, pBitmap
        .ENDIF
        .IF pGraphicsBuffer != NULL
            Invoke GdipDeleteGraphics, pGraphicsBuffer
        .ENDIF
        .IF pGraphics != NULL
            Invoke GdipDeleteGraphics, pGraphics
        .ENDIF
        ENDIF
    .ENDIF    

    ret
_MUI_SpinnerPaintImages ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_SpinnerFrame - gets the current frame image handle
;------------------------------------------------------------------------------
_MUI_SpinnerFrame PROC FRAME USES RBX hWin:QWORD
    LOCAL pSpinnerFramesArray:QWORD
    
    Invoke MUIGetIntProperty, hWin, @SpinnerTotalFrames
    .IF rax == 0
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @SpinnerFramesArray
    mov pSpinnerFramesArray, rax
    
    Invoke MUIGetIntProperty, hWin, @SpinnerFrameIndex
    mov rbx, SIZEOF SPINNER_FRAME
    mul rbx
    add rax, pSpinnerFramesArray
    mov rbx, rax
    mov rax, [rbx] ; handle to bitmap 
    
    ret
_MUI_SpinnerFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerEnable
;------------------------------------------------------------------------------
MUISpinnerEnable PROC FRAME hControl:QWORD
    LOCAL qwTimeInterval:QWORD
    IFDEF SPINNER_USE_MMTIMER
    LOCAL hTimer:QWORD
    ELSE
    IFDEF SPINNER_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    LOCAL hTimer:QWORD
    ENDIF
    ENDIF
    
    .IF hControl == NULL
        xor rax, rax
        ret
    .ENDIF
    
    Invoke ShowWindow, hControl, SW_SHOWNORMAL;SW_SHOWNA
    Invoke MUIGetExtProperty, hControl, @SpinnerSpeed
    .IF rax == 0
        Invoke MUISetIntProperty, hControl, @SpinnerSpeed, SPINNER_TIME_INTERVAL
        mov rax, SPINNER_TIME_INTERVAL
    .ENDIF
    mov qwTimeInterval, rax    
    
    Invoke InvalidateRect, hControl, NULL, TRUE
   
    IFDEF SPINNER_USE_MMTIMER
    
        Invoke MUIGetIntProperty, hControl, @SpinnerTimer
        mov hTimer, rax
        .IF hTimer != 0
            Invoke timeKillEvent, dword ptr hTimer
        .ENDIF
    
        Invoke timeSetEvent, dword ptr qwTimeInterval, 0, Addr _MUI_SpinnerMMTimerProc, hControl, TIME_PERIODIC
        mov hTimer, rax
        .IF rax != 0 ; success
            Invoke MUISetIntProperty, hControl, @SpinnerTimer, hTimer
        .ELSE ; fallback to WM_TIMER style
            Invoke MUISetIntProperty, hControl, @SpinnerTimer, 0
            Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
        .ENDIF

    ELSE
        IFDEF SPINNER_USE_TIMERQUEUE
        
            Invoke MUIGetIntProperty, hControl, @SpinnerUseTimerQueue
            .IF rax == TRUE
                Invoke MUIGetIntProperty, hControl, @SpinnerQueue
                mov hQueue, rax
                Invoke MUIGetIntProperty, hControl, @SpinnerTimer
                mov hTimer, rax
                .IF hQueue != NULL ; re-use existing hQueue
                    Invoke ChangeTimerQueueTimer, hQueue, hTimer, dword ptr qwTimeInterval, dword ptr qwTimeInterval
                    .IF rax == 0 ; failed 
                        Invoke DeleteTimerQueueEx, hQueue, FALSE
                        Invoke MUISetIntProperty, hControl, @SpinnerQueue, 0
                        Invoke MUISetIntProperty, hControl, @SpinnerTimer, 0
                        Invoke MUISetIntProperty, hControl, @SpinnerUseTimerQueue, FALSE
                        Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
                    .ENDIF
                .ELSE ; Try to create TimerQueue 
                    Invoke CreateTimerQueue
                    .IF rax != NULL
                        mov hQueue, rax
                        Invoke CreateTimerQueueTimer, Addr hTimer, hQueue, Addr _MUI_SpinnerTimerProc, hControl, dword ptr qwTimeInterval, dword ptr qwTimeInterval, 0
                        .IF eax == 0 ; failed, so fall back to WM_TIMER usage
                            Invoke DeleteTimerQueueEx, hQueue, FALSE
                            Invoke MUISetIntProperty, hControl, @SpinnerQueue, 0
                            Invoke MUISetIntProperty, hControl, @SpinnerTimer, 0
                            Invoke MUISetIntProperty, hControl, @SpinnerUseTimerQueue, FALSE
                            Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
                        .ELSE ; Success! - so save TimerQueue handles for re-use
                            IFDEF DEBUG32
                            PrintText 'Using QueueTimer'
                            ENDIF
                            Invoke MUISetIntProperty, hControl, @SpinnerQueue, hQueue
                            Invoke MUISetIntProperty, hControl, @SpinnerTimer, hTimer
                        .ENDIF
                    .ELSE ; failed, so fall back to WM_TIMER usage
                        Invoke MUISetIntProperty, hControl, @SpinnerUseTimerQueue, FALSE
                        Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
                    .ENDIF
                .ENDIF
            .ELSE  ; Not using TimerQueue, previous failure?, so fall back to WM_TIMER usage
                Invoke SetTimer, hControl, hControl, dword ptr qwTimeInterval, NULL
            .ENDIF
        
        ELSE ; compiled define says to use WM_TIMER instead
        
            Invoke SetTimer, hControl, hControl, qwTimeInterval, NULL
            
        ENDIF
    ENDIF
    
    mov rax, TRUE
    ret
MUISpinnerEnable ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerDisable
;------------------------------------------------------------------------------
MUISpinnerDisable PROC FRAME hControl:QWORD
    IFDEF SPINNER_USE_MMTIMER
    LOCAL hTimer:QWORD
    ELSE
    IFDEF SPINNER_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    LOCAL hTimer:QWORD
    ENDIF
    ENDIF
    
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke ShowWindow, hControl, SW_HIDE
    
    IFDEF SPINNER_USE_MMTIMER
    
        Invoke MUIGetIntProperty, hControl, @SpinnerTimer
        mov hTimer, rax
        .IF hTimer != 0
            Invoke timeKillEvent, dword ptr hTimer
            .IF rax == MMSYSERR_INVALPARAM
                Invoke KillTimer, hControl, hControl
            .ENDIF
        .ENDIF

    ELSE
        IFDEF SPINNER_USE_TIMERQUEUE
        
            Invoke MUIGetIntProperty, hControl, @SpinnerUseTimerQueue
            .IF rax == TRUE
                Invoke MUIGetIntProperty, hControl, @SpinnerQueue
                mov hQueue, rax
                Invoke MUIGetIntProperty, hControl, @SpinnerTimer
                mov hTimer, rax
                .IF hQueue != NULL
                    Invoke ChangeTimerQueueTimer, hQueue, hTimer, INFINITE, 0
                    .IF rax == 0 ; failed, fall back to use KillTimer for WM_TIMER usage
                        Invoke DeleteTimerQueueEx, hQueue, FALSE
                        Invoke MUISetIntProperty, hControl, @SpinnerQueue, 0
                        Invoke MUISetIntProperty, hControl, @SpinnerTimer, 0
                        Invoke MUISetIntProperty, hControl, @SpinnerUseTimerQueue, FALSE
                        Invoke KillTimer, hControl, hControl
                    .ENDIF
                .ELSE ; fall back to use KillTimer for WM_TIMER usage
                    Invoke MUISetIntProperty, hControl, @SpinnerUseTimerQueue, FALSE
                    Invoke KillTimer, hControl, hControl
                .ENDIF
            .ELSE ; Not using TimerQueue, previous failure? back to use KillTimer for WM_TIMER usage
                Invoke KillTimer, hControl, hControl
            .ENDIF
            
        ELSE ; compiled define says to use WM_TIMER instead
        
            Invoke KillTimer, hControl, hControl
            
        ENDIF
    ENDIF

    Invoke InvalidateRect, hControl, NULL, TRUE    
    
    mov rax, TRUE
    ret
MUISpinnerDisable ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerPause
;------------------------------------------------------------------------------
MUISpinnerPause PROC FRAME hControl:QWORD
    IFDEF SPINNER_USE_MMTIMER
    LOCAL hTimer:QWORD
    ELSE
    IFDEF SPINNER_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    LOCAL hTimer:QWORD
    ENDIF
    ENDIF
    
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    IFDEF SPINNER_USE_MMTIMER
    
        Invoke MUIGetIntProperty, hControl, @SpinnerTimer
        mov hTimer, rax
        .IF hTimer != 0
            Invoke timeKillEvent, dword ptr hTimer
            .IF rax == MMSYSERR_INVALPARAM
                Invoke KillTimer, hControl, hControl
            .ENDIF
        .ENDIF

    ELSE
        IFDEF SPINNER_USE_TIMERQUEUE
        
            Invoke MUIGetIntProperty, hControl, @SpinnerUseTimerQueue
            .IF rax == TRUE
                Invoke MUIGetIntProperty, hControl, @SpinnerQueue
                mov hQueue, rax
                Invoke MUIGetIntProperty, hControl, @SpinnerTimer
                mov hTimer, rax
                .IF hQueue != NULL
                    Invoke ChangeTimerQueueTimer, hQueue, hTimer, INFINITE, 0
                    .IF rax == 0 ; failed, fall back to use KillTimer for WM_TIMER usage
                        Invoke DeleteTimerQueueEx, hQueue, FALSE
                        Invoke MUISetIntProperty, hControl, @SpinnerQueue, 0
                        Invoke MUISetIntProperty, hControl, @SpinnerTimer, 0
                        Invoke MUISetIntProperty, hControl, @SpinnerUseTimerQueue, FALSE
                        Invoke KillTimer, hControl, hControl
                    .ENDIF
                .ELSE ; fall back to use KillTimer for WM_TIMER usage
                    Invoke MUISetIntProperty, hControl, @SpinnerUseTimerQueue, FALSE
                    Invoke KillTimer, hControl, hControl
                .ENDIF
            .ELSE ; Not using TimerQueue, previous failure? back to use KillTimer for WM_TIMER usage
                Invoke KillTimer, hControl, hControl
            .ENDIF
            
        ELSE ; compiled define says to use WM_TIMER instead
        
            Invoke KillTimer, hControl, hControl
            
        ENDIF
    ENDIF
    mov rax, TRUE
    ret
MUISpinnerPause ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerResume
;------------------------------------------------------------------------------
MUISpinnerResume PROC FRAME hControl:QWORD
    Invoke MUISpinnerEnable, hControl
    ret
MUISpinnerResume ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerReset - reset step to 0 or angle to 0
;------------------------------------------------------------------------------
MUISpinnerReset PROC FRAME hControl:QWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF

    Invoke MUISetIntProperty, hControl, @SpinnerFrameIndex, 0

    mov rax, TRUE
    ret
MUISpinnerReset ENDP

;------------------------------------------------------------------------------
; MUISpinnerReset - reset step to 0 or angle to 0
;------------------------------------------------------------------------------
MUISpinnerSpeed PROC FRAME hControl:QWORD, qwMillisecSpeed:QWORD
    .IF qwMillisecSpeed == 0
        mov rax, SPINNER_TIME_INTERVAL
    .ELSEIF sqword ptr qwMillisecSpeed < 10
        mov rax, SPINNER_TIME_INTERVAL_MIN
    .ELSE
        mov rax, qwMillisecSpeed
    .ENDIF
    Invoke MUISetExtProperty, hControl, @SpinnerSpeed, rax
    ret
MUISpinnerSpeed ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerAddFrame - Adds an image frame to the spinner control
;
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUISpinnerAddFrame PROC FRAME USES RBX hControl:QWORD, qwImageType:QWORD, hImage:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL pSpinnerFramesArray:QWORD
    LOCAL pCurrentFrame:QWORD
    LOCAL qwSize:QWORD

    IFDEF DEBUG64
    ;PrintText 'MUISpinnerAddFrame'
    ENDIF

    .IF hControl == NULL || qwImageType == NULL || hImage == NULL 
        xor eax, eax
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hControl, @SpinnerTotalFrames
    .IF rax == SPINNER_MAX_FRAMES
        xor eax, eax
        ret
    .ENDIF
    mov TotalFrames, rax
    
    Invoke MUIGetIntProperty, hControl, @SpinnerFramesArray
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov pSpinnerFramesArray, rax    
    
    mov rax, TotalFrames
    mov rbx, SIZEOF SPINNER_FRAME
    mul rbx
    add rax, pSpinnerFramesArray
    mov pCurrentFrame, rax

    mov rbx, pCurrentFrame
    mov rax, hImage
    mov [rbx], rax
    ;PrintQWORD rax
    Invoke MUISetIntProperty, hControl, @SpinnerImageType, qwImageType
    inc TotalFrames
    Invoke MUISetIntProperty, hControl, @SpinnerTotalFrames, TotalFrames
    
    mov rax, TRUE
    ret
MUISpinnerAddFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerAddFrames - Process an array of image handles and add them to the 
; spinner control as image frames
; 
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUISpinnerAddFrames PROC FRAME USES RBX RDX hControl:QWORD, qwCount:QWORD, qwImageType:QWORD, lpArrayImageHandles:QWORD
    LOCAL Index:QWORD

    .IF hControl == NULL || qwCount == NULL || qwImageType == NULL || lpArrayImageHandles == NULL
        xor eax, eax
        ret
    .ENDIF

    mov rbx, lpArrayImageHandles
    mov Index, 0
    mov rax, 0
    .WHILE rax < qwCount
        mov rax, [rbx]
        .IF rax != NULL
            Invoke MUISpinnerAddFrame, hControl, qwImageType, rax
            .IF rax == FALSE
                xor rax, rax
                ret
            .ENDIF
        .ENDIF
        add rbx, SIZEOF QWORD
        inc Index
        mov rax, Index
    .ENDW

    mov rax, TRUE
    ret
MUISpinnerAddFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerLoadFrame - Loads a resource as an image frame to the spinner control
;
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUISpinnerLoadFrame PROC FRAME hControl:QWORD, qwImageType:QWORD, idResImage:QWORD
    LOCAL hinstance:QWORD
    LOCAL hImage:QWORD
    
    IFDEF DEBUG32
    ;PrintText 'MUISpinnerLoadFrame'
    ENDIF
    
    .IF hControl == NULL || idResImage == NULL ||  qwImageType == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @SpinnerDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax    
    
    mov rax, qwImageType
    .IF rax == MUISPIT_BMP
        Invoke LoadBitmap, hinstance, idResImage
    .ELSEIF rax == MUISPIT_ICO
        Invoke LoadImage, hinstance, idResImage, IMAGE_ICON, 0, 0, 0
    .ELSEIF rax == MUISPIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke _MUI_SpinnerLoadPng, hinstance, idResImage
        ENDIF
    .ELSE
        xor eax, eax
        ret
    .ENDIF
    .IF eax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov hImage, rax

    Invoke MUISpinnerAddFrame, hControl, qwImageType, hImage
    .IF rax == FALSE
        xor eax, eax
        ret
    .ENDIF
    
    mov rax, TRUE
    ret
MUISpinnerLoadFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerLoadFrames - Process an array of resource ids and load the resource
; and add them to the spinner control as image frames
;
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUISpinnerLoadFrames PROC FRAME USES RBX RDX hControl:QWORD, qwCount:QWORD, qwImageType:QWORD, lpArrayResourceIDs:QWORD
    LOCAL Index:QWORD
    
    .IF hControl == NULL || qwCount == NULL || qwImageType == NULL || lpArrayResourceIDs == NULL
        xor eax, eax
        ret
    .ENDIF

    mov rbx, lpArrayResourceIDs
    mov Index, 0
    mov rax, 0
    .WHILE rax < qwCount
        mov rax, [ebx]
        .IF rax != NULL
            Invoke MUISpinnerLoadFrame, hControl, qwImageType, rax
            .IF rax == FALSE
                xor eax, eax
                ret
            .ENDIF
        .ENDIF
        add rbx, SIZEOF QWORD
        inc Index
        mov rax, Index
    .ENDW
    
    mov rax, TRUE
    ret
MUISpinnerLoadFrames ENDP

IFDEF MUI_USEGDIPLUS
MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerAddImage
;------------------------------------------------------------------------------
MUISpinnerAddImage PROC FRAME hControl:QWORD, hImage:QWORD, qwNoFramesToCreate:QWORD, bReverse:QWORD
    LOCAL BackColor:QWORD
    LOCAL nFrame:QWORD
    LOCAL hFrame:QWORD
    LOCAL fAngle:REAL4
    LOCAL slice:REAL4
    
    IFDEF DEBUG32
    ;PrintText 'MUISpinnerAddImage'
    ENDIF
    
    .IF hControl == NULL || hImage == NULL || qwNoFramesToCreate == 0
        xor eax, eax
        ret
    .ENDIF

    ; calc slice of pie required for each frame
    finit
    fld dword ptr FP4(360.0)
    fild qwNoFramesToCreate
    fdiv
    fstp slice
    
    ; init angle at 0 
    .IF bReverse == TRUE
        fld dword ptr FP4(360.0)
    .ELSE
        fld dword ptr FP4(0.0)
    .ENDIF
    fstp fAngle
    
    mov nFrame, 0
    mov rax, 0
    .WHILE rax < qwNoFramesToCreate
        Invoke _MUI_SpinnerRotateCenterImage, hImage, fAngle
        mov hFrame, rax
        
        Invoke MUISpinnerAddFrame, hControl, MUISPIT_PNG, hFrame
        .IF rax == FALSE
            xor eax, eax
            ret
        .ENDIF
        
        finit
        fld dword ptr fAngle
        .IF bReverse == TRUE
            fsub slice
        .ELSE
            fadd slice
        .ENDIF
        fstp dword ptr fAngle
        
        inc nFrame
        mov rax, nFrame
    .ENDW
    
    mov rax, TRUE
    ret
MUISpinnerAddImage ENDP
ENDIF

IFDEF MUI_USEGDIPLUS
MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerLoadImage
;------------------------------------------------------------------------------
MUISpinnerLoadImage PROC FRAME hControl:QWORD, idResImage:QWORD, qwNoFramesToCreate:QWORD, bReverse:QWORD
    LOCAL hinstance:QWORD
    LOCAL hImage:QWORD
    
    IFDEF DEBUG32
    ;PrintText 'MUISpinnerLoadImage'
    ENDIF
    
    .IF hControl == NULL || idResImage == NULL || qwNoFramesToCreate == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @SpinnerDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax   
    
    Invoke _MUI_SpinnerLoadPng, hinstance, idResImage
    mov hImage, rax

    Invoke MUISpinnerAddImage, hControl, hImage, qwNoFramesToCreate, bReverse
    .IF rax == FALSE
        xor eax, eax
        ret
    .ENDIF
    
    mov rax, TRUE
    ret
MUISpinnerLoadImage ENDP
ENDIF

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerAddSpriteSheet
;------------------------------------------------------------------------------
MUISpinnerAddSpriteSheet PROC FRAME USES RCX RDX hControl:QWORD, qwSpriteCount:QWORD, qwImageType:QWORD, hImageSpriteSheet:QWORD, bReverse:QWORD
    LOCAL hImageSpriteSheetOld:QWORD
    LOCAL hIcoSpriteSheet:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL FrameWidth:QWORD
    LOCAL FrameHeight:QWORD
    LOCAL nFrame:QWORD
    LOCAL hFrame:QWORD
    LOCAL hFrameOld:QWORD
    LOCAL x:QWORD
    LOCAL y:QWORD
    LOCAL hdc:QWORD
    LOCAL hdcFrame:QWORD
    LOCAL hdcSpriteSheet:QWORD
    LOCAL pGraphics:QWORD
    LOCAL pGraphicsFrame:QWORD
    LOCAL pFrame:QWORD
    LOCAL fxzero:REAL4
    LOCAL fyzero:REAL4
    LOCAL fx:REAL4
    LOCAL fy:REAL4
    LOCAL fFrameWidth:REAL4
    LOCAL fFrameHeight:REAL4
    
    IFDEF DEBUG32
    ;PrintText 'MUISpinnerAddSpriteSheet'
    ENDIF
    
    .IF hControl == NULL || qwImageType == NULL || qwSpriteCount == 0 || hImageSpriteSheet == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetImageSize, hImageSpriteSheet, qwImageType, Addr ImageWidth, Addr ImageHeight
    
;    mov rax, ImageWidth
;    PrintQWORD rax
;    mov rax, ImageHeight
;    PrintQWORD rax    
    
    ;--------------------------------------------------------------------------
    ; Calc frame width
    ;--------------------------------------------------------------------------
    xor rdx, rdx
    mov rax, ImageWidth
    mov rcx, qwSpriteCount
    div ecx
    mov FrameWidth, rax
    mov rax, ImageHeight
    mov FrameHeight, rax
    
;    mov rax, FrameWidth
;    PrintQWORD rax
;    mov rax, FrameHeight
;    PrintQWORD rax   


    Invoke GetDC, hControl
    mov hdc, rax

    ;--------------------------------------------------------------------------
    ; Get spritesheet image and create a dc + bitmap to store our sprite frame
    ;--------------------------------------------------------------------------
    mov rax, qwImageType
    .IF rax == MUISPIT_BMP
        Invoke CreateCompatibleDC, hdc
        mov hdcSpriteSheet, rax
        Invoke SelectObject, hdcSpriteSheet, hImageSpriteSheet
        mov hImageSpriteSheetOld, rax
        Invoke CreateCompatibleDC, hdc
        mov hdcFrame, rax
    .ELSEIF rax == MUISPIT_ICO
        Invoke CreateCompatibleDC, hdc
        mov hdcSpriteSheet, rax
        Invoke CreateCompatibleBitmap, hdc, dword ptr ImageWidth, dword ptr ImageHeight
        mov hIcoSpriteSheet, rax
        Invoke SelectObject, hdcSpriteSheet, hIcoSpriteSheet
        mov hImageSpriteSheetOld, rax
        Invoke CreateCompatibleDC, hdc
        mov hdcFrame, rax
        Invoke DrawIconEx, hdcSpriteSheet, 0, 0, hImageSpriteSheet, 0, 0, 0, 0, DI_NORMAL
    .ELSEIF rax == MUISPIT_PNG
        mov pGraphics, 0
        mov pGraphicsFrame, 0
        mov pFrame, 0
        Invoke GdipCreateFromHDC, hdc, Addr pGraphics
    .ENDIF

    ;--------------------------------------------------------------------------
    ; Cut each frame from spritesheet to hFrame and add to spinner
    ;--------------------------------------------------------------------------
    .IF bReverse == TRUE
        mov rax, ImageWidth
        sub rax, FrameWidth
        mov x, rax
        mov y, 0
        mov rax, qwSpriteCount
        mov nFrame, rax
        .WHILE rax > 0
            mov rax, qwImageType
            .IF rax == MUISPIT_BMP || rax == MUISPIT_ICO
                Invoke CreateCompatibleBitmap, hdc, dword ptr FrameWidth, dword ptr FrameHeight
                mov hFrame, rax
                Invoke SelectObject, hdcFrame, hFrame
                mov hFrameOld, rax
                Invoke BitBlt, hdcFrame, 0, 0, dword ptr FrameWidth, dword ptr FrameHeight, hdcSpriteSheet, dword ptr x, dword ptr y, SRCCOPY
                Invoke MUISpinnerAddFrame, hControl, MUISPIT_BMP, hFrame
                Invoke SelectObject, hdcFrame, hFrameOld
            .ELSEIF rax == MUISPIT_PNG
                Invoke GdipCreateBitmapFromGraphics, FrameWidth, FrameHeight, pGraphics, Addr pFrame
                Invoke GdipGetImageGraphicsContext, pFrame, Addr pGraphicsFrame
                
                Invoke GdipSetPixelOffsetMode, pGraphics, PixelOffsetModeHighQuality
                Invoke GdipSetPixelOffsetMode, pGraphicsFrame, PixelOffsetModeHighQuality
                Invoke GdipSetPageUnit, pGraphics, UnitPixel
                Invoke GdipSetPageUnit, pGraphicsFrame, UnitPixel
                Invoke GdipSetSmoothingMode, pGraphics, SmoothingModeAntiAlias
                Invoke GdipSetSmoothingMode, pGraphicsFrame, SmoothingModeAntiAlias
                Invoke GdipSetInterpolationMode, pGraphics, InterpolationModeHighQualityBicubic
                Invoke GdipSetInterpolationMode, pGraphicsFrame, InterpolationModeHighQualityBicubic

                Invoke GdipDrawImageRectRectI, pGraphicsFrame, hImageSpriteSheet, 0, 0, dword ptr FrameWidth, dword ptr FrameHeight, dword ptr x, dword ptr y, dword ptr FrameWidth, dword ptr FrameHeight, UnitPixel, NULL, NULL, NULL
                Invoke MUISpinnerAddFrame, hControl, MUISPIT_PNG, pFrame
                .IF pGraphicsFrame != NULL
                    Invoke GdipDeleteGraphics, pGraphicsFrame
                .ENDIF
            .ENDIF
            mov rax, FrameWidth
            sub x, rax
            dec nFrame
            mov rax, nFrame
        .ENDW
    .ELSE
        mov x, 0
        mov y, 0    
        mov rax, 0
        mov nFrame, rax
        .WHILE rax < qwSpriteCount
            mov rax, qwImageType
            .IF rax == MUISPIT_BMP || rax == MUISPIT_ICO
                Invoke CreateCompatibleBitmap, hdc, dword ptr FrameWidth, dword ptr FrameHeight
                mov hFrame, rax
                Invoke SelectObject, hdcFrame, hFrame
                mov hFrameOld, rax
                Invoke BitBlt, hdcFrame, 0, 0, dword ptr FrameWidth, dword ptr FrameHeight, hdcSpriteSheet, dword ptr x, dword ptr y, SRCCOPY
                Invoke MUISpinnerAddFrame, hControl, MUISPIT_BMP, hFrame
                Invoke SelectObject, hdcFrame, hFrameOld
            .ELSEIF rax == MUISPIT_PNG
                Invoke GdipCreateBitmapFromGraphics, FrameWidth, FrameHeight, pGraphics, Addr pFrame
                Invoke GdipGetImageGraphicsContext, pFrame, Addr pGraphicsFrame
                
                ;Invoke GdipSetPixelOffsetMode, pGraphics, PixelOffsetModeHighQuality
                Invoke GdipSetPixelOffsetMode, pGraphicsFrame, PixelOffsetModeHighQuality
                ;Invoke GdipSetPageUnit, pGraphics, UnitPixel
                Invoke GdipSetPageUnit, pGraphicsFrame, UnitPixel
                ;Invoke GdipSetSmoothingMode, pGraphics, SmoothingModeAntiAlias
                Invoke GdipSetSmoothingMode, pGraphicsFrame, SmoothingModeAntiAlias
                ;Invoke GdipSetInterpolationMode, pGraphics, InterpolationModeHighQualityBicubic
                Invoke GdipSetInterpolationMode, pGraphicsFrame, InterpolationModeHighQualityBicubic
                
;                finit
;                fld FP4(0.0)
;                fstp fxzero
;                fld FP4(0.0)
;                fstp fyzero
;                fild FrameHeight
;                fstp fFrameHeight
;                fild FrameWidth
;                fstp fFrameWidth
;                fild x
;                fstp fx
;                fild y
;                fstp fy
;                Invoke GdipDrawImageRectRect, pGraphicsFrame, hImageSpriteSheet, fxzero, fyzero, fFrameWidth, fFrameHeight, fx, fy, fFrameWidth, fFrameHeight, UnitPixel, NULL, NULL, NULL
                
                Invoke GdipDrawImageRectRectI, pGraphicsFrame, hImageSpriteSheet, 0, 0, dword ptr FrameWidth, dword ptr FrameHeight, dword ptr x, dword ptr y, dword ptr FrameWidth, dword ptr FrameHeight, UnitPixel, NULL, NULL, NULL
                
                Invoke MUISpinnerAddFrame, hControl, MUISPIT_PNG, pFrame
                .IF pGraphicsFrame != NULL
                    Invoke GdipDeleteGraphics, pGraphicsFrame
                .ENDIF 
            .ENDIF
            mov rax, FrameWidth
            add x, rax
            inc nFrame
            mov rax, nFrame
        .ENDW
    .ENDIF
    
    ;--------------------------------------------------------------------------
    ; Tidy up
    ;--------------------------------------------------------------------------
    mov rax, qwImageType
    .IF rax == MUISPIT_BMP || rax == MUISPIT_ICO
        Invoke SelectObject, hdcSpriteSheet, hImageSpriteSheetOld
        Invoke DeleteObject, hImageSpriteSheetOld
    .ELSEIF rax == MUISPIT_PNG
        .IF pGraphicsFrame != NULL
            Invoke GdipDeleteGraphics, pGraphicsFrame
        .ENDIF
        .IF pGraphics != NULL
            Invoke GdipDeleteGraphics, pGraphics
        .ENDIF
    .ENDIF
    
    Invoke ReleaseDC, hControl, hdc
    mov rax, TRUE
    ret
MUISpinnerAddSpriteSheet ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUISpinnerLoadSpriteSheet
;------------------------------------------------------------------------------
MUISpinnerLoadSpriteSheet PROC FRAME hControl:QWORD, qwSpriteCount:QWORD, qwImageType:QWORD, idResSpriteSheet:QWORD, bReverse:QWORD
    LOCAL hinstance:QWORD
    LOCAL hImage:QWORD
    
    IFDEF DEBUG32
    ;PrintText 'MUISpinnerLoadSpriteSheet'
    ENDIF
    
    .IF hControl == NULL || idResSpriteSheet == NULL ||  qwImageType == 0 || qwSpriteCount == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @SpinnerDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax    
    
    mov rax, qwImageType
    .IF rax == MUISPIT_BMP
        Invoke LoadBitmap, hinstance, idResSpriteSheet
    .ELSEIF rax == MUISPIT_ICO
        Invoke LoadImage, hinstance, idResSpriteSheet, IMAGE_ICON, 0, 0, 0
    .ELSEIF rax == MUISPIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke _MUI_SpinnerLoadPng, hinstance, idResSpriteSheet
        ENDIF
    .ELSE
        xor eax, eax
        ret
    .ENDIF
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov hImage, rax

    Invoke MUISpinnerAddSpriteSheet, hControl, qwSpriteCount, qwImageType, hImage, bReverse
    .IF rax == FALSE
        xor eax, eax
        ret
    .ENDIF
    
    mov eax, TRUE
    ret
MUISpinnerLoadSpriteSheet ENDP 

;------------------------------------------------------------------------------
; Load JPG/PNG from resource using GDI+
;   Actually, this function can load any image format supported by GDI+
;
; by: Chris Vega
;
; Addendum KSR 2014 : Needs OLE32 include and lib for CreateStreamOnHGlobal and 
; GetHGlobalFromStream calls. Underlying stream needs to be left open for the 
; life of the bitmap or corruption of png occurs. store png as RCDATA in 
; resource file.
;------------------------------------------------------------------------------
IFDEF MUI_USEGDIPLUS
MUI_ALIGN
_MUI_SpinnerLoadPng PROC FRAME hinstance:QWORD, idResPng:QWORD
    local rcRes:HRSRC
    local hResData:HRSRC
    local pResData:HANDLE
    local sizeOfRes:QWORD
    local hResBuffer:HANDLE
    local pResBuffer:QWORD
    local pIStream:QWORD
    local hIStream:QWORD
    LOCAL pImage:QWORD
    LOCAL pBitmapFromStream:QWORD
    LOCAL pGraphics:QWORD
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD  

    ; ------------------------------------------------------------------
    ; STEP 1: Find the resource
    ; ------------------------------------------------------------------
    invoke  FindResource, hinstance, idResPng, RT_RCDATA
    or      rax, rax
    jnz     @f
    jmp     _MUISpinnerLoadPng@Close
@@: mov     rcRes, rax
    
    ; ------------------------------------------------------------------
    ; STEP 2: Load the resource
    ; ------------------------------------------------------------------
    invoke  LoadResource, hinstance, rcRes
    or      rax, rax
    jnz     @f
    ret     ; Resource was not loaded
@@: mov     hResData, rax
    
    ; ------------------------------------------------------------------
    ; STEP 3: Create a stream to contain our loaded resource
    ; ------------------------------------------------------------------
    invoke  SizeofResource, hinstance, rcRes
    or      rax, rax
    jnz     @f
    jmp     _MUISpinnerLoadPng@Close
@@: mov     sizeOfRes, rax
    
    invoke  LockResource, hResData
    or      rax, rax
    jnz     @f
    jmp     _MUISpinnerLoadPng@Close
@@: mov     pResData, rax

    invoke  GlobalAlloc, GMEM_MOVEABLE, sizeOfRes
    or      rax, rax
    jnz     @f
    jmp     _MUISpinnerLoadPng@Close
@@: mov     hResBuffer, rax

    invoke  GlobalLock, hResBuffer
    mov     pResBuffer, rax
    
    invoke  RtlMoveMemory, pResBuffer, hResData, sizeOfRes
    invoke  CreateStreamOnHGlobal, pResBuffer, TRUE, Addr pIStream
    or      rax, rax
    jz      @f
    jmp     _MUISpinnerLoadPng@Close
@@: 

    ; ------------------------------------------------------------------
    ; STEP 4: Create an image object from stream
    ; ------------------------------------------------------------------
    invoke  GdipCreateBitmapFromStream, pIStream, Addr pBitmapFromStream
    invoke  GetHGlobalFromStream, pIStream, Addr hIStream
    
    ; ------------------------------------------------------------------
    ; STEP 5: Copy stream bitmap image to new ARGB 32bpp bitmap image
    ; ------------------------------------------------------------------
    mov pGraphics, 0
    Invoke GdipGetImageWidth, pBitmapFromStream, Addr qwImageWidth
    Invoke GdipGetImageHeight, pBitmapFromStream, Addr qwImageHeight    
    Invoke GdipCreateBitmapFromScan0, dword ptr qwImageWidth, dword ptr qwImageHeight, 0, PixelFormat32bppARGB, 0, Addr pImage
    Invoke GdipGetImageGraphicsContext, pImage, Addr pGraphics
    Invoke GdipDrawImageI, pGraphics, pBitmapFromStream, 0, 0
    
    ; ------------------------------------------------------------------
    ; STEP 6: Free all used locks and resources
    ; ------------------------------------------------------------------
    .IF pGraphics != NULL
        Invoke GdipDeleteGraphics, pGraphics
    .ENDIF
    Invoke GlobalUnlock, hResBuffer
    Invoke GlobalFree, pResBuffer
    
    ; ------------------------------------------------------------------
    ; STEP 7: Set property and return pImage
    ; ------------------------------------------------------------------
    mov rax, pImage;pBitmapFromStream;pImage

_MUISpinnerLoadPng@Close:
    ret
_MUI_SpinnerLoadPng endp
ENDIF

;-------------------------------------------------------------------------------------
; _MUI_SpinnerRotateCenterImage
;-------------------------------------------------------------------------------------
_MUI_SpinnerRotateCenterImage PROC FRAME hImage:QWORD, fAngle:REAL4
    LOCAL pGraphics:QWORD
    LOCAL pGraphicsBuffer:QWORD
    LOCAL matrix:QWORD
    LOCAL pBitmap:QWORD
    LOCAL pBrush:QWORD
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    LOCAL ImageWidth:REAL4
    LOCAL ImageHeight:REAL4
    LOCAL qwX:SQWORD
    LOCAL qwY:SQWORD
    LOCAL x:REAL4
    LOCAL y:REAL4
    LOCAL xneg:REAL4
    LOCAL yneg:REAL4
    LOCAL angle:REAL4

    ;---------------------------------------------------------------------------------
    ; Create new image based on hImage and rotate this new image 
    ;---------------------------------------------------------------------------------
    mov pGraphics, 0
    mov pGraphicsBuffer, 0
    mov matrix, 0
    mov pBitmap, 0
    mov pBrush, 0
    
    Invoke MUIGetImageSize, hImage, MUIIT_PNG, Addr qwImageWidth, Addr qwImageHeight
    Invoke GdipGetImageGraphicsContext, hImage, Addr pGraphics
    Invoke GdipCreateBitmapFromGraphics, qwImageWidth, qwImageHeight, pGraphics, Addr pBitmap 
    Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer
    
    Invoke GdipSetPixelOffsetMode, pGraphics, PixelOffsetModeHighQuality
    Invoke GdipSetPixelOffsetMode, pGraphicsBuffer, PixelOffsetModeHighQuality
    Invoke GdipSetPageUnit, pGraphics, UnitPixel
    Invoke GdipSetPageUnit, pGraphicsBuffer, UnitPixel
    Invoke GdipSetSmoothingMode, pGraphics, SmoothingModeAntiAlias
    Invoke GdipSetSmoothingMode, pGraphicsBuffer, SmoothingModeAntiAlias
    Invoke GdipSetInterpolationMode, pGraphics, InterpolationModeHighQualityBicubic
    Invoke GdipSetInterpolationMode, pGraphicsBuffer, InterpolationModeHighQualityBicubic
    
;    finit
;    fld qwImageWidth
;    fstp ImageWidth
;    fld qwImageHeight
;    fstp ImageHeight
    
    ;---------------------------------------------------------------------------------
    ; Check if angle is 180, if it is then do a flip instead of rotating
    ; (fixes the speed wobble issue when 180.0 is the angle)
    ;---------------------------------------------------------------------------------
    finit           ; init fpu
    fld fAngle
    fcom FP4(180.0) ; compare ST(0) with the value of the real4_var variable: 180.0
    fstsw ax        ; copy the Status Word containing the result to AX
    fwait           ; insure the previous instruction is completed
    sahf            ; transfer the condition codes to the CPU's flag register
    fstp st(0)
    ;ffree st(0)
    jz angle_is_180
    jmp angle_is_not_180
    
angle_is_180:
    ;Invoke GdipDrawImageRectRectI, pGraphicsBuffer, hImage, 0, 0, dwImageWidth, dwImageHeight, 0, 0, dwImageWidth, dwImageHeight, UnitPixel, NULL, NULL, NULL
    Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
    Invoke GdipImageRotateFlip, pBitmap, Rotate180FlipNone
    jmp tidyup

angle_is_not_180:

    ;---------------------------------------------------------------------------------
    ; Check if angle is 90, if it is then do a flip instead of rotating
    ;---------------------------------------------------------------------------------
    finit           ; init fpu
    fld fAngle
    fcom FP4(90.0) ; compare ST(0) with the value of the real4_var variable: 180.0
    fstsw ax        ; copy the Status Word containing the result to AX
    fwait           ; insure the previous instruction is completed
    sahf            ; transfer the condition codes to the CPU's flag register
    fstp st(0)
    ;ffree st(0)
    jz angle_is_90
    jmp angle_is_not_90
    
angle_is_90:
    ;Invoke GdipDrawImageRectRectI, pGraphicsBuffer, hImage, 0, 0, dwImageWidth, dwImageHeight, 0, 0, dwImageWidth, dwImageHeight, UnitPixel, NULL, NULL, NULL
    Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
    Invoke GdipImageRotateFlip, pBitmap, Rotate90FlipNone
    jmp tidyup

angle_is_not_90:

    ;---------------------------------------------------------------------------------
    ; Check if angle is 270, if it is then do a flip instead of rotating
    ;---------------------------------------------------------------------------------
    finit           ; init fpu
    fld fAngle
    fcom FP4(270.0) ; compare ST(0) with the value of the real4_var variable: 180.0
    fstsw ax        ; copy the Status Word containing the result to AX
    fwait           ; insure the previous instruction is completed
    sahf            ; transfer the condition codes to the CPU's flag register
    fstp st(0)
    ;ffree st(0)
    jz angle_is_270
    jmp angle_is_not_270
    
angle_is_270:
    ;Invoke GdipDrawImageRectRectI, pGraphicsBuffer, hImage, 0, 0, dwImageWidth, dwImageHeight, 0, 0, dwImageWidth, dwImageHeight, UnitPixel, NULL, NULL, NULL
    Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
    Invoke GdipImageRotateFlip, pBitmap, Rotate270FlipNone
    jmp tidyup

angle_is_not_270:

    ;---------------------------------------------------------------------------------
    ; Check if angle is 360, if it is then do a flip instead of rotating
    ;---------------------------------------------------------------------------------
    finit           ; init fpu
    fld fAngle
    fcom FP4(360.0) ; compare ST(0) with the value of the real4_var variable: 180.0
    fstsw ax        ; copy the Status Word containing the result to AX
    fwait           ; insure the previous instruction is completed
    sahf            ; transfer the condition codes to the CPU's flag register
    fstp st(0)
    ;ffree st(0)
    jz angle_is_360
    jmp angle_is_not_360
    
angle_is_360:
    ;Invoke GdipDrawImageRectRectI, pGraphicsBuffer, hImage, 0, 0, dwImageWidth, dwImageHeight, 0, 0, dwImageWidth, dwImageHeight, UnitPixel, NULL, NULL, NULL
    Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
    ;Invoke GdipImageRotateFlip, pBitmap, RotateNoneFlipNone
    jmp tidyup

angle_is_not_360:

    ;---------------------------------------------------------------------------------
    ; Check if angle is 0, if it is then do a flip instead of rotating
    ;---------------------------------------------------------------------------------
    finit           ; init fpu
    fld fAngle
    fcom FP4(0.0)   ; compare ST(0) with the value of the real4_var variable: 180.0
    fstsw ax        ; copy the Status Word containing the result to AX
    fwait           ; insure the previous instruction is completed
    sahf            ; transfer the condition codes to the CPU's flag register
    fstp st(0)
    ;ffree st(0)
    jz angle_is_0
    jmp angle_is_not_0
    
angle_is_0:
    ;Invoke GdipDrawImageRectRectI, pGraphicsBuffer, hImage, 0, 0, dwImageWidth, dwImageHeight, 0, 0, dwImageWidth, dwImageHeight, UnitPixel, NULL, NULL, NULL
    ;Invoke GdipCloneImage, hImage, Addr pBitmap
    Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
    jmp tidyup

angle_is_not_0:

    ;---------------------------------------------------------------------------------
    ; Do the actual rotation, calc Translate x, y position for GdipTranslateMatrix to
    ; rotate at image center. Calc the negative of x, y to restore
    ; the origin for drawing with GdipDrawImage
    ;---------------------------------------------------------------------------------
    finit           ; init fpu
    
    fild qwImageWidth;qwImageWidthScaled;qwImageWidth
    fld FP4(2.0)
    fdiv
    fstp x
    
    fild qwImageHeight;qwImageHeightScaled;qwImageHeight
    fld FP4(2.0)
    fdiv
    fstp y
    
    fld x
    fld FP4(-1.0)
    fmul
    fstp xneg
    
    fld y
    fld FP4(-1.0)
    fmul
    fstp yneg
    
    fld xneg
    fistp qwX
    
    fld yneg
    fistp qwY
    
    finit
    
    ;Invoke GdipTranslateWorldTransform, pGraphicsBuffer, x, y, MatrixOrderPrepend ;%MatrixOrderAppend)
    ;Invoke GdipRotateWorldTransform, pGraphicsBuffer, fAngle, MatrixOrderPrepend;MatrixOrderAppend;%MatrixOrderPrepend)
    ;Invoke GdiFlush
    ;Invoke GdipSetRenderingOrigin, pGraphicsBuffer, 0, 0
    ;Invoke GdipResetWorldTransform, pGraphics
    Invoke GdipResetWorldTransform, pGraphicsBuffer
    Invoke GdipCreateMatrix, Addr matrix
    Invoke GdipTranslateMatrix, matrix, x, y, MatrixOrderPrepend
    Invoke GdipRotateMatrix, matrix, fAngle, MatrixOrderPrepend
    Invoke GdipSetWorldTransform, pGraphicsBuffer, matrix
    
    ;Invoke GdipDrawImageRectRectI, pGraphicsBuffer, hImage, dword ptr qwX, dword ptr qwY, dword ptr qwImageWidth, dword ptr qwImageHeight, 0, 0, dword ptr qwImageWidth, dword ptr qwImageHeight, UnitPixel, NULL, NULL, NULL
    ;Invoke GdipDrawImageRectRect, pGraphicsBuffer, hImage, FP4(0.0), FP4(0.0), ImageWidth, ImageHeight, x, y, ImageWidth, ImageHeight, UnitPixel, NULL, NULL, NULL    
    
    Invoke GdipDrawImage, pGraphicsBuffer, hImage, xneg, yneg

    Invoke GdipResetWorldTransform, pGraphicsBuffer

tidyup:
    ;---------------------------------------------------------------------------------
    ; Delete buffers and return our new rotated image
    ;---------------------------------------------------------------------------------
    .IF matrix != NULL
        Invoke GdipDeleteMatrix, matrix
    .ENDIF
    .IF pBrush != NULL
        Invoke GdipDeleteBrush, pBrush
    .ENDIF
    .IF pGraphicsBuffer != NULL
        Invoke GdipDeleteGraphics, pGraphicsBuffer
    .ENDIF
    .IF pGraphics != NULL
        Invoke GdipDeleteGraphics, pGraphics
    .ENDIF

    mov rax, pBitmap
    ret
_MUI_SpinnerRotateCenterImage endp

;------------------------------------------------------------------------------
; _MUI_SpinnerTimerProc for TimerQueue
;------------------------------------------------------------------------------
IFDEF SPINNER_USE_TIMERQUEUE
MUI_ALIGN
_MUI_SpinnerTimerProc PROC FRAME lpParam:QWORD, TimerOrWaitFired:QWORD
    ; lpParam is hControl
    Invoke _MUI_SpinnerNextFrameIndex, lpParam
    Invoke InvalidateRect, lpParam, NULL, TRUE
    Invoke UpdateWindow, lpParam
    ret
_MUI_SpinnerTimerProc ENDP
ENDIF

;------------------------------------------------------------------------------
; _MUI_SpinnerMMTimerProc for Multimedia Timer
;------------------------------------------------------------------------------
IFDEF SPINNER_USE_MMTIMER
MUI_ALIGN
_MUI_SpinnerMMTimerProc PROC FRAME uTimerID:QWORD, uMsg:QWORD, qwUser:QWORD, qw1:QWORD, qw2:QWORD
    ; qwUser is hControl
    Invoke _MUI_SpinnerNextFrameIndex, qwUser
    Invoke InvalidateRect, qwUser, NULL, TRUE
    Invoke UpdateWindow, qwUser
    ret
_MUI_SpinnerMMTimerProc ENDP
ENDIF




MODERNUI_LIBEND
