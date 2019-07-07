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
;    includelib \JWasm\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'\Jwasm\bin\DbgWin.exe'>
;    include \JWasm\include\debug64.inc
;    .DATA
;    RDBG_DbgWin	DB DEBUGEXE,0
;    .CODE
;ENDIF

include MUIProgressBar.inc

.CODE

WinMainCRTStartup proc FRAME
	invoke GetModuleHandle, NULL
	mov hInstance, rax
	invoke GetCommandLine
	mov CommandLine, rax
	Invoke InitCommonControls
	mov icc.dwSize, sizeof INITCOMMONCONTROLSEX
    mov icc.dwICC, ICC_COOL_CLASSES or ICC_STANDARD_CLASSES or ICC_WIN95_CLASSES
    Invoke InitCommonControlsEx, offset icc
	invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess, eax
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
	mov wcex.hbrBackground, COLOR_WINDOW+1
	mov wcex.lpszMenuName, IDM_MENU ;NULL 
	lea rax, ClassName
	mov wcex.lpszClassName, rax
	;invoke LoadIcon, NULL, IDI_APPLICATION
	Invoke LoadIcon, hInstance, ICO_MAIN ; resource icon for main application icon
	;mov hIcoMain, eax ; main application icon	
	mov wcex.hIcon, rax
	mov wcex.hIconSm, rax
	invoke LoadCursor, NULL, IDC_ARROW
	mov wcex.hCursor, rax
	invoke RegisterClassEx, addr wcex
	
	;invoke CreateWindowEx, 0, addr ClassName, addr szAppName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, hInstance, NULL
	Invoke CreateDialogParam, hInstance, IDD_DIALOG, 0, Addr WndProc, 0
	mov hWnd, rax
	
	invoke ShowWindow, hWnd, SW_SHOWNORMAL
	invoke UpdateWindow, hWnd
	
	.while (TRUE)
		invoke GetMessage, addr msg, NULL, 0, 0
		.break .if (!rax)		
		
		invoke TranslateMessage, addr msg
		invoke DispatchMessage, addr msg
	.endw
	
	mov rax, msg.wParam
	ret	
WinMain endp


