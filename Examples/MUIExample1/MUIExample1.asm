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

include MUIExample1.inc

include Panels.asm


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
	mov wcex.style, 0
	lea rax, WndProc
	mov wcex.lpfnWndProc, rax
	mov wcex.cbClsExtra, 0
	mov wcex.cbWndExtra, DLGWINDOWEXTRA
	mov rax, hInst
	mov wcex.hInstance, rax
	mov wcex.hbrBackground, 0
	mov wcex.lpszMenuName, NULL 
	lea rax, ClassName
	mov wcex.lpszClassName, rax
	Invoke LoadIcon, hInst, ICO_MAIN ; resource icon for main application icon
	mov hIcoMain, rax ; main application icon	
	mov wcex.hIcon, rax
	mov wcex.hIconSm, rax
	Invoke LoadCursor, NULL, IDC_ARROW
	mov wcex.hCursor, rax
	Invoke RegisterClassEx, addr wcex
	Invoke CreateDialogParam, hInstance, IDD_DIALOG, 0, Addr WndProc, 0
	mov hWnd, rax
	Invoke ShowWindow, hWnd, SW_SHOWNORMAL
	Invoke UpdateWindow, hWnd
	
    .WHILE TRUE
        Invoke GetMessage,addr msg,NULL,0,0
        .BREAK .if !rax

        .IF hCurrentPanel != NULL
            Invoke IsDialogMessage, hCurrentPanel, addr msg ; add in a reference to our currently selected child dialog so we can do tabbing between controls etc.
            .IF rax == 0
                Invoke TranslateMessage,addr msg
                Invoke DispatchMessage,addr msg
            .ENDIF
        .ELSE
            Invoke TranslateMessage,addr msg
            Invoke DispatchMessage,addr msg
        .ENDIF
    .ENDW
	
	mov rax, msg.wParam
	ret	
WinMain endp


;-------------------------------------------------------------------------------------
; WndProc - Main Window Message Loop
;-------------------------------------------------------------------------------------
WndProc proc FRAME hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL wNotifyCode:QWORD
    
    mov eax, uMsg
	.IF eax == WM_INITDIALOG
        Invoke InitGUI, hWin

    .ELSEIF eax == WM_COMMAND
        mov rax, wParam
        shr rax, 32d
        mov wNotifyCode, rax
        mov rax,wParam
        and rax,0FFFFFFFFh

    ;-----------------------------------------------------------------------------------------------------
    ; ModernUI - Color background and border
    ;-----------------------------------------------------------------------------------------------------
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(45,45,48), MUI_RGBCOLOR(12,12,12)
        mov rax, 0
        ret

	.ELSEIF eax == WM_CLOSE
        Invoke MUISmartPanelCurrentPanelIndex, hMUISmartPanel
        .IF rax == 1 ; preparing installation dialog panel
        
            mov rax, qwInstallStage
            .IF rax == 0 ; before prep has finished        
                Invoke MUIProgressDotsAnimateStop, hMUIPD
                Invoke MUISmartPanelSetCurrentPanel, hMUISmartPanel, 0, FALSE
                .IF hPreThread != NULL
                    Invoke ResumeThread, hPreThread
                .ENDIF
                .IF qwInstallStage == 1
                    Invoke MUIProgressDotsAnimateStop, hMUIPD
                    Invoke MUISmartPanelSetCurrentPanel, hMUISmartPanel, 2, FALSE ; 3rd dialog - choose components
                .ENDIF                
                ret
            .ELSEIF rax == 1
                Invoke MUIProgressDotsAnimateStop, hMUIPD
                Invoke MUISmartPanelSetCurrentPanel, hMUISmartPanel, 2, FALSE ; 3rd dialog - choose components
                ret
            .ENDIF
        
        .ELSEIF rax == 2 ; choosing components dialog panel
        
            Invoke MUISmartPanelSetCurrentPanel, hMUISmartPanel, 0, FALSE
            ret
        
        .ENDIF	
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


