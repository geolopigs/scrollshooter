//
//  Level.h
//  Curry
//
//	A Level is responsible for initializing all the game states including enemies
//

#import <Foundation/Foundation.h>
#import "LayerCameraDelegate.h"

@class LevelConfig;
@class LevelAnimData;
@class LevelPathData;
@class LevelTriggersData;
@class ScrollLayer;
@class TopCam;
@class FloatingLayer;
@interface Level : NSObject 
{
	LevelConfig* config;
    LevelAnimData* animData;
    LevelPathData* pathsData;
    LevelTriggersData* triggersData;
    
    NSMutableArray* backgroundTextures;
    ScrollLayer*    bgScroll;
    TopCam*         gameCamera;
    NSMutableArray*  floatingLayers;
    
    NSMutableArray* layerCameraDelegates;
    
    // bucket indices
    unsigned int grPreDynamicsIndex;
    unsigned int grDynamicsIndex;
    unsigned int grPostDynamicsIndex;
    unsigned int shadowsIndex;
    unsigned int bigDynamicsIndex;
    unsigned int bigAddonsIndex;
    unsigned int bigAddons2Index;
    unsigned int dynamicsIndex;
    unsigned int addonsIndex;
    unsigned int playerIndex;
    unsigned int playerAddonsIndex;
    unsigned int bulletsIndex;
    unsigned int pointsHudIndex;
}
@property (nonatomic,retain) LevelConfig* config;
@property (nonatomic,retain) LevelAnimData* animData;
@property (nonatomic,retain) LevelPathData* pathsData;
@property (nonatomic,retain) LevelTriggersData* triggersData;
@property (nonatomic,retain) NSMutableArray* backgroundTextures;
@property (nonatomic,retain) ScrollLayer*   bgScroll;
@property (nonatomic,retain) TopCam*        gameCamera;
@property (nonatomic,retain) NSMutableArray* floatingLayers;
@property (nonatomic,retain) NSMutableArray* layerCameraDelegates;

- (id) initWithConfig:(LevelConfig*)givenConfig;
- (void) addDraw;
- (void) update:(NSTimeInterval)elapsed;
- (CGSize) getCameraFrameSize;
- (void) restartLevel;
- (void) spawnAllAnimSprites;
- (void) killAllAnimSprites;

@end
