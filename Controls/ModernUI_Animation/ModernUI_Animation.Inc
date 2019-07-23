;==============================================================================
;
; ModernUI Control x64 - ModernUI_Animation x64
;
; Copyright (c) 2019 by fearless
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

;------------------------------------------------------------------------------
; ModernUI_Animation Prototypes
;------------------------------------------------------------------------------
MUIAnimationRegister	    PROTO												    ; Use 'ModernUI_Animation' as class in RadASM custom class control
MUIAnimationCreate		    PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD  ; hWndParent, xpos, ypos, qwWidth, qwHeight, qwResourceID, qwStyle
MUIAnimationSetProperty	    PROTO :QWORD,:QWORD,:QWORD							    ; hModernUI_Animation, qwProperty, qwPropertyValue
MUIAnimationGetProperty	    PROTO :QWORD,:QWORD									    ; hModernUI_Animation, qwProperty

; Add image handle (bitmap, icon or png) as an animation frame image
MUIAnimationAddFrame        PROTO :QWORD,:QWORD,:QWORD						        ; hModernUI_Animation, qwImageType, lpMuiAnimationFrameStruct
MUIAnimationAddFrames       PROTO :QWORD,:QWORD,:QWORD,:QWORD                       ; hModernUI_Animation, qwImageType, lpArrayMuiAnimationFrameStructs, qwCount
; Load an image resource id (bitmap, icon or png) as an animation frame image
MUIAnimationLoadFrame       PROTO :QWORD,:QWORD,:QWORD						        ; hModernUI_Animation, qwImageType, lpMuiAnimationFrameStruct
MUIAnimationLoadFrames      PROTO :QWORD,:QWORD,:QWORD,:QWORD                       ; hModernUI_Animation, qwImageType, lpArrayMuiAnimationFrameStructs, qwCount
; Create a series of animation frames images from a sprite sheet
MUIAnimationAddSpriteSheet  PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD  ; hModernUI_Animation, qwImageType, hImageSpriteSheet, qwSpriteCount, lpFrameTimes, qwFrameTimeSize, qwFrameTimeType
MUIAnimationLoadSpriteSheet PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD  ; hModernUI_Animation, qwImageType, idResSpriteSheet, qwSpriteCount, lpFrameTimes, qwFrameTimeSize, qwFrameTimeType
; Insert image handle as an animation frame image
MUIAnimationInsertFrame     PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD                ; hModernUI_Animation, qwImageType, lpMuiAnimationFrameStruct, qwFrameIndex, bInsertBefore
MUIAnimationInsertFrames    PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD,:QWORD         ; hModernUI_Animation, qwImageType, lpArrayMuiAnimationFrameStructs, qwCount, qwFrameIndex, bInsertBefore

; Frame Operations
MUIAnimationClear           PROTO :QWORD                                            ; hModernUI_Animation
MUIAnimationDeleteFrames    PROTO :QWORD                                            ; hModernUI_Animation
MUIAnimationDeleteFrame     PROTO :QWORD,:QWORD                                     ; hModernUI_Animation, qwFrameIndex
MUIAnimationMoveFrame       PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_Animation, qwFrameIndexFrom, qwFrameIndexTo
MUIAnimationCopyFrame       PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_Animation, qwFrameIndexFrom, qwFrameIndexTo
MUIAnimationCropFrame       PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_Animation, qwFrameIndex, lpRect
MUIAnimationCropFrames      PROTO :QWORD,:QWORD                                     ; hModernUI_Animation, lpRect

; Save frames to file
MUIAnimationExportSpriteSheet PROTO :QWORD,:QWORD,:QWORD                            ; hModernUI_Animation, qwImageType, lpszSpritesheetFilename, lpszFrameTimesFilename
MUIAnimationExportFrame       PROTO :QWORD,:QWORD,:QWORD,:QWORD                     ; hModernUI_Animation, qwImageType, lpszFrameFilename, qwFrameIndex
MUIAnimationExportFrames      PROTO :QWORD,:QWORD,:QWORD,:QWORD,:QWORD              ; hModernUI_Animation, qwImageType, lpszFrameFolder, lpszFilePrefix, bFileFrameNo