;-------------------------------------------------------------------------------------
; InitGUI - initialize GUI
;-------------------------------------------------------------------------------------
InitGUI PROC FRAME hWin:QWORD
    
    ;-----------------------------------------------------------------------------------------------------
    ; ModernUI_CaptionBar
    ;-----------------------------------------------------------------------------------------------------      
    Invoke MUICaptionBarCreate, hWin, Addr AppName, 50d, IDC_CAPTIONBAR, MUICS_NOCAPTIONTITLETEXT or MUICS_LEFT or MUICS_NOMAXBUTTON or MUICS_WINNODROPSHADOW; or MUICS_NOCAPTIONTITLETEXT ;or MUICS_NOMAXBUTTON
    mov hMUICaptionBar, rax
    Invoke MUICaptionBarSetProperty, hMUICaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(45,45,48)
    Invoke MUICaptionBarSetProperty, hMUICaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUICaptionBarSetProperty, hMUICaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(66,66,68)
    Invoke MUICaptionBarSetProperty, hMUICaptionBar, @CaptionBarBtnWidth, 28d
    Invoke MUICaptionBarSetProperty, hMUICaptionBar, @CaptionBarBtnBorderRollColor, MUI_RGBCOLOR(56,163,254)
    Invoke MUICaptionBarLoadBackImage, hMUICaptionBar, MUICBIT_BMP, BMP_RSLOGO


    ; ------------------------------------------------------------------------
    ; ModernUI_SmartPanel
    ; ------------------------------------------------------------------------
    Invoke MUISmartPanelCreate, hWin, 2, 98, 457, 545, IDC_SMARTPANEL, MUISPS_SLIDEPANELS_NORMAL or MUISPS_SPS_SKIPBETWEEN
    mov hMUISmartPanel, rax
    ; Register child panels to use with ModernUI_SmartPanel:
    Invoke MUISmartPanelRegisterPanel, hMUISmartPanel, IDD_Panel1, Addr Panel1Proc
    mov hPanel1, rax
    Invoke MUISmartPanelRegisterPanel, hMUISmartPanel, IDD_Panel2, Addr Panel2Proc
    mov hPanel2, rax
    Invoke MUISmartPanelRegisterPanel, hMUISmartPanel, IDD_Panel3, Addr Panel3Proc
    mov hPanel3, rax
    Invoke MUISmartPanelRegisterPanel, hMUISmartPanel, IDD_Panel4, Addr Panel4Proc
    mov hPanel4, rax
    ; Set current panel to index 0 and store handle to current panel in 
    ; hCurrentPanel (for use with IsDialogMessage)
    Invoke MUISmartPanelSetCurrentPanel, hMUISmartPanel, 1, FALSE
    Invoke MUISmartPanelSetIsDlgMsgVar, hMUISmartPanel, Addr hCurrentPanel
    ;Invoke MUISmartPanelSetProperty, hMUISmartPanel, @SmartPanelPanelsColor, MUI_RGBCOLOR(45,45,48)

    ;-----------------------------------------------------------------------------------------------------
    ; ModernUI_Text: Community Edition 2018
    ;-----------------------------------------------------------------------------------------------------        
    Invoke MUITextCreate, hWin, Addr szRSHeader, 17, 70, 457, 30, IDC_TEXTRSHEADER, MUITS_CAPTION or MUITS_FONT_SEGOE 
    mov hMUITextRSHeader, rax
    Invoke MUITextSetProperty, hMUITextRSHeader, @TextColor, MUI_RGBCOLOR(179,179,179)
    Invoke MUITextSetProperty, hMUITextRSHeader, @TextColorAlt, MUI_RGBCOLOR(179,179,179)
    Invoke MUITextSetProperty, hMUITextRSHeader, @TextBackColor, MUI_RGBCOLOR(45,45,48)
    Invoke MUITextSetProperty, hMUITextRSHeader, @TextBackColorAlt, MUI_RGBCOLOR(45,45,48)
    
    ret

InitGUI ENDP


;-------------------------------------------------------------------------------------
; PreInstallation - Prepare installation. Calls PreInstallationThread
;-------------------------------------------------------------------------------------
PreInstallation PROC FRAME
    Invoke CreateThread, NULL, NULL, Addr PreInstallationThread, NULL, NULL, Addr lpThreadID
    mov hPreThread, rax
    ret
PreInstallation ENDP


;-------------------------------------------------------------------------------------
; PreInstallationThread - Main work for preparing installation goes here
;-------------------------------------------------------------------------------------
PreInstallationThread PROC FRAME qwParam:QWORD
    
    mov qwInstallStage, 0
    
    ; Pretend we are doing something here for the preperation of the installation
    Invoke SleepEx, 10000, FALSE

    ; Finally, we finished the prep part, now move on to next dialog for user to 
    ; choose components or installation location or something

    Invoke MUIProgressDotsAnimateStop, hMUIPD ; stop dots
    Invoke MUISmartPanelSetCurrentPanel, hMUISmartPanel, 2, FALSE ; move to dialog 3
    mov hPreThread, 0
    mov qwInstallStage, 1
    
    ret
PreInstallationThread ENDP


end WinMainCRTStartup
