//
//  TopCam.h
//! \brief
//!     Top-down Orthogonal View Camera
//
//  Created by Shu Chiun Cheah on 6/30/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

enum PAUSETYPE
{
    PAUSETYPE_NONE = 0,
    PAUSETYPE_REGULAR,
    PAUSETYPE_TRIGGERONLY     // pause that requires syncing with the break of the main-path when unpaused
};

@class TopCamRenderer;
@class CamPath;
@class Player;
@class LevelConfig;
@interface TopCam : NSObject
{
    CGRect  appFrame;           // the application's window frame (in points)
    CGRect  frame;              // basic model-view frame
    CGPoint pos;                // origin of camera with respect to background
    CGPoint dynamicPos;         // origin of camera with respect to dynamic objects
    float   distanceToGameplayLayer;    // distance from camera to the layer on which gameplay takes place
                                        // basically the layer on which the player lives
                                        // this is used as a reference to make layers at different distances scroll
                                        // at different speeds
    float   distanceMaxLayer;           // distance to the max layer
    float   distanceFuncSlope;          // slope of the function that returns the translationScale
    CamPath* camPath;
    CamPath* triggerPath;
    NSMutableArray* scrollPaths;        // any layer specific scroll paths that need to be updated when camPath gets updated
    NSMutableArray* triggersArray;      // triggers registered from GameManager
    NSMutableDictionary* scrollPathRegistry;
    int    lastTrigger;
    BOOL    paused;
    BOOL    shouldUnpauseAndBreak;
    PAUSETYPE pauseType;
    
    unsigned int renderBucketIndex;
    unsigned int dynamicsBucketIndex;
    TopCamRenderer* renderer;
}
@property (nonatomic,assign) CGRect     appFrame;
@property (nonatomic,assign) CGRect     frame;
@property (nonatomic,assign) CGPoint    pos;
@property (nonatomic,assign) CGPoint    dynamicPos;
@property (nonatomic,retain) CamPath*   camPath;
@property (nonatomic,retain) CamPath*   triggerPath;
@property (nonatomic,retain) NSMutableArray* scrollPaths;
@property (nonatomic,retain) NSMutableArray* triggersArray;
@property (nonatomic,retain) NSMutableDictionary* scrollPathRegistry;
@property (nonatomic,assign) int lastTrigger;
@property (nonatomic,assign) BOOL paused;
@property (nonatomic,retain) TopCamRenderer* renderer;
@property (nonatomic,assign) float      distanceMaxLayer;

- (id) initFromLevelConfig:(LevelConfig*)config forRendererViewFrame:(CGRect)viewFrame;
- (void) restartLevel;
- (void) restartTriggers;
- (void) addDrawToBucketIndex:(unsigned int)bucketIndex;
- (void) addScrollPath:(CamPath*)newPath withName:(NSString*)layerName;

- (void) update:(NSTimeInterval)elapsed;
- (void) offsetPosByPlayer:(Player*)player;
- (CGRect) getPlayArea;     // this is the complete area in play (including the sides that don't fit in the camera view)
- (CGRect) getPlayFrame;    // this is just the view frame

- (float) translationScaleForLayerDistance:(float)layerDistance;
- (CGPoint) camWorldPointAtLayerDistance:(float)dist fromWorldPoint:(CGPoint)worldPoint;
- (CGPoint) camOriginAtLayerDistance:(float)dist;
- (CGPoint) camPointFromWorldPoint:(CGPoint)worldPoint atDistance:(float)dist;

// main path scrolling controls
- (void) startMainPath;
- (void) stopMainPath:(PAUSETYPE)stopType;

// named path controls
- (void) resetPathNamed:(NSString*)name;
- (void) pausePathNamed:(NSString*)name;
- (void) unpausePathNamed:(NSString*)name;
- (BOOL) isAtEndOfPathNamed:(NSString*)name;

@end
