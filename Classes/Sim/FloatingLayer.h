//
//  FloatingLayer.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/15/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerCameraDelegate.h"

@class LevelConfig;
@class DrawCommand;
@class TopCamInstance;
@class CamPath;
@class LevelAnimData;

@interface FloatingLayer : NSObject<LayerCameraDelegate> 
{
    NSString*           layerName;
    NSMutableArray*     textureNames;
    NSMutableArray*     textures;
    NSMutableArray*     sprites;
    NSMutableArray*     animSprites;
    float               layerDistance;
    BOOL                isDynamics;
    CamPath*            scrollPath;
    
    unsigned int        renderBucketShadows;
    unsigned int        renderBucket;
    unsigned int        renderBucketAddons;
    
    DrawCommand*        drawCmd;
    TopCamInstance*     drawData;
}
@property (nonatomic,retain) NSString* layerName;
@property (nonatomic,retain) NSMutableArray* textureNames;
@property (nonatomic,retain) NSMutableArray* textures;
@property (nonatomic,retain) NSMutableArray* sprites;
@property (nonatomic,retain) NSMutableArray* animSprites;
@property (nonatomic,assign) float layerDistance;
@property (nonatomic,assign) BOOL isDynamics;
@property (nonatomic,retain) CamPath* scrollPath;
@property (nonatomic,retain) DrawCommand* drawCmd;
@property (nonatomic,retain) TopCamInstance* drawData;

- (id) initFromLayerConfig:(NSDictionary*)layerConfig levelAnimData:(LevelAnimData*)levelAnimData;
- (void) createSpawnersInLayer:(NSDictionary*)layerConfig;
- (void) addDraw;
- (void) spawnAllAnimSprites;
- (void) killAllAnimSprites;
@end
