;==============================================================================
;
; ModernUI Library x64 v0.0.0.7
;
; Copyright (c) 2023 by fearless
;
; All Rights Reserved
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


MUI_ALIGN                       TEXTEQU <ALIGN 16>  ; Default ModernUI alignment

;------------------------------------------
; ModernUI Library Typedefs
;------------------------------------------
IFDEF _WIN64
; ModernUI Typedefs
MUIWND                          TYPEDEF QWORD       ; Alias for HWND window handle for a ModernUI control handle, typically defined as hWin
MUIPROPERTIES                   TYPEDEF QWORD       ; Typedef for use of MUI_INTERNAL_PROPERTIES, MUI_EXTERNAL_PROPERTIES etc
MUIPROPERTY                     TYPEDEF QWORD       ; Typedef for MUIGetIntProperty/MUIGetExtProperty/MUISetIntProperty/MUISetExtProperty Property parameter
MUIPROPERTYVALUE                TYPEDEF QWORD       ; Typedef for MUISetIntProperty/MUISetExtProperty PropertyValue parameter
MUIVALUE                        TYPEDEF QWORD       ; QWORD in x64
LPMUIVALUE                      TYPEDEF PTR MUIVALUE; Pointer to MUIVALUE
MUILPVALUE                      TYPEDEF PTR MUIVALUE; Pointer to MUIVALUE
MUILPSTRING                     TYPEDEF QWORD       ; Pointer to zero terminated string
MUIIT                           TYPEDEF QWORD       ; Image type
MUIIL                           TYPEDEF QWORD       ; Image location
MUIPFS                          TYPEDEF QWORD       ; Paint frame style
MUIPGS                          TYPEDEF QWORD       ; Paint gradient style
MUIIMAGE                        TYPEDEF QWORD       ; HBITMAP, HICON or GPIMAGE
LPMUIIMAGE                      TYPEDEF PTR MUIIMAGE; Pointer to MUIIMAGE
MUICOLORRGB                     TYPEDEF QWORD       ; COLORREF color value using MUI_RGBCOLOR macro
MUICOLORARGB                    TYPEDEF QWORD       ; ARGB color value using MUI_ARGBCOLOR macro
; Expand on or add to some of the GDI+ data types:
GPGRAPHICS                      TYPEDEF QWORD       ; GDI+ graphics context
LPGPGRAPHICS                    TYPEDEF PTR GPGRAPHICS
GPIMAGE                         TYPEDEF QWORD       ; GDI+ image
LPGPIMAGE                       TYPEDEF PTR GPIMAGE ; Pointer to GDI+ image
; Expand on or add to some of the common Windows data types:
LPRECT                          TYPEDEF PTR RECT    ; Pointer to RECT
LPHBITMAP                       TYPEDEF PTR HBITMAP ; Pointer to HBITMAP
LPHDC                           TYPEDEF PTR HDC     ; Pointer to HDC
POINTER                         TYPEDEF QWORD       ; QWORD in x64
RESID                           TYPEDEF QWORD       ; Resource ID 
ELSE ; WIN32 x86
; ModernUI Typedefs
MUIWND                          TYPEDEF DWORD       ; Alias for HWND window handle for a ModernUI control handle, typically defined as hWin
MUIPROPERTIES                   TYPEDEF DWORD       ; Typedef for use of MUI_INTERNAL_PROPERTIES, MUI_EXTERNAL_PROPERTIES etc
MUIPROPERTY                     TYPEDEF DWORD       ; Typedef for MUIGetIntProperty/MUIGetExtProperty/MUISetIntProperty/MUISetExtProperty Property parameter
MUIPROPERTYVALUE                TYPEDEF DWORD       ; Typedef for MUISetIntProperty/MUISetExtProperty PropertyValue parameter
MUIVALUE                        TYPEDEF DWORD       ; DWORD in x86
LPMUIVALUE                      TYPEDEF PTR MUIVALUE; Pointer to MUIVALUE
MUILPVALUE                      TYPEDEF PTR MUIVALUE; Pointer to MUIVALUE
MUILPSTRING                     TYPEDEF DWORD       ; Pointer to zero terminated string
MUIIT                           TYPEDEF DWORD       ; Image type
MUIIL                           TYPEDEF DWORD       ; Image location
MUIPFS                          TYPEDEF DWORD       ; Paint frame style
MUIPGS                          TYPEDEF DWORD       ; Paint gradient style
MUIIMAGE                        TYPEDEF DWORD       ; HBITMAP, HICON or GPIMAGE
LPMUIIMAGE                      TYPEDEF PTR MUIIMAGE; Pointer to MUIIMAGE
MUICOLORRGB                     TYPEDEF DWORD       ; COLORREF color value using MUI_RGBCOLOR macro
MUICOLORARGB                    TYPEDEF DWORD       ; ARGB color value using MUI_ARGBCOLOR macro
; Expand on or add to some of the GDI+ data types:
GPGRAPHICS                      TYPEDEF DWORD       ; GDI+ graphics context
LPGPGRAPHICS                    TYPEDEF PTR GPGRAPHICS
GPIMAGE                         TYPEDEF DWORD       ; GDI+ image
LPGPIMAGE                       TYPEDEF PTR GPIMAGE ; Pointer to GDI+ image
; Expand on or add to some of the common Windows data types:
LPRECT                          TYPEDEF PTR RECT    ; Pointer to RECT
LPHBITMAP                       TYPEDEF PTR HBITMAP ; Pointer to HBITMAP
LPHDC                           TYPEDEF PTR HDC     ; Pointer to HDC
POINTER                         TYPEDEF DWORD       ; DWORD in x86
RESID                           TYPEDEF DWORD       ; Resource ID 
ENDIF

