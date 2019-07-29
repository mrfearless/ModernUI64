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

include TrayInfo.inc
include Menu.asm

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
	mov wcex.hbrBackground, COLOR_BTNFACE+1
	mov wcex.lpszMenuName, IDM_MENU ;NULL 
	lea rax, ClassName
	mov wcex.lpszClassName, rax
    Invoke LoadIcon, hInstance, ICO_MAIN ; resource icon for main application icon
    mov hMainIcon, rax ; main application icon
	mov wcex.hIcon, rax
	mov wcex.hIconSm, rax
	Invoke LoadCursor, NULL, IDC_ARROW
	mov wcex.hCursor, rax
	Invoke RegisterClassEx, addr wcex
	
	;Invoke CreateWindowEx, 0, addr ClassName, addr szAppName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, hInstance, NULL
	Invoke CreateDialogParam, hInstance, IDD_DIALOG, 0, Addr WndProc, 0
	mov hWnd, rax
	; hide initial dialog to just show tray icons
	;Invoke ShowWindow, hWnd, SW_SHOWNORMAL
	;Invoke UpdateWindow, hWnd
	
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
        Invoke InitGUI, hWin
        
        ;-----------------------------------------------------------------------------
        ; ModernUI_CaptionBar
        ;-----------------------------------------------------------------------------
        Invoke MUIApplyToDialog, hWin, TRUE, TRUE
        Invoke MUICaptionBarCreate, hWin, Addr AppName, 32, IDC_CAPTIONBAR, MUICS_NOMAXBUTTON or MUICS_LEFT or MUICS_REDCLOSEBUTTON
        mov hCaptionBar, rax
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(27,161,226)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(61,61,61)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(87,193,244)   
        
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_Checkbox
        ;-----------------------------------------------------------------------------------------------------
        Invoke MUICheckboxCreate, hWin, Addr szCheckTextCPU, 13, 55, 215, 24, IDC_CHECKCPU, MUICBS_HAND or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_TABSTOP ;or THEMEDARK; or MUICBS_NOFOCUSRECT
        mov hChkCPU, rax
        Invoke MUICheckboxCreate, hWin, Addr szCheckTextMEM, 13, 80, 215, 24, IDC_CHECKMEM, MUICBS_HAND or WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_TABSTOP ;or THEMEDARK; or MUICBS_NOFOCUSRECT
        mov hChkMEM, rax        
        
        ;-----------------------------------------------------------------------------------------------------
        ; ModernUI_Button
        ;-----------------------------------------------------------------------------------------------------
        Invoke MUIButtonCreate, hWin, Addr szButtonTextExit, 20, 130, 140, 38, IDC_BUTTONEXIT, WS_CHILD or WS_VISIBLE or MUIBS_HAND or MUIBS_PUSHBUTTON or MUIBS_CENTER or WS_TABSTOP ;or MUIBS_THEME or MUIBS_NOFOCUSRECT
        mov hBtnExit, rax
        Invoke MUIButtonCreate, hWin, Addr szButtonTextHide, 180, 130, 140, 38, IDC_BUTTONHIDE, WS_CHILD or WS_VISIBLE or MUIBS_HAND or MUIBS_PUSHBUTTON or MUIBS_CENTER or WS_TABSTOP ;or MUIBS_THEME or MUIBS_NOFOCUSRECT
        mov hBtnHide, rax
        
        ;-----------------------------------------------------------------------------
        ; ModernUI_TrayMenu
        ;-----------------------------------------------------------------------------
        Invoke MUITrayMenuCreate, hWin, hMainIcon, Addr szAppTooltip, MUITMT_POPUPMENU, hTrayMenu, MUITMS_HIDEIFMIN or MUITMS_MINONCLOSE,0
        mov hMUITM, rax
        Invoke MUITrayMenuCreate, hWin, hIconBlank, Addr szCPUTip, MUITMT_POPUPMENU, hTrayMenu, MUITMS_HIDEIFMIN or MUITMS_MINONCLOSE,0
        mov hMUITMCPU, rax
        Invoke MUITrayMenuCreate, hWin, hIconBlank, Addr szMEMTip, MUITMT_POPUPMENU, hTrayMenu, MUITMS_HIDEIFMIN or MUITMS_MINONCLOSE,0
        mov hMUITMMEM, rax
        
        ;-----------------------------------------------------------------------------
        ; Start Icon Timers
        ;-----------------------------------------------------------------------------
        Invoke InitTimers, hWin


    ;---------------------------------------------------------------------------------
    ; Handle painting of our dialog with our specified background and border color to 
    ; mimic new Modern style UI feel
    ;---------------------------------------------------------------------------------
    .ELSEIF eax == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke MUIPaintBackground, hWin, MUI_RGBCOLOR(240,240,240), MUI_RGBCOLOR(27,161,226)
        mov eax, 0
        ret
    ;---------------------------------------------------------------------------------
		
		
	.ELSEIF eax == WM_COMMAND
        mov rax, wParam
		.IF rax == IDM_FILE_EXIT
			Invoke SendMessage, hWin, WM_CLOSE, 0, 0
			
        .ELSEIF rax == IDC_BUTTONEXIT ; ModernUI_Button
            Invoke SendMessage, hWin, WM_CLOSE, 0, 0
        
        .ELSEIF rax == IDC_BUTTONHIDE ; ModernUI_Button
	        Invoke ShowWindow, hWin, SW_MINIMIZE
	        Invoke ShowWindow, hWin, SW_HIDE
        
        .ELSEIF rax == IDM_HELP_ABOUT
            Invoke ShellAbout, hWin, Addr AppName, Addr AboutMsg,NULL
        
        .ELSEIF rax == IDC_CHECKCPU ; ModernUI_Checkbox
            Invoke MUICheckboxGetState, hChkCPU
            .IF rax == FALSE
                mov g_IconCPU, ICONS_CPU_HIDE
                Invoke KillTimer, hWin, TIMER_CPU
                Invoke MUITrayMenuHideTrayIcon, hMUITMCPU
            .ELSE
                Invoke GetSystemTimes, Addr last_idleTime, Addr last_kernelTime, Addr last_userTime 
                mov g_IconCPU, ICONS_CPU_SHOW
                Invoke MUITrayMenuShowTrayIcon, hMUITMCPU
                mov rax, g_ResponseCPU
                .IF rax == RESPONSE_CPU_05_SECS
                    Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_05, NULL
                .ELSEIF rax == RESPONSE_CPU_1_SEC
                    Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_1, NULL
                .ELSEIF rax == RESPONSE_CPU_2_SECS
                    Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_2, NULL
                .ELSEIF rax == RESPONSE_CPU_3_SECS
                    Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_3, NULL
                .ELSEIF rax == RESPONSE_CPU_5_SECS
                    Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_5, NULL
                .ENDIF
            .ENDIF
            Invoke TrayMenuUpdate, hWin
        
        .ELSEIF rax == IDC_CHECKMEM ; ModernUI_Checkbox
            Invoke MUICheckboxGetState, hChkMEM
            .IF rax == FALSE
                mov g_IconMEM, ICONS_MEM_HIDE
                Invoke KillTimer, hWin, TIMER_MEM
                Invoke MUITrayMenuHideTrayIcon, hMUITMMEM
            .ELSE
                mov g_IconMEM, ICONS_MEM_SHOW
                Invoke MUITrayMenuShowTrayIcon, hMUITMMEM
                mov rax, g_ResponseMEM
                .IF rax == RESPONSE_MEM_2_SECS
                    Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_2, NULL
                .ELSEIF rax == RESPONSE_MEM_5_SECS
                    Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_5, NULL
                .ELSEIF rax == RESPONSE_MEM_10_SECS
                    Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_10, NULL
                .ELSEIF rax == RESPONSE_MEM_20_SECS
                    Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_20, NULL
                .ELSEIF rax == RESPONSE_MEM_30_SECS
                    Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_30, NULL
                .ENDIF
            .ENDIF
            Invoke TrayMenuUpdate, hWin
        
        ; Handle all tray menu clicks within the one function
		.ELSEIF rax >= IDM_TM_FIRST && rax <= IDM_TM_LAST
		    Invoke TrayMenuSelection, hWin, rax 
            
        .ENDIF

    .ELSEIF eax == WM_TIMER
        mov rax, wParam
        .IF rax == TIMER_CPU ; poll for cpu load and update of tray icon
            Invoke CPULoad
        .ELSEIF rax == TIMER_MEM ; poll for mem load and update of tray icon
            Invoke GetMemoryLoad
        .ENDIF

	.ELSEIF eax == WM_CLOSE
		Invoke DestroyWindow, hWin
		
	.ELSEIF eax == WM_DESTROY
		Invoke PostQuitMessage, NULL
		
	.ELSE
		Invoke DefWindowProc, hWin, uMsg, wParam, lParam ; rcx, edx, r8, r9
		ret
	.ENDIF
	xor rax, rax
	ret
