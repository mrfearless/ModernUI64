#ifdef __cplusplus
extern "C" {
#endif

#ifdef _MSC_VER     // MSVC compiler
#define MUI_EXPORT __declspec(dllexport) __fastcall
#else
#define MUI_EXPORT
#endif


//------------------------------------------------------------------------------
// ModernUI_ProgressDots Prototypes
//------------------------------------------------------------------------------

void MUI_EXPORT MUIProgressDotsRegister(); // Use 'ModernUI_ProgressDots' as class in RadASM custom class control
HWND MUI_EXPORT MUIProgressDotsCreate(HWND hWndParent, QWORD ypos, QWORD qwHeight, QWORD qwResourceID, QWORD qwStyle);
unsigned int MUI_EXPORT MUIProgressDotsSetProperty(HWND hMUIProgressDots, QWORD qwProperty, QWORD qwPropertyValue);
unsigned int MUI_EXPORT MUIProgressDotsGetProperty(HWND hMUIProgressDots, QWORD qwProperty);
void MUI_EXPORT MUIProgressDotsAnimateStart(HWND hMUIProgressDots);
void MUI_EXPORT MUIProgressDotsAnimateStop(HWND hMUIProgressDots);



//------------------------------------------------------------------------------
// ModernUI_ProgressDots Properties: Use with MUIProgressDotsSetProperty / 
// MUIProgressDotsGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
//------------------------------------------------------------------------------
#define ProgressDotsBackColor        0   // Background color of control 
#define ProgressDotsDotColor         8   // Progress Dots color 
#define ProgressDotsShowInterval     16  // Interval till dot starts showing, default is 16
#define ProgressDotsTimeInterval     24  // Milliseconds for timer, defaults to 10, higher will slow down animation of dots
#define ProgressDotsSpeed            32  // Speed for fast dots (before and after markers), default is 2. For adjusting xpos of dots. Middle portion is always xpos=xpos+1

#ifdef __cplusplus
}
#endif