;------------------------------------------------------------------------------------
; UNICODE SUPPORT
;------------------------------------------------------------------------------------
; To explicitly enable unicode support uncomment the define for MUI_UNICODE below
; This will force all controls that are built to use the unicode versions of the 
; ModernUI Library functions.
;
; If you wish to just compile one specific control as unicode, add the MUI_UNICODE
; define in the control's source before the include ModernUI.inc like below:
;------------------------------------------------------------------------------------
;MUI_UNICODE TEXTEQU <__UNICODE__>
;IFDEF MUI_UNICODE
;__UNICODE__ EQU 1
;ECHO ModernUI UNICODE
;ELSE
;ECHO ModernUI ANSI
;ENDIF
;------------------------------------------------------------------------------------

.CONST
;------------------------------------------
; Conditional for ModernUI DLL compiling
;------------------------------------------
IFDEF MODERNUI_DLL
    MODERNUI_LIBEND TEXTEQU <>
ELSE
    MODERNUI_LIBEND TEXTEQU <END>
ENDIF

;------------------------------------------
; Define MUI_USEGDIPLUS to compile
; gdiplus support into ModernUI library 
; Other controls can force this off by
; defining MUI_DONTUSEGDIPLUS if they
; wish to exclude gdiplus support
;------------------------------------------
IFNDEF MUI_DONTUSEGDIPLUS
MUI_USEGDIPLUS                  EQU 1               ; Use GDI+ or not
ENDIF

;------------------------------------------
; ModernUI Property Constants 
;------------------------------------------
IFDEF _WIN64
MUI_INTERNAL_PROPERTIES         EQU 0               ; cbWndExtra offset for internal properties pointer
MUI_EXTERNAL_PROPERTIES         EQU 8               ; cbWndExtra offset for external properties pointer
MUI_INTERNAL_PROPERTIES_EXTRA   EQU 16              ; cbWndExtra offset for extra internal properties pointer
MUI_EXTERNAL_PROPERTIES_EXTRA   EQU 24              ; cbWndExtra offset for extra external properties pointer
MUI_PROPERTY_ADDRESS            EQU 8000000000000000h ; OR with Property in MUIGetIntProperty/MUIGetExtProperty to return address of property
ELSE ; WIN32 x86
MUI_INTERNAL_PROPERTIES         EQU 0               ; cbWndExtra offset for internal properties pointer
MUI_EXTERNAL_PROPERTIES         EQU 4               ; cbWndExtra offset for external properties pointer
MUI_INTERNAL_PROPERTIES_EXTRA   EQU 8               ; cbWndExtra offset for extra internal properties pointer
MUI_EXTERNAL_PROPERTIES_EXTRA   EQU 12              ; cbWndExtra offset for extra external properties pointer
MUI_PROPERTY_ADDRESS            EQU 80000000h       ; OR with Property in MUIGetIntProperty/MUIGetExtProperty to return address of property
ENDIF 

