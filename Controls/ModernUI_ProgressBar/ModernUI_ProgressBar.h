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


// ModernUI_ProgressBar Styles
#define MUIPBS_PULSE                0   // Show pulse hearbeat on progress (default)
#define MUIPBS_NOPULSE              1   // Dont show pulse heartbeat on progress
#define MUIPBS_TEXT_NONE            0   // Dont show % text (default)
#define MUIPBS_TEXT_CENTRE          2   // Show % text in centre of progress control
#define MUIPBS_TEXT_FOLLOW          4   // Show % text and follow progress bar 
#define MUIPBS_R2G                  8   // Show a fading red to green progress bar


//------------------------------------------------------------------------------
// ModernUI_ProgressBar Properties: Use with MUIProgressBarSetProperty / 
// MUIProgressBarGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
//------------------------------------------------------------------------------
#define ProgressBarTextColor        0   // Text color for caption text and system buttons (min/max/restore/close)
#define ProgressBarTextFont	        8   // Font for caption text
#define ProgressBarBackColor        16  // Background color of caption and system buttons
#define ProgressBarProgressColor    24  // RGBCOLOR. Progress bar color
#define ProgressBarBorderColor      32  // RGBCOLOR. Border color
#define ProgressBarPercent          40  // QWORD. Current percent - get or set
#define ProgressBarMin              48  // QWORD. Set min value (not used currently)
#define ProgressBarMax              56  // QWORD. Set max value (not used currently)
#define ProgressBarStep             64  // QWORD. Amount to step by (default 1) (not used currently)
#define ProgressBarPulse            72  // BOOL. Use pulse glow on bar. (default TRUE)
#define ProgressBarPulseTime        80  // QWORD. Milliseconds until pulse (default 3000ms)
#define ProgressBarTextType         88  // QWORD. (Default 0) dont show. 1=show centre, 2=follow progress
#define ProgressBarSetTextPos       96  // QWORD. (Default 0) 0 = preppend WM_SETTEXT text, 1 = append WM_SETTEXT text (not used currently)

// ProgressBar Text Type:
#define MUIPBTT_NONE                0   // No percentage text in progress bar (default)
#define MUIPBTT_CENTRE              1   // Percentage text in center of progress bar
#define MUIPBTT_FOLLOW              2   // Percentage text follows progress as it draws


#ifdef __cplusplus
}
#endif
