;==============================================================================
;
; ModernUI Library x64
;
; Copyright (c) 2019 by fearless
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
includelib kernel32.lib

include ModernUI.inc


.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Dynamically allocates or resizes a memory location based on items in a 
; structure and the size of the structure.
;
; StructMemPtr is an address to receive the pointer to memory location of the 
; base structure in memory.
;
; StructMemPtr can be NULL if TotalItems are 0. Otherwise it must contain the 
; address of the base structure in memory if the memory is to be increased, 
; TotalItems > 0
;
; ItemSize is typically SIZEOF structure to be allocated (this function calcs 
; for you the size * TotalItems)
;
; If StructMemPtr is NULL then memory object is initialized to the size of total
; items * itemsize and pointer to mem is returned in eax.
; 
; On return eax contains the pointer to the new structure item or -1 if there 
; was a problem alloc'ing memory.
;------------------------------------------------------------------------------
MUIAllocStructureMemory PROC FRAME USES RBX qwPtrStructMem:QWORD, TotalItems:QWORD, ItemSize:QWORD
    LOCAL StructDataOffset:QWORD
    LOCAL StructSize:QWORD
    LOCAL StructData:QWORD
    
    ;PrintText 'AllocStructureMemory'
    .IF TotalItems == 0
        Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, ItemSize ;
        .IF rax != NULL
            mov StructData, rax
            mov rbx, qwPtrStructMem
            mov [rbx], rax ; save pointer to memory alloc'd for structure
            mov StructDataOffset, 0 ; save offset for new entry
            ;IFDEF DEBUG32
            ;    PrintDec StructData
            ;ENDIF
        .ELSE
            IFDEF DEBUG64
            PrintText '_AllocStructureMemory::Mem error GlobalAlloc'
            ENDIF
            mov rax, -1
            ret
        .ENDIF
    .ELSE
        
        .IF qwPtrStructMem != NULL
        
            ; calc new size to grow structure and offset to new entry
            mov rax, TotalItems
            inc rax
            mov rbx, ItemSize
            mul rbx
            mov StructSize, rax ; save new size to alloc mem for
            mov rbx, ItemSize
            sub rax, rbx
            mov StructDataOffset, rax ; save offset for new entry
            
            mov rbx, qwPtrStructMem ; get value from addr of passed dword dwPtrStructMem into eax, this is our pointer to previous mem location of structure
            mov rax, [rbx]
            mov StructData, rax
            ;IFDEF DEBUG32
            ;    PrintDec StructData
            ;    PrintDec StructSize
            ;ENDIF
            
            .IF TotalItems >= 2
                Invoke GlobalUnlock, StructData
            .ENDIF
            Invoke GlobalReAlloc, StructData, StructSize, GMEM_ZEROINIT + GMEM_MOVEABLE ; resize memory for structure
            .IF rax != NULL
                ;PrintDec eax
                Invoke GlobalLock, rax
                mov StructData, rax
                
                mov rbx, qwPtrStructMem
                mov [rbx], rax ; save new pointer to memory alloc'd for structure back to dword address passed as dwPtrStructMem
            .ELSE
                IFDEF DEBUG64
                PrintText '_AllocStructureMemory::Mem error GlobalReAlloc'
                ENDIF
                mov rax, -1
                ret
            .ENDIF
        
        .ELSE ; initialize structure size to the size specified by items * size
            
            ; calc size of structure
            mov rax, TotalItems
            mov rbx, ItemSize
            mul rbx
            mov StructSize, rax ; save new size to alloc mem for        
            Invoke GlobalAlloc, GMEM_FIXED+GMEM_ZEROINIT, StructSize ;GMEM_FIXED+GMEM_ZEROINIT
            .IF rax != NULL
                mov StructData, rax
                ;mov ebx, dwPtrStructMem ; alloc memory so dont return anything to this as it was null when we got it
                ;mov [ebx], eax ; save pointer to memory alloc'd for structure
                mov StructDataOffset, 0 ; save offset for new entry
                ;IFDEF DEBUG32
                ;    PrintDec StructData
                ;ENDIF
            .ELSE
                IFDEF DEBUG64
                PrintText '_AllocStructureMemory::Mem error GlobalAlloc'
                ENDIF
                mov rax, -1
                ret
            .ENDIF
        .ENDIF
    .ENDIF

    ; calc entry to new item, (base address of memory alloc'd for structure + size of mem for new structure size - size of structure item)
    ;PrintText 'AllocStructureMemory END'
    mov rax, StructData
    add rax, StructDataOffset
    
    ret
MUIAllocStructureMemory endp


MODERNUI_LIBEND



