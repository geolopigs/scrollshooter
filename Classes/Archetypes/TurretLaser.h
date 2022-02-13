//
//  TurretLaser.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

extern const NSString* TLANIMKEY_IDLE;
extern const NSString* TLANIMKEY_FIRE;
extern const NSString* TLANIMKEY_DESTROYED;

@class BossWeapon;
@interface TurretLaserContext : NSObject<EnemyBehaviorContext>
{
    // runtime
    float idleTimer;
    float timeTillFire;
    unsigned int shotsFired;
    unsigned int hitCounts;
    int   fireSlot;
    float layerDistance;
    float rotateParamTarget;
    float rotateParam;
    float rotateSpeed;
    unsigned int behaviorState;
    BossWeapon* bossWeapon;
    float laserDir;
    
    // configs
    float idleDelay;
    float roundDelay;
    float shotDelay;
    float shotSpeed;
    unsigned int shotsPerRound;
    int initHealth;
    float angularSpeed;
    float angleA;   // turret fires within the range of angleA and angleB
    float angleB;
    NSDictionary* scatterBombContext;
    unsigned int _flags;
}
@property (nonatomic,assign) float idleTimer;
@property (nonatomic,assign) float  timeTillFire;
@property (nonatomic,assign) unsigned int shotsFired;
@property (nonatomic,assign) unsigned int hitCounts;
@property (nonatomic,assign) int    fireSlot;
@property (nonatomic,assign) float  layerDistance;
@property (nonatomic,assign) float  rotateParamTarget;
@property (nonatomic,assign) float  rotateParam;
@property (nonatomic,assign) float  rotateSpeed;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,retain) BossWeapon* bossWeapon;
@property (nonatomic,assign) float laserDir;

@property (nonatomic,assign) float idleDelay;
@property (nonatomic,assign) float roundDelay;
@property (nonatomic,assign) float shotDelay;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) unsigned int shotsPerRound;
@property (nonatomic,assign) int initHealth;
@property (nonatomic,assign) float angularSpeed;
@property (nonatomic,assign) float angleA;
@property (nonatomic,assign) float angleB;
@property (nonatomic,retain) NSDictionary* scatterBombContext;
- (void) setupRotationParamsForSrc:(float)srcAngle target:(float)tgtAngle;
- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface TurretLaser : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyAABBDelegate,EnemyKilledDelegate>
@property (nonatomic,retain) NSString* typeName;
@property (nonatomic,retain) NSString* sizeName;
@property (nonatomic,retain) NSDictionary* animStates;
- (id) initWithTypeName:(NSString*)typeName sizeName:(NSString*)sizeName animStates:(NSDictionary*)animStates;
@end