;------------------------------------------
; ModernUI Custom Messages - each control 
; should handle these
;------------------------------------------
MUI_GETPROPERTY                 EQU WM_USER + 1800  ; wParam = Property, lParam = NULL
MUI_SETPROPERTY                 EQU WM_USER + 1799  ; wParam = Property, lParam = PropertyValue
;MUI_GETTHEME                   EQU WM_USER + 1798  ; wParam = NULL, lParam = NULL. Returns in eax lpMUITHEMEStructure
;MUI_SETTHEME                   EQU WM_USER + 1797  ; wParam = lpMUITHEMEStructure, lParam = NULL

;------------------------------------------
; Image Types Enum MUIIMAGE
;------------------------------------------
MUIIT_NONE                      EQU 0
MUIIT_BMP                       EQU 1
MUIIT_ICO                       EQU 2
MUIIT_PNG                       EQU 3

;------------------------------------------
; Image Locations Enum MUIIL
;------------------------------------------
MUIIL_CENTER                    EQU 0
MUIIL_BOTTOMLEFT                EQU 1
MUIIL_BOTTOMRIGHT               EQU 2
MUIIL_TOPLEFT                   EQU 3
MUIIL_TOPRIGHT                  EQU 4
MUIIL_TOPCENTER                 EQU 5
MUIIL_BOTTOMCENTER              EQU 6

;------------------------------------------
; MUIGDIPaintFrame Frame Style Enum MUIPFS
;------------------------------------------
MUIPFS_NONE                     EQU 0
MUIPFS_LEFT                     EQU 1
MUIPFS_TOP                      EQU 2
MUIPFS_BOTTOM                   EQU 4
MUIPFS_RIGHT                    EQU 8
MUIPFS_ALL                      EQU MUIPFS_LEFT + MUIPFS_TOP + MUIPFS_BOTTOM + MUIPFS_RIGHT

;------------------------------------------
; MUIGDIPaintGradient Gradient Style Enum MUIPGS
;------------------------------------------
MUIPGS_HORZ                     EQU 0
MUIPGS_VERT                     EQU 1

;------------------------------------------
; Color Macros
;------------------------------------------
MUI_ARGBCOLOR MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

AlphaRGB MACRO alpha, red, green, blue
    EXITM < alpha SHL 24 OR red SHL 16 OR green SHL 8 OR blue >
ENDM

MUI_RGBCOLOR MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM

RGB MACRO red:REQ, green:REQ, blue:REQ
    EXITM < red or green shl 8 or blue shl 16 >
ENDM

;------------------------------------------
; ModernUI Structures
;------------------------------------------
IFNDEF GDIPRECT
GDIPRECT     STRUCT
    left     REAL4 ?
    top      REAL4 ?
    right    REAL4 ?
    bottom   REAL4 ?
GDIPRECT     ENDS
ENDIF
GPRECT                          TYPEDEF GDIPRECT    ; Alias for GDIPRECT
LPGPRECT                        TYPEDEF PTR GDIPRECT; Pointer to GDIPRECT
LPGDIPRECT                      TYPEDEF PTR GDIPRECT; Pointer to GDIPRECT

;------------------------------------------------------------------------------
; ModernUI Prototypes
;------------------------------------------------------------------------------
; ModernUI Base Functions:
MUIGetPropertyA                 PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
MUISetPropertyA                 PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
MUIGetExtPropertyA              PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetExtPropertyA              PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
MUIGetIntPropertyA              PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetIntPropertyA              PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE

MUIGetExtPropertyExA            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY
MUISetExtPropertyExA            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTYVALUE
MUIGetIntPropertyExA            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY
MUISetIntPropertyExA            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTYVALUE

MUIGetExtPropertyExtraA         PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetExtPropertyExtraA         PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
MUIGetIntPropertyExtraA         PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetIntPropertyExtraA         PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE

