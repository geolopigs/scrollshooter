//
//  WaterMine.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/17/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class BossWeapon;
@class SineWeaver;
@interface WaterMineContext : NSObject<EnemyBehaviorContext>
{
    // config params
    unsigned int numShotsPerRound;
    CGPoint initVel;
    unsigned int _flags;
    
    // runtime params
    BossWeapon* scatterWeapon;
    unsigned int shotCount;
}
// configs
@property (nonatomic,assign) unsigned int numShotsPerRound;
@property (nonatomic,assign) CGPoint initVel;
@property (nonatomic,assign) unsigned int flags;
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,retain) SineWeaver* weaverX;
@property (nonatomic,retain) SineWeaver* weaverY;
@property (nonatomic,assign) float introDelay;
@property (nonatomic,assign) int initHealth;

// runtime
@property (nonatomic,retain) BossWeapon* scatterWeapon;
@property (nonatomic,assign) unsigned int shotCount;
@property (nonatomic,assign) unsigned int state;
@property (nonatomic,assign) float introTimer;

- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface WaterMine : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemySpawnedDelegate>
{
    NSString* animName;
    NSString* explosionName;
}
@property (nonatomic,retain) NSString* typeName;
@property (nonatomic,retain) NSString* animName;
@property (nonatomic,retain) NSString* explosionName;
@property (nonatomic,retain) NSString* spawnName;
- (id) initWithTypeName:(NSString*)typeName animNamed:(NSString*)name explosionNamed:(NSString*)expName spawnAnimNamed:(NSString*)spawnName;
@end
