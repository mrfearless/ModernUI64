//=============================================================================
//
// ModernUI Library
//
// Copyright (c) 2019 by fearless
//
// All Rights Reserved
//
// http://github.com/mrfearless/ModernUI
//
//=============================================================================

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _MSC_VER     // MSVC compiler
#define MUI_EXPORT __declspec(dllexport) __fastcall
#else
#define MUI_EXPORT
#endif


//------------------------------------------------------------------------------
// ModernUI64 Prototypes
//------------------------------------------------------------------------------

// ModernUI Base Functions:
unsigned int MUI_EXPORT MUIGetExtProperty(HWND hControl, QWORD qwProperty);
unsigned int MUI_EXPORT MUISetExtProperty(HWND hControl, QWORD qwProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUIGetIntProperty(HWND hControl, QWORD qwProperty);
unsigned int MUI_EXPORT MUISetIntProperty(HWND hControl, QWORD qwProperty, QWORD qwPropertyValue);
	
unsigned int MUI_EXPORT MUIGetExtPropertyEx(HWND hControl, QWORD qwParentProperty, QWORD qwChildProperty);
unsigned int MUI_EXPORT MUISetExtPropertyEx(HWND hControl, QWORD qwParentProperty, QWORD qwChildProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUIGetIntPropertyEx(HWND hControl, QWORD qwParentProperty, QWORD qwChildProperty);
unsigned int MUI_EXPORT MUISetIntPropertyEx(HWND hControl, QWORD qwParentProperty, QWORD qwChildProperty, QWORD qwPropertyValue);

unsigned int MUI_EXPORT MUIGetExtPropertyExtra(HWND hControl, QWORD qwProperty);
unsigned int MUI_EXPORT MUISetExtPropertyExtra(HWND hControl, QWORD qwProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUIGetIntPropertyExtra(HWND hControl, QWORD qwProperty);
unsigned int MUI_EXPORT MUISetIntPropertyExtra(HWND hControl, QWORD qwProperty, QWORD qwPropertyValue);


// ModernUI Memory Functions:
bool MUI_EXPORT MUIAllocMemProperties(HWND hControl, QWORD cbWndExtraOffset, QWORD qwSizeToAllocate);
bool MUI_EXPORT MUIFreeMemProperties(HWND hControl, QWORD cbWndExtraOffset);
unsigned int MUI_EXPORT MUIAllocStructureMemory(QWORD qwPtrStructMem, QWORD TotalItems, QWORD ItemSize);

// ModernUI GDI Functions:
bool MUI_EXPORT MUIGDIDoubleBufferStart(HWND hWin, HDC hdcSource, HDC *lpHDCBuffer, RECT *lpClientRect, HBITMAP *lphBufferBitmap);
bool MUI_EXPORT MUIGDIDoubleBufferFinish(HDC hdcBuffer, HBITMAP hBufferBitmap, HBITMAP hBitmapUsed, HFONT hFontUsed, HBRUSH hBrushUsed, HPEN hPenUsed);
bool MUI_EXPORT MUIGDIBlend (HWND hWin, HDC hdc, COLORREF qwColor, int qwBlendLevel);
bool MUI_EXPORT MUIGDIBlendBitmaps(HBITMAP hBitmap1, HBITMAP hBitmap2, int qwColorBitmap2, int qwTransparency);
HBITMAP MUI_EXPORT MUIGDIStretchBitmap(HBITMAP hBitmap, RECT *lpBoundsRect, int *lpqwBitmapWidth, int *lpqwBitmapHeight, int *lpqwX, int *lpqwY);
HBITMAP MUI_EXPORT MUIGDIStretchImage(hImage, qwImageType, RECT *lpBoundsRect, int *lpqwImageWidth, int *lpqwImageHeight, int *lpqwImageX, int *lpqwImageY);
HBITMAP MUI_EXPORT MUIGDIRotateBitmapCenter(HWND hWin, HBITMAP hBitmap, int qwAngle, int qwBackColor);
void MUI_EXPORT MUIGDIPaintFill(HDC hdc, RECT *lpFillRect, COLORREF qwFillColor);
void MUI_EXPORT MUIGDIPaintFrame(HDC hdc, RECT *lpFrameRect, COLORREF qwFrameColor, QWORD qwFrameStyle);

// ModernUI GDIPlus Functions:
void MUI_EXPORT MUIGDIPlusStart();
void MUI_EXPORT MUIGDIPlusFinish();
void MUI_EXPORT MUIGDIPlusDoubleBufferStart(HWND hWin, HANDLE pGraphics, HANDLE *lpBitmapHandle, HANDLE *lpGraphicsBuffer);
void MUI_EXPORT MUIGDIPlusDoubleBufferFinish(HWND hWin, HANDLE pGraphics, HBITMAP hBitmap, HANDLE pGraphicsBuffer);
void MUI_EXPORT MUIGDIPlusRotateCenterImage(HANDLE hImage, FLOAT fAngle);
void MUI_EXPORT MUIGDIPlusPaintFill(pGraphics, GDIPRECT *lpFillGdipRect, ARGBCOLOR qwFillColor);
void MUI_EXPORT MUIGDIPlusPaintFillI(pGraphics, RECT *lpFillRectI, COLORREF qwFillColor);
void MUI_EXPORT MUIGDIPlusPaintFrame(pGraphics, GDIPRECT *lpFrameGdipRect, ARGBCOLOR qwFrameColor, QWORD qwFrameStyle);
void MUI_EXPORT MUIGDIPlusPaintFrameI(pGraphics, RECT *lpFrameRectI, COLORREF qwFrameColor, QWORD qwFrameStyle);
HANDLE MUI_EXPORT MUILoadPngFromResource(HWND hWin, QWORD qwInstanceProperty, QWORD qwProperty, QWORD idPngRes);
void MUI_EXPORT MUIGDIPlusRectToGdipRect(RECT *lpRect, GDIPRECT *lpGdipRect);

// ModernUI Painting & Color Functions:
void MUI_EXPORT MUIPaintBackground(HWND hDialogWindow, COLORREF qwBackColor, COLORREF qwBorderColor);
void MUI_EXPORT MUIPaintBackgroundImage(HWND hDialogWindow, COLORREF qwBackColor, COLORREF qwBorderColor, HANDLE hImage, QWORD qwImageType, QWORD qwImageLocation);
unsigned int MUI_EXPORT MUIGetParentBackgroundColor(HWND hControl);
unsigned int MUI_EXPORT MUIGetParentBackgroundBitmap(HWND hControl);

// ModernUI Window/Dialog Functions:
void MUI_EXPORT MUIApplyToDialog(HWND hDialogWindow, BOOL bDropShadow, BOOL bClipping);
void MUI_EXPORT MUICenterWindow(HWND hWndChild, HWND hWndParent);
void MUI_EXPORT MUIGetParentRelativeWindowRect(HWND hControl, RECT *lpRectControl);

// ModernUI Region Functions:
bool MUI_EXPORT MUILoadRegionFromResource(HINSTANCE hInstance, QWORD idRgnRes, QWORD *lpRegion, QWORD *lpqwSizeRegion);
bool MUI_EXPORT MUISetRegionFromResource(HWND hWin, QWORD idRgnRes, QWORD *lpqwCopyRgn, BOOL bRedraw);

// ModernUI Font Functions:
unsigned int MUI_EXPORT MUIPointSizeToLogicalUnit(HWND hControl, QWORD qwPointSize);

// ModernUI Image Functions:
bool MUI_EXPORT MUIGetImageSize(HANDLE hImage, QWORD qwImageType, QWORD *lpqwImageWidth, QWORD *lpqwImageHeight);
bool MUI_EXPORT MUICreateIconFromMemory(QWORD pIconData, QWORD iIcon);
bool MUI_EXPORT MUICreateCursorFromMemory(QWORD pCursorData);
bool MUI_EXPORT MUICreateBitmapFromMemory(QWORD pBitmapData);
HBITMAP MUI_EXPORT MUILoadBitmapFromResource(HWND hWin, QWORD qwInstanceProperty, QWORD qwProperty, QWORD idBmpRes);
HICON MUI_EXPORT MUILoadIconFromResource(HWND hWin, QWORD qwInstanceProperty, QWORD qwProperty, QWORD idIcoRes);
HANDLE MUI_EXPORT MUILoadImageFromResource(HWND hWin, QWORD qwInstanceProperty, QWORD qwProperty, QWORD qwImageType, QWORD qwImageResId);

// ModernUI DPI & Scaling Functions:
void MUIDPI(QWORD *lpqwDPIX, QWORD *lpqwDPIY);
unsigned int MUIDPIScaleX(QWORD qwValueX);
unsigned int MUIDPIScaleY(QWORD qwValueY);
bool MUIDPIScaleRect(RECT *lpRect);
void MUIDPIScaleControl(QWORD *lpqwLeft, QWORD *lpqwTop, QWORD *lpqwWidth, QWORD *lpqwHeight);
void MUIDPIScaleFontSize(HWND hControl, QWORD qwPointSize);
void MUIDPIScaledScreen(QWORD *lpqwScreenWidth, QWORD *lpqwScreenHeight);
bool MUIDPISetDPIAware();



//------------------------------------------
// Global constants used by all ModernUI64
// controls. 
//------------------------------------------
#define MUI_INTERNAL_PROPERTIES         0               // cbWndExtra offset for internal properties pointer
#define MUI_EXTERNAL_PROPERTIES         8               // cbWndExtra offset for external properties pointer
#define MUI_INTERNAL_PROPERTIES_EXTRA   16              // cbWndExtra offset for extra internal properties pointer
#define MUI_EXTERNAL_PROPERTIES_EXTRA   24              // cbWndExtra offset for extra external properties pointer
#define MUI_PROPERTY_ADDRESS            80000000h       // OR with qwProperty in MUIGetIntProperty/MUIGetExtProperty to return address of property 


//------------------------------------------
// ModernUI Custom Messages - each control 
// should handle these
//------------------------------------------
#define MUI_GETPROPERTY                 WM_USER + 1800  // wParam = qwProperty, lParam = NULL
#define MUI_SETPROPERTY                 WM_USER + 1799  // wParam = qwProperty, lParam = qwPropertyValue


//------------------------------------------
// Image Types
//------------------------------------------
#define MUIIT_NONE                      0
#define MUIIT_BMP                       1
#define MUIIT_ICO                       2
#define MUIIT_PNG                       3


//------------------------------------------
// Image Locations
//------------------------------------------
#define MUIIL_CENTER                    0
#define MUIIL_BOTTOMLEFT                1
#define MUIIL_BOTTOMRIGHT               2
#define MUIIL_TOPLEFT                   3
#define MUIIL_TOPRIGHT                  4
#define MUIIL_TOPCENTER                 5
#define MUIIL_BOTTOMCENTER              6

//------------------------------------------
// ModernUI Macros
//------------------------------------------
#define MUI_RGBCOLOR(r,g,b) ((COLORREF)(((BYTE)(r)|((WORD)((BYTE)(g))<<8))|(((DWORD)(BYTE)(b))<<16)))
#define MUI_ARGBCOLOR(a,r,g,b) ((DWORD(a)<<24) + (DWORD(r)<<16) + (DWORD(g)<<8) + DWORD(b))

//------------------------------------------
// ModernUI Structures
//------------------------------------------
typedef struct GDIPRECT{
    double left;
    double top;
    double right;
    double bottom;
} GDIPRECT;


#ifdef __cplusplus
}
#endif