MUIGetPropertyW                 PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY
MUISetPropertyW                 PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
MUIGetExtPropertyW              PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetExtPropertyW              PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
MUIGetIntPropertyW              PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetIntPropertyW              PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE

MUIGetExtPropertyExW            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY
MUISetExtPropertyExW            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTYVALUE
MUIGetIntPropertyExW            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY
MUISetIntPropertyExW            PROTO hWin:MUIWND, Property:MUIPROPERTY, ParentProperty:MUIPROPERTY, ChildProperty:MUIPROPERTYVALUE

MUIGetExtPropertyExtraW         PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetExtPropertyExtraW         PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE
MUIGetIntPropertyExtraW         PROTO hWin:MUIWND, Property:MUIPROPERTY
MUISetIntPropertyExtraW         PROTO hWin:MUIWND, Property:MUIPROPERTY, PropertyValue:MUIPROPERTYVALUE

; ModernUI Memory Functions:
MUIAllocMemProperties           PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES, SizeToAllocate:MUIVALUE
MUIFreeMemProperties            PROTO hWin:MUIWND, cbWndExtraOffset:MUIPROPERTIES
MUIAllocStructureMemory         PROTO PtrStructMem:POINTER, TotalItems:MUIVALUE, ItemSize:MUIVALUE

; ModernUI GDI Functions:
MUIGDIDoubleBufferStart         PROTO hWin:MUIWND, hdcSource:HDC, lpHDCBuffer:LPHDC, lpClientRect:LPRECT, lphBufferBitmap:LPHBITMAP
MUIGDIDoubleBufferFinish        PROTO hdc:HDC, hBufferBitmap:HBITMAP, hBitmapUsed:HBITMAP, hFontUsed:HFONT, hBrushUsed:HBRUSH, hPenUsed:HPEN 
MUIGDIBlend                     PROTO hWin:MUIWND, hdc:HDC, BlendColor:MUICOLORRGB, BlendLevel:MUIVALUE
MUIGDIBlendBitmaps              PROTO hBitmap1:HBITMAP, hBitmap2:HBITMAP, ColorBitmap2:MUICOLORRGB, Transparency:MUIVALUE
MUIGDIStretchBitmap             PROTO hBitmap:HBITMAP, lpBoundsRect:LPRECT, lpBitmapWidth:LPMUIVALUE, lpBitmapHeight:LPMUIVALUE, lpBitmapX:LPMUIVALUE, lpBitmapY:LPMUIVALUE
MUIGDIStretchImage              PROTO hImage:MUIIMAGE, ImageHandleType:MUIIT, lpBoundsRect:LPRECT, lpImageWidth:LPMUIVALUE, lpImageHeight:LPMUIVALUE, lpImageX:LPMUIVALUE, lpImageY:LPMUIVALUE
MUIGDIRotateCenterBitmap        PROTO hWin:MUIWND, hBitmap:HBITMAP, Angle:MUIVALUE, BackColor:MUICOLORRGB
MUIGDIPaintFill                 PROTO hdc:HDC, lpFillRect:LPRECT, FillColor:MUICOLORRGB
MUIGDIPaintFrame                PROTO hdc:HDC, lpFrameRect:LPRECT, FrameColor:MUICOLORRGB, FrameStyle:MUIPFS
MUIGDIPaintRectangle            PROTO hdc:HDC, lpRect:LPRECT, FrameColor:MUICOLORRGB, FillColor:MUICOLORRGB
MUIGDIPaintBrush                PROTO hdc:HDC, lpBrushRect:LPRECT, hBrushBitmap:HBITMAP, qwBrushOrgX:MUIVALUE, qwBrushOrgY:MUIVALUE
MUIGDIPaintGradient             PROTO hdc:HDC, lpGradientRect:LPRECT, GradientColorFrom:MUICOLORRGB, GradientColorTo:MUICOLORRGB, HorzVertGradient:MUIPGS
MUIGDICreateBitmapMask          PROTO hBitmap:HBITMAP, TransparentColor:MUICOLORRGB

