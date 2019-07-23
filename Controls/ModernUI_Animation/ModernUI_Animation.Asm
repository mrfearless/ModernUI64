;==============================================================================
;
; ModernUI Control x64 - ModernUI_Animation x64
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

include ModernUI_Animation.inc


ANIMATION_USE_TIMERQUEUE      EQU 1 ; comment out to use WM_SETIMER instead of TimerQueue

IFDEF ANIMATION_USE_TIMERQUEUE
ECHO *** ModernUI_Animation - Using TimerQueue ***
ELSE
ECHO *** ModernUI_Animation - Using WM_TIMER ***
ENDIF


;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_AnimationWndProc         PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_AnimationInit            PROTO :QWORD
_MUI_AnimationCleanup         PROTO :QWORD
_MUI_AnimationPaint           PROTO :QWORD
_MUI_AnimationPaintImages     PROTO :QWORD, :QWORD, :QWORD, :QWORD
_MUI_AnimationNotify          PROTO :QWORD, :QWORD

_MUI_AnimationFrameData       PROTO :QWORD, :QWORD
_MUI_AnimationFrameIndex      PROTO :QWORD
_MUI_AnimationFrameType       PROTO :QWORD, :QWORD
_MUI_AnimationFrameImage      PROTO :QWORD, :QWORD
_MUI_AnimationFrameTime       PROTO :QWORD, :QWORD
_MUI_AnimationFrameParam      PROTO :QWORD, :QWORD

_MUI_AnimationNextFrame       PROTO :QWORD
_MUI_AnimationNextFrameIndex  PROTO :QWORD
_MUI_AnimationNextFrameTime   PROTO :QWORD

IFDEF MUI_USEGDIPLUS
_MUI_AnimationLoadPng         PROTO :QWORD, :QWORD
ENDIF
IFDEF ANIMATION_USE_TIMERQUEUE
_MUI_AnimationTimerProc       PROTO :QWORD, :QWORD
ENDIF
_MUI_AnimationTimerStart      PROTO :QWORD
_MUI_AnimationTimerStop       PROTO :QWORD


;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
MUI_ANIMATION_PROPERTIES      STRUCT
	qwBackColor			      DQ ?  ; RGBCOLOR. Background color of animation
	qwBorderColor             DQ ?  ; RGBCOLOR. Border color of animation
	qwAnimationLoop           DQ ?  ; BOOL. Loop animation back to start. Default is TRUE
	qwAnimationNotifications  DQ ?  ; BOOL. Allow notifications via WM_NOTIFY. Default is TRUE
	qwAnimationNotifyCallback DQ ?  ; QWORD. Address of custom notifications callback function
	qwAnimationDllInstance    DQ ?  ; QWORD. Instance of DLL if using control in a DLL
    qwAnimationParam          DQ ?  ; QWORD. Custom user specified value
MUI_ANIMATION_PROPERTIES      ENDS

; Internal properties
_MUI_ANIMATION_PROPERTIES     STRUCT
	qwMouseOver		          DQ ?  ; BOOL. Mouse is over control
    qwTotalFrames             DQ ?  ; QWORD. Total image frames in control
    qwFrameIndex              DQ ?  ; QWORD. Current frame index
    qwFramesArray             DQ ?  ; QWORD. Points to array of _MUI_ANIMATION_FRAME structures for each frame
    qwFramesImageType         DQ ?  ; QWORD. BMP, ICO or PNG
    qwFrameTimeDefault        DQ ?  ; QWORD. Default frame time for all frames that have frame time as 0
    qwFrameSpeed              DQ ?  ; QWORD. Current frame's speed (frame time)
    fSpeedFactor              DQ ?
    qwNotifyData              DQ ?  ; QWORD. Pointer to NM_ANIMATION notification structure data
    qwAnimationStatus         DQ ?  ; QWORD. 0 == stopped, 1 == paused, 2 == step mode, 3 == playing
    IFDEF ANIMATION_USE_TIMERQUEUE
    bUseTimerQueue            DQ ?  ; BOOL. Use timerqueue - if timerqueue api calls fail can fallback to WM_TIMER
    hQueue                    DQ ?  ; QWORD. Handle to timerqueue
    hTimer                    DQ ?  ; QWORD. Handle to timerqueue timer
    ENDIF
_MUI_ANIMATION_PROPERTIES     ENDS

IFNDEF _MUI_ANIMATION_FRAME
_MUI_ANIMATION_FRAME          STRUCT
    qwFrameType               DQ ?  ; Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    qwFrameImage              DQ ?  ; Handle to image: Bitmap, Icon or PNG
    qwFrameTime               DQ ?  ; Frame time in milliseconds
    lParam                    DQ ?  ; Custom user specified value
_MUI_ANIMATION_FRAME          ENDS
ENDIF

IFNDEF NM_ANIMATION_FRAME     ; ModernUI_Animation Notification Item
NM_ANIMATION_FRAME            STRUCT
    qwFrameIndex              DQ ?  ; Frame index
    qwFrameType               DQ ?  ; Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    qwFrameImage              DQ ?  ; Handle or resource ID of image : Bitmap, Icon or PNG (RT_BITMAP, RT_ICON or RT_RCDATA resource)
    qwFrameTime               DQ ?  ; Frame time in milliseconds
    lParam                    DQ ?  ; Custom user specified value
NM_ANIMATION_FRAME            ENDS
ENDIF

IFNDEF NM_ANIMATION           ; Notification Message Structure for ModernUI_Animation
NM_ANIMATION                  STRUCT
    hdr                       NMHDR <>
    item                      NM_ANIMATION_FRAME <>
NM_ANIMATION                  ENDS
ENDIF

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
ANIMATION_FRAME_TIME_MIN      EQU 10
ANIMATION_FRAME_TIME_DEFAULT  EQU 250 ; Milliseconds for timer firing


MUIANI_STATUS_STOPPED         EQU 0
MUIANI_STATUS_PAUSED          EQU 1
MUIANI_STATUS_STEPPING        EQU 2
MUIANI_STATUS_PLAYING         EQU 3


; Internal properties
@AnimationMouseOver           EQU 0
@AnimationTotalFrames         EQU 8
@AnimationFrameIndex          EQU 16
@AnimationFramesArray         EQU 24
@AnimationImageType           EQU 32
@AnimationFrameTimeDefault    EQU 40
@AnimationFrameSpeed          EQU 48
@AnimationSpeedFactor         EQU 56
@AnimationNotifyData          EQU 64
@AnimationStatus              EQU 72
IFDEF ANIMATION_USE_TIMERQUEUE
@AnimationUseTimerQueue       EQU 80
@AnimationQueue               EQU 88
@AnimationTimer               EQU 96
ENDIF



.DATA
szMUIAnimationClass           DB 'ModernUI_Animation',0 	; Class name for creating our ModernUI_Animation control


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for Animation control
;------------------------------------------------------------------------------
MUIAnimationSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUIAnimationSetProperty ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for Animation control
;------------------------------------------------------------------------------
MUIAnimationGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUIAnimationGetProperty ENDP

;-------------------------------------------------------------------------------------
; MUIAnimationRegister - Registers the ModernUI_Animation control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Animation
;-------------------------------------------------------------------------------------
MUIAnimationRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUIAnimationClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUIAnimationClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_AnimationWndProc
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

MUIAnimationRegister ENDP

;-------------------------------------------------------------------------------------
; MUIAnimationCreate - Returns handle in rax of newly created control
;-------------------------------------------------------------------------------------
MUIAnimationCreate PROC FRAME hWndParent:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
	LOCAL qwNewStyle:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUIAnimationRegister
	
    mov rax, qwStyle
    mov qwNewStyle, rax
    and rax, WS_CHILD or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_CLIPCHILDREN
        or qwNewStyle, WS_CHILD or WS_CLIPCHILDREN
    .ENDIF	
	
    Invoke CreateWindowEx, NULL, Addr szMUIAnimationClass, NULL, dword ptr qwNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUIAnimationCreate ENDP

;-------------------------------------------------------------------------------------
; _MUI_AnimationWndProc - Main processing window for our control
;-------------------------------------------------------------------------------------
_MUI_AnimationWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    LOCAL qwStyle:QWORD
    
    mov eax, uMsg
    .IF eax == WM_NCCREATE
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, MUI_INTERNAL_PROPERTIES, SIZEOF _MUI_ANIMATION_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, MUI_EXTERNAL_PROPERTIES, SIZEOF MUI_ANIMATION_PROPERTIES ; external properties
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGDIPlusStart ; for png resources if used
        ENDIF
		Invoke _MUI_AnimationInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_DESTROY
        Invoke _MUI_AnimationCleanup, hWin
		mov rax, 0
		ret

    .ELSEIF eax == WM_NCDESTROY
        Invoke MUIFreeMemProperties, hWin, MUI_INTERNAL_PROPERTIES
        Invoke MUIFreeMemProperties, hWin, MUI_EXTERNAL_PROPERTIES
        IFDEF MUI_USEGDIPLUS
        Invoke MUIGDIPlusFinish
        ENDIF
		mov rax, 0
		ret           
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_AnimationPaint, hWin
        mov rax, 0
        ret

    .ELSEIF eax== WM_SETCURSOR
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUIAS_HAND
        .IF rax == MUIAS_HAND
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

		Invoke GetWindowLongPtr, hWin, GWL_STYLE
		mov qwStyle, rax
		and rax, MUIAS_LCLICK
		.IF rax == MUIAS_LCLICK
		    Invoke MUIGetIntProperty, hWin, @AnimationStatus
		    .IF rax == MUIANI_STATUS_STOPPED
		        Invoke MUIAnimationStart, hWin
		    .ELSEIF rax == MUIANI_STATUS_PAUSED
		        Invoke MUIAnimationResume, hWin
		    .ELSEIF rax == MUIANI_STATUS_STEPPING
		        Invoke MUIAnimationStep, hWin, FALSE
		    .ELSEIF rax == MUIANI_STATUS_PLAYING
		        mov rax, qwStyle
		        and rax, MUIAS_CONTROL
		        .IF rax != MUIAS_CONTROL
		            Invoke MUIAnimationPause, hWin
		        .ENDIF
		    .ENDIF
		.ENDIF

    .ELSEIF eax == WM_RBUTTONUP
		Invoke GetWindowLongPtr, hWin, GWL_STYLE
		and rax, MUIAS_RCLICK
		.IF rax == MUIAS_RCLICK
		    Invoke MUIGetIntProperty, hWin, @AnimationStatus
		    .IF rax == MUIANI_STATUS_STOPPED
		        Invoke MUIAnimationStart, hWin
		    .ELSEIF rax == MUIANI_STATUS_PAUSED
		        Invoke MUIAnimationResume, hWin
		    .ELSEIF rax == MUIANI_STATUS_STEPPING
		        Invoke MUIAnimationStep, hWin, TRUE
		    .ELSEIF rax == MUIANI_STATUS_PLAYING
		        Invoke MUIAnimationPause, hWin
		    .ENDIF
		.ENDIF

	.ELSEIF eax == WM_TIMER
	    mov rax, wParam
	    .IF rax == hWin
	        Invoke _MUI_AnimationNextFrame, hWin
	    .ENDIF

	; custom messages start here
    .ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
		Invoke MUISetExtProperty, hWin, wParam, lParam
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret

_MUI_AnimationWndProc ENDP

;-------------------------------------------------------------------------------------
; _MUI_AnimationInit - set initial default values
;-------------------------------------------------------------------------------------
_MUI_AnimationInit PROC FRAME hWin:QWORD
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
    Invoke MUIGetParentBackgroundColor, hWin
    .IF rax == -1 ; if background was NULL then try a color as default
        Invoke GetSysColor, COLOR_WINDOW
    .ENDIF    
    Invoke MUISetExtProperty, hWin, @AnimationBackColor, rax ;MUI_RGBCOLOR(240,240,240)
    Invoke MUISetExtProperty, hWin, @AnimationBorderColor, MUI_RGBCOLOR(48,48,48)
    Invoke MUISetExtProperty, hWin, @AnimationLoop, TRUE
    Invoke MUISetIntProperty, hWin, @AnimationFrameTimeDefault, ANIMATION_FRAME_TIME_DEFAULT

    IFDEF ANIMATION_USE_TIMERQUEUE
    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, TRUE
    Invoke MUISetIntProperty, hWin, @AnimationQueue, 0
    Invoke MUISetIntProperty, hWin, @AnimationTimer, 0
    ENDIF

    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF NM_ANIMATION
    .IF rax != NULL
        Invoke MUISetIntProperty, hWin, @AnimationNotifyData, rax
        Invoke MUISetExtProperty, hWin, @AnimationNotifications, TRUE
    .ENDIF
    
    mov rax, TRUE
    ret
_MUI_AnimationInit ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationCleanup - cleanup
;------------------------------------------------------------------------------
_MUI_AnimationCleanup PROC FRAME USES RBX hWin:QWORD
    IFDEF ANIMATION_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    ENDIF

    IFDEF DEBUG32
    PrintText '_MUI_AnimationCleanup'
    ENDIF

    Invoke _MUI_AnimationTimerStop, hWin
    Invoke MUIAnimationClear, hWin

    IFDEF ANIMATION_USE_TIMERQUEUE
        Invoke MUIGetIntProperty, hWin, @AnimationUseTimerQueue
        .IF rax == TRUE
            Invoke MUIGetIntProperty, hWin, @AnimationQueue
            mov hQueue, rax
            Invoke DeleteTimerQueueEx, hQueue, NULL
            Invoke MUISetIntProperty, hWin, @AnimationQueue, NULL
            Invoke MUISetIntProperty, hWin, @AnimationTimer, NULL
        .ENDIF
    ENDIF

    Invoke MUIGetIntProperty, hWin, @AnimationNotifyData
    .IF rax != NULL
        Invoke GlobalFree, rax
        ;PrintText 'deleted notify data'
        Invoke MUISetIntProperty, hWin, @AnimationNotifyData, NULL
    .ENDIF

    ret
_MUI_AnimationCleanup ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationPaint
;------------------------------------------------------------------------------
_MUI_AnimationPaint PROC hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hBufferBitmap:QWORD
    LOCAL BackColor:QWORD
    LOCAL BorderColor:QWORD

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax

    ;----------------------------------------------------------
    ; Get some property values
    ;---------------------------------------------------------- 
    Invoke MUIGetExtProperty, hWin, @AnimationBackColor
    mov BackColor, rax
    Invoke MUIGetExtProperty, hWin, @AnimationBorderColor
    mov BorderColor, rax

    ;----------------------------------------------------------
    ; Setup Double Buffering
    ;----------------------------------------------------------
    Invoke MUIGDIDoubleBufferStart, hWin, hdc, Addr hdcMem, Addr rect, Addr hBufferBitmap

    ;----------------------------------------------------------
    ; Paint background
    ;----------------------------------------------------------
    Invoke MUIGDIPaintFill, hdcMem, Addr rect, BackColor
    
    ;----------------------------------------------------------
    ; Images
    ;----------------------------------------------------------
    Invoke _MUI_AnimationPaintImages, hWin, hdc, hdcMem, Addr rect

    ;----------------------------------------------------------
    ; Paint Border
    ;----------------------------------------------------------
    Invoke MUIGDIPaintFrame, hdcMem, Addr rect, BorderColor, MUIPFS_ALL
    
    ;----------------------------------------------------------
    ; BitBlt from hdcMem back to hdc
    ;----------------------------------------------------------
    Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

    ;----------------------------------------------------------
    ; Finish Double Buffering & Cleanup
    ;----------------------------------------------------------    
    Invoke MUIGDIDoubleBufferFinish, hdcMem, hBufferBitmap, 0, 0, 0, 0    
    
    Invoke EndPaint, hWin, Addr ps
    ret
_MUI_AnimationPaint ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationPaintImages
;------------------------------------------------------------------------------
_MUI_AnimationPaintImages PROC FRAME USES RBX hWin:QWORD, hdcMain:QWORD, hdcDest:QWORD, lpRect:QWORD
    LOCAL hdcMem:HDC
    LOCAL hbmOld:QWORD
    LOCAL hImage:QWORD
    LOCAL qwImageType:QWORD
    LOCAL pGraphics:QWORD
    LOCAL pGraphicsBuffer:QWORD
    LOCAL pBitmap:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL qwStyle:QWORD
    LOCAL bStretch:QWORD
    LOCAL rect:RECT
    LOCAL pt:POINT
    
    IFDEF DEBUG32
    ;PrintText '_MUI_AnimationPaintImages'
    ENDIF
    
    ;Invoke MUIGetIntProperty, hWin, @AnimationImageType
    Invoke _MUI_AnimationFrameType, hWin, -1
    .IF rax == 0
        ret
    .ENDIF
    mov qwImageType, rax
    
    Invoke _MUI_AnimationFrameImage, hWin, -1 ; get current frame
    ;Invoke _MUI_AnimationCurrentFrameImage, hWin
    .IF rax == 0
        ret
    .ENDIF
    mov hImage, rax
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    
    Invoke CopyRect, Addr rect, lpRect
    Invoke MUIGetImageSize, hImage, qwImageType, Addr ImageWidth, Addr ImageHeight
    
    
    mov rax, qwStyle
    and rax, MUIAS_STRETCH
    .IF rax == MUIAS_STRETCH
        mov bStretch, TRUE
    .ELSE
        mov bStretch, FALSE
    .ENDIF
    
    .IF bStretch == TRUE
        mov pt.x, 0
        mov pt.y, 0
    .ELSE
        mov rax, qwStyle
        and rax, MUIAS_CENTER
        .IF rax == MUIAS_CENTER
            xor rax, rax
            mov eax, rect.right
            shr rax, 1
            mov rbx, ImageWidth
            shr rbx, 1
            sub rax, rbx
            .IF sqword ptr rax < 0
                mov rax, 0
            .ENDIF
            mov pt.x, eax
            
            xor rax, rax
            mov eax, rect.bottom
            shr rax, 1
            mov rbx, ImageHeight
            shr rbx, 1
            sub rax, rbx
            .IF sqword ptr rax < 0
                mov rax, 0
            .ENDIF
            mov pt.y, eax
        .ELSE
            mov pt.x, 0
            mov pt.y, 0
        .ENDIF
    .ENDIF
    
    IFDEF DEBUG32
    ;PrintDec pt.x
    ;PrintDec pt.y
    ;PrintDec ImageWidth
    ;PrintDec ImageHeight
    ;PrintDec rect.right
    ;PrintDec rect.bottom
    ENDIF
    
    mov rax, qwImageType
    .IF rax == MUIAIT_BMP ; bitmap
        
        Invoke CreateCompatibleDC, hdcMain
        mov hdcMem, rax
        Invoke SelectObject, hdcMem, hImage
        mov hbmOld, rax
        
        .IF bStretch == TRUE
            Invoke StretchBlt, hdcDest, pt.x, pt.y, rect.right, rect.bottom, hdcMem, 0, 0, dword ptr ImageWidth, dword ptr ImageHeight, SRCCOPY
        .ELSE
            Invoke BitBlt, hdcDest, pt.x, pt.y, dword ptr ImageWidth, dword ptr ImageHeight, hdcMem, 0, 0, SRCCOPY
        .ENDIF

        Invoke SelectObject, hdcMem, hbmOld
        Invoke DeleteDC, hdcMem
        .IF hbmOld != 0
            Invoke DeleteObject, hbmOld
        .ENDIF
        
    .ELSEIF rax == MUIAIT_ICO ; icon
        .IF bStretch == TRUE
            Invoke DrawIconEx, hdcDest, pt.x, pt.y, hImage, rect.right, rect.bottom, 0, 0, DI_NORMAL
        .ELSE
            Invoke DrawIconEx, hdcDest, pt.x, pt.y, hImage, 0, 0, 0, 0, DI_NORMAL
        .ENDIF
    
    .ELSEIF rax == MUIAIT_PNG ; png
        IFDEF MUI_USEGDIPLUS
        Invoke GdipCreateFromHDC, hdcDest, Addr pGraphics
        Invoke GdipCreateBitmapFromGraphics, ImageWidth, ImageHeight, pGraphics, Addr pBitmap
        Invoke GdipGetImageGraphicsContext, pBitmap, Addr pGraphicsBuffer
        
        Invoke GdipSetPixelOffsetMode, pGraphics, PixelOffsetModeHighQuality
        Invoke GdipSetPixelOffsetMode, pGraphicsBuffer, PixelOffsetModeHighQuality
        Invoke GdipSetPageUnit, pGraphics, UnitPixel
        Invoke GdipSetPageUnit, pGraphicsBuffer, UnitPixel
        Invoke GdipSetSmoothingMode, pGraphics, SmoothingModeAntiAlias
        Invoke GdipSetSmoothingMode, pGraphicsBuffer, SmoothingModeAntiAlias
        Invoke GdipSetInterpolationMode, pGraphics, InterpolationModeHighQualityBicubic
        Invoke GdipSetInterpolationMode, pGraphicsBuffer, InterpolationModeHighQualityBicubic
        
        Invoke GdipDrawImageI, pGraphicsBuffer, hImage, 0, 0
        .IF bStretch == TRUE
            Invoke GdipDrawImageRectRectI, pGraphics, pBitmap, pt.x, pt.y, rect.right, rect.bottom, 0, 0, dword ptr ImageWidth, dword ptr ImageHeight, UnitPixel, 0, 0, 0
        .ELSE
            Invoke GdipDrawImageRectI, pGraphics, pBitmap, pt.x, pt.y, dword ptr ImageWidth, dword ptr ImageHeight
        .ENDIF
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
_MUI_AnimationPaintImages ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNotify
;------------------------------------------------------------------------------
_MUI_AnimationNotify PROC FRAME USES RBX hWin:QWORD, qwCode:QWORD
    LOCAL pAnimationFramesArray:QWORD
    LOCAL pFrameData:QWORD
    LOCAL NotifyData:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL FrameType:QWORD
    LOCAL FrameImage:QWORD
    LOCAL FrameTime:QWORD
    LOCAL lParam:QWORD
    LOCAL hParent:QWORD
    LOCAL idControl:QWORD
    LOCAL NotifyCallback:QWORD
    
    Invoke MUIGetExtProperty, hWin, @AnimationNotifications
    .IF rax == FALSE
        mov rax, TRUE
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF rax == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationFramesArray
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov pAnimationFramesArray, rax

    Invoke MUIGetIntProperty, hWin, @AnimationNotifyData
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov NotifyData, rax

    ; Get current frame index and then frame data
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    mov FrameIndex, rax
    mov rax, FrameIndex
    mov rbx, SIZEOF _MUI_ANIMATION_FRAME
    mul rbx
    add rax, pAnimationFramesArray
    mov pFrameData, rax
    
    ; Get current information about our frame
    mov rbx, pFrameData
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameType
    mov FrameType, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameImage
    mov FrameImage, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameTime
    mov FrameTime, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.lParam
    mov lParam, rax
    
    ; Add frame info and other info to notify data
    mov rbx, NotifyData
    mov rax, hWin
    mov [rbx].NM_ANIMATION.hdr.hwndFrom, rax
    mov rax, qwCode
    mov [rbx].NM_ANIMATION.hdr.code, eax
    mov rax, FrameIndex
    mov [rbx].NM_ANIMATION.item.qwFrameIndex, rax
    mov rax, FrameType
    mov [rbx].NM_ANIMATION.item.qwFrameType, rax
    mov rax, FrameImage
    mov [rbx].NM_ANIMATION.item.qwFrameImage, rax
    mov rax, FrameTime
    mov [rbx].NM_ANIMATION.item.qwFrameTime, rax
    mov rax, lParam
    mov [rbx].NM_ANIMATION.item.lParam, rax
    
    Invoke MUIGetExtProperty, hWin, @AnimationNotifyCallback
    .IF rax == NULL
        ; PostMessage WM_NOTIFY
        Invoke GetParent, hWin
        mov hParent, rax
        Invoke GetDlgCtrlID, hWin
        mov idControl, rax

        .IF hParent != NULL
            Invoke PostMessage, hParent, WM_NOTIFY, idControl, NotifyData
            mov rax, TRUE
        .ELSE
            mov rax, FALSE
        .ENDIF
    .ELSE
        ; Custom user callback for notifications instead of WM_NOTIFY
        mov NotifyCallback, rax
        mov rcx, NotifyData
        mov rdx, hWin
        call rax ;NotifyCallback
    .ENDIF
    ret
