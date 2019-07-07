//==============================================================================
//
// ModernUI x64 Control - ModernUI_SmartPanel x64
//
// Copyright (c) 2019 by fearless
//
// All Rights Reserved
//
// http://github.com/mrfearless/ModernUI64
//
//==============================================================================

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _MSC_VER     // MSVC compiler
#define MUI_EXPORT __declspec(dllexport) __fastcall
#else
#define MUI_EXPORT
#endif


//------------------------------------------------------------------------------
// ModernUI_SmartPanel Prototypes
//------------------------------------------------------------------------------

void MUI_EXPORT MUISmartPanelRegister(); // Use 'ModernUI_SmartPanel' as class in custom control
HWND MUI_EXPORT MUISmartPanelCreate(HWND hWndParent, QWORD xpos, QWORD ypos, QWORD qwWidth, QWORD qwHeight, QWORD qwResourceID, QWORD qwStyle);
unsigned int MUI_EXPORT MUISmartPanelSetProperty(HWND hModernUI_SmartPanel, QWORD qwProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUISmartPanelGetProperty(HWND hModernUI_SmartPanel, QWORD qwProperty);

unsigned int MUI_EXPORT MUISmartPanelGetCurrentPanel(HWND hModernUI_SmartPanel);
unsigned int MUI_EXPORT MUISmartPanelSetCurrentPanel(HWND hModernUI_SmartPanel, QWORD PanelIndex, BOOL bNotify);
unsigned int MUI_EXPORT MUISmartPanelCurrentPanelIndex(HWND hModernUI_SmartPanel);

bool MUI_EXPORT MUISmartPanelNextPanel(HWND hModernUI_SmartPanel, BOOL bNotify);
bool MUI_EXPORT MUISmartPanelPrevPanel(HWND hModernUI_SmartPanel, BOOL bNotify);
bool MUI_EXPORT MUISmartPanelSetIsDlgMsgVar(HWND hModernUI_SmartPanel, QWORD *lpqwVar);
bool MUI_EXPORT MUISmartPanelRegisterPanel(HWND hModernUI_SmartPanel, QWORD qwResIdPanelDlg, QWORD  *lpqwPanelProc);

unsigned int MUI_EXPORT MUISmartPanelSetPanelParam(HWND hModernUI_SmartPanel, QWORD PanelIndex, QWORD lParam);
unsigned int MUI_EXPORT MUISmartPanelGetPanelParam(HWND hModernUI_SmartPanel, QWORD PanelIndex);

void MUI_EXPORT MUISmartPanelNotifyCallback(HWND hModernUI_SmartPanel, NM_MUISMARTPANEL *lpNMSmartPanelStruct);

//------------------------------------------
// ModernUI_SmartPanel Structures
//------------------------------------------

IFNDEF MUISP_ITEM // SmartPanel Notification Item
typedef struct MUISP_ITEM
{
    qword iItem,
    qword lParam,
    qword hPanel
}
ENDIF

IFNDEF NM_MUISMARTPANEL // Notification Message Structure for SmartPanel
typedef struct NM_MUISMARTPANEL
{
    NMHDR hdr,
    MUISP_ITEM itemOld,
    MUISP_ITEM itemNew
}
ENDIF

// SmartPanel Notifications
#define MUISPN_SELCHANGED              0x0  // Used with WM_NOTIFY. wParam is a NM_MUISMARTPANEL struct


//------------------------------------------
// ModernUI_SmartPanel Styles
//------------------------------------------
#define MUISPS_NORMAL                  0x0
#define MUISPS_NOSLIDE                 MUISPS_NORMAL
#define MUISPS_SLIDEPANELS_SLOW        0x1
#define MUISPS_SLIDEPANELS_NORMAL      0x2
#define MUISPS_SLIDEPANELS             MUISPS_SLIDEPANELS_NORMAL
#define MUISPS_SLIDEPANELS_FAST        0x4
#define MUISPS_SLIDEPANELS_VFAST       0x8
#define MUISPS_SLIDEPANELS_INSTANT     MUISPS_NORMAL
#define MUISPS_SPS_WRAPAROUND          0x10   // for next/prev and showcase, if at end, moves to the right and starts again, otherwise if not specified, at last panel, scrolls left all the way back to start showing all panels along the way.
#define MUISPS_SPS_SKIPBETWEEN         0x20   // skips any in between panels, just moves from one to another.
#define MUISPS_DESIGN_INFO             0x1000 // only used at design time to show text, which can be toggled off by user


//------------------------------------------------------------------------------
// ModernUI_SmartPanel Properties: Use with MUIModernUI_SmartPanelSetProperty / 
// MUIModernUI_SmartPanelGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
//------------------------------------------------------------------------------
#define SmartPanelPanelsColor          0   // RGBCOLOR for panel's background. -1 = ignore, use system default. Default value is -1
#define SmartPanelBorderColor          8   // RGBCOLOR for border color of MUISmartPanel. -1 = none. Default value is -1
#define @SmartPanelNotifications       16  // BOOL. Allow notifications via WM_NOTIFY. Default is TRUE
#define @SmartPanelNotifyCallback      24  // QWORD. Address of custom notifications callback function (MUISmartPanelNotifyCallback)
#define @SmartPanelDllInstance         32  // reserved for future use
#define @SmartPanelParam               40  // user custom data



#ifdef __cplusplus
}
#endif