; ModernUI GDIPlus Functions:
MUIGDIPlusStart                 PROTO
MUIGDIPlusFinish                PROTO
MUIGDIPlusDoubleBufferStart     PROTO hWin:MUIWND, pGraphics:GPGRAPHICS, lpBitmapHandle:LPGPIMAGE, lpGraphicsBuffer:LPGPGRAPHICS 
MUIGDIPlusDoubleBufferFinish    PROTO hWin:MUIWND, pGraphics:GPGRAPHICS, pBitmap:GPIMAGE, pGraphicsBuffer:GPGRAPHICS
MUIGDIPlusRotateCenterImage     PROTO hImage:GPIMAGE, fAngle:REAL4 
MUIGDIPlusPaintFill             PROTO pGraphics:GPGRAPHICS, lpFillGdipRect:LPGPRECT, FillColor:MUICOLORARGB
MUIGDIPlusPaintFillI            PROTO pGraphics:GPGRAPHICS, lpFillRectI:LPRECT, FillColor:MUICOLORARGB
MUIGDIPlusPaintFrame            PROTO pGraphics:GPGRAPHICS, lpFrameGdipRect:LPGPRECT, FrameColor:MUICOLORARGB, FrameStyle:MUIPFS
MUIGDIPlusPaintFrameI           PROTO pGraphics:GPGRAPHICS, lpFrameRectI:LPRECT, FrameColor:MUICOLORARGB, FrameStyle:MUIPFS
MUILoadPngFromResource          PROTO hWin:MUIWND, InstanceProperty:MUIPROPERTY, Property:MUIPROPERTY, idPngRes:RESID
MUIGDIPlusRectToGdipRect        PROTO lpRect:LPRECT, lpGdipRect:LPGPRECT

; GDIPlus aliases:
MUIGDIPStart                    TEXTEQU <MUIGDIPlusStart>
MUIGDIPFinish                   TEXTEQU <MUIGDIPlusFinish>
MUIGDIPDoubleBufferStart        TEXTEQU <MUIGDIPlusDoubleBufferStart>
MUIGDIPDoubleBufferFinish       TEXTEQU <MUIGDIPlusDoubleBufferFinish>
MUIGDIPRotateCenterImage        TEXTEQU <MUIGDIPlusRotateCenterImage>
MUIGDIPPaintFill                TEXTEQU <MUIGDIPlusPaintFill>
MUIGDIPPaintFillI               TEXTEQU <MUIGDIPlusPaintFillI>
MUIGDIPPaintFrame               TEXTEQU <MUIGDIPlusPaintFrame>
MUIGDIPPaintFrameI              TEXTEQU <MUIGDIPlusPaintFrameI>
MUILoadJpgFromResource          TEXTEQU <MUILoadPngFromResource>
MUIGDIPRectToGdipRect           TEXTEQU <MUIGDIPlusRectToGdipRect>

; ModernUI Painting & Color Functions:
MUIPaintBackground              PROTO hWin:MUIWND, BackColor:MUICOLORRGB, BorderColor:MUICOLORRGB
MUIPaintBackgroundImage         PROTO hWin:MUIWND, BackColor:MUICOLORRGB, BorderColor:MUICOLORRGB, hImage:MUIIMAGE, ImageHandleType:MUIIT, ImageLocation:MUIIL
MUIPaintBorder                  PROTO hWin:MUIWND, BorderColor:MUICOLORRGB
MUIGetParentBackgroundColor     PROTO hWin:MUIWND
MUIGetParentBackgroundBitmap    PROTO hWin:MUIWND

; ModernUI Window/Dialog Functions:
MUICenterWindow                 PROTO hWndChild:MUIWND, hWndParent:MUIWND
MUIGetParentRelativeWindowRect  PROTO hWin:MUIWND, lpRectControl:LPRECT
MUIChangeScreenResolution       PROTO ScreenWidth:MUIVALUE, ScreenHeight:MUIVALUE, bitsPerPixel:MUIVALUE

MUIApplyToDialogA               PROTO hWin:MUIWND, bDropShadow:BOOL, bClipping:BOOL
MUIModifyStyleA                 PROTO hWin:MUIWND, dwRemove:MUIVALUE, dwAdd:MUIVALUE, bFrameChanged:BOOL
MUIModifyStyleExA               PROTO hWin:MUIWND, dwRemove:MUIVALUE, dwAdd:MUIVALUE, bFrameChanged:BOOL