_MUI_AnimationNotify endp

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameData - gets a pointer to a frame's data
; if dwFrameIndex == -1 then gets the current frame's data
; Returns in eax pointer to _MUI_ANIMATION_FRAME data
;------------------------------------------------------------------------------
_MUI_AnimationFrameData PROC FRAME USES RBX hWin:QWORD, qwFrameIndex:QWORD
    LOCAL pAnimationFramesArray:QWORD
    
    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF rax == 0
        mov rax, NULL
        ret
    .ENDIF
    .IF qwFrameIndex >= rax && qwFrameIndex != -1 ; rax = TotalFrames
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationFramesArray
    .IF rax == 0
        mov rax, NULL
        ret
    .ENDIF
    mov pAnimationFramesArray, rax
    
    .IF qwFrameIndex == -1
        Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    .ELSE
        mov rax, qwFrameIndex
    .ENDIF
    mov rbx, SIZEOF _MUI_ANIMATION_FRAME
    mul rbx
    add rax, pAnimationFramesArray

    ret
_MUI_AnimationFrameData ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameIndex - Gets current frame index
;------------------------------------------------------------------------------
_MUI_AnimationFrameIndex PROC FRAME hWin:QWORD
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    ret
_MUI_AnimationFrameIndex ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameType - gets a frame's image type
; if qwFrameIndex == -1 then gets the current frame's image type
;------------------------------------------------------------------------------
_MUI_AnimationFrameType PROC FRAME hWin:QWORD, qwFrameIndex:QWORD
    Invoke _MUI_AnimationFrameData, hWin, qwFrameIndex
    .IF rax == NULL
        IFDEF DEBUG32
        ;PrintText '_MUI_AnimationFrameType::_MUI_AnimationFrameData::NULL'
        ENDIF
        ret
    .ENDIF
    mov rax, [rax]._MUI_ANIMATION_FRAME.qwFrameType
    ret
_MUI_AnimationFrameType ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameImage - gets a frame's image handle
; if qwFrameIndex == -1 then gets the current frame's image handle
;------------------------------------------------------------------------------
_MUI_AnimationFrameImage PROC FRAME hWin:QWORD, qwFrameIndex:QWORD
    Invoke _MUI_AnimationFrameData, hWin, qwFrameIndex
    .IF rax == NULL
        IFDEF DEBUG32
        ;PrintText '_MUI_AnimationFrameImage::_MUI_AnimationFrameData::NULL'
        ENDIF
        ret
    .ENDIF
    mov rax, [rax]._MUI_ANIMATION_FRAME.qwFrameImage
    ret
_MUI_AnimationFrameImage ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameIndex - Gets a frame's time
; if qwFrameIndex == -1 then gets the current frame's time
;------------------------------------------------------------------------------
_MUI_AnimationFrameTime PROC FRAME hWin:QWORD, qwFrameIndex:QWORD
    Invoke _MUI_AnimationFrameData, hWin, qwFrameIndex
    .IF rax == NULL
        ret
    .ENDIF
    mov rax, [rax]._MUI_ANIMATION_FRAME.qwFrameTime
    ret
_MUI_AnimationFrameTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationFrameParam - Gets a frame's lParam
; if qwFrameIndex == -1 then gets the current frame's lParam
;------------------------------------------------------------------------------
_MUI_AnimationFrameParam PROC FRAME hWin:QWORD, qwFrameIndex:QWORD
    Invoke _MUI_AnimationFrameData, hWin, qwFrameIndex
    .IF rax == NULL
        ret
    .ENDIF
    mov rax, [rax]._MUI_ANIMATION_FRAME.lParam
    ret
_MUI_AnimationFrameParam ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNextFrameIndex - Sets the next frame index to use for painting
; Returns the next frame index or -1 if error or -2 if animation is at end.
;------------------------------------------------------------------------------
_MUI_AnimationNextFrameIndex PROC FRAME USES RBX hWin:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL NextFrame:QWORD
    LOCAL bLoop:QWORD

    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF rax == 0
        mov rax, -1 ; no frames
        ret
    .ENDIF
    mov TotalFrames, rax
    
    Invoke MUIGetExtProperty, hWin, @AnimationLoop
    mov bLoop, rax
    
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    inc rax
    .IF rax >= TotalFrames
        .IF bLoop == TRUE
            mov rax, 0
        .ELSE
            mov rax, -2 ; stop playing
            ret
        .ENDIF
    .ENDIF
    mov NextFrame, rax
    Invoke MUISetIntProperty, hWin, @AnimationFrameIndex, NextFrame
    mov rax, NextFrame
    ret
_MUI_AnimationNextFrameIndex ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNextFrameTime - Sets the next frame time to use for timer
; Returns frame time or -1 if error
;------------------------------------------------------------------------------
_MUI_AnimationNextFrameTime PROC FRAME hWin:QWORD
    LOCAL pAnimationFramesArray:QWORD
    LOCAL FrameTime:QWORD
    
    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF rax == 0
        Invoke MUISetIntProperty, hWin, @AnimationFrameSpeed, 0
        mov rax, 0
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hWin, @AnimationFramesArray
    .IF rax == NULL
        mov rax, -1
        ret
    .ENDIF
    mov pAnimationFramesArray, rax
    
    Invoke MUIGetIntProperty, hWin, @AnimationFrameIndex
    mov rbx, SIZEOF _MUI_ANIMATION_FRAME
    mul rbx
    add rax, pAnimationFramesArray
    mov rbx, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameTime
    mov FrameTime, rax
    Invoke MUISetIntProperty, hWin, @AnimationFrameSpeed, FrameTime 
    mov rax, FrameTime
    ret
_MUI_AnimationNextFrameTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationStart - Starts animation playing
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationStart PROC FRAME USES RBX hControl:QWORD

    IFDEF DEBUG32
    ;PrintText 'MUIAnimationStart'
    ENDIF
    
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF rax == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF rax == NULL
        ret
    .ENDIF
    mov rbx, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameTime
    Invoke MUISetIntProperty, hControl, @AnimationFrameSpeed, rax
    Invoke MUISetIntProperty, hControl, @AnimationFrameIndex, 0 ; set play to start at frame 0
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    
    Invoke MUISetIntProperty, hControl, @AnimationStatus, MUIANI_STATUS_PLAYING
    Invoke _MUI_AnimationNotify, hControl, MUIAN_START
    Invoke _MUI_AnimationTimerStart, hControl
    ret
MUIAnimationStart ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationStop - Stops animation
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationStop PROC FRAME hControl:QWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    Invoke _MUI_AnimationTimerStop, hControl
    Invoke MUISetIntProperty, hControl, @AnimationFrameIndex, 0 ; reset for play to start at frame 0
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    
    Invoke MUISetIntProperty, hControl, @AnimationStatus, MUIANI_STATUS_STOPPED
    Invoke _MUI_AnimationNotify, hControl, MUIAN_STOP
    mov rax, TRUE
    ret
