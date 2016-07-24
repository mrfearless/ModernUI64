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


include MUICaptionBar1.inc

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
	
	Invoke RtlZeroMemory, Addr wcex, SIZEOF WNDCLASSEX
	
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
	invoke LoadIcon, NULL, IDI_APPLICATION
	;Invoke LoadIcon, hInst, ICO_MAIN ; resource icon for main application icon
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
		
		; Create CaptionBar control via MUI api
		Invoke MUICaptionBarCreate, hWin, Addr AppName, 32d, IDC_CAPTIONBAR, MUICS_LEFT or MUICS_REDCLOSEBUTTON
		mov hCaptionBar, rax
		
		; Set some properties for our CaptionBar control 
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(51,51,51)
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(228,228,228)
		Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(81,81,81)
		
    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

	.ELSEIF eax == WM_PAINT
		invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(255,255,255), MUI_RGBCOLOR(51,51,51)
		mov eax, 0
		ret
		
	.ELSEIF eax == WM_COMMAND
		.IF wParam == IDM_FILE_EXIT
			Invoke SendMessage, hWin, WM_CLOSE, 0, 0
			
		.ELSEIF wParam == IDM_HELP_ABOUT
			Invoke ShellAbout, hWin, Addr AppName, Addr AboutMsg, NULL
			
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










































