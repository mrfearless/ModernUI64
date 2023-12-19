;==============================================================================
;
; ModernUI Library x64
;
; Copyright (c) 2023 by fearless
;
; All Rights Reserved
;
; http://github.com/mrfearless/ModernUI64
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

include windows.inc
includelib user32.lib
includelib Kernel32.Lib

include ModernUI.inc


.CONST

.DATA
ExistingClassWndProc    DQ 0

.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Superclass an existing control and registers the new superclass (ANSI version)
; https://learn.microsoft.com/en-us/windows/win32/winmsg/about-window-procedures#window-procedure-superclassing
;
; lpszExistingClassName     - string containing the existing class name to superclass
; lpdwExistingClassWndProc  - pointer to a dword to store the existing class's 
;                             main window procedure
; lpszSuperclassName        - string containing the new superclass name to register
; lpSuperclassWndProc       - pointer to the main window procedure to use for the
;                             new superclass
; lpSuperclassCursorName    - id as LoadCursor to use for cursor, or IDC_ARROW 
;                             as default
; cbSuperclassWndExtra      - amount of extra bytes needed for the superclass. 
;                             For MUI controls typically 8 bytes, first dword 
;                             for internal properties structure allocated in 
;                             memory via MUIAllocMemProperties, and second dword
;                             for external properties structure allocated in 
;                             memory via MUIAllocMemProperties.
; lpcbWndExtraOffset        - pointer to a dword to store the cbWndExtra bytes 
;                             used by the base existing class. Use MUIGetProperty
;                             and MUISetProperty functions and add the extra 
;                             base class bytes to the cbWndExtraOffset parameter
;
;------------------------------------------------------------------------------
MUISuperclassA PROC FRAME USES RBX lpszExistingClassName:MUILPSTRING, lpdwExistingClassWndProc:POINTER, lpszSuperclassName:MUILPSTRING, lpSuperclassWndProc:POINTER, lpSuperclassCursorName:MUIVALUE, cbSuperclassWndExtra:MUIVALUE, lpcbWndExtraOffset:LPMUIVALUE
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
	.IF lpszExistingClassName == NULL || lpdwExistingClassWndProc == NULL || lpszSuperclassName == NULL || lpSuperclassWndProc == NULL
	    mov rax, FALSE
	    ret
	.ENDIF
	
    Invoke GetModuleHandleA, NULL
    mov hinstance, rax
    
    mov wc.cbSize, SIZEOF WNDCLASSEX
    Invoke GetClassInfoExA, hinstance, lpszSuperclassName, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize, SIZEOF WNDCLASSEX
        ; get existing class information first
        Invoke GetClassInfoExA, hinstance, lpszExistingClassName, Addr wc
        mov wc.cbSize, SIZEOF WNDCLASSEX
        ; Change to our superclass
        mov rax, lpszSuperclassName
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
        .IF lpdwExistingClassWndProc != NULL
            ; ideally return the old window proc
            mov rax, wc.lpfnWndProc
            mov rbx, lpdwExistingClassWndProc
            mov [rbx], rax
        .ELSE
            ; else store old window proc in our global var
            mov rax, wc.lpfnWndProc
            mov ExistingClassWndProc, rax
        .ENDIF
        ; point to our superclass proc to use instead
        mov rax, lpSuperclassWndProc
    	mov wc.lpfnWndProc, rax
    	; Load a custom cursor if specified
    	.IF lpSuperclassCursorName != NULL
    	    Invoke LoadCursorA, NULL, lpSuperclassCursorName
    	.ELSE
    	    Invoke LoadCursorA, NULL, IDC_ARROW
        .ENDIF
    	mov wc.hCursor, rax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, NULL
        mov wc.cbClsExtra, 0
        ; Find out the base bytes used by the existing class in cbWndExtra
        mov eax, wc.cbWndExtra
        .IF lpcbWndExtraOffset != NULL
            ; store the base bytes used by the existing class as an offset into cbWndExtra
            mov rbx, lpcbWndExtraOffset
            mov [rbx], rax
        .ENDIF
        ; Add our own extra bytes required
        add rax, cbSuperclassWndExtra
    	mov wc.cbWndExtra, eax
    	Invoke RegisterClassExA, Addr wc
    	.IF rax == FALSE
    	.ELSE
    	    mov rax, TRUE
    	.ENDIF
    .ELSE
        mov rax, TRUE
    .ENDIF 

    ret
