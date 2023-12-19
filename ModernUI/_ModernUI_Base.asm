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


; Prototypes for internal use
_MUIGetPropertyA PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
_MUISetPropertyA PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
_MUIGetPropertyW PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
_MUISetPropertyW PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE

.CODE


;==============================================================================
; ANSI
;==============================================================================


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets the pointer to memory allocated to control at startup and stored in 
; cbWinExtra adds the offset to property to this pointer and fetches value at 
; this location and returns it in rax.
;
; Properties are defined as constants, which are used as offsets in memory to 
; the data alloc'd, for example: @MouseOver EQU 0, @SelectedState EQU 8
; we might specify 16 in cbWndExtra and then GlobalAlloc 16 bytes of data to 
; control at startup and store this pointer with:
;
;   Invoke SetWindowLongPtr, hWin, 0, pMem
;
; pMem is our pointer to our 16 bytes of storage, of which first eight bytes 
; (qword) is used for our @MouseOver property and the next qword for 
; @SelectedState 
;
; Added extra option to check if Property is OR'd with MUI_PROPERTY_ADDRESS
; then return address of property
;
;------------------------------------------------------------------------------
_MUIGetPropertyA PROC FRAME USES RBX hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
    Invoke GetWindowLongPtrA, hWin, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF
    mov rbx, rax
    add rbx, Property
    ;mov rax, Property
    ;and rax, MUI_PROPERTY_ADDRESS
    ;.IF rax == MUI_PROPERTY_ADDRESS
    ;    mov rax, rbx ; return address of the property in rax
    ;.ELSE
        mov rax, [rbx] ; return in rax the contents of the property at address in rbx
    ;.ENDIF
    ret
_MUIGetPropertyA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets property value and returns previous value in rax.
;------------------------------------------------------------------------------
_MUISetPropertyA PROC FRAME USES RBX hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    LOCAL qwPrevValue:QWORD
    Invoke GetWindowLongPtrA, hWin, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF    
    mov rbx, rax
    add rbx, Property
    mov rax, [rbx]
    mov qwPrevValue, rax    
    mov rax, PropertyValue
    mov [rbx], rax
    mov rax, qwPrevValue
    ret
_MUISetPropertyA ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Gets the pointer to memory allocated to control at startup and stored in 
; cbWinExtra adds the offset to property to this pointer and fetches value at 
; this location and returns it in rax.
;
; Properties are defined as constants, which are used as offsets in memory to 
; the; data alloc'd, for example: @MouseOver EQU 0, @SelectedState EQU 8
; we might specify 16 in cbWndExtra and then GlobalAlloc 16 bytes of data to 
; control at startup and store this pointer with:
; 
;   Invoke SetWindowLongPtr, hWin, 0, pMem
;
; pMem is our pointer to our 16 bytes of storage, of which first eight bytes 
; (qword) is used for our @MouseOver property and the next qword for 
; @SelectedState
; 
; Added extra option to check if Property is OR'd with MUI_PROPERTY_ADDRESS
; then return address of property
;
; Added public versions of these to allow for adjustment of the base address
; to fetch the internal or external property structures from. This is for
; example where we have to deal with a superclassed control based on an existing
; control that has its own cbWndExtra bytes, which we must preserve.
; Use GetClassInfoEx to determine the offset to account for theses bytes to
; add to the cbWndExtraOffset parameter to correctly address alloc mem.
; MUIAllocMemProperties also must be adjusted by this offset to preserve the
; extra bytes for the base class being superclassed
;------------------------------------------------------------------------------
MUIGetPropertyA PROC FRAME hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
    Invoke _MUIGetPropertyA, hWin, cbWndExtraOffset, Property ; get properties
    ret
MUIGetPropertyA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetPropertyA PROC FRAME hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyA, hWin, cbWndExtraOffset, Property, PropertyValue ; set properties
    ret
MUISetPropertyA endp


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets external property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetExtPropertyA PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyA, hWin, MUI_EXTERNAL_PROPERTIES, Property ; get external properties
    ret
MUIGetExtPropertyA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets external property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetExtProperty PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyA, hWin, MUI_EXTERNAL_PROPERTIES, Property, PropertyValue ; set external properties
    ret
MUISetExtProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets internal property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetIntPropertyA PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyA, hWin, MUI_INTERNAL_PROPERTIES, Property ; get internal properties
    ret
MUIGetIntPropertyA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets internal property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetIntPropertyA PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyA, hWin, MUI_INTERNAL_PROPERTIES, Property, PropertyValue ; set internal properties
    ret
MUISetIntPropertyA ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Gets child external property value and returns it in rax
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUIGetExtPropertyExA PROC FRAME hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY
    Invoke _MUIGetPropertyA, hWin, MUI_EXTERNAL_PROPERTIES, ParentProperty ; get parent external properties
    .IF rax != 0
        add rax, ChildProperty
        mov rax, [rax]
    .ENDIF
    ret
