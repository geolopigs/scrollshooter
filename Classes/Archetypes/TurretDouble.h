//
//  TurretDouble.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class BossWeapon;
@interface TurretDoubleContext : NSObject<EnemyBehaviorContext>
{
    float timeTillFire;
    float idleTimer;
    unsigned int shotsFired;
    unsigned int hitCounts;
    float layerDistance;
    float rotateParamTarget;
    float rotateParam;
    float rotateVel;
    unsigned int behaviorState;
    unsigned int targetSlot;
    BossWeapon* bossWeapon;
    int initHealth;
    unsigned int _flags;
    
    // behavior knobs
    float idleDelay;
    float rotateSpeed;
    float shotDelay;
    float shotSpeed;
}
@property (nonatomic,assign) float  timeTillFire;
@property (nonatomic,assign) float  idleTimer;
@property (nonatomic,assign) unsigned int shotsFired;
@property (nonatomic,assign) unsigned int hitCounts;
@property (nonatomic,assign) float  layerDistance;
@property (nonatomic,assign) float  rotateParamTarget;
@property (nonatomic,assign) float  rotateParam;
@property (nonatomic,assign) float  rotateVel;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) unsigned int targetSlot;
@property (nonatomic,retain) BossWeapon* bossWeapon;
@property (nonatomic,assign) int initHealth;

@property (nonatomic,assign) float idleDelay;
@property (nonatomic,assign) float rotateSpeed;
@property (nonatomic,assign) float shotDelay;
@property (nonatomic,assign) float shotSpeed;

- (void) setupRotationParamsForSrc:(float)srcAngle target:(float)tgtAngle;
- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface TurretDouble : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyAABBDelegate,EnemyKilledDelegate>

@end
