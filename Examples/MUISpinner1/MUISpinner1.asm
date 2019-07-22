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

include MUISpinner1.inc

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
    
    Invoke MUIGDIPlusStart
	Invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
	Invoke MUIGDIPlusFinish
	
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
	mov wcex.hbrBackground, COLOR_BTNFACE+1 ;COLOR_WINDOW+1
	mov wcex.lpszMenuName, IDM_MENU ;NULL 
	lea rax, ClassName
	mov wcex.lpszClassName, rax
	Invoke LoadIcon, hInst, ICO_MAIN ; resource icon for main application icon
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
        
        ;-----------------------------------------------------------------------------
        ; ModernUI_CaptionBar
        ;-----------------------------------------------------------------------------
        Invoke MUIApplyToDialog, hWin, TRUE, TRUE
        Invoke MUICaptionBarCreate, hWin, Addr AppName, 32, IDC_CAPTIONBAR, MUICS_NOMAXBUTTON or MUICS_LEFT or MUICS_REDCLOSEBUTTON;MUICS_LEFT or MUICS_REDCLOSEBUTTON
        mov hCaptionBar, rax
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBackColor, MUI_RGBCOLOR(27,161,226)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnTxtRollColor, MUI_RGBCOLOR(61,61,61)
        Invoke MUICaptionBarSetProperty, hCaptionBar, @CaptionBarBtnBckRollColor, MUI_RGBCOLOR(87,193,244)      
        
        ;-----------------------------------------------------------------------------
        ; ModernUI_Spinner Examples. For example spinners see: 
        ; - https://icons8.com/preloaders/en/circular# 
        ; - https://icons8.com/preloaders/en/search/spinner
        ;-----------------------------------------------------------------------------
        
        ;-----------------------------------------------------------------------------
        ; Create our ModernUI_Spinner control using 8 bmps: grey square spinner
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 50, 50, 32, 32, IDC_SPINNER1, MUISPNS_HAND
        mov hSpinner1, rax
        ; Load spinner frames as bitmaps stored as resources
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN1
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN2
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN3
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN4
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN5
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN6
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN7
        Invoke MUISpinnerLoadFrame, hSpinner1, MUISPIT_BMP, BMP_SPIN8
        ; Start the spinner animating
        Invoke MUISpinnerEnable, hSpinner1
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: small segment fading
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 100, 50, 32, 32, IDC_SPINNER2, MUISPNS_HAND
        mov hSpinner2, rax
        ; Load single png stored as a resource and rotate it into 12 segments
        Invoke MUISpinnerLoadImage, hSpinner2, PNG_SPIN2, 12, FALSE
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinner2, @SpinnerSpeed, 150
        Invoke MUISpinnerEnable, hSpinner2
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: faded circle
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 200, 50, 64, 64, IDC_SPINNER3, MUISPNS_HAND
        mov hSpinner3, rax
        ; Load single png stored as a resource and rotate it into 60 segments
        Invoke MUISpinnerLoadImage, hSpinner3, PNG_SPIN3, 60, TRUE ; spin backwards
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinner3, @SpinnerSpeed, 50
        Invoke MUISpinnerEnable, hSpinner3
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: 3 recycle green arrows
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 300, 50, 64, 64, IDC_SPINNER4, MUISPNS_HAND
        mov hSpinner4, rax
        ; Load single png stored as a resource and rotate it into 60 segments
        Invoke MUISpinnerLoadImage, hSpinner4, PNG_SPIN4, 60, FALSE
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinner4, @SpinnerSpeed, 20
        Invoke MUISpinnerEnable, hSpinner4
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: 12 segments fading
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 400, 50, 64, 64, IDC_SPINNER5, MUISPNS_HAND
        mov hSpinner5, rax
        ; Load single png stored as a resource and rotate it into 12 segments
        Invoke MUISpinnerLoadImage, hSpinner5, PNG_SPIN5, 12, FALSE
        Invoke MUISpinnerSetProperty, hSpinner5, @SpinnerSpeed, 500
        Invoke MUISpinnerEnable, hSpinner5
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: blue with arrows
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 100, 150, 64, 64, IDC_SPINNER6, MUISPNS_HAND
        mov hSpinner6, rax
        ; Load single png stored as a resource and rotate it into 30 segments
        Invoke MUISpinnerLoadImage, hSpinner6, PNG_SPIN6, 30, FALSE
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinner6, @SpinnerSpeed, 60
        Invoke MUISpinnerEnable, hSpinner6
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: large gear
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 200, 150, 64, 64, IDC_SPINNER7, 0; MUISPNS_HAND
        mov hSpinner7, rax
        ; Load single png stored as a resource and rotate it into 6 segments
        Invoke MUISpinnerLoadImage, hSpinner7, PNG_SPIN7, 6, FALSE ; gear
        Invoke MUISpinnerEnable, hSpinner7
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: small gear
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 264, 180, 32, 32, IDC_SPINNER7B, 0; MUISPNS_HAND
        mov hSpinner7b, rax
        ; Load single png stored as a resource and rotate it into 6 segments
        Invoke MUISpinnerLoadImage, hSpinner7b, PNG_SPIN7B, 6, TRUE ; small gear spin backwards
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinner7b, @SpinnerSpeed, 50
        Invoke MUISpinnerEnable, hSpinner7b        
        
        ;-----------------------------------------------------------------------------
        ; Spinner using single png file divided into x frames: 3 green arrows
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 330, 150, 48, 48, IDC_SPINNER8, MUISPNS_HAND
        mov hSpinner8, rax
        ; Load single png stored as a resource and rotate it into 60 segments
        Invoke MUISpinnerLoadImage, hSpinner8, PNG_SPIN8, 60, FALSE
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinner8, @SpinnerSpeed, 30
        Invoke MUISpinnerEnable, hSpinner8
        
        ;-----------------------------------------------------------------------------
        ; Spinner using 24 png files: small clock
        ;-----------------------------------------------------------------------------
        Invoke MUISpinnerCreate, hWin, 400, 150, 40, 40, IDC_SPINNER9, MUISPNS_HAND
        mov hSpinner9, rax
        ; Load spinner frames as pngs stored as resources
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK1
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK2
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK3
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK4
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK5
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK6
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK7
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK8
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK9
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK10
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK11
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK12
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK13
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK14
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK15
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK16
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK17
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK18
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK19
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK20
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK21
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK22
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK23
        Invoke MUISpinnerLoadFrame, hSpinner9, MUISPIT_PNG, PNG_CLOCK24
        Invoke MUISpinnerEnable, hSpinner9

        ;-----------------------------------------------------------------------------
        ; Spinner using a bmp spritesheet: clock 
        ;-----------------------------------------------------------------------------       
        Invoke MUISpinnerCreate, hWin, 100, 250, 72, 81, IDC_SPINNERSPRITE1, MUISPNS_HAND
        mov hSpinnerSprite1, rax
        ; Load spinner frames as a single spritesheet stored as a BITMAP resource
        ; Spritesheet contains 24 images stored as one long (wide) bitmap
        Invoke MUISpinnerLoadSpriteSheet, hSpinnerSprite1, 24, MUISPIT_BMP, BMP_CLOCK_SPRITESHEET, FALSE
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinnerSprite1, @SpinnerSpeed, 60
        Invoke MUISpinnerEnable, hSpinnerSprite1
        
        ;-----------------------------------------------------------------------------
        ; Spinner using a png spritesheet: clock spinning backwards
        ;-----------------------------------------------------------------------------        
        Invoke MUISpinnerCreate, hWin, 200, 250, 78, 81, IDC_SPINNERSPRITE2, MUISPNS_HAND
        mov hSpinnerSprite2, rax
        ; Load spinner frames as a single spritesheet stored as a PNG (RC_DATA) resource
        ; Spritesheet contains 24 images stored as one long (wide) png
        Invoke MUISpinnerLoadSpriteSheet, hSpinnerSprite2, 24, MUISPIT_PNG, PNG_CLOCK_SPRITESHEET, TRUE ; spin backwards
        Invoke MUISpinnerEnable, hSpinnerSprite2
        
        ;-----------------------------------------------------------------------------
        ; Spinner using a png spritesheet: infinity 
        ;-----------------------------------------------------------------------------       
        Invoke MUISpinnerCreate, hWin, 300, 250, 78, 81, IDC_SPINNERSPRITE3, MUISPNS_HAND
        mov hSpinnerSprite3, rax
        ; Load spinner frames as a single spritesheet stored as a PNG (RC_DATA) resource
        ; Spritesheet contains 20 images stored as one long (wide) png
        Invoke MUISpinnerLoadSpriteSheet, hSpinnerSprite3, 20, MUISPIT_PNG, PNG_INFINITY_SPRITESHEET, FALSE
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinnerSprite3, @SpinnerSpeed, 60
        Invoke MUISpinnerEnable, hSpinnerSprite3
        
        ;-----------------------------------------------------------------------------
        ; Spinner using a png spritesheet: green search with arrow 
        ;-----------------------------------------------------------------------------       
        Invoke MUISpinnerCreate, hWin, 400, 250, 78, 81, IDC_SPINNERSPRITE4, MUISPNS_HAND
        mov hSpinnerSprite4, rax
        ; Load spinner frames as a single spritesheet stored as a PNG (RC_DATA) resource
        ; Spritesheet contains 18 images stored as one long (wide) png
        Invoke MUISpinnerLoadSpriteSheet, hSpinnerSprite4, 18, MUISPIT_PNG, PNG_SEARCH_SPRITESHEET, FALSE
        ; Change spinner animatation speed
        Invoke MUISpinnerSetProperty, hSpinnerSprite4, @SpinnerSpeed, 100
        Invoke MUISpinnerEnable, hSpinnerSprite4
        
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
			
        .ELSEIF rax == IDC_SPINNER1
            .IF bSpinner1Pause == FALSE
                mov bSpinner1Pause, TRUE
                Invoke MUISpinnerPause, hSpinner1
            .ELSE
                mov bSpinner1Pause, FALSE
                Invoke MUISpinnerResume, hSpinner1
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNER2
            .IF bSpinner2Pause == FALSE
                mov bSpinner2Pause, TRUE
                Invoke MUISpinnerPause, hSpinner2
            .ELSE
                mov bSpinner2Pause, FALSE
                Invoke MUISpinnerResume, hSpinner2
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNER3
            .IF bSpinner3Pause == FALSE
                mov bSpinner3Pause, TRUE
                Invoke MUISpinnerPause, hSpinner3
            .ELSE
                mov bSpinner3Pause, FALSE
                Invoke MUISpinnerResume, hSpinner3
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNER4
            .IF bSpinner4Pause == FALSE
                mov bSpinner4Pause, TRUE
                Invoke MUISpinnerPause, hSpinner4
            .ELSE
                mov bSpinner4Pause, FALSE
                Invoke MUISpinnerResume, hSpinner4
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNER5
            .IF bSpinner5Pause == FALSE
                mov bSpinner5Pause, TRUE
                Invoke MUISpinnerPause, hSpinner5
            .ELSE
                mov bSpinner5Pause, FALSE
                Invoke MUISpinnerResume, hSpinner5
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNER6
            .IF bSpinner6Pause == FALSE
                mov bSpinner6Pause, TRUE
                Invoke MUISpinnerPause, hSpinner6
            .ELSE
                mov bSpinner6Pause, FALSE
                Invoke MUISpinnerResume, hSpinner6
            .ENDIF
            
