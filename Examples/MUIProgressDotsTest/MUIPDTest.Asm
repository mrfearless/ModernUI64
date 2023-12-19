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

include MUIPDTest.inc

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
	mov wcex.style, 0;CS_HREDRAW or CS_VREDRAW
	lea rax, WndProc
	mov wcex.lpfnWndProc, rax
	mov wcex.cbClsExtra, 0
	mov wcex.cbWndExtra, DLGWINDOWEXTRA
	mov rax, hInst
	mov wcex.hInstance, rax
	mov wcex.hbrBackground, 0;COLOR_WINDOW+1
	mov wcex.lpszMenuName, NULL
	lea rax, ClassName
	mov wcex.lpszClassName, rax
	;Invoke LoadIcon, NULL, IDI_APPLICATION
	Invoke LoadIcon, hInstance, ICO_MAIN ; resource icon for main application icon
	;mov hIcoMain, eax ; main application icon	
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
        push hWin
        pop hWnd
        
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_CaptionBar
        ;-----------------------------------------------------------------------------------------------------		
        Invoke MUICaptionBarCreate, hWin, Addr AppName, 64d, IDC_CAPTIONBAR, MUICS_NOCAPTIONTITLETEXT or MUICS_LEFT or MUICS_NOMAXBUTTON or MUICS_NOMINBUTTON or MUICS_WINNODROPSHADOW; or MUICS_NOCAPTIONTITLETEXT ;or MUICS_NOMAXBUTTON
        mov hCaptionBar, rax
        ; Set some properties for our CaptionBar control 
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(45,45,48)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(255,255,255)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(66,66,68)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnWidth, 36d
        Invoke MUICaptionBarLoadBackImage, hCaptionBar, MUICBIT_BMP, BMP_RSLOGO
        
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_Button
        ;-----------------------------------------------------------------------------------------------------
        ; Create a second ModernUI_Button control
        Invoke MUIButtonCreate, hWin, Addr szBtnCancelText, 350, 600, 90, 28, IDC_BTNCANCEL, WS_CHILD or WS_VISIBLE or MUIBS_HAND or MUIBS_PUSHBUTTON or MUIBS_CENTER
        mov hBtnCancel, rax        
        
        Invoke MUIButtonSetProperty, hBtnCancel, @ButtonTextColor, MUI_RGBCOLOR(179,179,179)
        Invoke MUIButtonSetProperty, hBtnCancel, @ButtonTextColorAlt, MUI_RGBCOLOR(179,179,179)
        Invoke MUIButtonSetProperty, hBtnCancel, @ButtonBackColor, MUI_RGBCOLOR(45,45,48)
        Invoke MUIButtonSetProperty, hBtnCancel, @ButtonBackColorAlt, MUI_RGBCOLOR(66,66,68)
        
        Invoke MUIButtonSetProperty, hBtnCancel, @ButtonBorderStyle, MUIBBS_ALL
        Invoke MUIButtonSetProperty, hBtnCancel, @ButtonBorderColor, MUI_RGBCOLOR(103,103,106)
        Invoke MUIButtonSetProperty, hBtnCancel, @ButtonBorderColorAlt, MUI_RGBCOLOR(56,163,254)
        
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_Text
        ;-----------------------------------------------------------------------------------------------------        
        Invoke MUITextCreate, hWin, Addr szInstalling, 33, 129, 379, 80, IDC_TEXT1, MUITS_10PT or MUITS_FONT_SEGOE
        mov hText1, rax
        Invoke MUITextSetProperty, hText1, @TextColor, MUI_RGBCOLOR(179,179,179)
        Invoke MUITextSetProperty, hText1, @TextColorAlt, MUI_RGBCOLOR(179,179,179)
        Invoke MUITextSetProperty, hText1, @TextBackColor, MUI_RGBCOLOR(45,45,48)
        Invoke MUITextSetProperty, hText1, @TextBackColorAlt, MUI_RGBCOLOR(45,45,48)
        
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_ProgressDot
        ;-----------------------------------------------------------------------------------------------------
		Invoke MUIProgressDotsCreate, hWin, 300, 3, IDC_MUIPD, 0
		mov hMUIPD, rax
		Invoke MUIProgressDotsSetProperty, hMUIPD, @ProgressDotsBackColor, MUI_RGBCOLOR(45,45,48)
		Invoke MUIProgressDotsAnimateStart, hMUIPD

    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(45,45,48), MUI_RGBCOLOR(12,12,12)
        mov eax, 0
        ret
		
	.ELSEIF eax == WM_COMMAND
        mov rax, wParam
		.IF eax == IDC_BTNCANCEL
	        Invoke MUIProgressDotsAnimateStop, hMUIPD
	        Invoke SendMessage, hWin, WM_CLOSE, 0, 0
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
