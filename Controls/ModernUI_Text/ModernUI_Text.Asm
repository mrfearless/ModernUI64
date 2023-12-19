;==============================================================================
;
; ModernUI x64 Control - ModernUI_Text x64
;
; Copyright (c) 2023 by fearless
;
; http://github.com/mrfearless/ModernUI64
;
;
; This software is provided 'as-is', without any express or implied warranty. 
; In no event will the author be held liable for any damages arising from the 
; use of this software.
;
; Permission is granted to anyone to use this software for any non-commercial 
; program. If you use the library in an application, an acknowledgement in the
; application or documentation is appreciated but not required. 
;
; You are allowed to make modifications to the source code, but you must leave
; the original copyright notices intact and not misrepresent the origin of the
; software. It is not allowed to claim you wrote the original software. 
; Modified files must have a clear notice that the files are modified, and not
; in the original state. This includes the name of the person(s) who modified 
; the code. 
;
; If you want to distribute or redistribute any portion of this package, you 
; will need to include the full package in it's original state, including this
; license and all the copyrights.  
;
; While distributing this package (in it's original state) is allowed, it is 
; not allowed to charge anything for this. You may not sell or include the 
; package in any commercial package without having permission of the author. 
; Neither is it allowed to redistribute any of the package's components with 
; commercial applications.
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

;------------------------------------------
; Remove comment to include DrawTextEXT
;------------------------------------------
;MUI_DRAWTEXTEXT EQU 1
;------------------------------------------


;------------------------------------------
; Remove comment to include unicode support
;------------------------------------------
;MUI_UNICODE TEXTEQU <UNICODE>
IFDEF MUI_UNICODE
UNICODE EQU 1
% ECHO ModernUI_Text MUI_UNICODE BUILD
ELSE
ECHO ModernUI_Text ANSI BUILD
ENDIF
;------------------------------------------


;------------------------------------------
; Remove comment to include debug64 macros
;------------------------------------------
;DEBUG64 EQU 1
;IFDEF DEBUG64
;    PRESERVEXMMREGS equ 1
;    includelib M:\UASM\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'M:\UASM\bin\DbgWin.exe'>
;    include M:\UASM\include\debug64.inc
;    .DATA
;    RDBG_DbgWin DB DEBUGEXE,0
;    .CODE
;ENDIF
;------------------------------------------

include windows.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

include ModernUI.inc
includelib ModernUI.lib

include ModernUI_Text.inc

PUBLIC MUITextFontTable


;------------------------------------------------------------------------------
; Prototypes for internal use
;------------------------------------------------------------------------------
_MUI_TextWndProc				PROTO :HWND, :UINT, :WPARAM, :LPARAM
_MUI_TextInit                   PROTO :QWORD
_MUI_TextPaint                  PROTO :QWORD
_MUI_TextPaintBackground        PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_TextPaintBrush             PROTO :QWORD, :QWORD, :QWORD
_MUI_TextPaintText              PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
_MUI_TextCheckMultiline         PROTO :QWORD, :QWORD
_MUI_TextSetFontFamilySize      PROTO :QWORD, :QWORD

_MUI_TextGetFontTableHandle     PROTO :QWORD, :QWORD
_MUI_TextSetFontTableHandle     PROTO :QWORD, :QWORD, :QWORD

_MUI_TextCheckSetFont           PROTO :QWORD, :QWORD

_MUI_TextUTF8Encode             PROTO :QWORD
_MUI_TextUTF8Decode             PROTO :QWORD
_MUI_TextUTF8Free               PROTO :QWORD

_MUI_TextUpdateBrushOrg         PROTO :QWORD

;------------------------------------------------------------------------------
; Structures for internal use
;------------------------------------------------------------------------------
; External public properties
MUI_TEXT_PROPERTIES             STRUCT
    qwTextFont                  DQ ?
    qwTextColor                 DQ ?
    qwTextColorAlt              DQ ?
    qwTextColorDisabled         DQ ?
    qwTextBackColor             DQ ?
    qwTextBackColorAlt          DQ ?
    qwTextBackColorDisabled     DQ ?
    qwTextCodeTextColor         DQ ?
    qwTextCodeBackColor         DQ ?
    qwTextQuoteTextColor        DQ ?
    qwTextQuoteBackColor        DQ ?
    qwTextLinkTextColor         DQ ?
    qwTextLinkUnderline         DQ ?
    qwTextHelpTextColor         DQ ?
    qwTextHelpUnderline         DQ ?
    qwTextHorzRuleColor         DQ ?
MUI_TEXT_PROPERTIES             ENDS

; Extended External public properties
MUI_TEXTEXT_PROPERTIES          STRUCT
    qwTextFont                  DQ ?
    qwTextCodeTextColor         DQ ?
    qwTextCodeBackColor         DQ ?
    qwTextQuoteTextColor        DQ ?
    qwTextQuoteBackColor        DQ ?
    qwTextLinkTextColor         DQ ?
    qwTextLinkUnderline         DQ ?
    qwTextHelpTextColor         DQ ?
    qwTextHelpUnderline         DQ ?
    qwTextHorzRuleColor         DQ ?
MUI_TEXTEXT_PROPERTIES          ENDS

; Internal properties
_MUI_TEXT_PROPERTIES            STRUCT
    qwEnabledState              DQ ?
    qwMouseOver                 DQ ?
    qwTextBuffer                DQ ?
    qwPtrColorStack             DQ ? ; Stack of text colors for DTE
    qwColorStackIndex           DQ ? ; Current index of color stack
    qwPtrListStack              DQ ? ; Stack of list items for DTE
    qwListStackIndex            DQ ? ; Current index of list stack
    qwPtrFontSpecial            DQ ? ; Array of fonts for DTE
    qwHyperLinkControl          DQ ? ; handle of DTE HyperLink control
    qwBrushBitmap               DD ?
    qwBrush                     DD ?
    qwBrushOrgX                 DD ?
    qwBrushOrgY                 DD ?
    qwBrushOrgOriginalX         DD ?
    qwBrushOrgOriginalY         DD ?
    qwBrushPos                  DD ?
_MUI_TEXT_PROPERTIES            ENDS

; Extended Internal properties
_MUI_TEXTEXT_PROPERTIES         STRUCT
    qwPtrColorStack             DQ ? ; Stack of text colors for DTE
    qwColorStackIndex           DQ ? ; Current index of color stack
    qwPtrListStack              DQ ? ; Stack of list items for DTE
    qwListStackIndex            DQ ? ; Current index of list stack
    qwPtrFontSpecial            DQ ? ; Array of fonts for DTE
    qwHyperLinkControl          DQ ? ; handle of DTE HyperLink control
_MUI_TEXTEXT_PROPERTIES         ENDS

MUI_TEXT_FONT_ENTRY             STRUCT
    hFont                       DQ 0
    hFontBold                   DQ 0
    hFontItalic                 DQ 0
    hFontUnderline              DQ 0
    hFontBoldItalic             DQ 0
    hFontBoldUnderline          DQ 0
    hFontBoldItalicUnderline    DQ 0
    hFontItalicUnderline        DQ 0
MUI_TEXT_FONT_ENTRY             ENDS

.CONST
IFDEF MUI_UNICODE
MUI_WIDE_CRLF                   EQU 13,0,10,0
MUI_WIDE_NULL                   EQU 0,0,0,0
MUI_TEXT_MAX_CHARS              EQU 8192
ELSE
MUI_TEXT_MAX_CHARS              EQU 4096
ENDIF
MUI_TEXT_NO_FONTTYPES           EQU 7
MUI_TEXT_NO_FONTSIZES           EQU 16
MUI_TEXT_FONT_ENTRIES_SIZE      EQU (MUI_TEXT_NO_FONTSIZES * SIZEOF MUI_TEXT_FONT_ENTRY)

MUI_TEXT_FONTSIZE_MASK          EQU 0000000Fh
MUI_TEXT_FONTTYPE_MASK          EQU 00000070h
MUI_TEXT_ALIGN_MASK             EQU 00000300h
;MUI_TEXT_FONTSIZE_MASK          EQU 000000000000000Fh
;MUI_TEXT_FONTTYPE_MASK          EQU 0000000000000070h
;MUI_TEXT_ALIGN_MASK             EQU 0000000000000300h


@@TextBufferSize                EQU 32d ; cbWndOffset+32

; Internal properties
@TextEnabledState				EQU 0
@TextMouseOver					EQU 8
@TextBuffer                     EQU 16
@TextPtrColorStack              EQU 24 ; Stack of text colors for DTE
@TextColorStackIndex            EQU 32 ; Current index of color stack
@TextPtrListStack               EQU 40 ; Stack of list items for DTE
@TextListStackIndex             EQU 48 ; Current index of list stack
@TextPtrFontSpecial             EQU 56 ; Array of fonts for DTE
@TextHyperLinkControl           EQU 64 ; handle of DTE HyperLink control
@TextBrushBitmap                EQU 72
@TextBrush                      EQU 80
@TextBrushOrgX                  EQU 88
@TextBrushOrgY                  EQU 96
@TextBrushOrgOriginalX          EQU 104
@TextBrushOrgOriginalY          EQU 112
@TextBrushPos                   EQU 120

.DATA
IFDEF MUI_UNICODE
szLorumIpsumText                DB "L",0,"o",0,"r",0,"e",0,"m",0," ",0,"i",0,"p",0,"s",0,"u",0,"m",0," ",0,"d",0,"o",0,"l",0,"o",0,"r",0," ",0,"s",0,"i",0,"t",0
                                DB "a",0,"m",0,"e",0,"t",0,",",0," ",0,"e",0,"x",0,"p",0,"l",0,"i",0,"c",0,"a",0,"r",0,"i",0," ",0,"m",0,"a",0,"l",0,"u",0,"i",0
                                DB "s",0,"s",0,"e",0,"t",0," ",0,"t",0,"e",0," ",0,"c",0,"u",0,"m",0,",",0," ",0,"e",0,"a",0," ",0,"v",0,"e",0,"l",0," ",0,"d",0
                                DB "e",0,"b",0,"i",0,"t",0,"i",0,"s",0," ",0,"o",0,"m",0,"i",0,"t",0,"t",0,"a",0,"m",0,".",0," ",0,"D",0,"u",0,"i",0,"s",0," ",0
                                DB "s",0,"a",0,"l",0,"e",0," ",0,"f",0,"e",0,"u",0,"g",0,"a",0,"i",0,"t",0," ",0,"i",0,"d",0," ",0,"d",0,"u",0,"o",0,",",0," ",0
                                DB "s",0,"i",0,"t",0," ",0,"m",0,"i",0,"n",0,"i",0,"m",0,"u",0,"m",0," ",0,"d",0,"e",0,"l",0,"e",0,"n",0,"i",0,"t",0,"i",0," ",0
                                DB "f",0,"a",0,"c",0,"i",0,"l",0,"i",0,"s",0,"i",0,"s",0," ",0,"n",0,"e",0,".",0," ",0
                                DB "S",0,"e",0,"a",0," ",0,"e",0,"t",0," ",0,"p",0,"r",0,"o",0,"m",0,"p",0,"t",0,"a",0," ",0,"l",0,"e",0,"g",0,"e",0,"n",0,"d",0
                                DB "o",0,"s",0,".",0," ",0,"B",0,"o",0,"n",0,"o",0,"r",0,"u",0,"m",0," ",0,"r",0,"e",0,"p",0,"r",0,"e",0,"h",0,"e",0,"n",0,"d",0
                                DB "u",0,"n",0,"t",0," ",0,"e",0,"t",0," ",0,"n",0,"a",0,"m",0,".",0," ",0,"N",0,"u",0,"l",0,"l",0,"a",0,"m",0," ",0,"v",0,"o",0
                                DB "l",0,"u",0,"t",0,"p",0,"a",0,"t",0," ",0,"u",0,"t",0," ",0,"v",0,"i",0,"m",0,",",0," ",0,"i",0,"n",0," ",0,"t",0,"e",0,"m",0
                                DB "p",0,"o",0,"r",0," ",0,"n",0,"o",0,"s",0,"t",0,"r",0,"u",0,"m",0," ",0,"a",0,"s",0,"s",0,"e",0,"n",0,"t",0,"i",0,"o",0,"r",0
                                DB " ",0,"s",0,"e",0,"d",0,".",0," ",0,"I",0,"n",0," ",0,"l",0,"i",0,"b",0,"r",0,"i",0,"s",0," ",0,"s",0,"i",0,"n",0,"g",0,"u",0
                                DB "l",0,"i",0,"s",0," ",0,"g",0,"l",0,"o",0,"r",0,"i",0,"a",0,"t",0,"u",0,"r",0," ",0,"p",0,"r",0,"i",0,",",0," ",0
                                DB "m",0,"e",0,"i",0," ",0,"c",0,"e",0,"t",0,"e",0,"r",0,"o",0," ",0,"c",0,"o",0,"m",0,"p",0,"r",0,"e",0,"h",0,"e",0,"n",0,"s",0
                                DB "a",0,"m",0," ",0,"n",0,"o",0,".",0," ",0,"H",0,"a",0,"s",0," ",0,"n",0,"e",0," ",0,"d",0,"o",0,"m",0,"i",0,"n",0,"g",0," ",0
                                DB "l",0,"a",0,"b",0,"o",0,"r",0,"e",0," ",0,"s",0,"a",0,"l",0,"u",0,"t",0,"a",0,"t",0,"u",0,"s",0,",",0," ",0,"v",0,"i",0,"x",0
                                DB " ",0,"e",0,"x",0," ",0,"t",0,"i",0,"m",0,"e",0,"a",0,"m",0," ",0,"a",0,"r",0,"g",0,"u",0,"m",0,"e",0,"n",0,"t",0,"u",0,"m",0
                                DB ".",0
                                DB MUI_WIDE_CRLF,MUI_WIDE_CRLF
                                DB "Q",0,"u",0,"i",0,"d",0,"a",0,"m",0," ",0,"m",0,"e",0,"l",0,"i",0,"u",0,"s",0," ",0,"c",0,"u",0,"m",0," ",0,"e",0,"i",0,".",0
                                DB " ",0,"I",0,"d",0," ",0,"i",0,"n",0,"v",0,"e",0,"n",0,"i",0,"r",0,"e",0," ",0,"p",0,"e",0,"r",0,"c",0,"i",0,"p",0,"i",0,"t",0
                                DB "u",0,"r",0," ",0,"h",0,"a",0,"s",0,",",0," ",0,"d",0,"i",0,"c",0,"a",0,"n",0,"t",0," ",0,"p",0,"a",0,"r",0,"t",0,"i",0,"e",0
                                DB "n",0,"d",0,"o",0," ",0,"s",0,"i",0,"t",0," ",0,"e",0,"i",0,".",0," ",0,"S",0,"e",0,"a",0," ",0,"e",0,"t",0," ",0,"a",0,"f",0
                                DB "f",0,"e",0,"r",0,"t",0," ",0,"p",0,"e",0,"r",0,"c",0,"i",0,"p",0,"i",0,"t",0," ",0,"n",0,"o",0,"m",0,"i",0,"n",0,"a",0,"t",0
                                DB "i",0,",",0," ",0,"m",0,"e",0,"a",0," ",0,"e",0,"x",0," ",0,"m",0,"i",0,"n",0,"i",0,"m",0,"u",0,"m",0," ",0,"p",0,"h",0,"i",0
                                DB "l",0,"o",0,"s",0,"o",0,"p",0,"h",0,"i",0,"a",0,",",0," ",0
                                DB "a",0,"d",0," ",0,"a",0,"l",0,"i",0,"q",0,"u",0,"i",0,"d",0," ",0,"p",0,"o",0,"n",0,"d",0,"e",0,"r",0,"u",0,"m",0," ",0,"p",0
                                DB "h",0,"a",0,"e",0,"d",0,"r",0,"u",0,"m",0," ",0,"n",0,"e",0,"c",0,".",0," ",0,"A",0,"t",0," ",0,"o",0,"p",0,"t",0,"i",0,"o",0
                                DB "n",0," ",0,"n",0,"u",0,"m",0,"q",0,"u",0,"a",0,"m",0," ",0,"m",0,"e",0,"a",0,".",0," ",0,"N",0,"e",0,"c",0," ",0,"r",0,"e",0
                                DB "q",0,"u",0,"e",0," ",0,"s",0,"c",0,"r",0,"i",0,"p",0,"t",0,"a",0," ",0,"e",0,"t",0,",",0," ",0,"t",0,"e",0," ",0,"m",0,"e",0
                                DB "a",0," ",0,"r",0,"e",0,"g",0,"i",0,"o",0,"n",0,"e",0," ",0,"s",0,"e",0,"n",0,"s",0,"e",0,"r",0,"i",0,"t",0,",",0," ",0,"s",0
                                DB "e",0,"d",0," ",0,"e",0,"a",0," ",0,"p",0,"a",0,"r",0,"t",0,"i",0,"e",0,"n",0,"d",0,"o",0," ",0,"s",0,"a",0,"p",0,"i",0,"e",0
                                DB "n",0,"t",0,"e",0,"m",0," ",0,"d",0,"e",0,"l",0,"i",0,"c",0,"a",0,"t",0,"i",0,"s",0,"s",0,"i",0,"m",0,"i",0,".",0," ",0
                                DB "O",0,"p",0,"o",0,"r",0,"t",0,"e",0,"a",0,"t",0," ",0,"a",0,"c",0,"c",0,"o",0,"m",0,"m",0,"o",0,"d",0,"a",0,"r",0,"e",0," ",0
                                DB "s",0,"e",0,"d",0," ",0,"a",0,"n",0,".",0," ",0,"A",0,"t",0," ",0,"h",0,"a",0,"s",0," ",0,"o",0,"r",0,"n",0,"a",0,"t",0,"u",0
                                DB "s",0," ",0,"a",0,"d",0,"o",0,"l",0,"e",0,"s",0,"c",0,"e",0,"n",0,"s",0," ",0,"e",0,"l",0,"a",0,"b",0,"o",0,"r",0,"a",0,"r",0
                                DB "e",0,"t",0,".",0
                                DB MUI_WIDE_CRLF,MUI_WIDE_CRLF
                                DB "C",0,"u",0," ",0,"e",0,"a",0,"m",0," ",0,"a",0,"d",0,"m",0,"o",0,"d",0,"u",0,"m",0," ",0,"s",0,"e",0,"n",0,"s",0,"e",0,"r",0
                                DB "i",0,"t",0," ",0,"m",0,"a",0,"l",0,"u",0,"i",0,"s",0,"s",0,"e",0,"t",0,".",0," ",0,"M",0,"e",0,"l",0," ",0,"i",0,"d",0," ",0
                                DB "p",0,"r",0,"o",0,"b",0,"o",0," ",0,"e",0,"l",0,"i",0,"t",0,"r",0," ",0,"i",0,"n",0,"s",0,"t",0,"r",0,"u",0,"c",0,"t",0,"i",0
                                DB "o",0,"r",0,".",0," ",0,"I",0,"l",0,"l",0,"u",0,"d",0," ",0,"v",0,"e",0,"l",0,"i",0,"t",0," ",0,"e",0,"f",0,"f",0,"i",0,"c",0
                                DB "i",0,"a",0,"n",0,"t",0,"u",0,"r",0," ",0,"m",0,"e",0,"a",0," ",0,"n",0,"e",0,",",0," ",0,"a",0,"u",0,"d",0,"i",0,"r",0,"e",0
                                DB " ",0,"a",0,"d",0,"o",0,"l",0,"e",0,"s",0,"c",0,"e",0,"n",0,"s",0," ",0,"n",0,"o",0," ",0,"p",0,"r",0,"i",0,",",0," ",0,"p",0
                                DB "r",0,"o",0," ",0,"f",0,"a",0,"b",0,"e",0,"l",0,"l",0,"a",0,"s",0," ",0,"i",0,"n",0,"t",0,"e",0,"l",0,"l",0,"e",0,"g",0,"a",0
                                DB "t",0," ",0,"e",0,"x",0,".",0 
                                DB "V",0,"i",0,"s",0," ",0,"i",0,"l",0,"l",0,"u",0,"m",0," ",0,"f",0,"a",0,"l",0,"l",0,"i",0," ",0,"c",0,"o",0,"n",0,"s",0,"t",0
                                DB "i",0,"t",0,"u",0,"t",0,"o",0," ",0,"a",0,"d",0,",",0," ",0,"e",0,"u",0,"m",0," ",0,"t",0,"a",0,"n",0,"t",0,"a",0,"s",0," ",0
                                DB "d",0,"o",0,"l",0,"o",0,"r",0,"e",0," ",0,"e",0,"i",0,"r",0,"m",0,"o",0,"d",0," ",0,"c",0,"u",0,".",0," ",0,"E",0,"t",0," ",0
                                DB "z",0,"r",0,"i",0,"l",0," ",0,"m",0,"a",0,"l",0,"o",0,"r",0,"u",0,"m",0," ",0,"m",0,"e",0,"l",0,"i",0,"o",0,"r",0,"e",0," ",0
                                DB "u",0,"s",0,"u",0,".",0
                                DB MUI_WIDE_CRLF,MUI_WIDE_CRLF
                                DB "N",0,"o",0," ",0,"s",0,"e",0,"a",0," ",0,"m",0,"o",0,"d",0,"u",0,"s",0," ",0,"m",0,"e",0,"n",0,"a",0,"n",0,"d",0,"r",0,"i",0
                                DB " ",0,"s",0,"c",0,"r",0,"i",0,"p",0,"t",0,"o",0,"r",0,"e",0,"m",0,",",0," ",0,"n",0,"e",0,"c",0," ",0,"c",0,"u",0," ",0,"p",0
                                DB "e",0,"t",0,"e",0,"n",0,"t",0,"i",0,"u",0,"m",0," ",0,"s",0,"i",0,"g",0,"n",0,"i",0,"f",0,"e",0,"r",0,"u",0,"m",0,"q",0,"u",0
                                DB "e",0,".",0," ",0,"C",0,"u",0," ",0,"c",0,"a",0,"u",0,"s",0,"a",0,"e",0," ",0,"s",0,"u",0,"s",0,"c",0,"i",0,"p",0,"i",0,"a",0
                                DB "n",0,"t",0,"u",0,"r",0," ",0,"d",0,"u",0,"o",0,",",0," ",0,"n",0,"a",0,"m",0," ",0,"n",0,"i",0,"b",0,"h",0," ",0,"i",0,"n",0
                                DB "a",0,"n",0,"i",0," ",0,"c",0,"o",0,"r",0,"r",0,"u",0,"m",0,"p",0,"i",0,"t",0," ",0,"a",0,"d",0,".",0," ",0,"P",0,"o",0,"r",0
                                DB "r",0,"o",0," ",0,"c",0,"a",0,"u",0,"s",0,"a",0,"e",0," ",0,"u",0,"t",0," ",0,"p",0,"r",0,"i",0,".",0," ",0
                                DB "D",0,"u",0,"o",0," ",0,"p",0,"a",0,"u",0,"l",0,"o",0," ",0,"a",0,"p",0,"e",0,"r",0,"i",0,"r",0,"i",0," ",0,"a",0,"t",0,",",0
                                DB " ",0,"q",0,"u",0,"i",0," ",0,"n",0,"e",0," ",0,"e",0,"r",0,"i",0,"p",0,"u",0,"i",0,"t",0," ",0,"v",0,"u",0,"l",0,"p",0,"u",0
                                DB "t",0,"a",0,"t",0,"e",0,",",0," ",0,"s",0,"i",0,"t",0," ",0,"f",0,"a",0,"c",0,"i",0,"l",0,"i",0,"s",0,"i",0," ",0,"a",0,"n",0
                                DB "t",0,"i",0,"o",0,"p",0,"a",0,"m",0," ",0,"s",0,"a",0,"l",0,"u",0,"t",0,"a",0,"n",0,"d",0,"i",0," ",0,"i",0,"d",0,".",0," ",0
                                DB "A",0,"t",0," ",0,"v",0,"i",0,"d",0,"i",0,"s",0,"s",0,"e",0," ",0,"e",0,"f",0,"f",0,"i",0,"c",0,"i",0,"e",0,"n",0,"d",0,"i",0
                                DB " ",0,"c",0,"u",0,"m",0,".",0
                                DB MUI_WIDE_CRLF,MUI_WIDE_CRLF
                                DB "E",0,"o",0,"s",0," ",0,"v",0,"i",0,"d",0,"i",0,"s",0,"s",0,"e",0," ",0,"i",0,"n",0,"d",0,"o",0,"c",0,"t",0,"u",0,"m",0," ",0
                                DB "d",0,"i",0,"s",0,"s",0,"e",0,"n",0,"t",0,"i",0,"u",0,"n",0,"t",0," ",0,"i",0,"d",0,".",0," ",0,"A",0,"l",0,"i",0,"a",0," ",0
                                DB "d",0,"u",0,"i",0,"s",0," ",0,"t",0,"o",0,"t",0,"a",0," ",0,"n",0,"e",0," ",0,"e",0,"s",0,"t",0,",",0," ",0,"i",0,"n",0," ",0
                                DB "m",0,"e",0,"a",0," ",0,"d",0,"e",0,"l",0,"e",0,"n",0,"i",0,"t",0,"i",0," ",0,"p",0,"e",0,"r",0,"t",0,"i",0,"n",0,"a",0,"x",0
                                DB ",",0," ",0,"a",0,"m",0,"e",0,"t",0," ",0,"s",0,"e",0,"n",0,"s",0,"e",0,"r",0,"i",0,"t",0," ",0,"n",0,"o",0," ",0,"h",0,"i",0
                                DB "s",0,".",0," ",0,"H",0,"i",0,"s",0," ",0,"m",0,"o",0,"l",0,"l",0,"i",0,"s",0," ",0,"i",0,"n",0,"t",0,"e",0,"l",0,"l",0,"e",0
                                DB "g",0,"e",0,"b",0,"a",0,"t",0," ",0,"u",0,"t",0,".",0," ",0
                                DB "S",0,"e",0,"d",0," ",0,"r",0,"e",0,"q",0,"u",0,"e",0," ",0,"q",0,"u",0,"a",0,"n",0,"d",0,"o",0," ",0,"e",0,"i",0,".",0," ",0
                                DB "E",0,"a",0," ",0,"p",0,"e",0,"r",0," ",0,"a",0,"t",0,"q",0,"u",0,"i",0," ",0,"i",0,"n",0,"t",0,"e",0,"g",0,"r",0,"e",0," ",0
                                DB "d",0,"e",0,"s",0,"e",0,"r",0,"u",0,"i",0,"s",0,"s",0,"e",0,",",0," ",0,"p",0,"r",0,"i",0," ",0,"e",0,"t",0," ",0,"s",0,"u",0
                                DB "m",0,"m",0,"o",0," ",0,"c",0,"o",0,"n",0,"g",0,"u",0,"e",0,".",0," ",0,"A",0,"f",0,"f",0,"e",0,"r",0,"t",0," ",0,"f",0,"u",0
                                DB "i",0,"s",0,"s",0,"e",0,"t",0," ",0,"s",0,"a",0,"l",0,"u",0,"t",0,"a",0,"n",0,"d",0,"i",0," ",0,"p",0,"e",0,"r",0," ",0,"t",0
                                DB "e",0,".",0
                                DB MUI_WIDE_CRLF,MUI_WIDE_CRLF
                                DB "E",0,"a",0," ",0,"d",0,"i",0,"c",0,"o",0," ",0,"t",0,"i",0,"m",0,"e",0,"a",0,"m",0," ",0,"v",0,"o",0,"l",0,"u",0,"p",0,"t",0
                                DB "a",0,"r",0,"i",0,"a",0," ",0,"q",0,"u",0,"i",0,",",0," ",0,"v",0,"e",0,"l",0," ",0,"e",0,"a",0," ",0,"v",0,"i",0,"d",0,"e",0
                                DB "r",0,"e",0,"r",0," ",0,"r",0,"e",0,"c",0,"t",0,"e",0,"q",0,"u",0,"e",0,".",0," ",0,"Q",0,"u",0,"a",0,"s",0," ",0,"s",0,"c",0
                                DB "a",0,"e",0,"v",0,"o",0,"l",0,"a",0," ",0,"a",0,"d",0," ",0,"v",0,"i",0,"m",0,",",0," ",0,"h",0,"a",0,"r",0,"u",0,"m",0," ",0
                                DB "o",0,"m",0,"n",0,"e",0,"s",0," ",0,"v",0,"u",0,"l",0,"p",0,"u",0,"t",0,"a",0,"t",0,"e",0," ",0,"h",0,"i",0,"s",0," ",0,"e",0
                                DB "x",0,",",0," ",0,"q",0,"u",0,"o",0," ",0,"a",0,"c",0,"c",0,"u",0,"s",0,"a",0,"m",0,"u",0,"s",0," ",0,"h",0,"e",0,"n",0,"d",0
                                DB "r",0,"e",0,"r",0,"i",0,"t",0," ",0,"i",0,"d",0,".",0," ",0
                                DB "E",0,"x",0," ",0,"m",0,"e",0,"a",0," ",0,"s",0,"o",0,"l",0,"u",0,"m",0," ",0,"c",0,"o",0,"n",0,"s",0,"t",0,"i",0,"t",0,"u",0
                                DB "a",0,"m",0,",",0," ",0,"n",0,"o",0," ",0,"q",0,"u",0,"o",0," ",0,"t",0,"r",0,"i",0,"t",0,"a",0,"n",0,"i",0," ",0,"d",0,"e",0
                                DB "f",0,"i",0,"n",0,"i",0,"e",0,"b",0,"a",0,"s",0," ",0,"i",0,"n",0,"t",0,"e",0,"l",0,"l",0,"e",0,"g",0,"e",0,"b",0,"a",0,"t",0
                                DB ".",0," ",0,"Q",0,"u",0,"i",0," ",0,"s",0,"a",0,"p",0,"e",0,"r",0,"e",0,"t",0," ",0,"i",0,"n",0,"s",0,"o",0,"l",0,"e",0,"n",0
                                DB "s",0," ",0,"n",0,"o",0,",",0," ",0,"e",0,"x",0," ",0,"p",0,"r",0,"i",0," ",0,"h",0,"o",0,"m",0,"e",0,"r",0,"o",0," ",0,"a",0
                                DB "c",0,"c",0,"u",0,"m",0,"s",0,"a",0,"n",0,".",0," ",0,"A",0,"d",0," ",0,"n",0,"e",0,"m",0,"o",0,"r",0,"e",0," ",0,"v",0,"o",0
                                DB "c",0,"i",0,"b",0,"u",0,"s",0," ",0,"q",0,"u",0,"i",0,".",0," ",0
                                DB "M",0,"u",0,"n",0,"d",0,"i",0," ",0,"v",0,"o",0,"l",0,"u",0,"m",0,"u",0,"s",0," ",0,"c",0,"o",0,"m",0,"p",0,"r",0,"e",0,"h",0
                                DB "e",0,"n",0,"s",0,"a",0,"m",0," ",0,"a",0,"d",0," ",0,"p",0,"e",0,"r",0,",",0," ",0,"i",0,"n",0," ",0,"a",0,"s",0,"s",0,"e",0
                                DB "n",0,"t",0,"i",0,"o",0,"r",0," ",0,"c",0,"o",0,"t",0,"i",0,"d",0,"i",0,"e",0,"q",0,"u",0,"e",0," ",0,"s",0,"i",0,"t",0,".",0
                                DB " ",0,"P",0,"r",0,"o",0," ",0,"u",0,"t",0," ",0,"i",0,"u",0,"d",0,"i",0,"c",0,"o",0," ",0,"i",0,"n",0,"c",0,"o",0,"r",0,"r",0
                                DB "u",0,"p",0,"t",0,"e",0,",",0," ",0,"d",0,"u",0,"o",0," ",0,"i",0,"n",0," ",0,"p",0,"o",0,"p",0,"u",0,"l",0,"o",0," ",0,"s",0
                                DB "u",0,"s",0,"c",0,"i",0,"p",0,"i",0,"t",0,".",0
                                DB MUI_WIDE_NULL,MUI_WIDE_NULL

szMUITextClass                  DB 'M',0,'o',0,'d',0,'e',0,'r',0,'n',0,'U',0,'I',0,'_',0,'T',0,'e',0,'x',0,'t',0,MUI_WIDE_NULL    ; Class name for creating our ModernUI_Text control

szMUITextFontSegoe              DB 'S',0,'e',0,'g',0,'o',0,'e',0,' ',0,'U',0,'I',0 ,MUI_WIDE_NULL
szMUITextFontTahoma             DB 'T',0,'a',0,'h',0,'o',0,'m',0,'a',0,MUI_WIDE_NULL
szMUITextFontArial              DB 'A',0,'r',0,'i',0,'a',0,'l',0,MUI_WIDE_NULL
szMUITextFontTimes              DB 'T',0,'i',0,'m',0,'e',0,'s',0,' ',0,'N',0,'e',0,'w',0,' ',0,'R',0,'o',0,'m',0,'a',0,'n',0,MUI_WIDE_NULL
szMUITextFontCourier            DB 'C',0,'o',0,'u',0,'r',0,'i',0,'e',0,'r',0,' ',0,'N',0,'e',0,'w',0,MUI_WIDE_NULL
szMUITextFontVerdana            DB 'V',0,'e',0,'r',0,'d',0,'a',0,'n',0,'a',0,MUI_WIDE_NULL

ELSE ; ANSI

szLorumIpsumText                DB "Lorem ipsum dolor sit amet, explicari maluisset te cum, ea vel debitis omittam. Duis sale feugait id duo, sit minimum deleniti facilisis ne. "
                                DB "Sea et prompta legendos. Bonorum reprehendunt et nam. Nullam volutpat ut vim, in tempor nostrum assentior sed. In libris singulis gloriatur pri, "
                                DB "mei cetero comprehensam no. Has ne doming labore salutatus, vix ex timeam argumentum."
                                DB 13,10,13,10
                                DB "Quidam melius cum ei. Id invenire percipitur has, dicant partiendo sit ei. Sea et affert percipit nominati, mea ex minimum philosophia, "
                                DB "ad aliquid ponderum phaedrum nec. At option numquam mea. Nec reque scripta et, te mea regione senserit, sed ea partiendo sapientem delicatissimi. "
                                DB "Oporteat accommodare sed an. At has ornatus adolescens elaboraret."
                                DB 13,10,13,10
                                DB "Cu eam admodum senserit maluisset. Mel id probo elitr instructior. Illud velit efficiantur mea ne, audire adolescens no pri, pro fabellas intellegat ex." 
                                DB "Vis illum falli constituto ad, eum tantas dolore eirmod cu. Et zril malorum meliore usu."
                                DB 13,10,13,10
                                DB "No sea modus menandri scriptorem, nec cu petentium signiferumque. Cu causae suscipiantur duo, nam nibh inani corrumpit ad. Porro causae ut pri. "
                                DB "Duo paulo aperiri at, qui ne eripuit vulputate, sit facilisi antiopam salutandi id. At vidisse efficiendi cum."
                                DB 13,10,13,10
                                DB "Eos vidisse indoctum dissentiunt id. Alia duis tota ne est, in mea deleniti pertinax, amet senserit no his. His mollis intellegebat ut. "
                                DB "Sed reque quando ei. Ea per atqui integre deseruisse, pri et summo congue. Affert fuisset salutandi per te."
                                DB 13,10,13,10
                                DB "Ea dico timeam voluptaria qui, vel ea viderer recteque. Quas scaevola ad vim, harum omnes vulputate his ex, quo accusamus hendrerit id. "
                                DB "Ex mea solum constituam, no quo tritani definiebas intellegebat. Qui saperet insolens no, ex pri homero accumsan. Ad nemore vocibus qui. "
                                DB "Mundi volumus comprehensam ad per, in assentior cotidieque sit. Pro ut iudico incorrupte, duo in populo suscipit."
                                DB 0,0,0,0
                                
szMUITextClass                  DB 'ModernUI_Text',0    ; Class name for creating our ModernUI_Text control

szMUITextFontSegoe              DB 'Segoe UI',0 
szMUITextFontTahoma             DB 'Tahoma',0
szMUITextFontArial              DB 'Arial',0
szMUITextFontTimes              DB 'Times New Roman',0
szMUITextFontCourier            DB 'Courier New',0
szMUITextFontVerdana            DB 'Verdana',0

ENDIF

MUITextFontTable                MUI_TEXT_FONT_ENTRY ((MUI_TEXT_NO_FONTTYPES+1) * (MUI_TEXT_NO_FONTSIZES+1)) DUP (<>)

.CODE


MUI_ALIGN
;------------------------------------------------------------------------------
; Set property for ModernUI_Text control
;------------------------------------------------------------------------------
MUITextSetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD, qwPropertyValue:QWORD
    Invoke SendMessage, hControl, MUI_SETPROPERTY, qwProperty, qwPropertyValue
    ret
MUITextSetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Get property for ModernUI_Text control
;------------------------------------------------------------------------------
MUITextGetProperty PROC FRAME hControl:QWORD, qwProperty:QWORD
    Invoke SendMessage, hControl, MUI_GETPROPERTY, qwProperty, NULL
    ret
MUITextGetProperty ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUITextRegister - Registers the ModernUI_Text control
; can be used at start of program for use with RadASM custom control
; Custom control class must be set as ModernUI_Text
;------------------------------------------------------------------------------
MUITextRegister PROC FRAME
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

    invoke GetClassInfoEx,hinstance,addr szMUITextClass, Addr wc 
    .IF rax == 0 ; if class not already registered do so
        mov wc.cbSize,sizeof WNDCLASSEX
        lea rax, szMUITextClass
    	mov wc.lpszClassName, rax
    	mov rax, hinstance
        mov wc.hInstance, rax
		lea rax, _MUI_TextWndProc
    	mov wc.lpfnWndProc, rax
    	Invoke LoadCursor, NULL, IDC_ARROW
    	mov wc.hCursor, rax
    	mov wc.hIcon, 0
    	mov wc.hIconSm, 0
    	mov wc.lpszMenuName, NULL
    	mov wc.hbrBackground, NULL
    	mov wc.style, NULL
        mov wc.cbClsExtra, 0
    	mov wc.cbWndExtra, 48d ; cbWndExtra +0 = QWORD ptr to internal properties memory block, cbWndExtra +8 = QWORD ptr to external properties memory block
    	Invoke RegisterClassEx, addr wc
    .ENDIF  
    ret

MUITextRegister ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; MUITextCreate - Returns handle in rax of newly created control
;------------------------------------------------------------------------------
MUITextCreate PROC FRAME hWndParent:QWORD, lpszText:QWORD, xpos:QWORD, ypos:QWORD, controlwidth:QWORD, controlheight:QWORD, qwResourceID:QWORD, qwStyle:QWORD
    LOCAL wc:WNDCLASSEX
    LOCAL hinstance:QWORD
	LOCAL hControl:QWORD
    LOCAL qwNewStyle:QWORD
    
    Invoke GetModuleHandle, NULL
    mov hinstance, rax

	Invoke MUITextRegister
	
    mov rax, qwStyle
    mov qwNewStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        or qwNewStyle, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .ENDIF
	
    Invoke CreateWindowEx, NULL, Addr szMUITextClass, lpszText, dword ptr qwNewStyle, dword ptr xpos, dword ptr ypos, dword ptr controlwidth, dword ptr controlheight, hWndParent, qwResourceID, hinstance, NULL
	mov hControl, rax
	.IF rax != NULL
		
	.ENDIF
	mov rax, hControl
    ret
MUITextCreate ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextWndProc - Main processing window for our control
;------------------------------------------------------------------------------
_MUI_TextWndProc PROC FRAME USES RBX hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TE:TRACKMOUSEEVENT
    LOCAL lpUTF8String:QWORD

    mov eax, uMsg
    .IF eax == WM_NCCREATE
        mov rbx, lParam
        Invoke SetWindowText, hWin, (CREATESTRUCT PTR [rbx]).lpszName	
        mov rax, TRUE
        ret

    .ELSEIF eax == WM_CREATE
		Invoke MUIAllocMemProperties, hWin, MUI_INTERNAL_PROPERTIES, SIZEOF _MUI_TEXT_PROPERTIES ; internal properties
		Invoke MUIAllocMemProperties, hWin, MUI_EXTERNAL_PROPERTIES, SIZEOF MUI_TEXT_PROPERTIES ; external properties
		
        Invoke MUIAllocMemProperties, hWin, MUI_INTERNAL_PROPERTIES_EXTRA, SIZEOF _MUI_TEXTEXT_PROPERTIES ; Extended internal properties
        Invoke MUIAllocMemProperties, hWin, MUI_EXTERNAL_PROPERTIES_EXTRA, SIZEOF MUI_TEXTEXT_PROPERTIES ; Extended external properties
        
		Invoke _MUI_TextInit, hWin
		mov rax, 0
		ret    

    .ELSEIF eax == WM_NCDESTROY
        Invoke MUIGetIntProperty, hWin, @TextBuffer ; release buffer used for text
        .IF rax != 0
            Invoke GlobalFree, rax
        .ENDIF      
        Invoke MUIFreeMemProperties, hWin, MUI_INTERNAL_PROPERTIES
		Invoke MUIFreeMemProperties, hWin, MUI_EXTERNAL_PROPERTIES
		mov rax, 0
		ret           
        
    .ELSEIF eax == WM_ERASEBKGND
        mov rax, 1
        ret

    .ELSEIF eax == WM_PAINT
        Invoke _MUI_TextPaint, hWin
        mov rax, 0
        ret
        
    .ELSEIF eax == WM_MOVE
        Invoke GetWindowLong, hWin, 0
        .IF rax != 0
            Invoke MUIGetIntProperty, hWin, @TextBrush
            .IF rax != 0
                Invoke MUIGetIntProperty, hWin, @TextBrushPos
                .IF rax == 0
                    Invoke _MUI_TextUpdateBrushOrg, hWin
                .ENDIF
            .ENDIF
        .ENDIF
        
    .ELSEIF eax== WM_SETCURSOR
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUITS_HAND
        .IF rax == MUITS_HAND
            invoke LoadCursor, NULL, IDC_HAND
        .ELSE
            invoke LoadCursor, NULL, IDC_ARROW
        .ENDIF
        Invoke SetCursor, rax
        mov rax, 0
        ret  

    .ELSEIF eax == WM_LBUTTONUP
		; simulates click on our control, delete if not required.
		Invoke GetDlgCtrlID, hWin
		mov rbx,rax
		Invoke GetParent, hWin
		Invoke PostMessage, rax, WM_COMMAND, rbx, hWin

;   .ELSEIF rax == WM_MOUSEMOVE
;        Invoke MUIGetIntProperty, hWin, @TextEnabledState
;        .IF rax == TRUE   
;    		Invoke MUISetIntProperty, hWin, @TextMouseOver , TRUE
;    		.IF rax != TRUE
;    		    ;Invoke ShowWindow, hWin, SW_HIDE
;    		    Invoke InvalidateRect, hWin, NULL, TRUE
;    		    ;Invoke ShowWindow, hWin, SW_SHOW
;    		    mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
;    		    mov TE.dwFlags, TME_LEAVE
;    		    mov rax, hWin
;    		    mov TE.hwndTrack, rax
;    		    mov TE.dwHoverTime, NULL
;    		    Invoke TrackMouseEvent, Addr TE
;    		.ENDIF
;        .ENDIF

   .ELSEIF eax == WM_MOUSEMOVE
        Invoke GetWindowLong, hWin, GWL_STYLE
        and rax, MUITS_HAND
        .IF rax == MUITS_HAND   
            Invoke MUIGetIntProperty, hWin, @TextEnabledState
            .IF rax == TRUE   
                Invoke MUISetIntProperty, hWin, @TextMouseOver, TRUE
                .IF eax != TRUE
                    ;Invoke ShowWindow, hWin, SW_HIDE
                    Invoke InvalidateRect, hWin, NULL, TRUE
                    ;Invoke ShowWindow, hWin, SW_SHOW
                    mov TE.cbSize, SIZEOF TRACKMOUSEEVENT
                    mov TE.dwFlags, TME_LEAVE
                    mov rax, hWin
                    mov TE.hwndTrack, rax
                    mov TE.dwHoverTime, NULL
                    Invoke TrackMouseEvent, Addr TE
                .ENDIF
            .ENDIF
            Invoke GetParent, hWin
            Invoke PostMessage, rax, WM_MOUSEMOVE, wParam, lParam ; pass mousemove to parent
        .ENDIF

    .ELSEIF eax == WM_MOUSELEAVE
        Invoke MUISetIntProperty, hWin, @TextMouseOver , FALSE
		;Invoke ShowWindow, hWin, SW_HIDE
		Invoke InvalidateRect, hWin, NULL, TRUE
		;Invoke ShowWindow, hWin, SW_SHOW
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, rax

    .ELSEIF eax == WM_KILLFOCUS
        Invoke MUISetIntProperty, hWin, @TextMouseOver , FALSE
		Invoke InvalidateRect, hWin, NULL, TRUE
		Invoke LoadCursor, NULL, IDC_ARROW
		Invoke SetCursor, rax

    .ELSEIF eax == WM_ENABLE
        Invoke MUISetIntProperty, hWin, @TextEnabledState, wParam
        ;Invoke ShowWindow, hWin, SW_HIDE
        Invoke InvalidateRect, hWin, NULL, TRUE
        ;Invoke ShowWindow, hWin, SW_SHOW
        mov rax, 0

    .ELSEIF eax == WM_SETTEXT
        Invoke _MUI_TextCheckMultiline, hWin, lParam
        IFDEF MUI_UNICODE
            Invoke GetWindowLongPtr, hWin, GWL_STYLE
            and rax, MUITS_UTF8
            .IF rax == MUITS_UTF8
                Invoke _MUI_TextUTF8Decode, lParam
                mov lpUTF8String, rax
                Invoke DefWindowProc, hWin, uMsg, wParam, rax
                Invoke _MUI_TextUTF8Free, lpUTF8String
            .ELSE
                Invoke DefWindowProc, hWin, uMsg, wParam, lParam
            .ENDIF
        ELSE        
            Invoke DefWindowProc, hWin, uMsg, wParam, lParam
        ENDIF
        Invoke InvalidateRect, hWin, NULL, TRUE
        ret

    .ELSEIF eax == WM_SETFONT
        ;PrintText '_MUI_TextWndProc::WM_SETFONT'
        Invoke GetWindowLongPtr, hWin, GWL_STYLE
        and rax, MUI_TEXT_FONTTYPE_MASK
        .IF rax == MUITS_FONT_DIALOG
            ;PrintDec wParam
            Invoke _MUI_TextCheckSetFont, hWin, wParam
            .IF eax == TRUE ; actually a font being passed in wParam
                Invoke MUISetExtProperty, hWin, @TextFont, wParam
                .IF lParam == TRUE
                    Invoke InvalidateRect, hWin, NULL, TRUE
                .ENDIF
            .ENDIF            
        .ELSE
            ret
        .ENDIF

	; custom messages start here
	
	.ELSEIF eax == MUI_GETPROPERTY
		Invoke MUIGetExtProperty, hWin, wParam
		ret
		
	.ELSEIF eax == MUI_SETPROPERTY	
        mov rax, wParam
        .IF rax == @TextFont
            Invoke MUIGetExtProperty, hWin, @TextFont
            .IF rax != NULL
                Invoke DeleteObject, rax
            .ENDIF
            Invoke MUISetExtProperty, hWin, wParam, lParam
            Invoke InvalidateRect, hWin, NULL, TRUE
        .ELSE
            Invoke MUISetExtProperty, hWin, wParam, lParam
        .ENDIF
		ret
		
    .ENDIF
    
    Invoke DefWindowProc, hWin, uMsg, wParam, lParam
    ret
_MUI_TextWndProc ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextInit - set initial default values
;------------------------------------------------------------------------------
_MUI_TextInit PROC FRAME hWin:QWORD
    LOCAL hParent:QWORD
    LOCAL qwStyle:QWORD
    LOCAL BackColor:QWORD
    
    Invoke GetParent, hWin
    mov hParent, rax
    
    ; get style and check it is our default at least
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax
    and rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
    .IF rax != WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov rax, qwStyle
        or rax, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN
        mov qwStyle, rax
        Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwStyle
    .ENDIF
     
    ; Set default initial external property values  
    mov rax, qwStyle
    and rax, WS_DISABLED
    .IF rax == WS_DISABLED
        Invoke MUISetIntProperty, hWin, @TextEnabledState, FALSE
    .ELSE
        Invoke MUISetIntProperty, hWin, @TextEnabledState, TRUE
    .ENDIF    
    Invoke MUISetExtProperty, hWin, @TextColor, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hWin, @TextColorAlt, MUI_RGBCOLOR(51,51,51)
    Invoke MUISetExtProperty, hWin, @TextColorDisabled, MUI_RGBCOLOR(204,204,204)
    
    Invoke MUIGetParentBackgroundColor, hWin
    .IF rax == -1 ; if background was NULL then try a color as default
        Invoke GetSysColor, COLOR_WINDOW
    .ENDIF
    mov BackColor, rax
    Invoke MUISetExtProperty, hWin, @TextBackColor, BackColor ;MUI_RGBCOLOR(255,255,255)   
    ;Invoke MUISetExtProperty, hWin, @TextBackColor, MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hWin, @TextBackColorAlt, BackColor ;MUI_RGBCOLOR(255,255,255)
    Invoke MUISetExtProperty, hWin, @TextBackColorDisabled, BackColor ;MUI_RGBCOLOR(192,192,192)
    
    Invoke _MUI_TextSetFontFamilySize, hWin, qwStyle

    ; Alloc Text Buffer
    ;Invoke GetWindowLongPtr, hWin, @@TextBufferSize ; buffer size
    ;.IF rax == 0
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, MUI_TEXT_MAX_CHARS
    ;.ELSE
    ;    IFDEF MUI_UNICODE
    ;    shl rax, 1 ; x2
    ;    ENDIF
    ;    and rax, 0FFFFFFFFFFFFFFF0h ; mask 
    ;    add rax, 16d ; round up to 16bytes        
    ;    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    ;.ENDIF
    .IF rax != NULL
        Invoke MUISetIntProperty, hWin, @TextBuffer, rax
    .ENDIF

    mov rax, qwStyle
    and rax, MUITS_LORUMIPSUM
    .IF rax == MUITS_LORUMIPSUM
        Invoke SetWindowText, hWin, Addr szLorumIpsumText
    .ENDIF
    
    IFDEF MUI_DRAWTEXTEXT
    ; Allocate memory for stacks if using htmlcode or bbcode tags
    mov rax, qwStyle
    and rax, MUITS_HTMLCODE
    .IF rax == MUITS_HTMLCODE
        mov rax, LISTSTACK_SIZE
        mov rbx, SIZEOF LISTINFO
        mul rbx
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
        Invoke MUISetIntProperty, hWin, @TextPtrListStack, rax
        
        mov rax, COLORSTACK_SIZE
        mov rbx, SIZEOF COLORREF
        mul rbx
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
        Invoke MUISetIntProperty, hWin, @TextPtrColorStack, rax
        
        mov rax, FV_NUMBER
        mov rbx, SIZEOF QWORD
        mul rbx
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
        Invoke MUISetIntProperty, hWin, @TextPtrFontSpecial, rax            
    .ENDIF
    
    mov rax, qwStyle
    and rax, MUITS_BBCODE
    .IF rax == MUITS_BBCODE
        mov rax, LISTSTACK_SIZE
        mov rbx, SIZEOF LISTINFO
        mul rbx
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
        Invoke MUISetIntProperty, hWin, @TextPtrListStack, rax
        
        mov rax, COLORSTACK_SIZE
        mov rbx, SIZEOF COLORREF
        mul rbx
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
        Invoke MUISetIntProperty, hWin, @TextPtrColorStack, rax
        
        mov rax, FV_NUMBER
        mov rbx, SIZEOF QWORD
        mul rbx
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
        Invoke MUISetIntProperty, hWin, @TextPtrFontSpecial, rax        
    .ENDIF
    ENDIF
    
    mov rax, qwStyle
    and rax, MUITS_HAND
    .IF rax != MUITS_HAND
        Invoke GetWindowLongPtr, hWin, GWL_EXSTYLE	
        mov qwStyle, rax
        or rax, WS_EX_TRANSPARENT
        Invoke SetWindowLongPtr, hWin, GWL_EXSTYLE, qwStyle
    .ENDIF     
    
    ret
_MUI_TextInit ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextPaint
;------------------------------------------------------------------------------
_MUI_TextPaint PROC FRAME hWin:QWORD
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hdc:HDC
    LOCAL hdcMem:HDC
    LOCAL hBufferBitmap:QWORD 
    LOCAL EnabledState:QWORD
    LOCAL MouseOver:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBackBrush:QWORD


    Invoke IsWindowVisible, hWin
    .IF rax == FALSE
        ;PrintText 'IsWindowVisible Not Visible'
        ret
    .ENDIF
    
    Invoke GetWindowLongPtr, hWin, 0
    .IF rax == 0
        ;PrintText 'Property Mem Not Allocated Yet'
        ret
    .ENDIF

    Invoke BeginPaint, hWin, Addr ps
    mov hdc, rax
    
    ;----------------------------------------------------------
    ; Get some property values
    ;----------------------------------------------------------
    Invoke GetClientRect, hWin, Addr rect
    Invoke MUIGetIntProperty, hWin, @TextEnabledState
    mov EnabledState, rax
    Invoke MUIGetIntProperty, hWin, @TextMouseOver
    mov MouseOver, rax
    Invoke MUIGetExtProperty, hWin, @TextBackColor
    mov BackColor, rax
    Invoke MUIGetIntProperty, hWin, @TextBrush
    mov hBackBrush, rax  

    IFDEF DEBUG64
    PrintText 'hBackBrush'
    PrintDec rax
    PrintText 'BackColor'
    mov rax, BackColor
    ENDIF

    .IF BackColor != -1 ; Not Transparent, background color is specified
        ;----------------------------------------------------------
        ; Setup Double Buffering
        ;----------------------------------------------------------
        Invoke MUIGDIDoubleBufferStart, hWin, hdc, Addr hdcMem, Addr rect, Addr hBufferBitmap
    
        ;----------------------------------------------------------
        ; Background
        ;----------------------------------------------------------
        Invoke _MUI_TextPaintBackground, hWin, hdcMem, Addr rect, EnabledState, MouseOver
    
        ;----------------------------------------------------------
        ; Text
        ;----------------------------------------------------------
        Invoke _MUI_TextPaintText, hWin, hdcMem, Addr rect, EnabledState, MouseOver
    
        ;----------------------------------------------------------
        ; BitBlt from hdcMem back to hdc
        ;----------------------------------------------------------
        Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY
    
        ;----------------------------------------------------------
        ; Finish Double Buffering & Cleanup
        ;----------------------------------------------------------
        Invoke MUIGDIDoubleBufferFinish, hdcMem, hBufferBitmap, 0, 0, 0, 0

    .ELSE ; Text on Transparent Background
    
        .IF hBackBrush == 0
        
            ;PrintText 'Text on Transparent Background'
            ;------------------------------------------------------
            ; Text
            ;------------------------------------------------------    
            Invoke _MUI_TextPaintText, hWin, hdc, Addr rect, EnabledState, MouseOver
        
        .ELSE
            
            ;------------------------------------------------------
            ; Setup Double Buffering
            ;------------------------------------------------------
            Invoke MUIGDIDoubleBufferStart, hWin, hdc, Addr hdcMem, Addr rect, Addr hBufferBitmap
            
            ;------------------------------------------------------
            ; Paint background brush
            ;------------------------------------------------------
            Invoke _MUI_TextPaintBrush, hWin, hdcMem, Addr rect
            
            ;------------------------------------------------------
            ; Text
            ;------------------------------------------------------
            Invoke _MUI_TextPaintText, hWin, hdcMem, Addr rect, EnabledState, MouseOver

            ;------------------------------------------------------
            ; BitBlt from hdcMem back to hdc
            ;------------------------------------------------------
            Invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY
        
            ;------------------------------------------------------
            ; Finish Double Buffering & Cleanup
            ;------------------------------------------------------
            Invoke MUIGDIDoubleBufferFinish, hdcMem, hBufferBitmap, 0, 0, 0, 0

        .ENDIF
        
    .ENDIF
    
    Invoke EndPaint, hWin, Addr ps
    ret
_MUI_TextPaint ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextPaintBackground
;------------------------------------------------------------------------------
_MUI_TextPaintBackground PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD
    LOCAL BackColor:QWORD
    LOCAL hBrush:QWORD
    LOCAL hOldBrush:QWORD

    .IF bEnabledState == TRUE
        .IF bMouseOver == FALSE
            Invoke MUIGetExtProperty, hWin, @TextBackColor              ; Normal back color
        .ELSE
            Invoke MUIGetExtProperty, hWin, @TextBackColorAlt           ; Mouse over back color
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @TextBackColorDisabled          ; Disabled back color
    .ENDIF
    .IF eax == 0 ; try to get default back color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @TextBackColor                  ; fallback to default Normal back color
    .ENDIF
    mov BackColor, rax
    
    .IF BackColor == -1 ; transparent
        ret
    .ENDIF

    Invoke MUIGDIPaintFill, hdc, lpRect, BackColor

;    Invoke GetStockObject, DC_BRUSH
;    mov hBrush, rax
;    Invoke SelectObject, hdc, rax
;    mov hOldBrush, rax
;    Invoke SetDCBrushColor, hdc, dword ptr BackColor
;    Invoke FillRect, hdc, lpRect, hBrush
;
;    .IF hOldBrush != 0
;        Invoke SelectObject, hdc, hOldBrush
;        Invoke DeleteObject, hOldBrush
;    .ENDIF     
;    .IF hBrush != 0
;        Invoke DeleteObject, hBrush
;    .ENDIF      
    ret
_MUI_TextPaintBackground ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextPaintBrush
;------------------------------------------------------------------------------
_MUI_TextPaintBrush PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD
    LOCAL hBackBrush:QWORD
    LOCAL hOldBrush:QWORD
    LOCAL qwXOrg:QWORD
    LOCAL qwYOrg:QWORD
    LOCAL rect:RECT
    
    Invoke MUIGetIntProperty, hWin, @TextBrush
    .IF rax == 0
        ret
    .ENDIF
    mov hBackBrush, rax

    Invoke MUIGetIntProperty, hWin, @TextBrushOrgX
    mov qwXOrg, rax
    Invoke MUIGetIntProperty, hWin, @TextBrushOrgY
    mov qwYOrg, rax

    Invoke MUIGDIPaintBrush, hdc, lpRect, hBackBrush, qwXOrg, qwYOrg

    ret
_MUI_TextPaintBrush ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextPaintText
;------------------------------------------------------------------------------
_MUI_TextPaintText PROC FRAME hWin:QWORD, hdc:QWORD, lpRect:QWORD, bEnabledState:QWORD, bMouseOver:QWORD
    LOCAL TextColor:QWORD
    LOCAL BackColor:QWORD
    LOCAL hFont:QWORD
    LOCAL hOldFont:QWORD
    LOCAL LenText:QWORD    
    LOCAL qwTextStyle:QWORD
    LOCAL qwStyle:QWORD
    LOCAL bUTF8:DWORD
    LOCAL rect:RECT
    LOCAL lpMUITextBuffer:QWORD
    LOCAL lpMUITextUTF8Buffer:QWORD
    
    IFDEF DEBUG64
    PrintText '_MUI_TextPaintText'
    ENDIF
    
    Invoke CopyRect, Addr rect, lpRect

    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax

    mov rax, qwStyle
    and rax, MUITS_UTF8
    .IF rax == MUITS_UTF8
        mov bUTF8, TRUE
    .ELSE
        mov bUTF8, FALSE
    .ENDIF    

    Invoke MUIGetIntProperty, hWin, @TextBuffer
    .IF rax == FALSE
        ret
    .ENDIF
    mov lpMUITextBuffer, rax
    
    Invoke MUIGetExtProperty, hWin, @TextFont        
    mov hFont, rax

    .IF bEnabledState == TRUE
        .IF bMouseOver == FALSE
            Invoke MUIGetExtProperty, hWin, @TextBackColor        ; Normal back color
        .ELSE
            Invoke MUIGetExtProperty, hWin, @TextBackColorAlt     ; Mouse over back color
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @TextBackColorDisabled        ; Disabled back color
    .ENDIF
    .IF rax == 0 ; try to get default back color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @TextBackColor                ; fallback to default Normal back color
    .ENDIF    
    mov BackColor, rax    

    .IF bEnabledState == TRUE
        .IF bMouseOver == FALSE
            Invoke MUIGetExtProperty, hWin, @TextColor        ; Normal text color
        .ELSE
            Invoke MUIGetExtProperty, hWin, @TextColorAlt     ; Mouse over text color
        .ENDIF
    .ELSE
        Invoke MUIGetExtProperty, hWin, @TextColorDisabled        ; Disabled text color
    .ENDIF
    .IF rax == 0 ; try to get default text color if others are set to 0
        Invoke MUIGetExtProperty, hWin, @TextColor                ; fallback to default Normal text color
    .ENDIF  
    mov TextColor, rax
    
    IFDEF DEBUG64
    PrintText '_MUI_TextPaintText:TextColor'
    PrintDec rax
    ENDIF
    
    .IF lpMUITextBuffer != 0
        Invoke GetWindowText, hWin, lpMUITextBuffer, MUI_TEXT_MAX_CHARS ; length of string is returned in eax
    .ELSE
        mov rax, 0
    .ENDIF
    mov LenText, rax
    
    IFDEF DEBUG64
    PrintText '_MUI_TextPaintText:LenText'
    PrintDec rax
    ENDIF
    
    Invoke SelectObject, hdc, hFont
    mov hOldFont, rax

    IFDEF DEBUG64
    PrintText '_MUI_TextPaintText:hFont'
    mov rax, hFont
    PrintDec rax
    ENDIF

    .IF BackColor != -1 ; transaprent
        Invoke SetBkMode, hdc, OPAQUE
        Invoke SetBkColor, hdc, dword ptr BackColor
    .ELSE
        Invoke SetBkMode, hdc, TRANSPARENT
    .ENDIF
    Invoke SetTextColor, hdc, dword ptr TextColor

    mov rax, qwStyle
    and rax, MUITS_SINGLELINE
    .IF rax == MUITS_SINGLELINE
        mov qwTextStyle, DT_SINGLELINE
    .ELSE
        mov qwTextStyle, DT_WORDBREAK or DT_EDITCONTROL
    .ENDIF
    mov rax, qwStyle
    and rax, (MUITS_ALIGN_CENTER or MUITS_ALIGN_RIGHT)
    .IF rax == MUITS_ALIGN_CENTER
        or qwTextStyle, DT_CENTER
    .ELSEIF rax == MUITS_ALIGN_RIGHT
        or qwTextStyle, DT_RIGHT
    .ELSEIF rax == MUITS_ALIGN_CENTER or MUITS_ALIGN_RIGHT ; MUITS_ALIGN_JUSTIFY
        or qwTextStyle, DT_LEFT        
    .ELSE
        or qwTextStyle, DT_LEFT
    .ENDIF

    Invoke DrawText, hdc, lpMUITextBuffer, dword ptr LenText, Addr rect, dword ptr qwTextStyle
    
    .IF hOldFont != 0
        Invoke SelectObject, hdc, hOldFont
        Invoke DeleteObject, hOldFont
    .ENDIF

    ret
_MUI_TextPaintText ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Returns TRUE if CR LF found in string, otherwise returns FALSE
;------------------------------------------------------------------------------
_MUI_TextCheckMultiline PROC FRAME USES RBX hWin:QWORD, lpszText:QWORD
    LOCAL lenText:QWORD
    LOCAL Cnt:QWORD
    LOCAL bMultiline:QWORD
    LOCAL qwStyle:QWORD
    
    ;PrintText '_MUI_TextCheckMultiline'
    
    .IF lpszText == 0
        ret
    .ENDIF
    Invoke lstrlen, lpszText
    mov lenText, rax
    
    Invoke GetWindowLongPtr, hWin, GWL_STYLE
    mov qwStyle, rax  
    
    mov bMultiline, FALSE
    mov rbx, lpszText
    mov Cnt, 0
    mov rax, 0
    .WHILE rax < lenText
        IFDEF MUI_UNICODE
        movzx rax, word ptr [rbx]
        .IF ax == 0
            mov bMultiline, FALSE
            .BREAK
        .ELSEIF ax == 10 || ax == 13
            mov bMultiline, TRUE
            .BREAK 
        .ENDIF
        inc rbx
        inc rbx
        inc Cnt
        inc Cnt        
        ELSE
        movzx rax, byte ptr [rbx]
        .IF al == 0
            mov bMultiline, FALSE
            .BREAK
        .ELSEIF al == 10 || al == 13
            mov bMultiline, TRUE
            .BREAK 
        .ENDIF
        inc rbx
        inc Cnt
        ENDIF
        mov rax, Cnt
    .ENDW


    mov rax, qwStyle
    .IF bMultiline == FALSE
        or rax, MUITS_SINGLELINE
    .ELSE
        and rax, (-1 xor MUITS_SINGLELINE)
    .ENDIF
    mov qwStyle, rax
    Invoke SetWindowLongPtr, hWin, GWL_STYLE, qwStyle

    mov rax, bMultiline
    ret

_MUI_TextCheckMultiline ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; Create Text size and font family based on style flags passed to control
;------------------------------------------------------------------------------
_MUI_TextSetFontFamilySize PROC FRAME USES RBX hWin:QWORD, qwStyle:QWORD
    LOCAL MUITextFont:QWORD
    LOCAL hFont:QWORD
    LOCAL dwFontHeight:DWORD
    LOCAL dwFontWeight:DWORD
    LOCAL dwFontFamily:DWORD
    LOCAL dwFontSize:DWORD
    LOCAL bFontBold:DWORD
    LOCAL bFontItalic:DWORD
    LOCAL bFontUnderline:DWORD
    LOCAL ncm:NONCLIENTMETRICS
    LOCAL lfnt:LOGFONT       

    Invoke MUIGetExtProperty, hWin, @TextFont
    mov hFont, rax
    .IF hFont != NULL
        Invoke DeleteObject, hFont
    .ENDIF

    ;--------------------------------
    ; Get font family
    ;--------------------------------
    mov rax, qwStyle
    and eax, MUI_TEXT_FONTTYPE_MASK
    mov dwFontFamily, eax
    
    .IF eax == MUITS_FONT_DIALOG
        Invoke GetParent, hWin
        Invoke SendMessage, rax, WM_GETFONT, 0, 0 ; hope parent is the dialog or container that has a font being used.
        mov hFont, rax
        Invoke MUISetExtProperty, hWin, @TextFont, hFont
    .ELSE
        mov eax, dwFontFamily
        .IF eax == MUITS_FONT_SEGOE
            lea rax, szMUITextFontSegoe
        .ELSEIF eax == MUITS_FONT_TAHOMA
            lea rax, szMUITextFontTahoma
        .ELSEIF eax == MUITS_FONT_ARIAL
            lea rax, szMUITextFontArial
        .ELSEIF eax == MUITS_FONT_TIMES
            lea rax, szMUITextFontTimes
        .ELSEIF eax == MUITS_FONT_COURIER
            lea rax, szMUITextFontCourier
        .ELSEIF eax == MUITS_FONT_VERDANA    
            lea rax, szMUITextFontVerdana
        .ELSE
            lea rax, szMUITextFontSegoe
        .ENDIF
        mov MUITextFont, rax

        ;--------------------------------
        ; Get font size
        ;--------------------------------        
        mov rax, qwStyle
        and eax, MUI_TEXT_FONTSIZE_MASK
        mov dwFontSize, eax
       .IF eax == MUITS_7PT
            Invoke MUIPointSizeToLogicalUnit, hWin, 7
        .ELSEIF eax == MUITS_8PT ; 8pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 8
        .ELSEIF eax == MUITS_9PT
            Invoke MUIPointSizeToLogicalUnit, hWin, 9
         .ELSEIF eax == MUITS_10PT ; 10pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 10
        .ELSEIF eax == MUITS_11PT; 11pt 
            Invoke MUIPointSizeToLogicalUnit, hWin, 11
        .ELSEIF eax == MUITS_12PT; 12pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 12
         .ELSEIF eax == MUITS_13PT; 13pt 
            Invoke MUIPointSizeToLogicalUnit, hWin, 13
        .ELSEIF eax == MUITS_14PT ; 14pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 14
         .ELSEIF eax == MUITS_15PT ; 15pt 
            Invoke MUIPointSizeToLogicalUnit, hWin, 15
        .ELSEIF eax == MUITS_16PT ; 16pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 16
        .ELSEIF eax == MUITS_18PT ; 18pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 18
        .ELSEIF eax == MUITS_20PT ; 20pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 20
        .ELSEIF eax == MUITS_22PT ; 22pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 22
        .ELSEIF eax == MUITS_24PT ; 24pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 24
        .ELSEIF eax == MUITS_28PT ; 28pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 28
        .ELSEIF eax == MUITS_32PT ; 32pt
            Invoke MUIPointSizeToLogicalUnit, hWin, 32
        .ELSE
            Invoke MUIPointSizeToLogicalUnit, hWin, 8
        .ENDIF
        mov dwFontHeight, eax
        
        ;--------------------------------
        ; Get font bold, italic, underline
        ;--------------------------------
        mov rax, qwStyle
        and eax, MUITS_FONT_BOLD
        .IF eax == MUITS_FONT_BOLD
            mov bFontBold, TRUE
            mov dwFontWeight, FW_BOLD
        .ELSE
            mov bFontBold, FALSE
            mov dwFontWeight, FW_NORMAL
        .ENDIF
        mov rax, qwStyle
        and eax, MUITS_FONT_ITALIC
        .IF eax == MUITS_FONT_ITALIC
            mov bFontItalic, TRUE
        .ELSE
            mov bFontItalic, FALSE
        .ENDIF
        mov rax, qwStyle
        and eax, MUITS_FONT_UNDERLINE
        .IF eax == MUITS_FONT_UNDERLINE
            mov bFontUnderline, TRUE
        .ELSE
            mov bFontUnderline, FALSE
        .ENDIF
        
        ;--------------------------------
        ; Create font 
        ;--------------------------------
        Invoke _MUI_TextGetFontTableHandle, hWin, qwStyle
        mov hFont, rax
        .IF rax == 0
            ;PrintText 'New Font'
            Invoke CreateFont, dwFontHeight, 0,0,0, dwFontWeight, bFontItalic, bFontUnderline, 0,0,0,0, PROOF_QUALITY, FF_DONTCARE, MUITextFont
            mov hFont, rax
            
            ; Add error checking in case font doesnt exist
            ; https://github.com/mrfearless/ModernUI/issues/8
            ; If it doesnt exist we can try to use existing lfMessageFont and adjust that
            .IF hFont == NULL
                Invoke SystemParametersInfo, SPI_GETNONCLIENTMETRICS, SIZEOF NONCLIENTMETRICS, Addr ncm, 0
                ; copy to lfMessageFont to lfnt and set values 
                lea rbx, ncm.lfMessageFont
                Invoke RtlMoveMemory, Addr lfnt, rbx, SIZEOF LOGFONT
                mov eax, dwFontHeight
                mov lfnt.lfHeight, eax
                mov eax, dwFontWeight
                mov lfnt.lfWeight, eax
                mov eax, bFontItalic
                mov lfnt.lfItalic, al
                mov eax, bFontUnderline
                mov lfnt.lfUnderline, al
                Invoke CreateFontIndirect, Addr lfnt
                mov hFont, rax
            .ENDIF            
            
            ; save handle to fonttable
            Invoke _MUI_TextSetFontTableHandle, hWin, qwStyle, hFont
        .ELSE ; use handle from fonttable instead
        .ENDIF
        Invoke MUISetExtProperty, hWin, @TextFont, hFont
    .ENDIF
    mov rax, hFont
    ret

_MUI_TextSetFontFamilySize ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextGetFontTableHandle
;
; Gets handle to font in our font table, allows us to re-use existing font handle
; if a previous ModernUI_Text control has created that font already. Instead of
; creating many fonts for each control individually this allows us to share the font
; handle when its already been created for a specific font family, and size and for
; bold or italic or underline (or combination)
;------------------------------------------------------------------------------
_MUI_TextGetFontTableHandle PROC FRAME USES RBX hWin:QWORD, qwStyle:QWORD
    LOCAL dwFontSizeValue:DWORD
    LOCAL dwFontTypeValue:DWORD
    LOCAL dwFontTypeIndex:DWORD
    LOCAL bFontBold:DWORD
    LOCAL bFontItalic:DWORD
    LOCAL bFontUnderline:DWORD
    LOCAL OffsetTextFont:QWORD
    LOCAL OffsetTextFontSize:QWORD
    LOCAL ptrTextFontEntry:QWORD
    
    lea rax, MUITextFontTable
    .IF rax == 0
        ret
    .ENDIF
    
    mov rax, qwStyle
    and eax, MUITS_FONT_BOLD
    .IF eax == MUITS_FONT_BOLD
        mov bFontBold, TRUE
    .ELSE
        mov bFontBold, FALSE
    .ENDIF

    mov rax, qwStyle
    and eax, MUITS_FONT_ITALIC
    .IF eax == MUITS_FONT_ITALIC
        mov bFontItalic, TRUE
    .ELSE
        mov bFontItalic, FALSE
    .ENDIF

    mov rax, qwStyle
    and eax, MUITS_FONT_UNDERLINE
    .IF eax == MUITS_FONT_UNDERLINE
        mov bFontUnderline, TRUE
    .ELSE
        mov bFontUnderline, FALSE
    .ENDIF

    mov rax, qwStyle
    and eax, MUI_TEXT_FONTSIZE_MASK
    mov dwFontSizeValue, eax

    ; text font entry is (index * MUI_TEXT_FONT_ENTRIES_SIZE) + (sizevalue * MUI_TEXT_FONT_ENTRY)

    mov rax, qwStyle
    and eax, MUI_TEXT_FONTTYPE_MASK
    mov dwFontTypeValue, eax
    shr eax, 4
    mov dwFontTypeIndex, eax
    mov rbx, MUI_TEXT_FONT_ENTRIES_SIZE
    mul rbx
    mov OffsetTextFont, rax

    mov rbx, SIZEOF MUI_TEXT_FONT_ENTRY
    mov eax, dwFontSizeValue
    mul rbx
    mov OffsetTextFontSize, rax
    
    lea rax, MUITextFontTable
    add rax, OffsetTextFont
    add rax, OffsetTextFontSize    
    mov ptrTextFontEntry, rax
    
    mov rbx, ptrTextFontEntry
    
    .IF bFontBold == FALSE && bFontItalic == FALSE && bFontUnderline == FALSE ; normal
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFont
        
    .ELSEIF bFontBold == TRUE && bFontItalic == FALSE && bFontUnderline == FALSE ; bold only
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFontBold
        
    .ELSEIF bFontBold == FALSE && bFontItalic == TRUE && bFontUnderline == FALSE ; italic only
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFontItalic
    
    .ELSEIF bFontBold == FALSE && bFontItalic == FALSE && bFontUnderline == TRUE ; underline only 
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFontUnderline
    
    .ELSEIF bFontBold == TRUE && bFontItalic == TRUE && bFontUnderline == FALSE ; bold + italic
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFontBoldItalic
    
    .ELSEIF bFontBold == TRUE && bFontItalic == FALSE && bFontUnderline == TRUE ; bold + underline
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFontBoldUnderline
    
    .ELSEIF bFontBold == TRUE && bFontItalic == TRUE && bFontUnderline == TRUE ; bold + italic + underline
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFontBoldItalicUnderline
    
    .ELSEIF bFontBold == FALSE && bFontItalic == TRUE && bFontUnderline == TRUE ; italic + underline
        mov rax, [rbx].MUI_TEXT_FONT_ENTRY.hFontItalicUnderline       

    .ENDIF

    ret
_MUI_TextGetFontTableHandle ENDP


MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextSetFontTableHandle
;
; Sets handle to font in our font table, allows us to re-use existing font handle
; if a previous ModernUI_Text control has created that font already. Instead of
; creating many fonts for each control individually this allows us to share the font
; handle when its already been created for a specific font family, and size and for
; bold or italic or underline (or combination)
;------------------------------------------------------------------------------
_MUI_TextSetFontTableHandle PROC FRAME USES RBX hWin:QWORD, qwStyle:QWORD, hFont:QWORD
    LOCAL dwFontSizeValue:DWORD
    LOCAL dwFontTypeValue:DWORD
    LOCAL dwFontTypeIndex:DWORD
    LOCAL bFontBold:DWORD
    LOCAL bFontItalic:DWORD
    LOCAL bFontUnderline:DWORD
    LOCAL OffsetTextFont:QWORD
    LOCAL OffsetTextFontSize:QWORD
    LOCAL ptrTextFontEntry:QWORD
    
    lea rax, MUITextFontTable
    .IF rax == 0 || hFont == 0
        ret
    .ENDIF
    
    mov rax, qwStyle
    and eax, MUITS_FONT_BOLD
    .IF eax == MUITS_FONT_BOLD
        mov bFontBold, TRUE
    .ELSE
        mov bFontBold, FALSE
    .ENDIF

    mov rax, qwStyle
    and eax, MUITS_FONT_ITALIC
    .IF eax == MUITS_FONT_ITALIC
        mov bFontItalic, TRUE
    .ELSE
        mov bFontItalic, FALSE
    .ENDIF

    mov rax, qwStyle
    and eax, MUITS_FONT_UNDERLINE
    .IF eax == MUITS_FONT_UNDERLINE
        mov bFontUnderline, TRUE
    .ELSE
        mov bFontUnderline, FALSE
    .ENDIF

    mov rax, qwStyle
    and eax, MUI_TEXT_FONTSIZE_MASK
    mov dwFontSizeValue, eax

    ; text font entry is (index * MUI_TEXT_FONT_ENTRIES_SIZE) + (sizevalue * MUI_TEXT_FONT_ENTRY)

    mov rax, qwStyle
    and eax, MUI_TEXT_FONTTYPE_MASK
    mov dwFontTypeValue, eax
    shr eax, 4
    mov dwFontTypeIndex, eax
    mov rbx, MUI_TEXT_FONT_ENTRIES_SIZE
    mul rbx
    mov OffsetTextFont, rax

    mov rbx, SIZEOF MUI_TEXT_FONT_ENTRY
    mov eax, dwFontSizeValue
    mul rbx
    mov OffsetTextFontSize, rax
    
    lea rax, MUITextFontTable
    add rax, OffsetTextFont
    add rax, OffsetTextFontSize    
    mov ptrTextFontEntry, rax

    mov rbx, ptrTextFontEntry
    mov rax, hFont
    
    .IF bFontBold == FALSE && bFontItalic == FALSE && bFontUnderline == FALSE ; normal
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFont, rax
        
    .ELSEIF bFontBold == TRUE && bFontItalic == FALSE && bFontUnderline == FALSE ; bold only
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFontBold, rax
        
    .ELSEIF bFontBold == FALSE && bFontItalic == TRUE && bFontUnderline == FALSE ; italic only
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFontItalic, rax
    
    .ELSEIF bFontBold == FALSE && bFontItalic == FALSE && bFontUnderline == TRUE ; underline only 
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFontUnderline, rax
    
    .ELSEIF bFontBold == TRUE && bFontItalic == TRUE && bFontUnderline == FALSE ; bold + italic
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFontBoldItalic, rax
    
    .ELSEIF bFontBold == TRUE && bFontItalic == FALSE && bFontUnderline == TRUE ; bold + underline
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFontBoldUnderline, rax
    
    .ELSEIF bFontBold == TRUE && bFontItalic == TRUE && bFontUnderline == TRUE ; bold + italic + underline
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFontBoldItalicUnderline, rax
    
    .ELSEIF bFontBold == FALSE && bFontItalic == TRUE && bFontUnderline == TRUE ; italic + underline
        mov [rbx].MUI_TEXT_FONT_ENTRY.hFontItalicUnderline, rax

    .ENDIF

    ret
_MUI_TextSetFontTableHandle ENDP

MUI_ALIGN
;-------------------------------------------------------------------------------------
; Check if font set via MUITextSetProperty is acutally a font, if it isnt return FALSE
;-------------------------------------------------------------------------------------
_MUI_TextCheckSetFont PROC FRAME hWin:QWORD, hFont:QWORD
    LOCAL lfnt:LOGFONT 
    
    .IF hWin == 0 || hFont == 0
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke GetObject, hFont, SIZEOF lfnt, Addr lfnt
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    mov rax, TRUE
    ret

_MUI_TextCheckSetFont ENDP


MUI_ALIGN
;-------------------------------------------------------------------------------------
; Convert wide Unicode String to an UTF8 string
;-------------------------------------------------------------------------------------
_MUI_TextUTF8Encode PROC FRAME lpString:QWORD
    LOCAL qwUTF8StringSize:QWORD
    LOCAL lpUTF8String:QWORD

    .IF lpString == NULL
        mov rax, NULL
        ret
    .ENDIF
    Invoke WideCharToMultiByte, CP_UTF8, 0, lpString, -1, NULL, 0, NULL, NULL
    .IF rax == 0
        ret
    .ENDIF
    mov qwUTF8StringSize, rax
    ;shl eax, 1 ; x2 to get non wide char count
    add rax, 4 ; add 4 for good luck and nulls
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    .IF rax == NULL
        ret
    .ENDIF
    mov lpUTF8String, rax    
    Invoke WideCharToMultiByte, CP_UTF8, 0, lpString, -1, lpUTF8String, dword ptr qwUTF8StringSize, NULL, NULL
    .IF rax == 0
        ret
    .ENDIF
    mov rax, lpUTF8String
    ret
_MUI_TextUTF8Encode ENDP


MUI_ALIGN
;-------------------------------------------------------------------------------------
; Convert an UTF8 string to a wide Unicode String
;-------------------------------------------------------------------------------------
_MUI_TextUTF8Decode PROC FRAME lpString:QWORD
    LOCAL qwWideStringSize:QWORD
    LOCAL lpWideString:QWORD
    
    .IF lpString == NULL
        mov rax, NULL
        ret
    .ENDIF
    Invoke MultiByteToWideChar, CP_UTF8, 0, lpString, -1, NULL, 0
    .IF rax == 0
        ret
    .ENDIF
    mov qwWideStringSize, rax
    shl rax, 1 ; x2 to get non wide char count
    add rax, 4 ; add 4 for good luck and nulls
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    .IF rax == NULL
        ret
    .ENDIF
    mov lpWideString, rax
    Invoke MultiByteToWideChar, CP_UTF8, 0, lpString, -1, lpWideString, dword ptr qwWideStringSize
    .IF rax == 0
        ret
    .ENDIF
    mov rax, lpWideString
    ret
_MUI_TextUTF8Decode ENDP


MUI_ALIGN
;-------------------------------------------------------------------------------------
; Frees a converted string which was created by UTF8_Decode or UTF8_Encode
;-------------------------------------------------------------------------------------
_MUI_TextUTF8Free PROC FRAME lpString:QWORD
    mov rax, lpString
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    Invoke GlobalFree, rax
    mov rax, TRUE
    ret
_MUI_TextUTF8Free ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; _MUI_TextUpdateBrushOrg - Updates brush org for relative brush after a 
; control has moved
;------------------------------------------------------------------------------
_MUI_TextUpdateBrushOrg PROC FRAME hWin:QWORD
    LOCAL rect:RECT
    LOCAL x:QWORD
    LOCAL y:QWORD
    LOCAL qwBrushOrgX:QWORD
    LOCAL qwBrushOrgY:QWORD
    
    Invoke MUIGetIntProperty, hWin, @TextBrushOrgOriginalX
    mov qwBrushOrgX, rax

    Invoke MUIGetIntProperty, hWin, @TextBrushOrgOriginalY
    mov qwBrushOrgY, rax
    
    Invoke MUIGetParentRelativeWindowRect, hWin, Addr rect
    
    xor rax, rax
    mov eax, rect.left
    sub eax, dword ptr qwBrushOrgX
    neg eax
    mov x, rax
    
    xor rax, rax
    mov eax, rect.top
    sub eax, dword ptr qwBrushOrgY
    neg eax
    mov y, rax

    Invoke MUISetIntProperty, hWin, @TextBrushOrgX, x
    Invoke MUISetIntProperty, hWin, @TextBrushOrgY, y
    Invoke InvalidateRect, hWin, NULL, FALSE
    ret
_MUI_TextUpdateBrushOrg ENDP


MUI_ALIGN
;-------------------------------------------------------------------------------------
; Sets internal buffer size for text - useful if you know ahead of time what size
; buffer should be - as in you know the text length expected.
;-------------------------------------------------------------------------------------
MUITextSetBufferSize PROC FRAME hWin:QWORD, qwSize:QWORD
    .IF hWin == 0 || qwSize == 0
        mov rax, FALSE
        ret
    .ENDIF
    Invoke MUIGetIntProperty, hWin, @TextBuffer
    .IF rax != 0 ; free existing buffer
        Invoke GlobalFree, rax
    .ENDIF
    mov rax, qwSize
    IFDEF MUI_UNICODE
    shl rax, 1 ; x2
    ENDIF
    and rax, 0FFFFFFFFFFFFFFF0h ; mask 
    add rax, 16d ; round up to 16bytes
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax
    .IF rax != NULL
        Invoke MUISetIntProperty, hWin, @TextBuffer, rax
        mov rax, TRUE
    .ELSE
        Invoke MUISetIntProperty, hWin, @TextBuffer, 0
        mov rax, FALSE
    .ENDIF
    ret
MUITextSetBufferSize ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUITextSetBackBrush - Set a background brush for text - used for text
; that have @TextBackColor set to -1 for transparency type effect.
; dwBrushPos: 0 = brush position is relative to control's position, and adjusted
; by x and y (typically 0,0 tho) - if brush image is set to parent's 0,0 then 
; control will capture and paint the part of the brush that is relative to it's 
; background position. Otherwise if dwBrushPos = 1 then its an absolute position 
; in a brush/bitmap
;
; If dwBrushPos is relative, then sizing/moving will readjust the brush offset
; to use for background
;------------------------------------------------------------------------------
MUITextSetBackBrush PROC FRAME hControl:QWORD, hBrush:QWORD, qwBrushOrgX:QWORD, qwBrushOrgY:QWORD, qwBrushPos:QWORD
    LOCAL rect:RECT
    LOCAL x:QWORD
    LOCAL y:QWORD
    
    mov rax, qwBrushPos
    .IF rax == 0 ; brush position is relative to control's position, and adjusted by x and y 
        Invoke MUIGetParentRelativeWindowRect, hControl, Addr rect
        
        xor rax, rax
        mov eax, rect.left
        sub eax, dword ptr qwBrushOrgX
        neg eax
        mov x, rax
        
        xor rax, rax
        mov eax, rect.top
        sub eax, dword ptr qwBrushOrgY
        neg eax
        mov y, rax
        
    .ELSE ; brush position is absolute, but adjusted by x and y as specified
        
        xor rax, rax
        mov eax, dword ptr qwBrushOrgX
        neg eax
        mov x, rax
        
        xor rax, rax
        mov eax, dword ptr qwBrushOrgY
        neg eax
        mov y, rax
        
    .ENDIF
    
    Invoke MUISetIntProperty, hControl, @TextBrush, hBrush
    Invoke MUISetIntProperty, hControl, @TextBrushOrgOriginalX, qwBrushOrgX
    Invoke MUISetIntProperty, hControl, @TextBrushOrgOriginalY, qwBrushOrgY
    Invoke MUISetIntProperty, hControl, @TextBrushOrgX, x
    Invoke MUISetIntProperty, hControl, @TextBrushOrgY, y
    Invoke MUISetIntProperty, hControl, @TextBrushPos, qwBrushPos
    Invoke InvalidateRect, hControl, NULL, FALSE
    ret
MUITextSetBackBrush ENDP

MUI_ALIGN
;------------------------------------------------------------------------------
; MUITextLoadBackBrush
;------------------------------------------------------------------------------
MUITextLoadBackBrush PROC FRAME hControl:QWORD, idResBitmap:QWORD, qwBrushOrgX:QWORD, qwBrushOrgY:QWORD, qwBrushPos:QWORD
    LOCAL hinstance:QWORD
    LOCAL hBrushBitmap:QWORD
    LOCAL hBrush:QWORD
    
    .IF idResBitmap == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MUIGetExtProperty, hControl, @TextDllInstance
    .IF rax == 0
        Invoke GetModuleHandle, NULL
    .ENDIF
    mov hinstance, rax
    
    Invoke LoadBitmap, hinstance, idResBitmap
    mov hBrushBitmap, rax
    Invoke MUISetIntProperty, hControl, @TextBrushBitmap, hBrushBitmap
    
    Invoke CreatePatternBrush, hBrushBitmap
    mov hBrush, rax
    
    Invoke MUITextSetBackBrush, hControl, hBrush, qwBrushOrgX, qwBrushOrgY, qwBrushPos
    
    ret
MUITextLoadBackBrush ENDP



IFDEF MUI_DRAWTEXTEXT
include ModernUI_DrawTextEXT.asm
ENDIF





MODERNUI_LIBEND
