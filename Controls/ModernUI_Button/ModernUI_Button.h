#ifdef __cplusplus
extern "C" {
#endif

#ifdef _MSC_VER     // MSVC compiler
#define MUI_EXPORT __declspec(dllexport) __fastcall
#else
#define MUI_EXPORT
#endif


//------------------------------------------------------------------------------
// ModernUI_Button Prototypes
//------------------------------------------------------------------------------

void MUI_EXPORT MUIButtonRegister(); // Use 'ModernUI_Button' as class in RadASM custom class control
bool MUI_EXPORT MUIButtonCreate(HWND hWndParent, LPCSTR *lpszText, QWORD xpos, QWORD ypos, QWORD qwWidth, QWORD qwHeight, QWORD qwResourceID, QWORD qwStyle);
unsigned int MUI_EXPORT MUIButtonSetProperty(HWND hModernUI_Button, QWORD qwProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUIButtonGetProperty(HWND hModernUI_Button, QWORD qwProperty);
bool MUI_EXPORT MUIButtonGetState(HWND hModernUI_Button);
bool MUI_EXPORT MUIButtonSetState(HWND hModernUI_Button, BOOL bState);

bool MUI_EXPORT MUIButtonLoadImages(HWND hModernUI_Button, QWORD qwImageType, QWORD qwResIDImage, QWORD qwResIDImageAlt, QWORD qwResIDImageSel, QWORD qwResIDImageSelAlt, QWORD qwResIDImageDisabled);
bool MUI_EXPORT MUIButtonSetImages(HWND hModernUI_Button, QWORD qwImageType, HANDLE hImage, HANDLE hImageAlt, HANDLE hImageSel, HANDLE hImageSelAlt, HANDLE hImageDisabled);



//------------------------------------------
// ModernUI_Button Styles
// 
//------------------------------------------

#define MUIBS_LEFT                     0x1     // Align text to the left of the button
#define MUIBS_BOTTOM                   0x2     // Place image at the top, and text below
#define MUIBS_CENTER                   0x4     // Align text centerally.
#define MUIBS_AUTOSTATE                0x8     // Automatically toggle between TRUE/FALSE state when clicked. TRUE = Selected.
#define MUIBS_PUSHBUTTON               0x10    // Simulate button movement down slightly when mouse click and movement up again when mouse is released.
#define MUIBS_HAND                     0x20    // Show a hand instead of an arrow when mouse moves over button.
#define MUIBS_KEEPIMAGES               0x40    // Dont delete image handles when control is destoyed. Essential if image handles are used in multiple controls.
#define MUIBS_DROPDOWN                 0x80    // Show dropdown arrow right side of control
#define MUIBS_NOFOCUSRECT              0x100   // Dont show focus rect, just use change border to ButtonBorderColorAlt when setfocus.
#define MUIBS_THEME                    0x800h  // Use default windows theme colors and react to WM_THEMECHANGED



//------------------------------------------------------------------------------
// ModernUI_Button Properties: Use with MUIButtonSetProperty / 
// MUIButtonGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
//------------------------------------------------------------------------------
#define ButtonTextFont                 0       // hFont
#define ButtonTextColor                8       // Colorref
#define ButtonTextColorAlt             16      // Colorref
#define ButtonTextColorSel             24      // Colorref
#define ButtonTextColorSelAlt          32      // Colorref
#define ButtonTextColorDisabled        40      // Colorref
#define ButtonBackColor                48      // Colorref
#define ButtonBackColorAlt             56      // Colorref
#define ButtonBackColorSel             64      // Colorref
#define ButtonBackColorSelAlt          72      // Colorref
#define ButtonBackColorDisabled        80      // Colorref
#define ButtonBorderColor              88      // Colorref
#define ButtonBorderColorAlt           96      // Colorref
#define ButtonBorderColorSel           104     // Colorref
#define ButtonBorderColorSelAlt        112     // Colorref
#define ButtonBorderColorDisabled      120     // Colorref
#define ButtonBorderStyle              128     // Button Border Styles - Either MUIBBS_NONE, MUIBBS_ALL or a combination of MUIBBS_LEFT, MUIBBS_TOP, MUIBBS_BOTTOM, MUIBBS_RIGHT
#define ButtonAccentColor              136     // Colorref
#define ButtonAccentColorAlt           144     // Colorref
#define ButtonAccentColorSel           152     // Colorref
#define ButtonAccentColorSelAlt        160     // Colorref
#define ButtonAccentStyle              168     // Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
#define ButtonAccentStyleAlt           176     // Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
#define ButtonAccentStyleSel           184     // Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
#define ButtonAccentStyleSelAlt        192     // Button Accent Styles - Either MUIBAS_NONE, MUIBAS_ALL or a combination of MUIBAS_LEFT, MUIBAS_TOP, MUIBAS_BOTTOM, MUIBAS_RIGHT
#define ButtonImageType                200     // Button Image Types - One of the following: MUIBIT_NONE, MUIBIT_BMP, MUIBIT_ICO or MUIBIT_PNG
#define ButtonImage                    208     // hImage
#define ButtonImageAlt                 216     // hImage
#define ButtonImageSel                 224     // hImage
#define ButtonImageSelAlt              232     // hImage
#define ButtonImageDisabled            240     // hImage
#define ButtonRightImage               248     // hImage - Right side image
#define ButtonRightImageAlt            256     // hImage - Right side image
#define ButtonRightImageSel            264     // hImage - Right side image
#define ButtonRightImageSelAlt         272     // hImage - Right side image
#define ButtonRightImageDisabled       280     // hImage - Right side image
#define ButtonNotifyTextFont           288     // hFont
#define ButtonNotifyTextColor          296     // Colorref
#define ButtonNotifyBackColor          304     // Colorref
#define ButtonNotifyRound              312     // qwPixels - Roundrect x,y value
#define ButtonNotifyImageType          320     // Button Image Types - One of the following: MUIBIT_NONE, MUIBIT_BMP, MUIBIT_ICO or MUIBIT_PNG
#define ButtonNotifyImage              328     // hImage
#define ButtonNoteTextFont             336     // hFont
#define ButtonNoteTextColor            344     // Colorref
#define ButtonNoteTextColorDisabled    352     // Colorref
#define ButtonPaddingLeftIndent        360     // qwPixels - No of pixels to indent images + text (or just text if no images). Defaults to 0 when control is created
#define ButtonPaddingGeneral           368     // qwPixels - No of pixels of padding to apply based on #define ButtonPaddingStyle: Defaults to 4px when control is created.
#define ButtonPaddingStyle             376     // Button Padding Style - Where to apply #define ButtonPaddingGeneral: defaults to MUIBPS_ALL when control is created
#define ButtonPaddingTextImage         384     // qwPixels - No of pixels between left images and text. Defaults to 8 when control is created
#define ButtonDllInstance              392     // Set to hInstance of dll before calling MUIButtonLoadImages or MUIButtonNotifyLoadImage if used within a dll
#define ButtonParam                    400     // Custom user data

// Button Border Styles
#define MUIBBS_NONE                    0
#define MUIBBS_LEFT                    1
#define MUIBBS_TOP                     2
#define MUIBBS_BOTTOM                  4
#define MUIBBS_RIGHT                   8
#define MUIBBS_ALL                     MUIBBS_LEFT + MUIBBS_TOP + MUIBBS_BOTTOM + MUIBBS_RIGHT


// Button Accent Styles
#define MUIBAS_NONE                    0
#define MUIBAS_LEFT                    1
#define MUIBAS_TOP                     2
#define MUIBAS_BOTTOM                  4
#define MUIBAS_RIGHT                   8
#define MUIBAS_ALL                     MUIBAS_LEFT + MUIBAS_TOP + MUIBAS_BOTTOM + MUIBAS_RIGHT

// Button Image Types
#define MUIBIT_NONE                    0
#define MUIBIT_BMP                     1
#define MUIBIT_ICO                     2
#define MUIBIT_PNG                     3

// Button Padding Styles
#define MUIBPS_NONE                    0
#define MUIBPS_LEFT                    1
#define MUIBPS_TOP                     2
#define MUIBPS_BOTTOM                  4
#define MUIBPS_RIGHT                   8
#define MUIBPS_ALL                     MUIBPS_LEFT + MUIBPS_TOP + MUIBPS_BOTTOM + MUIBPS_RIGHT





#ifdef __cplusplus
}
#endif