MUIApplyToDialogW               PROTO hWin:MUIWND, bDropShadow:BOOL, bClipping:BOOL
MUIModifyStyleW                 PROTO hWin:MUIWND, dwRemove:MUIVALUE, dwAdd:MUIVALUE, bFrameChanged:BOOL
MUIModifyStyleExW               PROTO hWin:MUIWND, dwRemove:MUIVALUE, dwAdd:MUIVALUE, bFrameChanged:BOOL

; ModernUI Region Functions:
MUILoadRegionFromResource       PROTO hInst:HINSTANCE, idRgnRes:RESID, lpRegionData:POINTER, lpSizeRegionData:LPMUIVALUE 
MUISetRegionFromResource        PROTO hWin:MUIWND, idRgnRes:RESID, lpCopyRgnHandle:LPMUIVALUE, bRedraw:BOOL

; ModernUI Font Functions:
MUIPointSizeToLogicalUnit       PROTO hWin:MUIWND, PointSize:MUIVALUE

; ModernUI Image Functions:
MUIGetImageSize                 PROTO hImage:MUIIMAGE, ImageHandleType:MUIIT, lpImageWidth:LPMUIVALUE, lpImageHeight:LPMUIVALUE
MUIGetImageSizeEx               PROTO hWin:MUIWND, hImage:MUIIMAGE, ImageHandleType:MUIIT, lpImageWidth:LPMUIVALUE, lpImageHeight:LPMUIVALUE, lpImageX:LPMUIVALUE, lpImageY:LPMUIVALUE
MUICreateIconFromMemory         PROTO pIconData:POINTER, iIcon:MUIVALUE
MUICreateCursorFromMemory       PROTO pCursorData:POINTER
MUICreateBitmapFromMemory       PROTO pBitmapData:POINTER
MUILoadBitmapFromResource       PROTO hWin:MUIWND, InstanceProperty:MUIPROPERTY, Property:MUIPROPERTY, idBmpRes:RESID
MUILoadIconFromResource         PROTO hWin:MUIWND, InstanceProperty:MUIPROPERTY, Property:MUIPROPERTY, idIcoRes:RESID
MUILoadImageFromResource        PROTO hWin:MUIWND, InstanceProperty:MUIPROPERTY, Property:MUIPROPERTY, ImageHandleType:MUIIT, idImageRes:RESID

; ModernUI DPI & Scaling Functions:
MUIDPI                          PROTO lpDPIX:LPMUIVALUE, lpDPIY:LPMUIVALUE
MUIDPIScaleX                    PROTO ValueX:MUIVALUE
MUIDPIScaleY                    PROTO ValueY:MUIVALUE
MUIDPIScaleRect                 PROTO lpRect:LPRECT
MUIDPIScaleControl              PROTO lpLeft:LPMUIVALUE, lpTop:LPMUIVALUE, lpWidth:LPMUIVALUE, lpHeight:LPMUIVALUE
MUIDPIScaleFontSize             PROTO PointSize:MUIVALUE
MUIDPIScaledScreen              PROTO lpScreenWidth:LPMUIVALUE, lpScreenHeight:LPMUIVALUE

MUIDPIScaleFontA                PROTO hFontToScale:HFONT 
MUIDPISetDPIAwareA              PROTO

MUIDPIScaleFontW                PROTO hFontToScale:HFONT 
MUIDPISetDPIAwareW              PROTO

; ModernUI Class Functions
MUIRegisterA                    PROTO lpszClassName:MUILPSTRING, lpClassWndProc:POINTER, lpCursorName:MUIVALUE, cbWndExtra:MUIVALUE
MUISuperclassA                  PROTO lpszExistingClassName:MUILPSTRING, lpdwExistingClassWndProc:POINTER, lpszSuperclassName:MUILPSTRING, lpSuperclassWndProc:POINTER, lpSuperclassCursorName:MUIVALUE, cbSuperclassWndExtra:MUIVALUE, lpcbWndExtraOffset:LPMUIVALUE

