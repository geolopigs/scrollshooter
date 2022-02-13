//
//  BoarSpeedo.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/6/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class AddonData;
@class Addon;
@interface BoarSpeedoContext : NSObject<EnemyBehaviorContext>
{
    float layerDistance;
    
    NSMutableArray* attachedEnemies;
    
    // timer
    float cruisingTimeout;  // params
    float cruisingTimer;    // runtime data
    NSString* enemyTriggerName;
    
    // movement behavior
    CGPoint initPos;
    float weaveVel;
    float weaveParam;
    float weaveRange;
    float weaveYVel;
    float weaveYParam;
    float weaveYRange;
    CGPoint introDoneBotLeft;
    CGPoint introDoneTopRight;
    CGPoint initVel;
    BOOL hasSetInitVel;         // for backward compatibility
                                // TODO: change initVel to all initialize from introDir and introSpeed so that
                                // this BOOL can be removed
    
    unsigned int dynamicsShadowsIndex;
    unsigned int dynamicsBucketIndex;
    unsigned int dynamicsAddonsIndex;
    unsigned int behaviorState;
    unsigned int behaviorCategory;
    
    // weapon params
    float timeBetweenShots; // 1 / shot-frequency
    float shotSpeed;
    float timeToCool;
    float timeToOverheat;
    
    // weapon runtime data
    float timeTillFire;
    unsigned int fireSlot;  // for scatter gun
    float overHeatTimer;
    
    
    // internal flags
    BOOL isDynamic;     // internal flag whether or not this BoarSpeedo has been prespawned into the Dynamics layer (set once)
    BOOL wakeStarted;
    NSMutableDictionary* behaviorCategoryReg; 
    NSDictionary* boarSpec;
    unsigned int _flags;
}
@property (nonatomic,assign) float  layerDistance;
@property (nonatomic,retain) NSMutableArray* attachedEnemies;
@property (nonatomic,assign) float cruisingTimeout;
@property (nonatomic,assign) float cruisingTimer;
@property (nonatomic,retain) NSString* enemyTriggerName;
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float weaveVel;
@property (nonatomic,assign) float weaveParam;
@property (nonatomic,assign) float weaveRange;
@property (nonatomic,assign) float weaveYVel;
@property (nonatomic,assign) float weaveYParam;
@property (nonatomic,assign) float weaveYRange;
@property (nonatomic,assign) CGPoint introDoneBotLeft;
@property (nonatomic,assign) CGPoint introDoneTopRight;
@property (nonatomic,assign) CGPoint initVel;
@property (nonatomic,assign) BOOL hasSetInitVel;
@property (nonatomic,assign) unsigned int dynamicsShadowsIndex;
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) unsigned int behaviorCategory;
@property (nonatomic,assign) float timeBetweenShots;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) float timeToCool;
@property (nonatomic,assign) float timeToOverheat;
@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,assign) unsigned int fireSlot;
@property (nonatomic,assign) float overHeatTimer;
@property (nonatomic,assign) BOOL isDynamic;
@property (nonatomic,assign) BOOL wakeStarted;
@property (nonatomic,retain) NSMutableDictionary* behaviorCategoryReg;
@property (nonatomic,retain) NSDictionary* boarSpec;
@property (nonatomic,assign) int initHealth;

// preIntro
@property (nonatomic,assign) CGPoint preIntroVel;
@property (nonatomic,assign) CGPoint preIntroBl;
@property (nonatomic,assign) CGPoint preIntroTr;
@property (nonatomic,assign) BOOL hasPreIntro;



- (unsigned int) behaviorCategoryFromName:(NSString *)name;

@end

@interface BoarSpeedo : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemyParentDelegate,EnemySpawnedDelegate>
{
}
@end
