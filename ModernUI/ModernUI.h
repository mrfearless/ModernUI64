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
unsigned int MUI_EXPORT MUIGetExtProperty(HWND hControl, QWORD dwProperty);
unsigned int MUI_EXPORT MUISetExtProperty(HWND hControl, QWORD dwProperty, QWORD dwPropertyValue);
unsigned int MUI_EXPORT MUIGetIntProperty(HWND hControl, QWORD dwProperty);
unsigned int MUI_EXPORT MUISetIntProperty(HWND hControl, QWORD dwProperty, QWORD dwPropertyValue);
	
unsigned int MUI_EXPORT MUIGetExtPropertyEx(HWND hControl, QWORD dwParentProperty, QWORD dwChildProperty);
unsigned int MUI_EXPORT MUISetExtPropertyEx(HWND hControl, QWORD dwParentProperty, QWORD dwChildProperty, QWORD dwPropertyValue);
unsigned int MUI_EXPORT MUIGetIntPropertyEx(HWND hControl, QWORD dwParentProperty, QWORD dwChildProperty);
unsigned int MUI_EXPORT MUISetIntPropertyEx(HWND hControl, QWORD dwParentProperty, QWORD dwChildProperty, QWORD dwPropertyValue);

unsigned int MUI_EXPORT MUIGetExtPropertyExtra(HWND hControl, QWORD dwProperty);
unsigned int MUI_EXPORT MUISetExtPropertyExtra(HWND hControl, QWORD dwProperty, QWORD dwPropertyValue);
unsigned int MUI_EXPORT MUIGetIntPropertyExtra(HWND hControl, QWORD dwProperty);
unsigned int MUI_EXPORT MUISetIntPropertyExtra(HWND hControl, QWORD dwProperty, QWORD dwPropertyValue);


// ModernUI Memory Functions:
bool MUI_EXPORT MUIAllocMemProperties(HWND hControl, QWORD cbWndExtraOffset, QWORD dwSizeToAllocate);
bool MUI_EXPORT MUIFreeMemProperties(HWND hControl, QWORD cbWndExtraOffset);
unsigned int MUI_EXPORT MUIAllocStructureMemory(QWORD dwPtrStructMem, QWORD TotalItems, QWORD ItemSize);

// ModernUI GDI DoubleBuffer Functions:
bool MUI_EXPORT MUIGDIDoubleBufferStart(HWND hWin, HDC hdcSource, HDC *lpHDCBuffer, RECT *lpClientRect, HBITMAP *lphBufferBitmap);
bool MUI_EXPORT MUIGDIDoubleBufferFinish(HDC hdcBuffer, HBITMAP hBufferBitmap, HBITMAP hBitmapUsed, HFONT hFontUsed, HBRUSH hBrushUsed, HPEN hPenUsed);

// ModernUI GDIPlus Functions:
void MUI_EXPORT MUIGDIPlusStart();
void MUI_EXPORT MUIGDIPlusFinish();

// ModernUI Painting & Color Functions:
void MUI_EXPORT MUIPaintBackground(HWND hDialogWindow, COLORREF dwBackColor, COLORREF dwBorderColor);
void MUI_EXPORT MUIPaintBackgroundImage(HWND hDialogWindow, COLORREF dwBackColor, COLORREF dwBorderColor, HANDLE hImage, QWORD dwImageType, QWORD dwImageLocation);
unsigned int MUI_EXPORT MUIGetParentBackgroundColor(HWND hControl);
unsigned int MUI_EXPORT MUIGetParentBackgroundBitmap(HWND hControl);

// ModernUI Window/Dialog Functions:
void MUI_EXPORT MUIApplyToDialog(HWND hDialogWindow, BOOL bDropShadow, BOOL bClipping);
void MUI_EXPORT MUICenterWindow(HWND hWndChild, HWND hWndParent);
void MUI_EXPORT MUIGetParentRelativeWindowRect(HWND hControl, RECT *lpRectControl);

// ModernUI Region Functions:
bool MUI_EXPORT MUILoadRegionFromResource(HINSTANCE hInstance, QWORD idRgnRes, QWORD *lpRegion, QWORD *lpdwSizeRegion);
bool MUI_EXPORT MUISetRegionFromResource(HWND hWin, QWORD idRgnRes, QWORD *lpdwCopyRgn, BOOL bRedraw);

// ModernUI Font Functions:
unsigned int MUI_EXPORT MUIPointSizeToLogicalUnit(HWND hControl, QWORD dwPointSize);

// ModernUI Image Functions:
bool MUI_EXPORT MUIGetImageSize(HANDLE hImage, QWORD dwImageType, QWORD *lpdwImageWidth, QWORD *lpdwImageHeight);
bool MUI_EXPORT MUICreateIconFromMemory(QWORD pIconData, QWORD iIcon);
bool MUI_EXPORT MUICreateCursorFromMemory(QWORD pCursorData);
bool MUI_EXPORT MUICreateBitmapFromMemory(QWORD pBitmapData);

// ModernUI DPI & Scaling Functions:
void MUIDPI(QWORD *lpdwDPIX, QWORD *lpdwDPIY);
unsigned int MUIDPIScaleX(QWORD dwValueX);
unsigned int MUIDPIScaleY(QWORD dwValueY);
bool MUIDPIScaleRect(RECT *lpRect);
void MUIDPIScaleControl(QWORD *lpdwLeft, QWORD *lpdwTop, QWORD *lpdwWidth, QWORD *lpdwHeight);
void MUIDPIScaleFontSize(HWND hControl, QWORD dwPointSize);
void MUIDPIScaledScreen(QWORD *lpdwScreenWidth, QWORD *lpdwScreenHeight);
bool MUIDPISetDPIAware();



//------------------------------------------
// Global constants used by all ModernUI64
// controls. 
//------------------------------------------
#define MUI_INTERNAL_PROPERTIES         0               // cbWndExtra offset for internal properties pointer
#define MUI_EXTERNAL_PROPERTIES         8               // cbWndExtra offset for external properties pointer
#define MUI_INTERNAL_PROPERTIES_EXTRA   16              // cbWndExtra offset for extra internal properties pointer
#define MUI_EXTERNAL_PROPERTIES_EXTRA   24              // cbWndExtra offset for extra external properties pointer
#define MUI_PROPERTY_ADDRESS            80000000h       // OR with dwProperty in MUIGetIntProperty/MUIGetExtProperty to return address of property 


//------------------------------------------
// ModernUI Custom Messages - each control 
// should handle these
//------------------------------------------
#define MUI_GETPROPERTY                 WM_USER + 1800  // wParam = dwProperty, lParam = NULL
#define MUI_SETPROPERTY                 WM_USER + 1799  // wParam = dwProperty, lParam = dwPropertyValue


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



#ifdef __cplusplus
}
#endif