MUIAnimationStop ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationPause - Pauses animation
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationPause PROC FRAME hControl:QWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    Invoke _MUI_AnimationTimerStop, hControl
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    
    Invoke MUISetIntProperty, hControl, @AnimationStatus, MUIANI_STATUS_PAUSED
    Invoke _MUI_AnimationNotify, hControl, MUIAN_PAUSE
    mov rax, TRUE
    ret
MUIAnimationPause ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationResume - Resumes animation that was paused or stopped.
; Returns: TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationResume PROC FRAME hControl:QWORD
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF rax == 0
        xor eax, eax
        ret
    .ENDIF    
    
    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    
    Invoke MUISetIntProperty, hControl, @AnimationStatus, MUIANI_STATUS_PLAYING
    Invoke _MUI_AnimationNotify, hControl, MUIAN_START
    Invoke _MUI_AnimationTimerStart, hControl
    ret
MUIAnimationResume ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationStep
; Returns: next frame that is being shown, or -1 if no frames, or -2 if end of
; animation and @AnimationLoop is not set to TRUE to loop.
;------------------------------------------------------------------------------
MUIAnimationStep PROC FRAME hControl:QWORD, bReverse:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL NextFrame:QWORD
    LOCAL bLoop:QWORD
    
    .IF hControl == NULL
        mov rax, -1 ; no frames
        ret
    .ENDIF
    
    ;Invoke MUIAnimationPause, hControl
    Invoke _MUI_AnimationTimerStop, hControl
    
    ; inc or dec frame index
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF rax == 0
        mov rax, -1 ; no frames
        ret
    .ENDIF
    mov TotalFrames, rax
    
    Invoke MUIGetExtProperty, hControl, @AnimationLoop
    mov bLoop, rax
    
    Invoke MUIGetIntProperty, hControl, @AnimationFrameIndex
    .IF bReverse == FALSE
        inc rax
        .IF rax >= TotalFrames
            .IF bLoop == TRUE
                mov rax, 0
            .ELSE
                ; stop playing
                mov rax, -2
                ret
            .ENDIF
        .ENDIF
    .ELSE
        dec rax
        .IF sqword ptr rax < 0 
            .IF bLoop == TRUE
                mov rax, TotalFrames
                dec rax
            .ELSE
                ; stop playing
                mov rax, -2
                ret
            .ENDIF
        .ENDIF
    .ENDIF
    mov NextFrame, rax
    Invoke MUISetIntProperty, hControl, @AnimationFrameIndex, NextFrame

    Invoke InvalidateRect, hControl, NULL, TRUE
    Invoke UpdateWindow, hControl
    
    Invoke MUISetIntProperty, hControl, @AnimationStatus, MUIANI_STATUS_STEPPING
    Invoke _MUI_AnimationNotify, hControl, MUIAN_STEP
    mov rax, NextFrame
    ret
MUIAnimationStep ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSpeed
;------------------------------------------------------------------------------
MUIAnimationSpeed PROC FRAME hControl:QWORD, fSpeedFactor:REAL4
    Invoke MUISetIntProperty, hControl, @AnimationSpeedFactor, fSpeedFactor
    ret
MUIAnimationSpeed ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSpeed
;------------------------------------------------------------------------------
MUIAnimationSetDefaultTime PROC FRAME hControl:QWORD, qwDefaultFrameTime:QWORD
    mov rax, qwDefaultFrameTime
    .IF rax == 0 || rax == -1 || rax > 60000 ; 0, -1 or 60seconds
        mov rax, ANIMATION_FRAME_TIME_DEFAULT
    .ELSE
        mov rax, qwDefaultFrameTime
    .ENDIF
    Invoke MUISetIntProperty, hControl, @AnimationFrameTimeDefault, rax
    ret
MUIAnimationSetDefaultTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationGetFrameInfo - Get MUI_ANIMATION_FRAME frame data
; Returns TRUE if successful or FALSE otherwise. On successful return the
; MUI_ANIMATION_FRAME structure pointed to by lpMuiAnimationFrameStruct will
; contain the frame data.
;------------------------------------------------------------------------------
MUIAnimationGetFrameInfo PROC FRAME USES RBX RDX hControl:QWORD, qwFrameIndex:QWORD, lpMuiAnimationFrameStruct:QWORD
    LOCAL FrameData:QWORD
    
    .IF lpMuiAnimationFrameStruct == NULL
        xor eax, eax
        ret
    .ENDIF
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, rax
    
    ; Get frame info
    mov rdx, lpMuiAnimationFrameStruct
    mov rbx, FrameData
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameType
    mov [rdx].MUI_ANIMATION_FRAME.qwFrameType, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameImage
    mov [edx].MUI_ANIMATION_FRAME.qwFrameImage, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameTime
    mov [rdx].MUI_ANIMATION_FRAME.qwFrameTime, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.lParam
    mov [rdx].MUI_ANIMATION_FRAME.lParam, rax
    
    mov rax, TRUE
    ret
MUIAnimationGetFrameInfo ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationGetFrameImage
; Returns: in eax the handle of the image, and the dword pointed to by 
; lpdwFrameType will contain the image type: MUIAIT_PNG, MUIAIT_BMP, MUIAIT_ICO
;------------------------------------------------------------------------------
MUIAnimationGetFrameImage PROC FRAME USES RBX RDX hControl:QWORD, qwFrameIndex:QWORD, lpqwFrameType:QWORD
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov rbx, rax ; rbx is FrameData

    .IF lpqwFrameType != NULL
        mov rdx, lpqwFrameType
        mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameType
        mov [rdx], rax
    .ENDIF
    
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameImage
    ret
MUIAnimationGetFrameImage ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationGetFrameTime
; Returns: 
;------------------------------------------------------------------------------
MUIAnimationGetFrameTime PROC FRAME USES RBX hControl:QWORD, qwFrameIndex:QWORD
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov rbx, rax ; rbx is FrameData
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameImage
    ret
MUIAnimationGetFrameTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSetFrameInfo - Get MUI_ANIMATION_FRAME frame data
; Returns TRUE if successful or FALSE otherwise. On successful return the
; MUI_ANIMATION_FRAME structure pointed to by lpMuiAnimationFrameStruct will
; contain the frame data.
;------------------------------------------------------------------------------
MUIAnimationSetFrameInfo PROC FRAME USES RBX RDX hControl:QWORD, qwFrameIndex:QWORD, lpMuiAnimationFrameStruct:QWORD
    LOCAL qwPrevFrameType:QWORD
    LOCAL qwPrevFrameImage:QWORD
    LOCAL FrameData:QWORD
    
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, rax
    
;    ; Get previous frame image and type
;    mov rbx, FrameData
;    mov rax, [rbx]._MUI_ANIMATION_FRAME.dwFrameType
;    mov rwPrevFrameType, rax
;    mov rax, [rbx]._MUI_ANIMATION_FRAME.dwFrameImage    
;    mov qwPrevFrameImage, rax
;    
;    ; Delete previous image
;    mov rax, qwPrevFrameType
;    .IF rax == MUIAIT_NONE
;    .ELSEIF rax == MUIAIT_BMP
;        ;PrintText 'Deleteing bitmap'
;        .IF qwPrevFrameImage != NULL
;            Invoke DeleteObject, qwPrevFrameImage
;        .ENDIF
;    .ELSEIF rax == MUIAIT_ICO
;        .IF qwPrevFrameImage != NULL
;            Invoke DestroyIcon, qwPrevFrameImage
;        .ENDIF
;    .ELSEIF rax == MUIAIT_PNG
;        IFDEF MUI_USEGDIPLUS
;        .IF qwPrevFrameImage != NULL
;            Invoke GdipDisposeImage, qwPrevFrameImage
;        .ENDIF
;        ENDIF
;    .ENDIF
    
    ; Set frame info
    mov rbx, lpMuiAnimationFrameStruct
    mov rdx, FrameData
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameType
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameType, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameImage
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameImage, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameTime
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameTime, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.lParam
    mov [rdx]._MUI_ANIMATION_FRAME.lParam, rax
        
    mov rax, TRUE
    ret
MUIAnimationSetFrameInfo ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSetFrameImage
; Returns: 
;------------------------------------------------------------------------------
MUIAnimationSetFrameImage PROC FRAME USES RBX hControl:QWORD, qwFrameIndex:QWORD, qwFrameType:QWORD, hFrameImage:QWORD
    LOCAL qwPrevFrameType:QWORD
    LOCAL qwPrevFrameImage:QWORD
    LOCAL FrameData:QWORD
    
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, rax
    
    ; Get previous frame image and type
    mov rbx, FrameData
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameType
    mov qwPrevFrameType, rax
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameImage    
    mov qwPrevFrameImage, rax
    
    ; Delete previous image
    mov rax, qwPrevFrameType
    .IF rax == MUIAIT_NONE
    .ELSEIF rax == MUIAIT_BMP
        ;PrintText 'Deleteing bitmap'
        Invoke DeleteObject, qwPrevFrameImage
    .ELSEIF rax == MUIAIT_ICO
        Invoke DestroyIcon, qwPrevFrameImage
    .ELSEIF rax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke GdipDisposeImage, qwPrevFrameImage
        ENDIF
    .ENDIF
    
    ; Set frame image and type
    mov rbx, FrameData
    mov rax, qwFrameType
    mov [rbx]._MUI_ANIMATION_FRAME.qwFrameType, rax
    mov rax, hFrameImage
    mov [rbx]._MUI_ANIMATION_FRAME.qwFrameImage, rax
    
    mov rax, TRUE
    ret
MUIAnimationSetFrameImage ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationSetFrameTime
; Returns: 
;------------------------------------------------------------------------------
MUIAnimationSetFrameTime PROC FRAME USES RBX hControl:QWORD, qwFrameIndex:QWORD, qwFrameTime:QWORD
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex ; auto checks if dwFrameIndex < @AnimationTotalFrames
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov rbx, rax
    mov rax, qwFrameTime
    mov [rbx]._MUI_ANIMATION_FRAME.qwFrameTime, rax
    mov rax, TRUE
    ret