MUIGetExtPropertyExA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets child external property value
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUISetExtPropertyEx PROC FRAME USES RBX hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    LOCAL qwPrevValue:QWORD
    Invoke _MUIGetPropertyA, hWin, MUI_EXTERNAL_PROPERTIES, ParentProperty ; get parent external properties
    .IF rax != 0
        mov rbx, rax
        add rbx, ChildProperty
        mov rax, [rax]
        mov qwPrevValue, rax
        mov rax, PropertyValue
        mov [rbx], rax
        mov rax, qwPrevValue
    .ENDIF
    ret
MUISetExtPropertyEx ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets child internal property value and returns it in rax
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUIGetIntPropertyExA PROC FRAME hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY
    Invoke _MUIGetPropertyA, hWin, MUI_INTERNAL_PROPERTIES, ParentProperty ; get parent internal properties
    .IF rax != 0
        add rax, ChildProperty
        mov rax, [rax]
    .ENDIF
    ret
MUIGetIntPropertyExA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets child internal property value
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUISetIntPropertyExA PROC FRAME USES RBX hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    LOCAL qwPrevValue:QWORD
    Invoke _MUIGetPropertyA, hWin, MUI_INTERNAL_PROPERTIES, ParentProperty ; get parent internal properties
    .IF rax != 0
        mov rbx, rax
        add rbx, ChildProperty
        mov rax, [rax]
        mov qwPrevValue, rax
        mov rax, PropertyValue
        mov [rbx], rax
        mov rax, qwPrevValue
    .ENDIF
    ret
MUISetIntPropertyExA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets Extra external property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetExtPropertyExtraA PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyA, hWin, MUI_EXTERNAL_PROPERTIES_EXTRA, Property ; get extra external properties
    ret
MUIGetExtPropertyExtraA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets Extra external property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetExtPropertyExtraA PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyA, hWin, MUI_EXTERNAL_PROPERTIES_EXTRA, Property, PropertyValue ; set extra external properties
    ret
MUISetExtPropertyExtraA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets Extra internal property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetIntPropertyExtraA PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyA, hWin, MUI_INTERNAL_PROPERTIES_EXTRA, Property ; get extra internal properties
    ret
MUIGetIntPropertyExtraA ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets Extra internal property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetIntPropertyExtraA PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyA, hWin, MUI_INTERNAL_PROPERTIES_EXTRA, Property, PropertyValue ; set extra internal properties
    ret
MUISetIntPropertyExtraA ENDP


;==============================================================================
; UNICODE
;==============================================================================

MUI_ALIGN
;------------------------------------------------------------------------------
; Gets the pointer to memory allocated to control at startup and stored in 
; cbWinExtra adds the offset to property to this pointer and fetches value at 
; this location and returns it in rax.
;
; Properties are defined as constants, which are used as offsets in memory to 
; the data alloc'd, for example: @MouseOver EQU 0, @SelectedState EQU 8
; we might specify 16 in cbWndExtra and then GlobalAlloc 16 bytes of data to 
; control at startup and store this pointer with:
;
;   Invoke SetWindowLongPtr, hWin, 0, pMem
;
; pMem is our pointer to our 16 bytes of storage, of which first eight bytes 
; (qword) is used for our @MouseOver property and the next qword for 
; @SelectedState 
;
; Added extra option to check if Property is OR'd with MUI_PROPERTY_ADDRESS
; then return address of property
;
;------------------------------------------------------------------------------
_MUIGetPropertyW PROC FRAME USES RBX hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
    Invoke GetWindowLongPtrW, hWin, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF
    mov rbx, rax
    add rbx, Property
    ;mov rax, Property
    ;and rax, MUI_PROPERTY_ADDRESS
    ;.IF rax == MUI_PROPERTY_ADDRESS
    ;    mov rax, rbx ; return address of the property in rax
    ;.ELSE
        mov rax, [rbx] ; return in rax the contents of the property at address in rbx
    ;.ENDIF
    ret
_MUIGetPropertyW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets property value and returns previous value in rax.
;------------------------------------------------------------------------------
_MUISetPropertyW PROC FRAME USES RBX hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    LOCAL qwPrevValue:QWORD
    Invoke GetWindowLongPtrW, hWin, cbWndExtraOffset
    .IF rax == 0
        ret
    .ENDIF    
    mov rbx, rax
    add rbx, Property
    mov rax, [rbx]
    mov qwPrevValue, rax
    mov rax, PropertyValue
    mov [rbx], rax
    mov rax, qwPrevValue
    ret
