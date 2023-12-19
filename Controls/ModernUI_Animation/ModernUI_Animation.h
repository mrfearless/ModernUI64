#ifdef __cplusplus
extern "C" {
#endif

#ifdef _MSC_VER     // MSVC compiler
#define MUI_EXPORT __declspec(dllexport) __fastcall
#else
#define MUI_EXPORT
#endif


//------------------------------------------------------------------------------
// ModernUI_Animation Prototypes
//------------------------------------------------------------------------------
void MUI_EXPORT MUIAnimationRegister(); // Use 'ModernUI_Animation' as class in RadASM custom class control
HWND MUI_EXPORT MUIAnimationCreateHWND hWndParent, QWORD xpos, QWORD ypos, QWORD qwWidth, QWORD qwHeight, QWORD qwResourceID, QWORD qwStyle);
unsigned int MUI_EXPORT MUIAnimationSetProperty(HWND hModernUI_Animation, DWORD dwProperty, DWORD dwPropertyValue);
unsigned int MUI_EXPORT MUIAnimationGetProperty(HWND hModernUI_Animation, DWORD dwProperty);

// Add image handle (bitmap, icon or png) as an animation frame image
bool MUI_EXPORT MUIAnimationAddFrame(HWND hModernUI_Animation, QWORD qwImageType, POINTER *lpMuiAnimationFrameStruct);
bool MUI_EXPORT MUIAnimationAddFrames(HWND hModernUI_Animation, QWORD qwImageType, POINTER *lpArrayMuiAnimationFrameStructs, QWORD qwCount);
// Load an image resource id (bitmap, icon or png) as an animation frame image
bool MUI_EXPORT MUIAnimationLoadFrame(HWND hModernUI_Animation, QWORD qwImageType, POINTER *lpMuiAnimationFrameStruct);
bool MUI_EXPORT MUIAnimationLoadFrames(HWND hModernUI_Animation, QWORD qwImageType, POINTER *lpArrayMuiAnimationFrameStructs, QWORD qwCount);
// Create a series of animation frames images from a sprite sheet
bool MUI_EXPORT MUIAnimationAddSpriteSheet(HWND hModernUI_Animation, QWORD qwImageType, HANDLE hImageSpriteSheet, QWORD qwSpriteCount, POINTER * lpFrameTimes, QWORD qwFrameTimeSize, QWORD qwFrameTimeType);
bool MUI_EXPORT MUIAnimationLoadSpriteSheet(HWND hModernUI_Animation, QWORD qwImageType, QWORD idResSpriteSheet, QWORD qwSpriteCount, POINTER * lpFrameTimes, QWORD qwFrameTimeSize, QWORD qwFrameTimeType);
// Insert image handle as an animation frame image
bool MUI_EXPORT MUIAnimationInsertFrame(HWND hModernUI_Animation, QWORD qwImageType, POINTER *lpMuiAnimationFrameStruct, QWORD qwFrameIndex, BOOL bInsertBefore);
bool MUI_EXPORT MUIAnimationInsertFrames(HWND hModernUI_Animation, QWORD qwImageType, POINTER *lpArrayMuiAnimationFrameStructs, QWORD qwCount, QWORD qwFrameIndex, BOOL bInsertBefore);

// Frame Operations
bool MUI_EXPORT MUIAnimationClear(HWND hModernUI_Animation);
bool MUI_EXPORT MUIAnimationDeleteFrames(HWND hModernUI_Animation);
bool MUI_EXPORT MUIAnimationDeleteFrame(HWND hModernUI_Animation, QWORD qwFrameIndex);
bool MUI_EXPORT MUIAnimationMoveFrame(HWND hModernUI_Animation, QWORD qwFrameIndexFrom, QWORD qwFrameIndexTo);
bool MUI_EXPORT MUIAnimationCopyFrame(HWND hModernUI_Animation, QWORD qwFrameIndexFrom, QWORD qwFrameIndexTo);
bool MUI_EXPORT MUIAnimationCropFrame(HWND hModernUI_Animation, QWORD qwFrameIndex, LPRECT *lpRect);
bool MUI_EXPORT MUIAnimationCropFrames(HWND hModernUI_Animation, LPRECT *lpRect);