MUIAnimationSetFrameTime ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationCropFrame - Crops a specific frame image based on rectangle 
; passed via lpRect. Area inside the rect is kept. Original frame image is 
; destroyed and the new cropped frame replaces it.
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationCropFrame PROC FRAME USES RBX hControl:QWORD, qwFrameIndex:QWORD, lpRect:QWORD
    LOCAL hImage:QWORD
    LOCAL hImageOld:QWORD
    LOCAL hImageCropped:QWORD
    LOCAL hImageCroppedOld:QWORD
    LOCAL qwImageType:QWORD
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    LOCAL FrameData:QWORD
    LOCAL hdc:QWORD
    LOCAL hdcOriginal:QWORD
    LOCAL hdcCropped:QWORD
    LOCAL pt:POINT
    LOCAL rect:RECT
    
    .IF hControl == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, rax
    
    Invoke _MUI_AnimationFrameImage, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov hImage, rax
    
    Invoke CopyRect, Addr rect, lpRect
    Invoke MUIGetImageSize, hImage, qwImageType, Addr qwImageWidth, Addr qwImageHeight
    
    Invoke GetDC, hControl
    mov hdc, rax
    
    ; get image type

    mov rax, qwImageType
    .IF rax == MUIAIT_NONE
        xor eax, eax
        ret
    
    .ELSEIF rax == MUIAIT_BMP ; bitmap
        Invoke CreateCompatibleDC, hdc
        mov hdcOriginal, rax
        Invoke SelectObject, hdcOriginal, hImage
        mov hImageOld, rax

        Invoke CreateCompatibleDC, hdc
        mov hdcCropped, rax
        Invoke CreateCompatibleBitmap, hdcCropped, rect.right, rect.bottom
        mov hImageCropped, rax
        Invoke SelectObject, hdcCropped, hImageCropped
        mov hImageCroppedOld, rax

        Invoke BitBlt, hdcCropped, 0, 0, rect.right, rect.bottom, hdcOriginal, rect.left, rect.top, SRCCOPY

        Invoke SelectObject, hdcCropped, hImageCroppedOld
        Invoke DeleteDC, hdcCropped
        .IF hImageCroppedOld != 0
            Invoke DeleteObject, hImageCroppedOld
        .ENDIF
        Invoke SelectObject, hdcOriginal, hImageOld
        Invoke DeleteDC, hdcOriginal
        .IF hImageOld != 0
            Invoke DeleteObject, hImageOld
        .ENDIF
        .IF hImage != 0
            Invoke DeleteObject, hImage
        .ENDIF
        
        ; Replace original image with new cropped image 
        mov rbx, FrameData
        mov rax, hImageCropped
        mov [rbx]._MUI_ANIMATION_FRAME.qwFrameImage, rax
    
    .ELSEIF eax == MUIAIT_ICO ; icon
    
    .ELSEIF eax == MUIAIT_PNG ; png
    
    .ENDIF
    
    mov rax, TRUE
    ret
MUIAnimationCropFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationCropFrames - Crops all frames based on rectangle passed via 
; lpRect. Area inside the rect is kept. Original frame images are destroyed and
; the new cropped frames replaces them.
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationCropFrames PROC FRAME hControl:QWORD, lpRect:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL FrameIndex:QWORD
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    .IF rax == 0
        xor eax, eax
        ret
    .ENDIF
    mov TotalFrames, rax
    
    mov rax, 0
    mov FrameIndex, 0
    .WHILE rax < TotalFrames
        
        Invoke MUIAnimationCropFrame, hControl, FrameIndex, lpRect
        .IF rax == FALSE
            xor eax, eax
            ret
        .ENDIF
        
        inc FrameIndex
        mov rax, FrameIndex
    .ENDW
    
    mov rax, TRUE
    ret
MUIAnimationCropFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationClear - deletes all frames
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationClear PROC FRAME hControl:QWORD
    Invoke MUIAnimationDeleteFrames, hControl
    ret
MUIAnimationClear ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationDeleteFrame
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationDeleteFrame PROC FRAME hControl:QWORD, qwFrameIndex:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL FrameData:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL qwImageType:QWORD
    LOCAL hImage:QWORD
    LOCAL qwSizeRemainingFrames:QWORD
    LOCAL pRemainingFrames:QWORD
    
    Invoke _MUI_AnimationFrameData, hControl, qwFrameIndex
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    mov FrameData, rax
    
    ; Get frame image handle and delete it
    Invoke MUIGetIntProperty, hControl, @AnimationImageType
    mov qwImageType, rax
    
    mov rbx, FrameData
    mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameImage
    mov hImage, rax
    
    mov rax, qwImageType
    .IF rax == MUIAIT_NONE
    .ELSEIF rax == MUIAIT_BMP
        ;PrintText 'Deleteing bitmap'
        Invoke DeleteObject, hImage
    .ELSEIF rax == MUIAIT_ICO
        Invoke DestroyIcon, hImage
    .ELSEIF rax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke GdipDisposeImage, hImage
        ENDIF
    .ENDIF
    
    .IF qwFrameIndex == -1
        Invoke MUIGetIntProperty, hControl, @AnimationFrameIndex
    .ELSE
        mov rax, qwFrameIndex
    .ENDIF
    mov FrameIndex, rax
    
    ; Move remaining frames down over deleted frame
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    mov TotalFrames, rax    
    sub rax, FrameIndex
    inc rax ; adjust for 0 based index
    mov rbx, SIZEOF _MUI_ANIMATION_FRAME
    mul rbx
    mov qwSizeRemainingFrames, rax
    
    mov rax, FrameData
    add rax, SIZEOF _MUI_ANIMATION_FRAME
    mov pRemainingFrames, rax
    Invoke RtlMoveMemory, FrameData, pRemainingFrames, qwSizeRemainingFrames
    
    ; null out end frame
    mov rax, FrameData
    add rax, qwSizeRemainingFrames
    sub rax, SIZEOF _MUI_ANIMATION_FRAME
    mov rbx, rax
    mov rax, NULL
    mov [rbx]._MUI_ANIMATION_FRAME.qwFrameType, rax
    mov [rbx]._MUI_ANIMATION_FRAME.qwFrameImage, rax
    mov [rbx]._MUI_ANIMATION_FRAME.qwFrameTime, rax
    mov [rbx]._MUI_ANIMATION_FRAME.lParam, rax
    
    ; Adjust total frames and free all memory if 0 total frames
    dec TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, TotalFrames
    .IF TotalFrames == 0
        Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
        Invoke MUISetIntProperty, hControl, @AnimationFramesArray, NULL
    .ENDIF
    
    ; if deleting current frame, move to next one
    Invoke MUIGetIntProperty, hControl, @AnimationFrameIndex
    .IF rax == qwFrameIndex
        Invoke _MUI_AnimationNextFrameIndex, hControl
        .IF sqword ptr rax >= 0
            Invoke _MUI_AnimationNextFrameTime, hControl
        .ENDIF
    .ENDIF
    
    mov rax, TRUE
    ret
MUIAnimationDeleteFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationDeleteFrames - deletes all frames
; Returns TRUE if successful or FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationDeleteFrames PROC FRAME USES RBX hControl:QWORD
    LOCAL pAnimationFramesArray:QWORD
    LOCAL pCurrentFrame:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL qwImageType:QWORD
    LOCAL hImage:QWORD
    
    IFDEF DEBUG32
    PrintText 'MUIAnimationDeleteFrames'
    ENDIF
    
    Invoke _MUI_AnimationTimerStop, hControl
    
    Invoke MUIGetIntProperty, hControl, @AnimationImageType
    mov qwImageType, rax    
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF rax != NULL
        mov pAnimationFramesArray, rax
        mov pCurrentFrame, rax
        
        Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
        mov TotalFrames, rax
        
        mov FrameIndex, 0
        mov rax, 0
        .WHILE rax < TotalFrames
            mov rbx, pCurrentFrame
            
            mov rax, [rbx]._MUI_ANIMATION_FRAME.qwFrameImage ; get bitmap handle and delete object if it exists
            
            .IF rax != NULL
                mov hImage, rax
                
                mov rax, NULL
                mov [rbx]._MUI_ANIMATION_FRAME.qwFrameImage, rax
                
                mov rax, qwImageType
                .IF rax == MUIAIT_BMP
                    ;PrintText 'Deleteing bitmap'
                    Invoke DeleteObject, hImage
                .ELSEIF rax == MUIAIT_ICO
                    Invoke DestroyIcon, hImage
                .ELSEIF rax == MUIAIT_PNG
                    IFDEF MUI_USEGDIPLUS
                    Invoke GdipDisposeImage, hImage
                    ENDIF
                .ENDIF
            .ENDIF
            
            add pCurrentFrame, SIZEOF _MUI_ANIMATION_FRAME
            inc FrameIndex
            mov rax, FrameIndex
        .ENDW
        Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, 0
        
        ;PrintText 'deleted image handles'
        .IF pAnimationFramesArray != NULL
            Invoke MUISetIntProperty, hControl, @AnimationFramesArray, NULL
            Invoke GlobalFree, pAnimationFramesArray
            ;PrintText 'deleted frame array'
        .ENDIF
        
    .ENDIF

    ret
MUIAnimationDeleteFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationAddFrame
;------------------------------------------------------------------------------
MUIAnimationAddFrame PROC FRAME USES RBX RDX hControl:QWORD, qwImageType:QWORD, lpMuiAnimationFrameStruct:QWORD
    LOCAL pAnimationFramesArray:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL FrameType:QWORD
    LOCAL FrameImage:QWORD
    LOCAL FrameTime:QWORD
    LOCAL FrameData:QWORD
    LOCAL qwSize:QWORD
    
    IFDEF DEBUG32
    ;PrintText 'MUIAnimationAddFrame'
    ENDIF
    
    .IF hControl == NULL || qwImageType == NULL || lpMuiAnimationFrameStruct == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    mov TotalFrames, rax
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF rax == NULL
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF _MUI_ANIMATION_FRAME
        .IF rax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, rax
        mov FrameData, rax
    .ELSE
        mov pAnimationFramesArray, rax
        mov rax, TotalFrames
        inc rax
        mov rbx, SIZEOF _MUI_ANIMATION_FRAME
        mul rbx
        mov qwSize, rax
        Invoke GlobalReAlloc, pAnimationFramesArray, qwSize, GMEM_ZEROINIT or GMEM_MOVEABLE
        .IF rax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, rax
        add rax, qwSize
        sub rax, SIZEOF _MUI_ANIMATION_FRAME
        mov FrameData, rax
    .ENDIF
    
    Invoke MUISetIntProperty, hControl, @AnimationFramesArray, pAnimationFramesArray
    
    mov rdx, FrameData
    mov rbx, lpMuiAnimationFrameStruct
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameType
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameType, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameImage
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameImage, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameTime
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameTime, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.lParam
    mov [rdx]._MUI_ANIMATION_FRAME.lParam, rax
    
    .IF TotalFrames == 0
        Invoke MUISetIntProperty, hControl, @AnimationFrameSpeed, FrameTime
    .ENDIF
    inc TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, TotalFrames
    
    mov rax, TRUE
    ret
MUIAnimationAddFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationAddFrames
;------------------------------------------------------------------------------
MUIAnimationAddFrames PROC FRAME hControl:QWORD, qwImageType:QWORD, lpArrayMuiAnimationFrameStructs:QWORD, qwCount:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL lpMuiAnimationFrameStruct:QWORD
    
    .IF hControl == NULL || qwImageType == NULL || lpArrayMuiAnimationFrameStructs == NULL || qwCount == NULL 
        xor eax, eax
        ret
    .ENDIF

    mov rax, lpArrayMuiAnimationFrameStructs
    mov lpMuiAnimationFrameStruct, rax
    mov FrameIndex, 0
    mov rax, 0
    .WHILE rax < qwCount
        Invoke MUIAnimationAddFrame, hControl, qwImageType, lpMuiAnimationFrameStruct
        .IF rax == FALSE
            xor eax, eax
            ret
        .ENDIF
        add lpMuiAnimationFrameStruct, SIZEOF MUI_ANIMATION_FRAME
        inc FrameIndex
        mov rax, FrameIndex
    .ENDW
    mov rax, TRUE
    ret
MUIAnimationAddFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationAddSpriteSheet
;------------------------------------------------------------------------------
MUIAnimationAddSpriteSheet PROC FRAME USES RBX RCX RDX hControl:QWORD, qwImageType:QWORD, hImageSpriteSheet:QWORD, qwSpriteCount:QWORD, lpFrameTimes:QWORD, qwFrameTimeSize:QWORD, qwFrameTimeType:QWORD
    LOCAL hImageSpriteSheetOld:QWORD
    LOCAL hIcoSpriteSheet:QWORD
    LOCAL ImageWidth:QWORD
    LOCAL ImageHeight:QWORD
    LOCAL pAnimationFramesArray:QWORD
    LOCAL FrameWidth:QWORD
    LOCAL FrameHeight:QWORD
    LOCAL FrameID:QWORD
    LOCAL FrameTime:QWORD
    LOCAL FrameTimeEntry:QWORD
    LOCAL FrameTimeCount:QWORD
    LOCAL nFrameTimeCompact:QWORD
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
    LOCAL FrameStruct:MUI_ANIMATION_FRAME
    
    IFDEF DEBUG32
    ;PrintText 'MUISpinnerAddSpriteSheet'
    ENDIF
    
    .IF hControl == NULL || qwImageType == NULL || qwSpriteCount == 0 || hImageSpriteSheet == NULL || lpFrameTimes == NULL || qwFrameTimeSize == 0
        xor eax, eax
        ret
    .ENDIF
    
    ;--------------------------------------------------------------------------
    ; Check frame entries count in lpFrameTimes array is same as spritecount
    ; and get frame entries count
    ;--------------------------------------------------------------------------
    .IF qwFrameTimeType == MUIAFT_FULL
        xor rdx, rdx
        mov rax, qwFrameTimeSize
        mov rcx, SIZEOF MUI_ANIMATION_FT_FULL
        div rcx
        mov FrameTimeCount, rax
        .IF rax != qwSpriteCount
            IFDEF DEBUG32
            PrintText 'Frame time entries not equal to spritecount!'
            ENDIF
            xor eax, eax
            ret
        .ENDIF
    .ELSE
        xor rdx, rdx
        mov rax, qwFrameTimeSize
        mov rcx, SIZEOF MUI_ANIMATION_FT_COMPACT
        div rcx
        mov FrameTimeCount, rax
        ;PrintDec FrameTimeCount
    .ENDIF
    
    mov rax, lpFrameTimes
    mov FrameTimeEntry, rax    

    ;--------------------------------------------------------------------------
    ; Calc frame width
    ;--------------------------------------------------------------------------
    Invoke MUIGetImageSize, hImageSpriteSheet, qwImageType, Addr ImageWidth, Addr ImageHeight
    
    xor rdx, rdx
    mov rax, ImageWidth
    mov rcx, qwSpriteCount
    div rcx
    mov FrameWidth, rax
    mov rax, ImageHeight
    mov FrameHeight, rax

    Invoke GetDC, hControl
    mov hdc, rax
    
    ;--------------------------------------------------------------------------
    ; Get spritesheet image and create a dc + bitmap to store our sprite frame
    ;--------------------------------------------------------------------------
    mov rax, qwImageType
    .IF rax == MUIAIT_BMP
        Invoke CreateCompatibleDC, hdc
        mov hdcSpriteSheet, rax
        Invoke SelectObject, hdcSpriteSheet, hImageSpriteSheet
        mov hImageSpriteSheetOld, rax
        Invoke CreateCompatibleDC, hdc
        mov hdcFrame, rax
    .ELSEIF rax == MUIAIT_ICO
        Invoke CreateCompatibleDC, hdc
        mov hdcSpriteSheet, rax
        Invoke CreateCompatibleBitmap, hdc, dword ptr ImageWidth, dword ptr ImageHeight
        mov hIcoSpriteSheet, rax
        Invoke SelectObject, hdcSpriteSheet, hIcoSpriteSheet
        mov hImageSpriteSheetOld, rax
        Invoke CreateCompatibleDC, hdc
        mov hdcFrame, rax
        Invoke DrawIconEx, hdcSpriteSheet, 0, 0, hImageSpriteSheet, 0, 0, 0, 0, DI_NORMAL
    .ELSEIF rax == MUIAIT_PNG
        mov pGraphics, 0
        mov pGraphicsFrame, 0
        mov pFrame, 0
        Invoke GdipCreateFromHDC, hdc, Addr pGraphics
    .ENDIF
    
    ;--------------------------------------------------------------------------
    ; Alloc block of memory instead of realloc memory for each frame addition
    ;--------------------------------------------------------------------------
;    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
;    .IF eax == NULL
;        mov eax, dwSpriteCount
;        inc eax
;        mov ebx, SIZEOF _MUI_ANIMATION_FRAME
;        mul ebx
;        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax
;        .IF eax == NULL
;            ret
;        .ENDIF
;        Invoke MUISetIntProperty, hControl, @AnimationFramesArray, eax
;    .ELSE
;        ; TODO - clear all existing images and free memory?
;        ; alloc block of memory and continue?
;    .ENDIF
;    Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, dwSpriteCount
    
    ;--------------------------------------------------------------------------
    ; Cut each frame from spritesheet to hFrame and add to animation
    ;--------------------------------------------------------------------------
    IFDEF DEBUG32
    PrintText 'MUISpinnerAddSpriteSheet start frame adding'
    ENDIF
    mov x, 0
    mov y, 0    
    mov rax, 0
    mov nFrame, 0
    .WHILE rax < qwSpriteCount
        mov rax, qwImageType
        .IF rax == MUIAIT_BMP || rax == MUIAIT_ICO
            Invoke CreateCompatibleBitmap, hdc, dword ptr FrameWidth, dword ptr FrameHeight
            mov hFrame, rax
            Invoke SelectObject, hdcFrame, hFrame
            mov hFrameOld, rax
            Invoke BitBlt, hdcFrame, 0, 0, dword ptr FrameWidth, dword ptr FrameHeight, hdcSpriteSheet, dword ptr x, dword ptr y, SRCCOPY
            
            .IF qwFrameTimeType == MUIAFT_FULL
                mov rbx, FrameTimeEntry
                mov rax, [rbx].MUI_ANIMATION_FT_FULL.qwFrameTime
                mov FrameTime, rax
            .ELSE
                mov FrameTime, 0
            .ENDIF
            
            mov FrameStruct.qwFrameType, MUIAIT_BMP
            mov rax, hFrame
            mov FrameStruct.qwFrameImage, rax
            mov rax, FrameTime
            mov FrameStruct.qwFrameTime, rax
            ;Invoke MUIAnimationSetFrameInfo, hControl, nFrame, Addr FrameStruct
            Invoke MUIAnimationAddFrame, hControl, MUIAIT_BMP, Addr FrameStruct
            Invoke SelectObject, hdcFrame, hFrameOld
        .ELSEIF rax == MUIAIT_PNG
            Invoke GdipCreateBitmapFromGraphics, FrameWidth, FrameHeight, pGraphics, Addr pFrame
            Invoke GdipGetImageGraphicsContext, pFrame, Addr pGraphicsFrame
            Invoke GdipSetPixelOffsetMode, pGraphicsFrame, PixelOffsetModeHighQuality
            Invoke GdipSetPageUnit, pGraphicsFrame, UnitPixel
            Invoke GdipSetSmoothingMode, pGraphicsFrame, SmoothingModeAntiAlias
            Invoke GdipSetInterpolationMode, pGraphicsFrame, InterpolationModeHighQualityBicubic
            Invoke GdipDrawImageRectRectI, pGraphicsFrame, hImageSpriteSheet, 0, 0, dword ptr FrameWidth, dword ptr FrameHeight, dword ptr x, dword ptr y, dword ptr FrameWidth, dword ptr FrameHeight, UnitPixel, NULL, NULL, NULL
            
            .IF qwFrameTimeType == MUIAFT_FULL
                mov rbx, FrameTimeEntry
                mov rax, [rbx].MUI_ANIMATION_FT_FULL.qwFrameTime
                mov FrameTime, rax
            .ELSE
                mov FrameTime, 0
            .ENDIF
            
            mov FrameStruct.qwFrameType, MUIAIT_PNG
            mov rax, pFrame
            mov FrameStruct.qwFrameImage, rax
            mov rax, FrameTime
            mov FrameStruct.qwFrameTime, rax
            ;Invoke MUIAnimationSetFrameInfo, hControl, nFrame, Addr FrameStruct
            Invoke MUIAnimationAddFrame, hControl, MUIAIT_PNG, Addr FrameStruct
            .IF pGraphicsFrame != NULL
                Invoke GdipDeleteGraphics, pGraphicsFrame
            .ENDIF 
        .ENDIF
        
        .IF qwFrameTimeType == MUIAFT_FULL
            add FrameTimeEntry, SIZEOF MUI_ANIMATION_FT_FULL
        .ENDIF
        
        mov rax, FrameWidth
        add x, rax
        inc nFrame
        mov rax, nFrame
    .ENDW

    IFDEF DEBUG32
    PrintText 'MUISpinnerAddSpriteSheet finish frame adding'
    ENDIF

    ;--------------------------------------------------------------------------
    ; For compact frame times array set FrameID with FrameTime 
    ;--------------------------------------------------------------------------
    .IF qwFrameTimeType == MUIAFT_COMPACT
        mov rax, 0
        mov nFrameTimeCompact, 0
        .WHILE rax < FrameTimeCount
            mov rbx, FrameTimeEntry
            mov rax, [rbx].MUI_ANIMATION_FT_COMPACT.qwFrameID
            mov FrameID, rax
            mov rax, [rbx].MUI_ANIMATION_FT_COMPACT.qwFrameTime
            mov FrameTime, rax
            
            Invoke MUIAnimationSetFrameTime, hControl, FrameID, FrameTime
            
            add FrameTimeEntry, SIZEOF MUI_ANIMATION_FT_COMPACT
            inc nFrameTimeCompact
            mov rax, nFrameTimeCompact
        .ENDW
    .ENDIF

    ;--------------------------------------------------------------------------
    ; Tidy up
    ;--------------------------------------------------------------------------
    mov rax, qwImageType
    .IF rax == MUIAIT_BMP || rax == MUIAIT_ICO
        Invoke SelectObject, hdcSpriteSheet, hImageSpriteSheetOld
        Invoke DeleteObject, hImageSpriteSheetOld
    .ELSEIF rax == MUIAIT_PNG
        .IF pGraphicsFrame != NULL
            Invoke GdipDeleteGraphics, pGraphicsFrame
        .ENDIF
        .IF pGraphics != NULL
            Invoke GdipDeleteGraphics, pGraphics
        .ENDIF
    .ENDIF
    
    Invoke ReleaseDC, hControl, hdc
    ;Invoke InvalidateRect, hControl, NULL, TRUE
    mov rax, TRUE
    ret