; Load frames from file
MUIAnimationImportSpriteSheet PROTO :QWORD,:QWORD,:QWORD                            ; hModernUI_Animation, qwImageType, lpszSpritesheetFilename, lpszFrameTimesFilename
MUIAnimationImportFrame       PROTO :QWORD,:QWORD,:QWORD,:QWORD                     ; hModernUI_Animation, qwImageType, lpszFrameFilename, qwFrameIndex

; Frame Information
MUIAnimationGetFrameInfo    PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_Animation, qwFrameIndex, lpMuiAnimationFrameStruct
MUIAnimationGetFrameImage   PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_Animation, qwFrameIndex, lpqwFrameType
MUIAnimationGetFrameTime    PROTO :QWORD,:QWORD                                     ; hModernUI_Animation, qwFrameIndex

MUIAnimationSetFrameInfo    PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_Animation, qwFrameIndex, lpMuiAnimationFrameStruct
MUIAnimationSetFrameImage   PROTO :QWORD,:QWORD,:QWORD,:QWORD                       ; hModernUI_Animation, qwFrameIndex, qwFrameType, hFrameImage
MUIAnimationSetFrameTime    PROTO :QWORD,:QWORD,:QWORD                              ; hModernUI_Animation, qwFrameIndex, qwFrameTime

; Animation control
MUIAnimationStart           PROTO :QWORD                                            ; hModernUI_Animation
MUIAnimationStop            PROTO :QWORD                                            ; hModernUI_Animation
MUIAnimationPause           PROTO :QWORD                                            ; hModernUI_Animation
MUIAnimationResume          PROTO :QWORD                                            ; hModernUI_Animation
MUIAnimationStep            PROTO :QWORD,:QWORD                                     ; hModernUI_Animation, bReverse
MUIAnimationSpeed           PROTO :QWORD,:REAL4                                     ; hModernUI_Animation, fSpeedFactor

MUIAnimationSetDefaultTime  PROTO :QWORD,:QWORD                                     ; hModernUI_Animation, qwDefaultFrameTime

MUIAnimationNotifyCallback  PROTO :QWORD,:QWORD                                     ; hModernUI_Animation, lpNMAnimationStruct


;------------------------------------------------------------------------------
; ModernUI_Animation Messages
;------------------------------------------------------------------------------
MUIAM_ADDFRAME              EQU WM_USER+1752 ; wParam = qwImageType, lParam = lpAnimationFrameStruct
MUIAM_LOADFRAME             EQU WM_USER+1751 ; wParam = qwImageType, lParam = idResImage
MUIAM_START                 EQU WM_USER+1750 ; wParam & lParam = NULL
MUIAM_STOP                  EQU WM_USER+1749 ; wParam & lParam = NULL
MUIAM_STEP                  EQU WM_USER+1748 ; wParam = bReverse
MUIAM_SPEED                 EQU WM_USER+1745 ; wParam = qwSpeedFactor


;------------------------------------------------------------------------------
; ModernUI_Animation Notifications
;------------------------------------------------------------------------------
MUIAN_STOP                  EQU 0   ; Animation is stopped
MUIAN_START                 EQU 1   ; Animation has started
MUIAN_PAUSE                 EQU 2   ; Animation is paused 
MUIAN_RESUME                EQU 3   ; Animation has resumed
MUIAN_STEP                  EQU 4   ; Animation stepping 
MUIAN_FRAME                 EQU 5   ; Occurs every frame shown