// Save frames to file
bool MUI_EXPORT MUIAnimationExportSpriteSheet(HWND hModernUI_Animation, QWORD qwImageType, LPCSTR *lpszSpritesheetFilename, LPCSTR *lpszFrameTimesFilename);
bool MUI_EXPORT MUIAnimationExportFrame(HWND hModernUI_Animation, QWORD qwImageType, LPCSTR *lpszFrameFilename, QWORD qwFrameIndex);
bool MUI_EXPORT MUIAnimationExportFrames(HWND hModernUI_Animation, QWORD qwImageType, LPCSTR *lpszFrameFolder, LPCSTR *lpszFilePrefix, BOOL bFileFrameNo);

// Load frames from file
bool MUI_EXPORT MUIAnimationImportSpriteSheet(HWND hModernUI_Animation, QWORD qwImageType, LPCSTR *lpszSpritesheetFilename, LPCSTR *lpszFrameTimesFilename);
bool MUI_EXPORT MUIAnimationImportFrame(HWND hModernUI_Animation, QWORD qwImageType, LPCSTR *lpszFrameFilename, QWORD qwFrameIndex);

// Frame Information
bool MUI_EXPORT MUIAnimationGetFrameInfo(HWND hModernUI_Animation, QWORD qwFrameIndex, POINTER *lpMuiAnimationFrameStruct);
HANDLE MUI_EXPORT MUIAnimationGetFrameImage(HWND hModernUI_Animation, QWORD qwFrameIndex, POINTER *lpqwFrameType);
unsigned long long MUIAnimationGetFrameTime(HWND hModernUI_Animation, QWORD qwFrameIndex);

bool MUI_EXPORT MUIAnimationSetFrameInfo(HWND hModernUI_Animation, QWORD qwFrameIndex, POINTER *lpMuiAnimationFrameStruct);
bool MUI_EXPORT MUIAnimationSetFrameImage(HWND hModernUI_Animation, QWORD qwFrameIndex, QWORD qwFrameType, HANDLE hFrameImage);
bool MUI_EXPORT MUIAnimationSetFrameTime(HWND hModernUI_Animation, QWORD qwFrameIndex, QWORD qwFrameTime);

// Animation control
void MUI_EXPORT MUIAnimationStart(HWND hModernUI_Animation);
void MUI_EXPORT MUIAnimationStop(HWND hModernUI_Animation);
void MUI_EXPORT MUIAnimationPause(HWND hModernUI_Animation);
void MUI_EXPORT MUIAnimationResume(HWND hModernUI_Animation);
void MUI_EXPORT MUIAnimationStep(HWND hModernUI_Animation, BOOL bReverse);
void MUI_EXPORT MUIAnimationSpeed(HWND hModernUI_Animation, FLOAT fSpeedFactor);

void MUI_EXPORT MUIAnimationSetDefaultTime(HWND hModernUI_Animation, QWORD qwDefaultFrameTime);

void MUI_EXPORT MUIAnimationNotifyCallback(HWND hModernUI_Animation, POINTER *lpNMAnimationStruct);


//------------------------------------------------------------------------------
// ModernUI_Animation Messages
//------------------------------------------------------------------------------
#define MUIAM_ADDFRAME              WM_USER+1752 // wParam = qwImageType, lParam = lpAnimationFrameStruct
#define MUIAM_LOADFRAME             WM_USER+1751 // wParam = qwImageType, lParam = idResImage
#define MUIAM_START                 WM_USER+1750 // wParam & lParam = NULL
#define MUIAM_STOP                  WM_USER+1749 // wParam & lParam = NULL
#define MUIAM_STEP                  WM_USER+1748 // wParam = bReverse
#define MUIAM_SPEED                 WM_USER+1745 // wParam = qwSpeedFactor