WndProc endp


;-------------------------------------------------------------------------------------
; InitGUI - initialize some gdi resources
;-------------------------------------------------------------------------------------
InitGUI PROC FRAME hWin:QWORD
    
    ; Fonts for tray icons
    Invoke CreateFont, -10, 0, 0, 0, 0, FALSE, FALSE, FALSE, 0, 0, 0, 0, 0, CTEXT("Segeo UI")
    mov hFontCPU, rax
    
    Invoke CreateFont, -10, 0, 0, 0, 0, FALSE, FALSE, FALSE, 0, 0, 0, 0, 0, CTEXT("Segeo UI")
    mov hFontMEM, rax
    
    ; A blank icon, just in case we need it
    Invoke LoadIcon, hInstance, ICO_BLANK
    mov hIconBlank, rax

    ; Tray menu bitmaps
    Invoke LoadBitmap, hInstance, BMP_TM_SHOW
    mov hBmpShow, rax
    Invoke LoadBitmap, hInstance, BMP_TM_HIDE
    mov hBmpHide, rax
    Invoke LoadBitmap, hInstance, BMP_TM_ICONS
    mov hBmpIcons, rax
    Invoke LoadBitmap, hInstance, BMP_TM_CPU
    mov hBmpCPU, rax
    Invoke LoadBitmap, hInstance, BMP_TM_MEM
    mov hBmpMEM, rax
    Invoke LoadBitmap, hInstance, BMP_TM_TIME
    mov hBmpTime, rax
    Invoke LoadBitmap, hInstance, BMP_TM_EXIT
    mov hBmpExit, rax
    
    ; Start creating the tray menu, before calling ModernUI_TrayMenu functions
    ; so we can assign ready made menu to it
    Invoke TrayMenuInit, hWin

    ret
