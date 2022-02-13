//
//  ScrollLayer.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/7/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerCameraDelegate.h"

@class ScrollRenderer;
@class LevelConfig;
@class ScrollLoader;
@class DrawCommand;
@class TopCamInstance;

@interface ScrollLayer : NSObject<LayerCameraDelegate> 
{
    NSMutableArray*     tiles;
    NSArray*            loadTriggers;
    ScrollRenderer*     renderer; 
    NSMutableArray*     activeTiles;
    NSMutableArray*     requestTiles;
    float               tileHeight;
    
    unsigned int        nextTrigger;    // index to the textureNames array
    BOOL                doUpload;
    
    ScrollLoader*       loader;
    
    float               distanceFromCamera;
    
    DrawCommand*        drawCmd;
    TopCamInstance*     drawData;
}
@property (nonatomic,retain) NSMutableArray* tiles;
@property (nonatomic,retain) NSArray* loadTriggers;
@property (nonatomic,retain) ScrollRenderer* renderer;
@property (nonatomic,retain) NSMutableArray* activeTiles;
@property (nonatomic,retain) NSMutableArray* requestTiles;
@property (retain)           ScrollLoader*   loader;
@property (nonatomic,assign) float           distanceFromCamera;
@property (nonatomic,retain) DrawCommand*    drawCmd;
@property (nonatomic,retain) TopCamInstance* drawData;

- (id) initWithLevelConfig:(LevelConfig*)config;
- (void) addDraw;
- (void) updateAtPos:(CGPoint)camPos;
- (void) jumpToPos:(CGPoint)camPos;
- (void) restart;
@end