//------------------------------------------------------------------------------
// ModernUI_Animation Notifications
//------------------------------------------------------------------------------
#define MUIAN_STOP                  0   // Animation is stopped
#define MUIAN_START                 1   // Animation has started
#define MUIAN_PAUSE                 2   // Animation is paused 
#define MUIAN_RESUME                3   // Animation has resumed
#define MUIAN_STEP                  4   // Animation stepping 
#define MUIAN_FRAME                 5   // Occurs every frame shown


//------------------------------------------
// ModernUI_Animation Structures
//------------------------------------------
IFNDEF MUI_ANIMATION_FRAME          // lpMuiAnimationFrameStruct
typedef struct MUI_ANIMATION_FRAME
{
    qword qwFrameType,              // QWORD. Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    qword qwFrameImage,             // QWORD/HANDLE. Handle or resource ID of image: Bitmap, Icon or PNG (RT_BITMAP, RT_ICON or RT_RCDATA resource)
    qword qwFrameTime,              // QWORD. Frame time in milliseconds
    qword lParam                    // QWORD. Custom user specified value
}
ENDIF

IFNDEF MUI_ANIMATION_FT_FULL        // For array of frame times for every frame in array
typedef struct MUI_ANIMATION_FT_FULL
{
    qword qwFrameTime
}
ENDIF

IFNDEF MUI_ANIMATION_FT_COMPACT     // For array of frame times for specified frame indexes in each entry
typedef struct MUI_ANIMATION_FT_COMPACT
{
    qword qwFrameID,
    qword qwFrameTime
}
ENDIF

IFNDEF NM_ANIMATION_FRAME           // ModernUI_Animation Notification Item
typedef struct NM_ANIMATION_FRAME
{
    qword qwFrameIndex,             // QWORD. Frame index
    qword qwFrameType,              // QWORD. Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    qword qwFrameImage,             // HANDLE. Handle of image: Bitmap, Icon or PNG
    qword qwFrameTime,              // QWORD. Frame time in milliseconds
    qword lParam                    // QWORD. Custom user specified value
}
ENDIF

IFNDEF NM_ANIMATION                 // Notification Message Structure for ModernUI_Animation
typedef struct NM_ANIMATION
{
    NMHDR hdr,
    NM_ANIMATION_FRAME item
}
ENDIF


//------------------------------------------
// ModernUI_Animation Styles
// 
//------------------------------------------
#define MUIAS_NOSTRETCH             0x0
#define MUIAS_NOCENTER              0x1
#define MUIAS_CENTER                0x2
#define MUIAS_STRETCH               0x3
#define MUIAS_LCLICK                0x4
#define MUIAS_RCLICK                0x8
#define MUIAS_HAND                  0x10
#define MUIAS_CONTROL               0x20

//------------------------------------------------------------------------------
// ModernUI_Animation Properties: Use with MUIAnimationSetProperty / 
// MUIAnimationGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
//------------------------------------------------------------------------------
#define AnimationBackColor          0   // RGBCOLOR. Background color of animation
#define AnimationBorderColor        8   // RGBCOLOR. Border color of animation
#define AnimationLoop               16  // BOOL. Loop animation back to start. Default is TRUE
#define AnimationNotifications      24  // BOOL. Allow notifications via WM_NOTIFY. Default is TRUE
#define AnimationNotifyCallback     32  // QWORD. Address of custom notifications callback function (MUIAnimationNotifyCallback)
#define AnimationDllInstance        40  // QWORD. Instance of DLL if using control in a DLL
#define AnimationParam              48  // QWORD. Custom user specified value

// Animation Image Type:
#define MUIAIT_NONE                 0
#define MUIAIT_BMP                  1
#define MUIAIT_ICO                  2
#define MUIAIT_PNG                  3

// Animation Frame Type:
#define MUIAFT_FULL                 0
#define MUIAFT_COMPACT              1


#ifdef __cplusplus
}
#endif