;        .ELSEIF eax == IDC_SPINNER7
;            .IF bSpinner7Pause == FALSE
;                mov bSpinner7Pause, TRUE
;                Invoke MUISpinnerPause, hSpinner7
;            .ELSE
;                mov bSpinner7Pause, FALSE
;                Invoke MUISpinnerResume, hSpinner7
;            .ENDIF
;            
;        .ELSEIF eax == IDC_SPINNER7B
;            .IF bSpinner7bPause == FALSE
;                mov bSpinner7bPause, TRUE
;                Invoke MUISpinnerPause, hSpinner7b
;            .ELSE
;                mov bSpinner7bPause, FALSE
;                Invoke MUISpinnerResume, hSpinner7b
;            .ENDIF
            
        .ELSEIF rax == IDC_SPINNER8
            .IF bSpinner8Pause == FALSE
                mov bSpinner8Pause, TRUE
                Invoke MUISpinnerPause, hSpinner8
            .ELSE
                mov bSpinner8Pause, FALSE
                Invoke MUISpinnerResume, hSpinner8
            .ENDIF
        
        .ELSEIF rax == IDC_SPINNER9
            .IF bSpinner9Pause == FALSE
                mov bSpinner9Pause, TRUE
                Invoke MUISpinnerPause, hSpinner9
            .ELSE
                mov bSpinner9Pause, FALSE
                Invoke MUISpinnerResume, hSpinner9
            .ENDIF
        
        .ELSEIF rax == IDC_SPINNERSPRITE1
            .IF bSpinnerSprite1Pause == FALSE
                mov bSpinnerSprite1Pause, TRUE
                Invoke MUISpinnerPause, hSpinnerSprite1
            .ELSE
                mov bSpinnerSprite1Pause, FALSE
                Invoke MUISpinnerResume, hSpinnerSprite1
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNERSPRITE2
            .IF bSpinnerSprite2Pause == FALSE
                mov bSpinnerSprite2Pause, TRUE
                Invoke MUISpinnerPause, hSpinnerSprite2
            .ELSE
                mov bSpinnerSprite2Pause, FALSE
                Invoke MUISpinnerResume, hSpinnerSprite2
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNERSPRITE3
            .IF bSpinnerSprite3Pause == FALSE
                mov bSpinnerSprite3Pause, TRUE
                Invoke MUISpinnerPause, hSpinnerSprite3
            .ELSE
                mov bSpinnerSprite3Pause, FALSE
                Invoke MUISpinnerResume, hSpinnerSprite3
            .ENDIF
            
        .ELSEIF rax == IDC_SPINNERSPRITE4
            .IF bSpinnerSprite4Pause == FALSE
                mov bSpinnerSprite4Pause, TRUE
                Invoke MUISpinnerPause, hSpinnerSprite4
            .ELSE
                mov bSpinnerSprite4Pause, FALSE
                Invoke MUISpinnerResume, hSpinnerSprite4
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
