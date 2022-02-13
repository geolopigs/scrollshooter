//
//  CollisionManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CollisionProtocols.h"

@interface CollisionManager : NSObject
{
    NSMutableDictionary*    collisionSets;
    NSMutableSet*           purgeSet;
    NSMutableArray*         detectionArray;
    NSMutableArray*         responseSet;
}
@property (nonatomic,retain) NSMutableDictionary*   collisionSets;
@property (nonatomic,retain) NSMutableSet*          purgeSet;
@property (nonatomic,retain) NSMutableArray*        detectionArray;
@property (nonatomic,retain) NSMutableArray*        responseSet;
+ (CollisionManager*)getInstance;
+ (void) destroyInstance;

// called by individual objects (player, enemies, bullets)
- (void) addCollisionDelegate:(NSObject<CollisionDelegate>*)delegate toSetNamed:(NSString*)setName;
- (void) removeCollisionDelegate:(NSObject<CollisionDelegate>*)delegate;

// called by GameManager and other high-level loops
- (void) newCollisionSetWithName:(NSString*)setName;
- (void) addDetectionPairForSet:(NSString*)thisSet against:(NSString*)theOtherSet;
- (void) processDetection:(NSTimeInterval)elapsed;
- (void) processResponse:(NSTimeInterval)elapsed;
- (void) reset;
- (void) collectGarbage;

@end