MUIRegisterW                    PROTO lpszClassName:MUILPSTRING, lpClassWndProc:POINTER, lpCursorName:MUIVALUE, cbWndExtra:MUIVALUE
MUISuperclassW                  PROTO lpszExistingClassName:MUILPSTRING, lpdwExistingClassWndProc:POINTER, lpszSuperclassName:MUILPSTRING, lpSuperclassWndProc:POINTER, lpSuperclassCursorName:MUIVALUE, cbSuperclassWndExtra:MUIVALUE, lpcbWndExtraOffset:LPMUIVALUE



IFNDEF MUI_UNICODE
MUIGetProperty                  EQU <MUIGetPropertyA>
MUISetProperty                  EQU <MUISetPropertyA>
MUIGetExtProperty               EQU <MUIGetExtPropertyA>
MUISetExtProperty               EQU <MUISetExtPropertyA>
MUIGetIntProperty               EQU <MUIGetIntPropertyA>
MUISetIntProperty               EQU <MUISetIntPropertyA>
MUIGetExtPropertyEx             EQU <MUIGetExtPropertyExA>
MUISetExtPropertyEx             EQU <MUISetExtPropertyExA>
MUIGetIntPropertyEx             EQU <MUIGetIntPropertyExA>
MUISetIntPropertyEx             EQU <MUISetIntPropertyExA>
MUIGetExtPropertyExtra          EQU <MUIGetExtPropertyExtraA>
MUISetExtPropertyExtra          EQU <MUISetExtPropertyExtraA>
MUIGetIntPropertyExtra          EQU <MUIGetIntPropertyExtraA>
MUISetIntPropertyExtra          EQU <MUISetIntPropertyExtraA>
MUIDPIScaleFont                 EQU <MUIDPIScaleFontA>
MUIDPISetDPIAware               EQU <MUIDPISetDPIAwareA>
MUIApplyToDialog                EQU <MUIApplyToDialogA>
MUIModifyStyle                  EQU <MUIModifyStyleA>
MUIModifyStyleEx                EQU <MUIModifyStyleExA>
MUIRegister                     EQU <MUIRegisterA>
MUISuperclass                   EQU <MUISuperclassA>
ENDIF

IFDEF MUI_UNICODE
MUIGetProperty                  EQU <MUIGetPropertyW>
MUISetProperty                  EQU <MUISetPropertyW>
MUIGetExtProperty               EQU <MUIGetExtPropertyW>
MUISetExtProperty               EQU <MUISetExtPropertyW>
MUIGetIntProperty               EQU <MUIGetIntPropertyW>
MUISetIntProperty               EQU <MUISetIntPropertyW>
MUIGetExtPropertyEx             EQU <MUIGetExtPropertyExW>
MUISetExtPropertyEx             EQU <MUISetExtPropertyExW>
MUIGetIntPropertyEx             EQU <MUIGetIntPropertyExW>
MUISetIntPropertyEx             EQU <MUISetIntPropertyExW>
MUIGetExtPropertyExtra          EQU <MUIGetExtPropertyExtraW>
MUISetExtPropertyExtra          EQU <MUISetExtPropertyExtraW>
MUIGetIntPropertyExtra          EQU <MUIGetIntPropertyExtraW>
MUISetIntPropertyExtra          EQU <MUISetIntPropertyExtraW>
MUIApplyToDialog                EQU <MUIApplyToDialogW>
MUIModifyStyle                  EQU <MUIModifyStyleW>
MUIModifyStyleEx                EQU <MUIModifyStyleExW>
MUIDPIScaleFont                 EQU <MUIDPIScaleFontW>
MUIDPISetDPIAware               EQU <MUIDPISetDPIAwareW>
MUIRegister                     EQU <MUIRegisterW>
MUISuperclass                   EQU <MUISuperclassW>
ENDIF


;------------------------------------------
; Notes
;------------------------------------------
; Custom controls: qwStyle parameter of 
; CreateWindowEx.
;
; The low 16 bits of the qwStyle parameter 
; are defined by the implementor of the 
; window class (by the person who calls 
; RegisterClass) - Raymond Chen
;
; 0x0h - 0xFFFFh reserved for user creating
; the control to define styles
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





