_MUISetPropertyW ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Gets the pointer to memory allocated to control at startup and stored in 
; cbWinExtra adds the offset to property to this pointer and fetches value at 
; this location and returns it in rax.
;
; Properties are defined as constants, which are used as offsets in memory to 
; the; data alloc'd, for example: @MouseOver EQU 0, @SelectedState EQU 8
; we might specify 16 in cbWndExtra and then GlobalAlloc 16 bytes of data to 
; control at startup and store this pointer with:
; 
;   Invoke SetWindowLongPtr, hWin, 0, pMem
;
; pMem is our pointer to our 16 bytes of storage, of which first eight bytes 
; (qword) is used for our @MouseOver property and the next qword for 
; @SelectedState
; 
; Added extra option to check if Property is OR'd with MUI_PROPERTY_ADDRESS
; then return address of property
;
; Added public versions of these to allow for adjustment of the base address
; to fetch the internal or external property structures from. This is for
; example where we have to deal with a superclassed control based on an existing
; control that has its own cbWndExtra bytes, which we must preserve.
; Use GetClassInfoEx to determine the offset to account for theses bytes to
; add to the cbWndExtraOffset parameter to correctly address alloc mem.
; MUIAllocMemProperties also must be adjusted by this offset to preserve the
; extra bytes for the base class being superclassed
;------------------------------------------------------------------------------
MUIGetPropertyW PROC FRAME hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
    Invoke _MUIGetPropertyW, hWin, cbWndExtraOffset, Property ; get properties
    ret
MUIGetPropertyW ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Sets property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetPropertyW PROC FRAME hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyW, hWin, cbWndExtraOffset, Property, PropertyValue ; set properties
    ret
MUISetPropertyW ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; Gets external property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetExtPropertyW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyW, hWin, MUI_EXTERNAL_PROPERTIES, Property ; get external properties
    ret
MUIGetExtPropertyW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets external property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetExtPropertyW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyW, hWin, MUI_EXTERNAL_PROPERTIES, Property, PropertyValue ; set external properties
    ret
MUISetExtPropertyW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets internal property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetIntPropertyW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyW, hWin, MUI_INTERNAL_PROPERTIES, Property ; get internal properties
    ret
MUIGetIntPropertyW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets internal property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetIntPropertyW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyW, hWin, MUI_INTERNAL_PROPERTIES, Property, PropertyValue ; set internal properties
    ret
MUISetIntPropertyW ENDP



MUI_ALIGN
;------------------------------------------------------------------------------
; Gets child external property value and returns it in rax
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUIGetExtPropertyExW PROC FRAME hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY
    Invoke _MUIGetPropertyW, hWin, MUI_EXTERNAL_PROPERTIES, ParentProperty ; get parent external properties
    .IF rax != 0
        add rax, ChildProperty
        mov rax, [rax]
    .ENDIF
    ret
MUIGetExtPropertyExW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets child external property value
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUISetExtPropertyExW PROC FRAME USES RBX hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    LOCAL qwPrevValue:QWORD
    Invoke _MUIGetPropertyW, hWin, MUI_EXTERNAL_PROPERTIES, ParentProperty ; get parent external properties
    .IF rax != 0
        mov rbx, rax
        add rbx, ChildProperty
        mov rax, [rax]
        mov qwPrevValue, rax
        mov rax, PropertyValue
        mov [rbx], rax
        mov rax, qwPrevValue
    .ENDIF
    ret
MUISetExtPropertyExW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets child internal property value and returns it in rax
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUIGetIntPropertyExW PROC FRAME hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY
    Invoke _MUIGetPropertyW, hWin, MUI_INTERNAL_PROPERTIES, ParentProperty ; get parent internal properties
    .IF rax != 0
        add rax, ChildProperty
        mov rax, [rax]
    .ENDIF
    ret
MUIGetIntPropertyExW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets child internal property value
; For properties (parent) in main ModernUI controls that store pointers to 
; another (child) defined properties structure
;------------------------------------------------------------------------------
MUISetIntPropertyExW PROC FRAME USES RBX hWin:MUIWND, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    LOCAL qwPrevValue:QWORD
    Invoke _MUIGetPropertyW, hWin, MUI_INTERNAL_PROPERTIES, ParentProperty ; get parent internal properties
    .IF rax != 0
        mov rbx, rax
        add rbx, ChildProperty
        mov rax, [rax]
        mov qwPrevValue, rax
        mov rax, PropertyValue
        mov [rbx], rax
        mov rax, qwPrevValue
    .ENDIF
    ret
MUISetIntPropertyExW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets Extra external property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetExtPropertyExtraW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyW, hWin, MUI_EXTERNAL_PROPERTIES_EXTRA, Property ; get extra external properties
    ret
MUIGetExtPropertyExtraW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets Extra external property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetExtPropertyExtraW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyW, hWin, MUI_EXTERNAL_PROPERTIES_EXTRA, Property, PropertyValue ; set extra external properties
    ret
MUISetExtPropertyExtraW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Gets Extra internal property value and returns it in rax
;------------------------------------------------------------------------------
MUIGetIntPropertyExtraW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY
    Invoke _MUIGetPropertyW, hWin, MUI_INTERNAL_PROPERTIES_EXTRA, Property ; get extra internal properties
    ret
MUIGetIntPropertyExtraW ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Sets Extra internal property value and returns previous value in rax.
;------------------------------------------------------------------------------
MUISetIntPropertyExtraW PROC FRAME hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
    Invoke _MUISetPropertyW, hWin, MUI_INTERNAL_PROPERTIES_EXTRA, Property, PropertyValue ; set extra internal properties
    ret
MUISetIntPropertyExtraW ENDP























MODERNUI_LIBEND



