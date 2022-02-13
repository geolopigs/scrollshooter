//
//  BoarSolo.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

enum BoarSoloBehaviorState 
{
    BOARSOLO_BEHAVIORSTATE_INIT = 0,
    BOARSOLO_BEHAVIORSTATE_IDLE,
    BOARSOLO_BEHAVIORSTATE_TARGETING,
    BOARSOLO_BEHAVIORSTATE_FIRING,
    BOARSOLO_BEHAVIORSTATE_DESTROYED,
    
    BOARSOLO_BEHAVIORSTATE_NUM
};

enum BOARSOLO_ANIMTYPES
{
    BOARSOLO_ANIMTYPE_GUN = 0,
    BOARSOLO_ANIMTYPE_GROUND,
    BOARSOLO_ANIMTYPE_HELMET,
    BOARSOLO_ANIMTYPE_HELMET2,
    
    BOARSOLO_ANIMTYPE_NUM
};


extern NSString* const BOARSOLO_IDLENAME_GUN;
extern NSString* const BOARSOLO_IDLENAME_GROUND;
extern NSString* const BOARSOLO_IDLENAME_HELMET;
extern NSString* const BOARSOLO_IDLENAME_HELMET2;
extern NSString* const BOARSOLO_FIRENAME_GUN;
extern NSString* const BOARSOLO_FIRENAME_GROUND;
extern NSString* const BOARSOLO_FIRENAME_HELMET;
extern NSString* const BOARSOLO_FIRENAME_HELMET2;

@class BossWeapon;
@class Addon;
@interface BoarSoloContext : NSObject<EnemyBehaviorContext>
{
    // configs
    float idleDelay;
    float shotDelay;
    float shotSpeed;
    unsigned int shotsPerRound;
    int initHealth;
    float angularSpeed;
    BOOL hidden;
    unsigned int _flags;
    
    // runtime
    float idleTimer;
    float timeTillFire;
    unsigned int hitCounts;
    float layerDistance;
    float rotateParamTarget;
    float rotateParam;
    float rotateSpeed;
    unsigned int behaviorState;
    BOOL hasCargo;
    BossWeapon* bossWeapon;
    unsigned int shotCount;
    Addon* _gunAddon;
}
@property (nonatomic,assign) float idleDelay;
@property (nonatomic,assign) float shotDelay;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) unsigned int shotsPerRound;
@property (nonatomic,assign) int initHealth;
@property (nonatomic,assign) float angularSpeed;
@property (nonatomic,assign) BOOL hidden;

@property (nonatomic,assign) float idleTimer;
@property (nonatomic,assign) float  timeTillFire;
@property (nonatomic,assign) unsigned int hitCounts;
@property (nonatomic,assign) float  layerDistance;
@property (nonatomic,assign) float  rotateParamTarget;
@property (nonatomic,assign) float  rotateParam;
@property (nonatomic,assign) float  rotateSpeed;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) BOOL hasCargo;
@property (nonatomic,retain) BossWeapon* bossWeapon;
@property (nonatomic,assign) unsigned int shotCount;
@property (nonatomic,retain) Addon* gunAddon;
- (void) setupRotationParamsForSrc:(float)srcAngle target:(float)tgtAngle;
- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface BoarSolo : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyAABBDelegate,EnemyKilledDelegate>
+ (void) enemy:(Enemy*)givenEnemy replaceAnimWithType:(unsigned int)newAnimType;
+ (unsigned int) animTypeFromName:(NSString*)name;
+ (void) enemy:(Enemy*)givenEnemy createGunAddonInBucket:(unsigned int)bucketIndex;
@end
