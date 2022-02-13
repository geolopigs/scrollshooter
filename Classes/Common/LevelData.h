//
//  LevelData.h
//  Pogditor
//
//  Created by Shu Chiun Cheah on 7/20/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LevelDataDelegate.h"

@interface LevelData : NSObject 
{
@private
    // committed data - background layer
    unsigned int    numTiles;
    float           tileWidth;
    float           tileHeight;
    float           tileTexWidth;
    float           tileTexHeight;
    NSMutableArray* bgTiles;
    NSMutableArray* bgTriggers;
    
    // committed data - floating layers
    NSMutableArray* floatingLayerData;
    
    // committed data - game camera
    float           cameraFrameWidth;
    float           cameraFrameHeight;
    float           cameraFrameX;
    float           cameraFrameY;
    float           gameplayLayerDistance;
    float           maxLayerDistance;

    // live data
    NSMutableDictionary* floatingLayers;
    BOOL            isAddonsData;

    // processing
    NSMutableArray* delegates;
    
    // property list for data to be written out
    NSMutableDictionary* plist;
}
@property (nonatomic,assign) unsigned int numTiles;
@property (nonatomic,assign) float tileWidth;
@property (nonatomic,assign) float tileHeight;
@property (nonatomic,assign) float tileTexWidth;
@property (nonatomic,assign) float tileTexHeight;
@property (nonatomic,retain) NSMutableArray* bgTiles;
@property (nonatomic,retain) NSMutableArray* bgTriggers;
@property (nonatomic,retain) NSMutableArray* floatingLayerData;
@property (nonatomic,assign) float cameraFrameWidth;
@property (nonatomic,assign) float cameraFrameHeight;

@property (nonatomic,retain) NSMutableDictionary* floatingLayers;
@property (nonatomic,assign) BOOL isAddonsData;
@property (nonatomic,retain) NSMutableArray* delegates;
@property (nonatomic,retain) NSMutableDictionary* plist;

- (id) initFromPlist:(NSDictionary*)loadedPlist;

- (void) addDelegate:(NSObject<LevelDataDelegate>*)delegate;
- (void) removeDelegate:(NSObject<LevelDataDelegate>*)delegate;

// commit data to plist for output
// call this before you serialize out the plist to an NSData
- (void) commitData;
@end