;------------------------------------------------------------------------------
; ModernUI_Animation Structures
;------------------------------------------------------------------------------
IFNDEF MUI_ANIMATION_FRAME  ; lpMuiAnimationFrameStruct
MUI_ANIMATION_FRAME         STRUCT
    qwFrameType             DQ ?    ; QWORD. Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    qwFrameImage            DQ ?    ; QWORD/HANDLE. Handle or resource ID of image: Bitmap, Icon or PNG (RT_BITMAP, RT_ICON or RT_RCDATA resource)
    qwFrameTime             DQ ?    ; QWORD. Frame time in milliseconds
    lParam                  DQ ?    ; QWORD. Custom user specified value
MUI_ANIMATION_FRAME         ENDS
ENDIF

IFNDEF MUI_ANIMATION_FT_FULL ; For array of frame times for every frame in array
MUI_ANIMATION_FT_FULL     STRUCT
    qwFrameTime           DQ ?
MUI_ANIMATION_FT_FULL     ENDS
ENDIF

IFNDEF MUI_ANIMATION_FT_COMPACT ; For array of frame times for specified frame indexes in each entry
MUI_ANIMATION_FT_COMPACT  STRUCT
    qwFrameID             DQ ?
    qwFrameTime           DQ ?
MUI_ANIMATION_FT_COMPACT  ENDS
ENDIF

IFNDEF NM_ANIMATION_FRAME   ; ModernUI_Animation Notification Item
NM_ANIMATION_FRAME          STRUCT
    qwFrameIndex            DQ ?    ; QWORD. Frame index
    qwFrameType             DQ ?    ; QWORD. Image type: MUIAIT_BMP, MUIAIT_ICO, MUIAIT_PNG
    qwFrameImage            DQ ?    ; HANDLE. Handle of image: Bitmap, Icon or PNG
    qwFrameTime             DQ ?    ; QWORD. Frame time in milliseconds
    lParam                  DQ ?    ; QWORD. Custom user specified value
NM_ANIMATION_FRAME          ENDS
ENDIF

IFNDEF NM_ANIMATION         ; Notification Message Structure for ModernUI_Animation
NM_ANIMATION                STRUCT
    hdr                     NMHDR <>
    item                    NM_ANIMATION_FRAME <>
NM_ANIMATION                ENDS
ENDIF


.CONST
;------------------------------------------------------------------------------
; ModernUI_Animation Constants
;------------------------------------------------------------------------------

; ModernUI_Animation Styles
MUIAS_NOSTRETCH             EQU 0
MUIAS_NOCENTER              EQU 1
MUIAS_CENTER                EQU 2
MUIAS_STRETCH               EQU 3
MUIAS_LCLICK                EQU 4
MUIAS_RCLICK                EQU 8
MUIAS_HAND                  EQU 10h
MUIAS_CONTROL               EQU 20h

;------------------------------------------------------------------------------
; ModernUI_Animation Properties: Use with MUIAnimationSetProperty / 
; MUIAnimationGetProperty or MUI_SETPROPERTY / MUI_GETPROPERTY msgs
;------------------------------------------------------------------------------
@AnimationBackColor         EQU 0   ; RGBCOLOR. Background color of animation
@AnimationBorderColor       EQU 8   ; RGBCOLOR. Border color of animation
@AnimationLoop              EQU 16  ; BOOL. Loop animation back to start. Default is TRUE
@AnimationNotifications     EQU 24  ; BOOL. Allow notifications via WM_NOTIFY. Default is TRUE
@AnimationNotifyCallback    EQU 32  ; QWORD. Address of custom notifications callback function (MUIAnimationNotifyCallback)
@AnimationDllInstance       EQU 40  ; QWORD. Instance of DLL if using control in a DLL
@AnimationParam             EQU 48  ; QWORD. Custom user specified value


; Animation Image Type:
MUIAIT_NONE                 EQU 0
MUIAIT_BMP                  EQU 1
MUIAIT_ICO                  EQU 2
MUIAIT_PNG                  EQU 3

; Animation Frame Type:
MUIAFT_FULL                 EQU 0
MUIAFT_COMPACT              EQU 1








