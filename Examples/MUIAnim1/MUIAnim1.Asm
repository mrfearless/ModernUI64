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

DEBUG64 EQU 1

IFDEF DEBUG64
    PRESERVEXMMREGS equ 1
    includelib \UASM\lib\x64\Debug64.lib
    DBG64LIB equ 1
    DEBUGEXE textequ <'\UASM\bin\DbgWin.exe'>
    include \UASM\include\debug64.inc
    .DATA
    RDBG_DbgWin	DB DEBUGEXE,0
    .CODE
ENDIF

include MUIAnim1.inc

.CODE

;-------------------------------------------------------------------------------------
; Startup
;-------------------------------------------------------------------------------------
WinMainCRTStartup proc FRAME
	Invoke GetModuleHandle, NULL
	mov hInstance, rax
	Invoke GetCommandLine
	mov CommandLine, rax
	Invoke InitCommonControls
	mov icc.dwSize, sizeof INITCOMMONCONTROLSEX
    mov icc.dwICC, ICC_COOL_CLASSES or ICC_STANDARD_CLASSES or ICC_WIN95_CLASSES
    Invoke InitCommonControlsEx, offset icc
	Invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
	Invoke ExitProcess, eax
    ret
WinMainCRTStartup endp
	

;-------------------------------------------------------------------------------------
; WinMain
;-------------------------------------------------------------------------------------
WinMain proc FRAME hInst:HINSTANCE, hPrev:HINSTANCE, CmdLine:LPSTR, iShow:DWORD
	LOCAL msg:MSG
	LOCAL wcex:WNDCLASSEX
	
	mov wcex.cbSize, sizeof WNDCLASSEX
	mov wcex.style, CS_HREDRAW or CS_VREDRAW
	lea rax, WndProc
	mov wcex.lpfnWndProc, rax
	mov wcex.cbClsExtra, 0
	mov wcex.cbWndExtra, DLGWINDOWEXTRA
	mov rax, hInst
	mov wcex.hInstance, rax
	mov wcex.hbrBackground, COLOR_BTNFACE+1 ; COLOR_WINDOW+1
	mov wcex.lpszMenuName, IDM_MENU ;NULL 
	lea rax, ClassName
	mov wcex.lpszClassName, rax
    Invoke LoadIcon, hInstance, ICO_MAIN ; resource icon for main application icon
	mov wcex.hIcon, rax
	mov wcex.hIconSm, rax
	Invoke LoadCursor, NULL, IDC_ARROW
	mov wcex.hCursor, rax
	Invoke RegisterClassEx, addr wcex
	
	;Invoke CreateWindowEx, 0, addr ClassName, addr szAppName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, hInstance, NULL
	Invoke CreateDialogParam, hInstance, IDD_DIALOG, 0, Addr WndProc, 0
	mov hWnd, rax
	
	Invoke ShowWindow, hWnd, SW_SHOWNORMAL
	Invoke UpdateWindow, hWnd
	
	.WHILE (TRUE)
		Invoke GetMessage, addr msg, NULL, 0, 0
		.BREAK .IF (!rax)		
		
        Invoke IsDialogMessage, hWnd, addr msg
        .IF rax == 0
            Invoke TranslateMessage, addr msg
            Invoke DispatchMessage, addr msg
        .ENDIF
	.ENDW
	
	mov rax, msg.wParam
	ret	
WinMain endp