InitGUI ENDP


;-------------------------------------------------------------------------------------
; InitTimers - init timers and other things for the tray icons
;-------------------------------------------------------------------------------------
InitTimers PROC FRAME hWin:QWORD
    
    ; Set checkbox initial states
    .IF g_IconCPU == ICONS_CPU_SHOW
        Invoke MUICheckboxSetState, hChkCPU, TRUE
    .ENDIF
    
    .IF g_IconMEM == ICONS_MEM_SHOW
        Invoke MUICheckboxSetState, hChkMEM, TRUE
    .ENDIF
    
    ; Assign a 0% icon to each tray icon to begin with before polling takes over
    Invoke MUITrayMenuSetTrayIconText, hMUITMCPU, Addr szZeroPercent, hFontCPU, MUI_RGBCOLOR(96,207,137)
    mov hIconCPU, rax ; save returned icon handle for later
    Invoke MUITrayMenuSetTrayIconText, hMUITMMEM, Addr szZeroPercent, hFontMEM, MUI_RGBCOLOR(96,176,207)
    mov hIconMEM, rax ; save returned icon handle for later
    
    ; Get g_ResponseCPU and g_ResponseMEM values
    ; Could fetch these from an ini file for user to keep settings persistant
    
    Invoke GetSystemTimes, Addr last_idleTime, Addr last_kernelTime, Addr last_userTime 
    
    ;---------------------------------------------------------
    ; CPU Icon Timer
    ;---------------------------------------------------------
    mov rax, g_ResponseCPU
    .IF rax == RESPONSE_CPU_05_SECS
        Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_05, NULL
    .ELSEIF rax == RESPONSE_CPU_1_SEC
        Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_1, NULL
    .ELSEIF rax == RESPONSE_CPU_2_SECS
        Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_2, NULL
    .ELSEIF rax == RESPONSE_CPU_3_SECS
        Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_3, NULL
    .ELSEIF rax == RESPONSE_CPU_5_SECS
        Invoke SetTimer, hWin, TIMER_CPU, TIME_CPU_5, NULL
    .ENDIF
    
    ;---------------------------------------------------------
    ; MEM Icon Timer
    ;---------------------------------------------------------
    mov rax, g_ResponseMEM
    .IF rax == RESPONSE_MEM_2_SECS
        Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_2, NULL
    .ELSEIF rax == RESPONSE_MEM_5_SECS
        Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_5, NULL
    .ELSEIF rax == RESPONSE_MEM_10_SECS
        Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_10, NULL
    .ELSEIF rax == RESPONSE_MEM_20_SECS
        Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_20, NULL
    .ELSEIF rax == RESPONSE_MEM_30_SECS
        Invoke SetTimer, hWin, TIMER_MEM, TIME_MEM_30, NULL
    .ENDIF

    ret
