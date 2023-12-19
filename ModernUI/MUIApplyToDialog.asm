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

include ModernUI.inc


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Applies the ModernUI style to a dialog to make it a captionless, borderless 
; form. User can manually change a form in a resource editor to have the 
; following style flags: WS_POPUP or WS_VISIBLE and optionally with DS_CENTER,
; DS_CENTERMOUSE, WS_CLIPCHILDREN, WS_CLIPSIBLINGS, WS_MINIMIZE, WS_MAXIMIZE
;------------------------------------------------------------------------------
MUIApplyToDialogA PROC FRAME hWin:MUIWND, bDropShadow:BOOL, bClipping:BOOL
    LOCAL qwStyle:QWORD
    LOCAL qwNewStyle:QWORD
    LOCAL qwClassStyle:QWORD
    
    mov qwNewStyle, WS_POPUP
    
    Invoke GetWindowLongPtrA, hWin, GWL_STYLE
    mov qwStyle, rax
    
    and rax, DS_CENTER
    .IF rax == DS_CENTER
        or qwNewStyle, DS_CENTER
    .ENDIF
    
    mov rax, qwStyle
    and rax, DS_CENTERMOUSE
    .IF rax == DS_CENTERMOUSE
        or qwNewStyle, DS_CENTERMOUSE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_VISIBLE
    .IF rax == WS_VISIBLE
        or qwNewStyle, WS_VISIBLE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_MINIMIZE
    .IF rax == WS_MINIMIZE
        or qwNewStyle, WS_MINIMIZE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_MAXIMIZE
    .IF rax == WS_MAXIMIZE
        or qwNewStyle, WS_MAXIMIZE
    .ENDIF        

    mov rax, qwStyle
    and rax, WS_CLIPSIBLINGS
    .IF rax == WS_CLIPSIBLINGS
        or qwNewStyle, WS_CLIPSIBLINGS
    .ENDIF        
    
    .IF bClipping == TRUE
        mov rax, qwStyle
        and rax, WS_CLIPSIBLINGS
        .IF rax == WS_CLIPSIBLINGS
            or qwNewStyle, WS_CLIPSIBLINGS
        .ENDIF        
        or qwNewStyle, WS_CLIPCHILDREN
    .ENDIF

    Invoke SetWindowLongPtrA, hWin, GWL_STYLE, qwNewStyle
    
    ; Set dropshadow on or off on our dialog
    
    Invoke GetClassLongPtrA, hWin, GCL_STYLE
    mov qwClassStyle, rax
    
    .IF bDropShadow == TRUE
        mov rax, qwClassStyle
        and rax, CS_DROPSHADOW
        .IF rax != CS_DROPSHADOW
            or qwClassStyle, CS_DROPSHADOW
            Invoke SetClassLongPtrA, hWin, GCL_STYLE, qwClassStyle
        .ENDIF
    .ELSE    
        mov rax, qwClassStyle
        and rax, CS_DROPSHADOW
        .IF rax == CS_DROPSHADOW
            and qwClassStyle,(-1 xor CS_DROPSHADOW)
            Invoke SetClassLongPtrA, hWin, GCL_STYLE, qwClassStyle
        .ENDIF
    .ENDIF

    ; remove any menu that might have been assigned via class registration - for modern ui look
    Invoke GetMenu, hWin
    .IF rax != NULL
        Invoke SetMenu, hWin, NULL
    .ENDIF
    
    ret
MUIApplyToDialogA ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Applies the ModernUI style to a dialog to make it a captionless, borderless 
; form. User can manually change a form in a resource editor to have the 
; following style flags: WS_POPUP or WS_VISIBLE and optionally with DS_CENTER,
; DS_CENTERMOUSE, WS_CLIPCHILDREN, WS_CLIPSIBLINGS, WS_MINIMIZE, WS_MAXIMIZE
;------------------------------------------------------------------------------
MUIApplyToDialogW PROC FRAME hWin:MUIWND, bDropShadow:BOOL, bClipping:BOOL
    LOCAL qwStyle:QWORD
    LOCAL qwNewStyle:QWORD
    LOCAL qwClassStyle:QWORD
    
    mov qwNewStyle, WS_POPUP
    
    Invoke GetWindowLongPtrW, hWin, GWL_STYLE
    mov qwStyle, rax
    
    and rax, DS_CENTER
    .IF rax == DS_CENTER
        or qwNewStyle, DS_CENTER
    .ENDIF
    
    mov rax, qwStyle
    and rax, DS_CENTERMOUSE
    .IF rax == DS_CENTERMOUSE
        or qwNewStyle, DS_CENTERMOUSE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_VISIBLE
    .IF rax == WS_VISIBLE
        or qwNewStyle, WS_VISIBLE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_MINIMIZE
    .IF rax == WS_MINIMIZE
        or qwNewStyle, WS_MINIMIZE
    .ENDIF
    
    mov rax, qwStyle
    and rax, WS_MAXIMIZE
    .IF rax == WS_MAXIMIZE
        or qwNewStyle, WS_MAXIMIZE
    .ENDIF        

    mov rax, qwStyle
    and rax, WS_CLIPSIBLINGS
    .IF rax == WS_CLIPSIBLINGS
        or qwNewStyle, WS_CLIPSIBLINGS
    .ENDIF        
    
    .IF bClipping == TRUE
        mov rax, qwStyle
        and rax, WS_CLIPSIBLINGS
        .IF rax == WS_CLIPSIBLINGS
            or qwNewStyle, WS_CLIPSIBLINGS
        .ENDIF        
        or qwNewStyle, WS_CLIPCHILDREN
    .ENDIF

    Invoke SetWindowLongPtrW, hWin, GWL_STYLE, qwNewStyle
    
    ; Set dropshadow on or off on our dialog
    
    Invoke GetClassLongPtrW, hWin, GCL_STYLE
    mov qwClassStyle, rax
    
    .IF bDropShadow == TRUE
        mov rax, qwClassStyle
        and rax, CS_DROPSHADOW
        .IF rax != CS_DROPSHADOW
            or qwClassStyle, CS_DROPSHADOW
            Invoke SetClassLongPtrW, hWin, GCL_STYLE, qwClassStyle
        .ENDIF
    .ELSE    
        mov rax, qwClassStyle
        and rax, CS_DROPSHADOW
        .IF rax == CS_DROPSHADOW
            and qwClassStyle,(-1 xor CS_DROPSHADOW)
            Invoke SetClassLongPtrW, hWin, GCL_STYLE, qwClassStyle
        .ENDIF
    .ENDIF

    ; remove any menu that might have been assigned via class registration - for modern ui look
    Invoke GetMenu, hWin
    .IF rax != NULL
        Invoke SetMenu, hWin, NULL
    .ENDIF
    
    ret
MUIApplyToDialogW ENDP




MODERNUI_LIBEND



