//==============================================================================
//
// ModernUI x64 Control - ModernUI_ProgressBar x64
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
// ModernUI_ProgressBar Prototypes
//------------------------------------------------------------------------------

void MUI_EXPORT MUIProgressBarRegister(); // Use 'ModernUI_ProgressBar' as class in custom control
HWND MUI_EXPORT MUIProgressBarCreate(HWND hWndParent, QWORD xpos, QWORD ypos, QWORD qwWidth, QWORD qwHeight, QWORD qwResourceID, QWORD qwStyle);
unsigned int MUI_EXPORT MUIProgressBarSetProperty(HWND hModernUI_ProgressBar, QWORD qwProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUIProgressBarGetProperty(HWND hModernUI_ProgressBar, QWORD qwProperty);
bool MUI_EXPORT MUIProgressBarSetMinMax(HWND hModernUI_ProgressBar, QWORD qwMin, QWORD qwMax);
unsigned int MUI_EXPORT MUIProgressBarSetPercent(HWND hModernUI_ProgressBar, QWORD qwPercent);
unsigned int MUI_EXPORT MUIProgressBarGetPercent(HWND hModernUI_ProgressBar);
bool MUI_EXPORT MUIProgressBarStep(HWND hModernUI_ProgressBar);



//------------------------------------------------------------------------------
// ModernUI_ProgressBar Properties: Use with MUIProgressBarSetProperty / 
// MUIProgressBarGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
//------------------------------------------------------------------------------
#define ProgressBarTextColor        0   // Text color for caption text and system buttons (min/max/restore/close)
#define ProgressBarTextFont	        8   // Font for caption text
#define ProgressBarBackColor        16  // Background color of caption and system buttons
#define ProgressBarProgressColor    24  //
#define ProgressBarBorderColor      32  //
#define ProgressBarPercent          40  // 
#define ProgressBarMin              48  //
#define ProgressBarMax              56  //
#define ProgressBarStep             64  //



#ifdef __cplusplus
}
#endif