InitTimers ENDP


;-------------------------------------------------------------------------------------
; CPULoad - get the cpu load and change icon to reflect percentage of the cpu load
;-------------------------------------------------------------------------------------
CPULoad PROC FRAME
    LOCAL qwPercent:QWORD
    
    Invoke GetCPULoad, Addr szCpuLoadPercent
    mov qwPercent, rax
    
    .IF hIconCPU != 0
        Invoke DestroyIcon, hIconCPU ; delete existing icon otherwise gdi leak
    .ENDIF
    
    ; Create a tray icon based on our percent text and assign it to our existing TrayMenu
    .IF sqword ptr qwPercent >= 90
        Invoke MUITrayMenuSetTrayIconText, hMUITMCPU, Addr szCpuLoadPercent, hFontCPU, MUI_RGBCOLOR(207,96,96)
    .ELSE
        Invoke MUITrayMenuSetTrayIconText, hMUITMCPU, Addr szCpuLoadPercent, hFontCPU, MUI_RGBCOLOR(96,207,137) ;MUI_RGBCOLOR(255,50,75)
    .ENDIF
    mov hIconCPU, rax ; save returned icon handle for later

;    Invoke lstrcpy, Addr szCPUToolTip, Addr szCPUTip
;    Invoke lstrcat, Addr szCPUToolTip, Addr szCpuLoadPercent
;    Invoke lstrcat, Addr szCPUToolTip, Addr szPercentage
;    Invoke MUITrayMenuSetTooltipText, hMUITMCPU, Addr szCPUToolTip

    ret
CPULoad ENDP