;-------------------------------------------------------------------------------------
; WndProc - Main Window Message Loop
;-------------------------------------------------------------------------------------
WndProc proc FRAME hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    
    mov eax, uMsg
	.IF eax == WM_INITDIALOG
        ;-----------------------------------------------------------------------------
        ; ModernUI_CaptionBar
        ;-----------------------------------------------------------------------------
        Invoke MUIApplyToDialog, hWin, TRUE, TRUE
        Invoke MUICaptionBarCreate, hWin, Addr AppName, 32, IDC_CAPTIONBAR, MUICS_NOMAXBUTTON or MUICS_LEFT or MUICS_REDCLOSEBUTTON
        mov hCaptionBar, rax
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(27,161,226)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(61,61,61)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(87,193,244)   

        ;-----------------------------------------------------------------------------
        ; Create our ModernUI_Animation control, animate the facebook clickbait image
        ;-----------------------------------------------------------------------------
        Invoke MUIAnimationCreate, hWin, 50, 50, 231, 148, IDC_ANIM1, MUIAS_STRETCH or MUIAS_LCLICK or MUIAS_HAND
        mov hAnim1, rax
        
        ;-----------------------------------------------------------------------------
        ; Load animation spritesheet. Frame times are in an array. MUIAFT_FULL is a 
        ; one for one entry for each frame for its time, MUIAFT_COMPACT means only the
        ; entries in the array that match the frame id (index) are updated with frame 
        ; times, the other frames default to default frame time value - which can be
        ; set by calling MUIAnimationSetDefaultTime
        ;----------------------------------------------------------------------------- 
        Invoke MUIAnimationLoadSpriteSheet, hAnim1, MUIAIT_PNG, PNG_FCCB, FCCBFrameCount, Addr FCCBFrameTimes, FCCBFrameTimesSize, MUIAFT_FULL
        ;Invoke MUIAnimationLoadSpriteSheet, hAnim1, MUIAIT_PNG, PNG_FCCB, FCCBFrameCount, Addr FrameTimes, FrameTimesSize, MUIAFT_COMPACT
        
        ; Modify some settings
        Invoke MUIAnimationSpeed, hAnim1, FP4(1.5) ; speed up animation
        ;Invoke MUIAnimationSpeed, hAnim1, FP4(0.5) ; slow down animation
        ;Invoke MUIAnimationSetDefaultTime, hAnim1, 40 ; if using MUIAFT_COMPACT set default frame times
        ;Invoke MUIAnimationStart, hAnim1 ; if style is MUIAS_LCLICK then clicking with play/stop animation
        
        ;-----------------------------------------------------------------------------
        ; Another ModernUI_Animation control for OnOff, to mimic a rocker/slider control
        ;-----------------------------------------------------------------------------
        Invoke MUIAnimationCreate, hWin, 100, 220, 127, 43, IDC_ONOFF, MUIAS_CENTER or MUIAS_LCLICK or MUIAS_HAND or MUIAS_CONTROL; MUIAS_STRETCH461, 294
        mov hOnOff, rax
        Invoke MUIAnimationLoadSpriteSheet, hOnOff, MUIAIT_PNG, PNG_ONOFF, OnOffFrameCount, Addr OnOffFrameTimes, OnOffFrameTimesSize, MUIAFT_FULL
        ;Invoke MUIAnimationSetProperty, hOnOff, @AnimationBorderColor, -1 ; no border
        Invoke MUIAnimationSetProperty, hOnOff, @AnimationBorderColor, MUI_RGBCOLOR(188,188,188)
        

    ;---------------------------------------------------------------------------------
    ; Handle painting of our dialog with our specified background and border color to 
    ; mimic new Modern style UI feel
    ;---------------------------------------------------------------------------------
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), MUI_RGBCOLOR(27,161,226)
        mov rax, 0
        ret
    ;---------------------------------------------------------------------------------
		
	.ELSEIF eax == WM_COMMAND
        mov rax, wParam
		.IF rax == IDM_FILE_EXIT
			Invoke SendMessage, hWin, WM_CLOSE, 0, 0
			
		.ELSEIF rax == IDM_HELP_ABOUT
			Invoke ShellAbout, hWin, Addr AppName, Addr AboutMsg, NULL
			
        .ELSEIF eax == IDC_ONOFF
            .IF OnOffState == FALSE
                mov OnOffState, TRUE
                Invoke MUIAnimationResume, hAnim1
            .ELSE
                mov OnOffState, FALSE
                Invoke MUIAnimationPause, hAnim1
            .ENDIF
        
        .ELSEIF eax == IDC_ANIM1
            .IF OnOffState == FALSE
                mov OnOffState, TRUE
                Invoke MUIAnimationResume, hOnOff
            .ELSE
                mov OnOffState, FALSE
                Invoke MUIAnimationResume, hOnOff
            .ENDIF
			
		.ENDIF

	.ELSEIF eax == WM_CLOSE
		Invoke DestroyWindow, hWin
		
	.ELSEIF eax == WM_DESTROY
		Invoke PostQuitMessage, NULL
		
	.ELSE
		Invoke DefWindowProc, hWin, uMsg, wParam, lParam
		ret
	.ENDIF
	xor rax, rax
	ret
WndProc endp

end WinMainCRTStartup
