//
//  Loot.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DynamicProtocols.h"
#import "CollisionProtocols.h"
#import "LootProtocols.h"

@class Sprite;
@class AnimClip;
@interface Loot : NSObject<DynamicDelegate,CollisionDelegate>
{
    Sprite* sprite;
    AnimClip* animClip;
    CGPoint pos;
    CGPoint vel;
    CGSize  collisionSize;
    CGPoint renderScale;
    float layerDistance;
    BOOL  releasedAsDynamic;
    BOOL isAlive;
    
    // render buckets variables
    unsigned int renderBucketIndex;
    
    NSObject<LootBehaviorDelegate>* behaviorDelegate;
    id lootContext;
    
    NSObject<LootCollisionResponse>* collisionResponseDelegate;
    NSObject<LootCollectedDelegate>* collectedDelegate;
    NSObject<lootAABBDelegate>* collisionAABBDelegate;
}
@property (nonatomic,retain) Sprite* sprite;
@property (nonatomic,retain) AnimClip* animClip;
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint vel;
@property (nonatomic,assign) CGSize collisionSize;
@property (nonatomic,assign) CGPoint renderScale;
@property (nonatomic,assign) unsigned int renderBucketIndex;
@property (nonatomic,retain) NSObject<LootBehaviorDelegate>* behaviorDelegate;
@property (nonatomic,retain) id lootContext;
@property (nonatomic,retain) NSObject<LootCollisionResponse>* collisionResponseDelegate;
@property (nonatomic,retain) NSObject<LootCollectedDelegate>* collectedDelegate;
@property (nonatomic,retain) NSObject<lootAABBDelegate>* collisionAABBDelegate;
@property (nonatomic,assign) float layerDistance;
@property (nonatomic,assign) BOOL releasedAsDynamic;
@property (nonatomic,assign) BOOL isAlive;

- (id) initAtPos:(CGPoint)givenPos isDynamics:(BOOL)isDynamics usingDelegate:(NSObject<LootInitDelegate>*)initDelegate;
- (void) spawn;
- (void) kill;

@end
