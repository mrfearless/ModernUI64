#ifdef __cplusplus
extern "C" {
#endif

#ifdef _MSC_VER     // MSVC compiler
#define MUI_EXPORT __declspec(dllexport) __fastcall
#else
#define MUI_EXPORT
#endif


//------------------------------------------------------------------------------
// ModernUI_Checkbox Prototypes
//------------------------------------------------------------------------------

void MUI_EXPORT MUICheckboxRegister(); // Use 'ModernUI_Checkbox' as class in custom control
HWND MUI_EXPORT MUICheckboxCreate(hWndParent, LPCSTR *lpszText, QWORD xpos, QWORD ypos, QWORD qwWidth, QWORD qwHeight, QWORD qwResourceID, QWORD qwStyle);
unsigned int MUI_EXPORT MUICheckboxSetProperty(HWND hModernUI_Checkbox, QWORD qwProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUICheckboxGetProperty(HWND hModernUI_Checkbox, QWORD qwProperty);
bool MUI_EXPORT MUICheckboxGetState(HWND hModernUI_Checkbox);
bool MUI_EXPORT MUICheckboxSetState(HWND hModernUI_Checkbox, BOOL bState);

bool MUI_EXPORT MUICheckboxLoadImages(HWND hModernUI_Checkbox, QWORD qwImageType, QWORD qwResIDImage, QWORD qwResIDImageAlt, QWORD qwResIDImageSel, QWORD qwResIDImageSelAlt, QWORD qwResIDImageDisabled, QWORD qwResIDImageDisabledSel);
bool MUI_EXPORT MUICheckboxSetImages(HWND hModernUI_Checkbox, QWORD qwImageType, HANDLE hImage, HANDLE hImageAlt, HANDLE hImageSel, HANDLE hImageSelAlt, HANDLE hImageDisabled, hImageDisabledSel);



//------------------------------------------
// ModernUI_Checkbox Styles
// 
//------------------------------------------

#define MUICBS_CHECK                   0x00    //
#define MUICBS_RADIO                   0x01    //
#define MUICBS_HAND                    0x20    // Show a hand instead of an arrow when mouse moves over checkbox.
#define MUICBS_NOFOCUSRECT             0x100   // Dont show focus rect, just use change border to CheckboxTextColorAlt when setfocus.
#define MUICBS_THEMEDARK               0x200   // For default icons, if not set default dark icons for light backgrounds, if set light icons for dark backgrounds
#define MUICBS_THEME                   0x8000  // Use default windows theme colors and react to WM_THEMECHANGED


//------------------------------------------------------------------------------
// ModernUI_Checkbox Properties: Use with MUICheckboxSetProperty / 
// MUICheckboxGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
//------------------------------------------------------------------------------
#define CheckboxTextFont	           0       // Font for checkbox text
#define CheckboxTextColor              8       // Colorref Text color for checkbox
#define CheckboxTextColorAlt           16      // Colorref
#define CheckboxTextColorSel           24      // Colorref
#define CheckboxTextColorSelAlt        32      // Colorref
#define CheckboxTextColorDisabled      40      // Colorref
#define CheckboxBackColor              48      // Colorref
#define CheckboxImageType              56      // Button Image Types - One of the following: MUICIT_NONE, MUICIT_BMP, MUICIT_ICO or MUICIT_PNG
#define CheckboxImage                  64      // hImage
#define CheckboxImageAlt               72      // hImage
#define CheckboxImageSel               80      // hImage
#define CheckboxImageSelAlt            88      // hImage
#define CheckboxImageDisabled          96      // hImage
#define CheckboxImageDisabledSel       104     // hImage
#define CheckboxDllInstance            112     // Set to hInstance of dll before calling MUICheckboxLoadImages if used within a dll
#define CheckboxParam                  120     // Custom user data

// Checkbox Image Types
#define MUICIT_NONE                     0
#define MUICIT_BMP                      1
#define MUICIT_ICO                      2
#define MUICIT_PNG                      3



#ifdef __cplusplus
}
#endif