;-------------------------------------------------------------------------------------
; GetCPULoad - calculates the cpu load based on times
;-------------------------------------------------------------------------------------
GetCPULoad PROC FRAME USES RBX RDX lpszPercent:QWORD
    LOCAL idleTime:FILETIME
    LOCAL kernelTime:FILETIME
    LOCAL userTime:FILETIME
    LOCAL idl:FILETIME
    LOCAL ker:FILETIME
    LOCAL usr:FILETIME
    LOCAL sys:FILETIME
    LOCAL sysidl:FILETIME
    LOCAL preresult:QWORD
    LOCAL divvalue:QWORD
    LOCAL percent:QWORD
    LOCAL fPercent:REAL10
    LOCAL dw100:QWORD
    LOCAL decimalPlace:QWORD
    
    mov decimalPlace, 1
    
    Invoke GetSystemTimes, Addr idleTime, Addr kernelTime, Addr userTime
    
    finit
    xor rax, rax
    mov rax, idleTime
    sub rax, last_idleTime
    mov idl, rax
    
    xor rax, rax
    mov rax, kernelTime
    sub rax, last_kernelTime
    mov ker, rax
    
    xor rax, rax
    mov rax, userTime
    sub rax, last_userTime
    mov usr, rax
    
    add rax, ker
    add rax, usr
    mov rbx, rax
    mov divvalue, rax
    xor rdx, rdx
    sub rax, idl
    imul rax, 100
    mov preresult, rax
    .IF rbx != 0
        idiv rbx
    .ELSE
        mov rax, 0
    .ENDIF
    mov percent, rax    

    ; if percentage is 0-9 then show a decimal place, otherwise dont
;    .IF sdword ptr percent < 10
;        fild preresult
;        fild divvalue
;        fdiv
;        fstp fPercent
;        .IF lpszPercent != NULL
;            Invoke FpuFLtoA, Addr fPercent, decimalPlace, lpszPercent, SRC1_REAL Or STR_REG
;        .ENDIF
;    .ELSE
        .IF lpszPercent != NULL
            Invoke qwtoa, percent, lpszPercent
        .ENDIF
;    .ENDIF
    
    ; store results for next go around
    fild qword ptr idleTime
    fistp qword ptr last_idleTime
    
    fild qword ptr kernelTime
    fistp qword ptr last_kernelTime
    
    fild qword ptr userTime
    fistp qword ptr last_userTime
    
    mov rax, percent
    ret

GetCPULoad ENDP


;------------------------------------------------------------------------------
; Get memory load percent
;------------------------------------------------------------------------------
GetMemoryLoad PROC FRAME
    LOCAL mse:MEMORYSTATUSEX
    LOCAL qwMemoryLoad:QWORD
    
    mov mse.dwLength, SIZEOF MEMORYSTATUSEX     ; initialise length
    Invoke GlobalMemoryStatusEx, Addr mse       ; call API
    
    mov eax, mse.dwMemoryLoad
    mov qwMemoryLoad, rax
    
    Invoke qwtoa, qwMemoryLoad, Addr szMemLoadPercent ; convert to text

    .IF hIconMEM != 0
        Invoke DestroyIcon, hIconMEM ; delete existing icon otherwise gdi leak
    .ENDIF

    ; Create a tray icon based on our percent text and assign it to our existing TrayMenu
    
    .IF sqword ptr qwMemoryLoad >= 90
        Invoke MUITrayMenuSetTrayIconText, hMUITMMEM, Addr szMemLoadPercent, hFontMEM, MUI_RGBCOLOR(207,96,96)
    .ELSE
        Invoke MUITrayMenuSetTrayIconText, hMUITMMEM, Addr szMemLoadPercent, hFontMEM, MUI_RGBCOLOR(96,176,207)
    .ENDIF
    mov hIconMEM, rax ; save returned icon handle for later
    
;    Invoke lstrcpy, Addr szMEMToolTip, Addr szMEMTip
;    Invoke lstrcat, Addr szMEMToolTip, Addr szMemLoadPercent
;    Invoke lstrcat, Addr szMEMToolTip, Addr szPercentage
;    Invoke MUITrayMenuSetTooltipText, hMUITMMEM, Addr szMEMToolTip
    
    ret
GetMemoryLoad ENDP



end WinMainCRTStartup

