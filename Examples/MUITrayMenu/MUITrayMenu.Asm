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

include MUITrayMenu.inc

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
	Invoke LoadIcon, hInst, ICO_MUI ; resource icon for main application icon
	mov hIcoMain, rax ; main application icon	
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
        Invoke MUICaptionBarCreate, hWin, Addr AppName, 32d, IDC_CAPTIONBAR, MUICS_LEFT or MUICS_REDCLOSEBUTTON or MUICS_USEICONSFORBUTTONS ; or MUICS_NOCAPTIONTITLETEXT ;or MUICS_NOMAXBUTTON
        mov hCaptionBar, rax
        
        Invoke MUICaptionBarLoadIcons, hCaptionBar, ICO_MIN, NULL, ICO_MAX, NULL, ICO_RES, NULL, ICO_CLOSE, NULL
        
        ; Set some properties for our CaptionBar control 
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(51,51,51)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(228,228,228)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(81,81,81)

        ;Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnWidth, 36d
        
        ; Create ModernUI_Button control for buttons: notify and exit
        Invoke MUIButtonCreate, hWin, Addr szShowNotifyText, 50, 80, 200, 38, IDC_SHOWNOTIFICATION, WS_CHILD or WS_VISIBLE or MUIBS_HAND or MUIBS_PUSHBUTTON or MUIBS_CENTER
        mov hNotifyBtn, rax

        Invoke MUIButtonCreate, hWin, Addr szExitButton, 50, 130, 200, 38, IDC_EXIT, WS_CHILD or WS_VISIBLE or MUIBS_HAND or MUIBS_PUSHBUTTON or MUIBS_CENTER
        mov hExitBtn, rax
        
        ; Create our ModernUI_TrayMenu control
        Invoke MUITrayMenuCreate, hWin, hIcoMain, Addr szTrayMenuTooltip, MUITMT_MENUITEMS, Addr TrayMenu1, MUITMS_MINONCLOSE or MUITMS_HIDEIFMIN, NULL
        mov hTrayMenu, rax        
        

    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF eax == WM_PAINT
        invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), MUI_RGBCOLOR(51,51,51) ; MUI_RGBCOLOR(255,255,255)
        mov eax, 0
        ret
		
	.ELSEIF eax == WM_COMMAND
        mov rax, wParam
        and rax, 0FFFFh
        .IF eax == IDM_TRAY_EXIT ; ModernUI_TrayMenu right click menu: Exit menu item 
            Invoke SendMessage,hWin,WM_CLOSE,0,0
        
        .ELSEIF eax == IDM_TRAY_OPT ; ModernUI_TrayMenu right click menu: Option menu item
        
        .ELSEIF eax == IDM_TRAY_URL ; ModernUI_TrayMenu right click menu: Web url menu item
            Invoke ShellExecute, hWin, Addr szShellCmdOpen, Addr szWebUrl, NULL, NULL, SW_SHOWNORMAL
        
        .ELSEIF eax == IDC_EXIT ; ModernUI_Button Exit Button
            Invoke SendMessage,hWin,WM_CLOSE,0,0
            
        .ELSEIF eax == IDC_SHOWNOTIFICATION ; ModernUI_Button Notify Button
            Invoke MUITrayMenuShowNotification, hTrayMenu, Addr szNotifyMsg, Addr szNotifyTitle, 5000d, MUITMNI_INFO
            
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