MUISuperclassA ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Superclass an existing control and registers the new superclass (UNICODE version)
; https://learn.microsoft.com/en-us/windows/win32/winmsg/about-window-procedures#window-procedure-superclassing
;
; lpszExistingClassName     - string containing the existing class name to superclass
; lpdwExistingClassWndProc  - pointer to a dword to store the existing class's 
;                             main window procedure
; lpszSuperclassName        - string containing the new superclass name to register
; lpSuperclassWndProc       - pointer to the main window procedure to use for the
;                             new superclass
; lpSuperclassCursorName    - id as LoadCursor to use for cursor, or IDC_ARROW 
;                             as default
; cbSuperclassWndExtra      - amount of extra bytes needed for the superclass. 
;                             For MUI controls typically 8 bytes, first dword 
;                             for internal properties structure allocated in 
;                             memory via MUIAllocMemProperties, and second dword
;                             for external properties structure allocated in 
;                             memory via MUIAllocMemProperties.
; lpcbWndExtraOffset        - pointer to a dword to store the cbWndExtra bytes 
;                             used by the base existing class. Use MUIGetProperty
;                             and MUISetProperty functions and add the extra 
;                             base class bytes to the cbWndExtraOffset parameter
;
;------------------------------------------------------------------------------
MUISuperclassW PROC FRAME USES RBX lpszExistingClassName:MUILPSTRING, lpdwExistingClassWndProc:POINTER, lpszSuperclassName:MUILPSTRING, lpSuperclassWndProc:POINTER, lpSuperclassCursorName:MUIVALUE, cbSuperclassWndExtra:MUIVALUE, lpcbWndExtraOffset:LPMUIVALUE
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
	.IF lpszExistingClassName == NULL || lpdwExistingClassWndProc == NULL || lpszSuperclassName == NULL || lpSuperclassWndProc == NULL
	    mov rax, FALSE
	    ret
	.ENDIF
	
    Invoke GetModuleHandleW, NULL
    mov hinstance, rax
    
    mov wc.cbSize, SIZEOF WNDCLASSEX
    Invoke GetClassInfoExW, hinstance, lpszSuperclassName, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize, SIZEOF WNDCLASSEX
        ; get existing class information first
        Invoke GetClassInfoExW, hinstance, lpszExistingClassName, Addr wc
        mov wc.cbSize, SIZEOF WNDCLASSEX
        ; Change to our superclass
        mov rax, lpszSuperclassName
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
        .IF lpdwExistingClassWndProc != NULL
            ; ideally return the old window proc
            mov rax, wc.lpfnWndProc
            mov rbx, lpdwExistingClassWndProc
            mov [rbx], rax
        .ELSE
            ; else store old window proc in our global var
            mov rax, wc.lpfnWndProc
            mov ExistingClassWndProc, rax
        .ENDIF
        ; point to our superclass proc to use instead
        mov rax, lpSuperclassWndProc
    	mov wc.lpfnWndProc, rax
    	; Load a custom cursor if specified
    	.IF lpSuperclassCursorName != NULL
    	    Invoke LoadCursorW, NULL, lpSuperclassCursorName
    	.ELSE
    	    Invoke LoadCursorW, NULL, IDC_ARROW
        .ENDIF
    	mov wc.hCursor, rax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, NULL
        mov wc.cbClsExtra, 0
        ; Find out the base bytes used by the existing class in cbWndExtra
        mov eax, wc.cbWndExtra
        .IF lpcbWndExtraOffset != NULL
            ; store the base bytes used by the existing class as an offset into cbWndExtra
            mov rbx, lpcbWndExtraOffset
            mov [rbx], rax
        .ENDIF
        ; Add our own extra bytes required
        add rax, cbSuperclassWndExtra
    	mov wc.cbWndExtra, eax
    	Invoke RegisterClassExW, Addr wc
    	.IF rax == FALSE
    	.ELSE
    	    mov rax, TRUE
    	.ENDIF
    .ELSE
        mov rax, TRUE
    .ENDIF 

    ret
MUISuperclassW ENDP




MODERNUI_LIBEND

