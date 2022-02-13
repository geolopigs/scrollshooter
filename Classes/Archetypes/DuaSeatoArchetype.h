//
//  DuaSeatoArchetype.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class SineWeaver;
@class BossWeapon;
@interface DuaSeatoContext : NSObject<EnemyBehaviorContext>
{
    NSMutableArray* attachedEnemies;
    float timeTillFire;
    int   fireSlot;
    unsigned int dynamicsBucketIndex;
    unsigned int _dynamicsAddonsIndex;
    unsigned int behaviorState;
    CGPoint introDoneBotLeft;
    CGPoint introDoneTopRight;
    float cruisingTimer;
    NSString* enemyTriggerName;

    SineWeaver* weaverX;
    SineWeaver* weaverY;
    BossWeapon* bossWeapon;
    BOOL        fireBossWeaponRightAway;
    
    // config params
    float timeBetweenShots;
    float shotSpeed;
    float cruisingTimeout;
    CGPoint exitVel;
    CGPoint cruisingVel;
    NSDictionary* boarSpec;
    int _initHealth;
    unsigned int _flags;
    CGPoint _introVel;
    float _faceDir;
}
@property (nonatomic,retain) NSMutableArray* attachedEnemies;
@property (nonatomic,assign) float  timeTillFire;
@property (nonatomic,assign) int    fireSlot;
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) CGPoint introDoneBotLeft;
@property (nonatomic,assign) CGPoint introDoneTopRight;
@property (nonatomic,assign) float cruisingTimer;
@property (nonatomic,retain) NSString* enemyTriggerName;
@property (nonatomic,retain) SineWeaver* weaverX;
@property (nonatomic,retain) SineWeaver* weaverY;
@property (nonatomic,retain) BossWeapon* bossWeapon;
@property (nonatomic,assign) BOOL fireBossWeaponRightAway;
@property (nonatomic,assign) float timeBetweenShots;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) float cruisingTimeout;
@property (nonatomic,assign) CGPoint exitVel;
@property (nonatomic,assign) CGPoint cruisingVel;
@property (nonatomic,retain) NSDictionary* boarSpec;
@property (nonatomic,assign) int initHealth;
@property (nonatomic,assign) unsigned int flags;
@property (nonatomic,assign) CGPoint introVel;
@property (nonatomic,assign) float faceDir;
@end

@interface DuaSeatoArchetype : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemyParentDelegate,EnemySpawnedDelegate>

@end