;-------------------------------------------------------------------------------------
; WndProc - Main Window Message Loop
;-------------------------------------------------------------------------------------
WndProc proc FRAME hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax, uMsg
	.IF eax == WM_INITDIALOG
		push hWin
		pop hWnd
		
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_CaptionBar
        ;-----------------------------------------------------------------------------------------------------
		Invoke MUICaptionBarCreate, hWin, Addr AppName, 32d, IDC_CAPTIONBAR, MUICS_NOMAXBUTTON or MUICS_LEFT or MUICS_REDCLOSEBUTTON
		mov hCaptionBar, rax
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(27,161,226)
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(61,61,61)
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(87,193,244)		

		;-----------------------------------------------------------------------------------------------------
        ; ModernUI_Button Example: Start Button - Used to start the progress bar in this example
        ;-----------------------------------------------------------------------------------------------------
		Invoke MUIButtonCreate, hWin, Addr szStartButtonText, 20, 160, 140, 38, IDC_STARTBUTTON, WS_CHILD or WS_VISIBLE or MUIBS_HAND or MUIBS_PUSHBUTTON or MUIBS_CENTER
		mov hStartBtn, rax
		
		;-----------------------------------------------------------------------------------------------------
        ; ModernUI_Button Example: Exit Button - used to exit this example
        ;-----------------------------------------------------------------------------------------------------
		Invoke MUIButtonCreate, hWin, Addr szExitButtonText, 180, 160, 140, 38, IDC_EXITBUTTON, WS_CHILD or WS_VISIBLE or MUIBS_HAND or MUIBS_PUSHBUTTON or MUIBS_CENTER
		mov hExitBtn, rax

        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_ProgressBar Examples: - when user clicks Start Button we start the progress bars or restart
        ;-----------------------------------------------------------------------------------------------------
        Invoke MUIProgressBarCreate, hWin, 20,50,300,12, IDC_PB1, 0
        mov hPB1, rax
        Invoke MUIProgressBarSetProperty, hPB1, @ProgressBarBorderColor, MUI_RGBCOLOR(93,95,120)
        Invoke MUIProgressBarSetProperty, hPB1, @ProgressBarTextType, MUIPBTT_CENTRE ; show % text in centre
        Invoke MUIProgressBarSetProperty, hPB1, @ProgressBarPulseTime, 1500 ; speed up pulse
        
        Invoke MUIProgressBarCreate, hWin, 20,70,300,12, IDC_PB2, 0
        mov hPB2, rax
        Invoke MUIProgressBarSetProperty, hPB2, @ProgressBarBackColor, MUI_RGBCOLOR(255,255,255)
        Invoke MUIProgressBarSetProperty, hPB2, @ProgressBarTextColor, MUI_RGBCOLOR(96,96,96)
        Invoke MUIProgressBarSetProperty, hPB2, @ProgressBarProgressColor, MUI_RGBCOLOR(33,186,69) ; change progress color
        Invoke MUIProgressBarSetProperty, hPB2, @ProgressBarTextType, MUIPBTT_CENTRE ; show % text in centre
        
        Invoke MUIProgressBarCreate, hWin, 20,90,300,12, IDC_PB3, 0
        mov hPB3, rax
        Invoke MUIProgressBarSetProperty, hPB3, @ProgressBarBorderColor, MUI_RGBCOLOR(93,95,120)
        Invoke MUIProgressBarSetProperty, hPB3, @ProgressBarProgressColor, MUI_RGBCOLOR(186,69,33) ; change progress color
        Invoke MUIProgressBarSetProperty, hPB3, @ProgressBarPulse, FALSE ; dont show a pulse
        
        Invoke MUIProgressBarCreate, hWin, 20,110,300,12, IDC_PB4, MUIPBS_TEXT_FOLLOW ; % using style flag instead of @ProgressBarTextType - text follows progress
        mov hPB4, rax
        Invoke MUIProgressBarSetProperty, hPB4, @ProgressBarBackColor, MUI_RGBCOLOR(240,240,240)
        Invoke MUIProgressBarSetProperty, hPB4, @ProgressBarProgressColor, MUI_RGBCOLOR(131,131,138) ; change progress color
        
        Invoke MUIProgressBarCreate, hWin, 20,130,300,12, IDC_PB5, MUIPBS_TEXT_FOLLOW or MUIPBS_R2G ; % using style flag - text follows progress and goes from red to green
        mov hPB5, rax
        
    ;---------------------------------------------------------------------------------------------------------------
    ; Handle painting of our dialog with our specified background and border color to mimic new Modern style UI feel
    ;---------------------------------------------------------------------------------------------------------------
    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

	.ELSEIF eax == WM_PAINT
		invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(255,255,255), MUI_RGBCOLOR(27,161,226)
		mov eax, 0
		ret
    ;---------------------------------------------------------------------------------------------------------------

	.ELSEIF eax == WM_COMMAND
	    mov rax, wParam
		.IF rax == IDM_FILE_EXIT
			Invoke SendMessage, hWin, WM_CLOSE, 0, 0
			
		.ELSEIF rax == IDM_HELP_ABOUT
			Invoke ShellAbout, hWin, Addr AppName, Addr AboutMsg, NULL

        .ELSEIF rax == IDC_STARTBUTTON
            Invoke KillTimer, hWin, 1
            Invoke KillTimer, hWin, 2
            Invoke KillTimer, hWin, 3
            Invoke KillTimer, hWin, 4
            Invoke KillTimer, hWin, 5
            Invoke MUIProgressBarSetPercent, hPB1, 0
            Invoke MUIProgressBarSetPercent, hPB2, 0
            Invoke MUIProgressBarSetPercent, hPB3, 0
            Invoke MUIProgressBarSetPercent, hPB4, 0
            Invoke MUIProgressBarSetPercent, hPB5, 0
            Invoke SetTimer, hWin, 1, 200, 0
            Invoke SetTimer, hWin, 2, 250, 0
            Invoke SetTimer, hWin, 3, 300, 0
            Invoke SetTimer, hWin, 4, 200, 0
            Invoke SetTimer, hWin, 5, 250, 0
            mov qwTimer1, 0
        
        .ELSEIF rax == IDC_EXITBUTTON
            Invoke KillTimer, hWin, 1
            Invoke KillTimer, hWin, 2
            Invoke KillTimer, hWin, 3
            Invoke KillTimer, hWin, 4
            Invoke KillTimer, hWin, 5
            Invoke SendMessage,hWin,WM_CLOSE,0,0
		.ENDIF
    
    .ELSEIF eax == WM_TIMER
        mov rax, wParam
        .IF rax == 1
            Invoke MUIProgressBarStep, hPB1
            Invoke MUIProgressBarGetPercent, hPB1
            .IF rax == 20
                Invoke MUIProgressBarSetPercent, hPB1, 40
            .ELSEIF rax == 60
                Invoke MUIProgressBarSetPercent, hPB1, 80
            .ELSEIF rax == 100
                Invoke KillTimer, hWin, 1
                inc qwTimer1
                .IF qwTimer1 < 3 ; stops after 3 times
                    Invoke MUIProgressBarSetPercent, hPB1, 0
                    Invoke SetTimer, hWin, 1, 150, 0
                .ENDIF
            .ENDIF
        .ELSEIF rax == 2
            Invoke MUIProgressBarStep, hPB2
            Invoke MUIProgressBarGetPercent, hPB2
            .IF rax == 100
                Invoke KillTimer, hWin, 2
            .ENDIF
        .ELSEIF rax == 3
            Invoke MUIProgressBarStep, hPB3
            Invoke MUIProgressBarGetPercent, hPB3
            .IF rax == 100
                Invoke KillTimer, hWin, 3
            .ENDIF
        .ELSEIF rax == 4
            Invoke MUIProgressBarStep, hPB4
            Invoke MUIProgressBarGetPercent, hPB4
            .IF rax == 100
                Invoke KillTimer, hWin, 4
            .ENDIF
        .ELSEIF rax == 5
            Invoke MUIProgressBarStep, hPB5
            Invoke MUIProgressBarGetPercent, hPB5
            .IF rax == 100
                Invoke KillTimer, hWin, 5
            .ENDIF
        .ENDIF
         
	.ELSEIF eax == WM_CLOSE
		Invoke DestroyWindow, hWin
		
	.ELSEIF eax == WM_DESTROY
		Invoke PostQuitMessage, NULL
		
	.ELSE
		invoke DefWindowProc, hWin, uMsg, wParam, lParam
		ret
	.ENDIF
	xor rax, rax
	ret
WndProc endp

end WinMainCRTStartup