MUIAnimationAddSpriteSheet ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationLoadFrame - Loads a resource as an image frame to the Animation
;
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationLoadFrame PROC FRAME USES RBX hControl:QWORD, qwImageType:QWORD, lpMuiAnimationFrameStruct:QWORD
    LOCAL hinstance:QWORD
    LOCAL idResImage:QWORD
    LOCAL MAF:MUI_ANIMATION_FRAME
    
    IFDEF DEBUG32
    ;PrintText 'MUIAnimationLoadFrame'
    ENDIF
    
    .IF hControl == NULL || qwImageType == 0 || lpMuiAnimationFrameStruct == NULL  
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @AnimationDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax    
    
    Invoke RtlMoveMemory, Addr MAF, lpMuiAnimationFrameStruct, SIZEOF MUI_ANIMATION_FRAME
    
    lea rbx, MAF
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameImage
    .IF rax == NULL
        ret
    .ENDIF
    mov idResImage, rax
    
    mov rax, qwImageType
    .IF rax == MUIAIT_BMP
        Invoke LoadBitmap, hinstance, idResImage
    .ELSEIF rax == MUIAIT_ICO
        Invoke LoadImage, hinstance, idResImage, IMAGE_ICON, 0, 0, 0
    .ELSEIF rax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke _MUI_AnimationLoadPng, hinstance, idResImage
        ENDIF
    .ELSE
        xor eax, eax
        ret
    .ENDIF
    .IF rax == NULL
        xor eax, eax
        ret
    .ENDIF
    ; eax contains image handle
    ; save image handle to copy of the animation frame
    lea rbx, MAF
    mov [rbx].MUI_ANIMATION_FRAME.qwFrameImage, rax
    
    Invoke MUIAnimationAddFrame, hControl, qwImageType, Addr MAF
    .IF rax == FALSE
        xor eax, eax
        ret
    .ENDIF
    
    mov rax, TRUE
    ret
MUIAnimationLoadFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationLoadFrames - Process an array of resource ids and load the resource
; and add them to the Animation control as image frames
;
; Returns: TRUE if success, FALSE otherwise
;------------------------------------------------------------------------------
MUIAnimationLoadFrames PROC FRAME USES RBX RDX hControl:QWORD, qwImageType:QWORD, lpArrayMuiAnimationFrameStructs:QWORD, qwCount:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL lpMuiAnimationFrameStruct:QWORD
    
    .IF hControl == NULL || qwCount == NULL || qwImageType == NULL || lpArrayMuiAnimationFrameStructs == NULL
        xor eax, eax
        ret
    .ENDIF

    mov rax, lpArrayMuiAnimationFrameStructs
    mov lpMuiAnimationFrameStruct, rax
    mov FrameIndex, 0
    mov rax, 0
    .WHILE rax < qwCount
        Invoke MUIAnimationLoadFrame, hControl, qwImageType, lpMuiAnimationFrameStruct
        .IF rax == FALSE
            xor eax, eax
            ret
        .ENDIF
        add lpMuiAnimationFrameStruct, SIZEOF MUI_ANIMATION_FRAME
        inc FrameIndex
        mov rax, FrameIndex
    .ENDW
    
    mov rax, TRUE
    ret
MUIAnimationLoadFrames ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationLoadSpriteSheet
;------------------------------------------------------------------------------
MUIAnimationLoadSpriteSheet PROC FRAME hControl:QWORD, qwImageType:QWORD, idResSpriteSheet:QWORD, qwSpriteCount:QWORD, lpFrameTimes:QWORD, qwFrameTimeSize:QWORD, qwFrameTimeType:QWORD
    LOCAL hinstance:QWORD
    LOCAL hImage:QWORD
    
    IFDEF DEBUG32
    ;PrintText 'MUIAnimationLoadSpriteSheet'
    ENDIF
    
    .IF hControl == NULL || idResSpriteSheet == NULL || qwImageType == 0 || qwSpriteCount == 0 || lpFrameTimes == 0
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @AnimationDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax    
    
    mov rax, qwImageType
    .IF rax == MUIAIT_BMP
        Invoke LoadBitmap, hinstance, idResSpriteSheet
    .ELSEIF rax == MUIAIT_ICO
        Invoke LoadImage, hinstance, idResSpriteSheet, IMAGE_ICON, 0, 0, 0
    .ELSEIF rax == MUIAIT_PNG
        IFDEF MUI_USEGDIPLUS
        Invoke _MUI_AnimationLoadPng, hinstance, idResSpriteSheet
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

    Invoke MUIAnimationAddSpriteSheet, hControl, qwImageType, hImage, qwSpriteCount, lpFrameTimes, qwFrameTimeSize, qwFrameTimeType
    .IF rax == FALSE
        xor eax, eax
        ret
    .ENDIF
    
    mov rax, TRUE
    ret
MUIAnimationLoadSpriteSheet ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUIAnimationInsertFrame
;------------------------------------------------------------------------------
MUIAnimationInsertFrame PROC FRAME USES RBX RDX hControl:QWORD, qwImageType:QWORD, lpMuiAnimationFrameStruct:QWORD, qwFrameIndex:QWORD, bInsertAfter:QWORD
    LOCAL pAnimationFramesArray:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL FrameIndex:QWORD
    LOCAL FrameType:QWORD
    LOCAL FrameImage:QWORD
    LOCAL FrameTime:QWORD
    LOCAL FrameData:QWORD
    LOCAL qwSize:QWORD
    LOCAL qwSizeRemainingFrames:QWORD
    LOCAL pRemainingFrames:QWORD
    
    .IF hControl == NULL || qwImageType == NULL || lpMuiAnimationFrameStruct == NULL
        xor eax, eax
        ret
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationTotalFrames
    mov TotalFrames, rax
    .IF rax > 0
        .IF qwFrameIndex >= rax
            xor eax, eax
            ret
        .ENDIF
    .ENDIF
    
    Invoke MUIGetIntProperty, hControl, @AnimationFramesArray
    .IF rax == NULL
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF _MUI_ANIMATION_FRAME
        .IF rax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, rax
        mov FrameData, rax
    .ELSE
        mov pAnimationFramesArray, rax
        mov rax, TotalFrames
        inc rax
        mov rbx, SIZEOF _MUI_ANIMATION_FRAME
        mul rbx
        mov qwSize, rax
        Invoke GlobalReAlloc, pAnimationFramesArray, qwSize, GMEM_ZEROINIT or GMEM_MOVEABLE
        .IF rax == NULL
            ret
        .ENDIF
        mov pAnimationFramesArray, rax
        
        ; Calc frame data for specified index
        mov rax, qwFrameIndex
        mov rbx, SIZEOF _MUI_ANIMATION_FRAME
        mul rbx
        add rax, pAnimationFramesArray
        .IF bInsertAfter == TRUE
            add rax, SIZEOF _MUI_ANIMATION_FRAME
        .ENDIF
        mov FrameData, rax
        
        ; shift memory for inserting new frame
        mov rax, TotalFrames
        inc rax
        mov rbx, FrameIndex
        inc rbx
        .IF bInsertAfter == TRUE
            inc rbx
        .ENDIF
        sub rax, rbx
        .IF sqword ptr rax > 0
            mov rbx, SIZEOF _MUI_ANIMATION_FRAME
            mul rbx
            mov qwSizeRemainingFrames, rax
        
            mov rax, FrameData
            add rax, SIZEOF _MUI_ANIMATION_FRAME
            mov pRemainingFrames, rax
            Invoke RtlMoveMemory, FrameData, pRemainingFrames, qwSizeRemainingFrames
        .ENDIF
    .ENDIF
    
    Invoke MUISetIntProperty, hControl, @AnimationFramesArray, pAnimationFramesArray
    
    mov rdx, FrameData
    mov rbx, lpMuiAnimationFrameStruct
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameType
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameType, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameImage
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameImage, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.qwFrameTime
    mov [rdx]._MUI_ANIMATION_FRAME.qwFrameTime, rax
    mov rax, [rbx].MUI_ANIMATION_FRAME.lParam
    mov [rdx]._MUI_ANIMATION_FRAME.lParam, rax
    
    inc TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationTotalFrames, TotalFrames
    Invoke MUISetIntProperty, hControl, @AnimationFrameSpeed, FrameTime    
    
    mov rax, TRUE
    ret
MUIAnimationInsertFrame ENDP

