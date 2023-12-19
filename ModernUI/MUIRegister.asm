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



.CODE

MUI_ALIGN
;------------------------------------------------------------------------------
; Register a windows class (ANSI version)
;
; lpszClassName     - string containing the class name to register
; lpClassWndProc    - pointer to the main window procedure to use for the class
; lpCursorName      - id as LoadCursor to use for cursor, or IDC_ARROW as default
; cbWndExtra        - amount of extra bytes needed for the class - for MUI controls
;                     typically 8 bytes, first dword for internal properties 
;                     structure allocated in memory via MUIAllocMemProperties, 
;                     and second dword for external properties structure 
;                     allocated in memory via MUIAllocMemProperties.
;
;------------------------------------------------------------------------------
MUIRegisterA PROC FRAME lpszClassName:MUILPSTRING, lpClassWndProc:POINTER, lpCursorName:MUIVALUE, cbWndExtra:MUIVALUE
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
	.IF lpszClassName == NULL || lpClassWndProc == NULL
	    mov rax, FALSE
	    ret
	.ENDIF
	
    Invoke GetModuleHandleA, NULL
    mov hinstance, rax
    
    mov wc.cbSize, SIZEOF WNDCLASSEX
    Invoke GetClassInfoExA, hinstance, lpszClassName, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize, SIZEOF WNDCLASSEX
        mov rax, lpszClassName
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
        mov rax, lpClassWndProc
    	mov wc.lpfnWndProc, rax
    	.IF lpCursorName != NULL
    	    Invoke LoadCursorA, NULL, lpCursorName
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
        mov rax, cbWndExtra
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
MUIRegisterA ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Register a windows class (UNICODE version)
;
; lpszClassName     - string containing the class name to register
; lpClassWndProc    - pointer to the main window procedure to use for the class
; lpCursorName      - id as LoadCursor to use for cursor, or IDC_ARROW as default
; cbWndExtra        - amount of extra bytes needed for the class - for MUI controls
;                     typically 8 bytes, first dword for internal properties 
;                     structure allocated in memory via MUIAllocMemProperties, 
;                     and second dword for external properties structure 
;                     allocated in memory via MUIAllocMemProperties.
;
;------------------------------------------------------------------------------
MUIRegisterW PROC FRAME lpszClassName:MUILPSTRING, lpClassWndProc:POINTER, lpCursorName:MUIVALUE, cbWndExtra:MUIVALUE
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
	.IF lpszClassName == NULL || lpClassWndProc == NULL
	    mov rax, FALSE
	    ret
	.ENDIF
	
    Invoke GetModuleHandleW, NULL
    mov hinstance, rax
    
    mov wc.cbSize, SIZEOF WNDCLASSEX
    Invoke GetClassInfoExW, hinstance, lpszClassName, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize, SIZEOF WNDCLASSEX
        mov rax, lpszClassName
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
        mov rax, lpClassWndProc
    	mov wc.lpfnWndProc, rax
    	.IF lpCursorName != NULL
    	    Invoke LoadCursorW, NULL, lpCursorName
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
        mov rax, cbWndExtra
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
MUIRegisterW ENDP


MODERNUI_LIBEND