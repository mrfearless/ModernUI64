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

include MUICheckbox.inc

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
	mov wcex.hbrBackground, COLOR_WINDOW+1
	mov wcex.lpszMenuName, IDM_MENU ;NULL 
	lea rax, ClassName
	mov wcex.lpszClassName, rax
	Invoke LoadIcon, NULL, IDI_APPLICATION
	;Invoke LoadIcon, hInst, ICO_MAIN ; resource icon for main application icon
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
        ; ModernUI_CaptionBar Example - similar to the other example projects based on this control
        ;-----------------------------------------------------------------------------------------------------
        ; Applies the ModernUI base style to the dialog, turning it into a borderless, caption less form
        ; we set our own caption and system buttons with the ModernUI_CaptionBar control
        Invoke MUIApplyToDialog, hWin, TRUE, TRUE
        
        ; Create CaptionBar control via MUI api
        Invoke MUICaptionBarCreate, hWin, Addr AppName, 32d, IDC_CAPTIONBAR, MUICS_LEFT or MUICS_REDCLOSEBUTTON ;or MUICS_USEICONSFORBUTTONS ; or MUICS_NOCAPTIONTITLETEXT ;or MUICS_NOMAXBUTTON
        mov hCaptionBar, rax
        
        ; Set some properties for our CaptionBar control 
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(27,161,226)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(61,61,61)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(87,193,244) 

        ;Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnWidth, 36d

        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_Checkbox Examples:
        ;-----------------------------------------------------------------------------------------------------        
        Invoke MUICheckboxCreate, hWin, Addr szCheckbox1Text, 20, 50, 200, 24, IDC_CHECKBOX1, MUICS_HAND or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov hChk1, rax
        ;Invoke MUICheckboxLoadImages, hChk1, MUICIT_ICO, ICO_NOCHECKMARK, ICO_NOCHECKMARK, ICO_CHECKMARK, ICO_CHECKMARK, ICO_NOCHECKMARK, ICO_CHECKMARK

        Invoke MUICheckboxCreate, hWin, Addr szCheckbox2Text, 20, 75, 200, 24, IDC_CHECKBOX2, MUICS_HAND or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov hChk2, rax
        ;Invoke MUICheckboxLoadImages, hChk2, MUICIT_ICO, ICO_NOCHECKMARK, ICO_NOCHECKMARK, ICO_CHECKMARK, ICO_CHECKMARK, ICO_NOCHECKMARK, ICO_CHECKMARK
        
        Invoke MUICheckboxCreate, hWin, Addr szCheckbox3Text, 20, 100, 200, 24, IDC_CHECKBOX3, MUICS_HAND or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov hChk3, rax
        ;Invoke MUICheckboxLoadImages, hChk3, MUICIT_ICO, ICO_NOCHECKMARK, ICO_NOCHECKMARK, ICO_CHECKMARK, ICO_CHECKMARK, ICO_NOCHECKMARK, ICO_CHECKMARK


    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), MUI_RGBCOLOR(27,161,226)
        mov eax, 0
        ret
		
	.ELSEIF eax == WM_COMMAND
        mov rax, wParam
		.IF rax == IDM_FILE_EXIT
			Invoke SendMessage, hWin, WM_CLOSE, 0, 0
			
		.ELSEIF rax == IDM_HELP_ABOUT
			Invoke ShellAbout, hWin, Addr AppName, Addr AboutMsg, NULL
			
		.ENDIF

	.ELSEIF eax == WM_CLOSE
		Invoke DestroyWindow, hWin
		
	.ELSEIF eax == WM_DESTROY
		Invoke PostQuitMessage, NULL
		
	.ELSE
		Invoke DefWindowProc, rcx, edx, r8, r9
		ret
	.ENDIF
	xor rax, rax
	ret
WndProc endp

end WinMainCRTStartup