;------------------------------------------------------------------------------
; _MUI_AnimationTimerProc for TimerQueue
;------------------------------------------------------------------------------
IFDEF ANIMATION_USE_TIMERQUEUE
MUI_ALIGN
_MUI_AnimationTimerProc PROC FRAME USES RBX lpParam:QWORD, TimerOrWaitFired:QWORD
    ; lpParam is hControl
    Invoke _MUI_AnimationNextFrame, lpParam
    ret
_MUI_AnimationTimerProc ENDP
ENDIF

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationNextFrame - called by _MUI_AnimationTimerProc or WM_TIMER
; advances frame index to next frame and updates timer to new frame's time
;------------------------------------------------------------------------------
_MUI_AnimationNextFrame PROC FRAME hWin:QWORD
    LOCAL FrameTime:QWORD
    
    .IF hWin == NULL
        xor eax, eax
        ret
    .ENDIF
    
    IFDEF DEBUG32
    PrintText '_MUI_AnimationNextFrame'
    ENDIF
    
    
    ;Invoke MUIAnimationPause, hWin
    Invoke _MUI_AnimationTimerStop, hWin

    Invoke _MUI_AnimationNextFrameIndex, hWin
    .IF sqword ptr rax >= 0
        Invoke _MUI_AnimationNextFrameTime, hWin
        mov FrameTime, rax
    .ELSE 
        ; no frames or end of animation, so stop
        Invoke MUIAnimationStop, hWin
        ret
    .ENDIF
    Invoke InvalidateRect, hWin, NULL, TRUE
    Invoke UpdateWindow, hWin
    
    .IF FrameTime == -1
        Invoke MUIAnimationPause, hWin
    .ELSE
        Invoke _MUI_AnimationTimerStart, hWin
    .ENDIF
    ;Invoke MUIAnimationResume, hWin ; timer is restarted with new frame time set in _MUI_AnimationNextFrameTime
     
    mov rax, TRUE
    ret
_MUI_AnimationNextFrame ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationTimerStart
;------------------------------------------------------------------------------
_MUI_AnimationTimerStart PROC FRAME hWin:QWORD
    LOCAL qwTimeInterval:QWORD
    LOCAL fSpeedFactor:REAL4
    IFDEF ANIMATION_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    LOCAL hTimer:QWORD
    ENDIF

    .IF hWin == NULL
        xor eax, eax
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @AnimationTotalFrames
    .IF rax == 0
        xor eax, eax
        ret
    .ENDIF

    Invoke MUIGetIntProperty, hWin, @AnimationSpeedFactor
    mov fSpeedFactor, eax
    

    Invoke MUIGetIntProperty, hWin, @AnimationFrameSpeed
    .IF rax == 0
        Invoke MUIGetIntProperty, hWin, @AnimationFrameTimeDefault
        .IF rax == 0
            mov rax, ANIMATION_FRAME_TIME_DEFAULT
        .ENDIF
    .ENDIF
    .IF rax == -1 ; if frame time is set to -1 = special pause animation, then resume with default min time
        mov rax, ANIMATION_FRAME_TIME_MIN
    .ENDIF
    mov qwTimeInterval, rax
    ;PrintDec dwTimeInterval
    
    .IF fSpeedFactor != 0
        IFDEF DEBUG32
        ;PrintDec fSpeedFactor
        ;PrintText 'fSpeedFactor != 0'
        ;PrintDec dwTimeInterval
        ENDIF
        finit
        fild qwTimeInterval
        fld fSpeedFactor
        fdiv
        fistp qwTimeInterval
        IFDEF DEBUG32
        ;PrintText 'new speed:'
        ;PrintDec dwTimeInterval
        ENDIF
        .IF sqword ptr qwTimeInterval <= 0
            mov qwTimeInterval, ANIMATION_FRAME_TIME_MIN
        .ENDIF
    .ENDIF
    
    ;PrintDec qwTimeInterval

    IFDEF ANIMATION_USE_TIMERQUEUE
        Invoke MUIGetIntProperty, hWin, @AnimationUseTimerQueue
        .IF rax == TRUE
            Invoke MUIGetIntProperty, hWin, @AnimationQueue
            mov hQueue, rax
            Invoke MUIGetIntProperty, hWin, @AnimationTimer
            mov hTimer, rax
            .IF hQueue != NULL ; re-use existing hQueue
                Invoke ChangeTimerQueueTimer, hQueue, hTimer, dword ptr qwTimeInterval, dword ptr qwTimeInterval
                .IF rax == 0 ; failed 
                    ;PrintText 'Existing CreateTimerQueueTimer failed'
                    Invoke DeleteTimerQueueEx, hQueue, FALSE
                    Invoke MUISetIntProperty, hWin, @AnimationQueue, 0
                    Invoke MUISetIntProperty, hWin, @AnimationTimer, 0
                    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                    Invoke SetTimer, hWin, hWin, dword ptr qwTimeInterval, NULL
                .ENDIF
            .ELSE ; Try to create TimerQueue 
                Invoke CreateTimerQueue
                .IF rax != NULL
                    mov hQueue, rax
                    Invoke CreateTimerQueueTimer, Addr hTimer, hQueue, Addr _MUI_AnimationTimerProc, hWin, dword ptr qwTimeInterval, dword ptr qwTimeInterval, 0
                    .IF rax == 0 ; failed, so fall back to WM_TIMER usage
                        ;PrintText 'CreateTimerQueueTimer failed'
                        Invoke DeleteTimerQueueEx, hQueue, FALSE
                        Invoke MUISetIntProperty, hWin, @AnimationQueue, 0
                        Invoke MUISetIntProperty, hWin, @AnimationTimer, 0
                        Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                        Invoke SetTimer, hWin, hWin, dword ptr qwTimeInterval, NULL
                    .ELSE ; Success! - so save TimerQueue handles for re-use
                        IFDEF DEBUG32
                        PrintText 'Using QueueTimer'
                        ENDIF
                        Invoke MUISetIntProperty, hWin, @AnimationQueue, hQueue
                        Invoke MUISetIntProperty, hWin, @AnimationTimer, hTimer
                    .ENDIF
                .ELSE ; failed, so fall back to WM_TIMER usage
                    ;PrintText 'CreateTimerQueue failed'
                    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                    Invoke SetTimer, hWin, hWin, dword ptr qwTimeInterval, NULL
                .ENDIF
            .ENDIF
        .ELSE  ; Not using TimerQueue, previous failure?, so fall back to WM_TIMER usage
            Invoke SetTimer, hWin, hWin, dword ptr qwTimeInterval, NULL
        .ENDIF
    ELSE ; compiled define says to use WM_TIMER instead
        Invoke SetTimer, hWin, hWin, dword ptr qwTimeInterval, NULL
    ENDIF
    mov rax, TRUE
    ret
_MUI_AnimationTimerStart ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_AnimationTimerStop
;------------------------------------------------------------------------------
_MUI_AnimationTimerStop PROC FRAME hWin:QWORD
    IFDEF ANIMATION_USE_TIMERQUEUE
    LOCAL hQueue:QWORD
    LOCAL hTimer:QWORD
    ENDIF

    .IF hWin == NULL
        xor eax, eax
        ret
    .ENDIF
    
    IFDEF ANIMATION_USE_TIMERQUEUE
        Invoke MUIGetIntProperty, hWin, @AnimationUseTimerQueue
        .IF rax == TRUE
            Invoke MUIGetIntProperty, hWin, @AnimationQueue
            mov hQueue, rax
            Invoke MUIGetIntProperty, hWin, @AnimationTimer
            mov hTimer, rax
            .IF hQueue != NULL
                Invoke ChangeTimerQueueTimer, hQueue, hTimer, INFINITE, 0
                .IF rax == 0 ; failed, fall back to use KillTimer for WM_TIMER usage
                    Invoke DeleteTimerQueueEx, hQueue, FALSE
                    Invoke MUISetIntProperty, hWin, @AnimationQueue, 0
                    Invoke MUISetIntProperty, hWin, @AnimationTimer, 0
                    Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                    Invoke KillTimer, hWin, hWin
                .ENDIF
            .ELSE ; fall back to use KillTimer for WM_TIMER usage
                Invoke MUISetIntProperty, hWin, @AnimationUseTimerQueue, FALSE
                Invoke KillTimer, hWin, hWin
            .ENDIF
        .ELSE ; Not using TimerQueue, previous failure? back to use KillTimer for WM_TIMER usage
            Invoke KillTimer, hWin, hWin
        .ENDIF
    ELSE ; compiled define says to use WM_TIMER instead
        Invoke KillTimer, hWin, hWin
    ENDIF
    
    mov rax, TRUE
    ret
_MUI_AnimationTimerStop ENDP

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
_MUI_AnimationLoadPng PROC FRAME hinstance:QWORD, idResPng:QWORD
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
    LOCAL dwImageWidth:QWORD
    LOCAL dwImageHeight:QWORD  

    ; ------------------------------------------------------------------
    ; STEP 1: Find the resource
    ; ------------------------------------------------------------------
    invoke  FindResource, hinstance, idResPng, RT_RCDATA
    or      rax, rax
    jnz     @f
    jmp     _MUIAnimationLoadPng@Close
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
    jmp     _MUIAnimationLoadPng@Close
@@: mov     sizeOfRes, rax
    
    invoke  LockResource, hResData
    or      rax, rax
    jnz     @f
    jmp     _MUIAnimationLoadPng@Close
@@: mov     pResData, rax

    invoke  GlobalAlloc, GMEM_MOVEABLE, sizeOfRes
    or      rax, rax
    jnz     @f
    jmp     _MUIAnimationLoadPng@Close
@@: mov     hResBuffer, rax

    invoke  GlobalLock, hResBuffer
    mov     pResBuffer, rax
    
    invoke  RtlMoveMemory, pResBuffer, hResData, sizeOfRes
    invoke  CreateStreamOnHGlobal, pResBuffer, TRUE, Addr pIStream
    or      rax, rax
    jz      @f
    jmp     _MUIAnimationLoadPng@Close
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
    Invoke GdipGetImageWidth, pBitmapFromStream, Addr dwImageWidth
    Invoke GdipGetImageHeight, pBitmapFromStream, Addr dwImageHeight    
    Invoke GdipCreateBitmapFromScan0, dwImageWidth, dwImageHeight, 0, PixelFormat32bppARGB, 0, Addr pImage
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
    mov rax, pImage

_MUIAnimationLoadPng@Close:
    ret
_MUI_AnimationLoadPng endp
ENDIF




MODERNUI_LIBEND


