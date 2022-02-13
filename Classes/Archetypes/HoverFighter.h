//
//  HoverFighter.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class SineWeaver;
@interface HoverFighterContext : NSObject<EnemyBehaviorContext>
{
    // config params
    CGPoint introVel;
    CGPoint introDoneBotLeft;
    CGPoint introDoneTopRight;
    float introDelay;
    float shotSpeed;
    unsigned int numShotsPerRound;
    float shotDelay;
    float roundDelay;
    float hoverInterval;
    float hoverDelay;
    float hoverDelayStep;
    float angularSpeed;
    CGPoint exitVel;
    float targetAngle;
    SineWeaver* weaverX;
    SineWeaver* weaverY;
    int initHealth;
    unsigned int groundedBucket;
    unsigned int dynamicsBucket;
    float layerDistance;
    CGPoint groundedPos;
    unsigned int _flags;
    
    // runtime params
    float introTimer;
    float timeTillFire;
    unsigned int shotCount;
    float roundTimer;
    float hoverTimer;
    unsigned int behaviorState;
    float rotateParamTarget;
    float rotateParam;
    float rotateSpeed;
    float nextHoverParam;
    float cruisingTimer;
}
@property (nonatomic,assign) CGPoint introVel;
@property (nonatomic,assign) CGPoint introDoneBotLeft;
@property (nonatomic,assign) CGPoint introDoneTopRight;
@property (nonatomic,assign) float introDelay;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) unsigned int numShotsPerRound;
@property (nonatomic,assign) float shotDelay;
@property (nonatomic,assign) float roundDelay;
@property (nonatomic,assign) float hoverInterval;
@property (nonatomic,assign) float hoverDelay;
@property (nonatomic,assign) float hoverDelayStep;
@property (nonatomic,assign) float angularSpeed;
@property (nonatomic,assign) CGPoint exitVel;
@property (nonatomic,assign) float targetAngle;
@property (nonatomic,retain) SineWeaver* weaverX;
@property (nonatomic,retain) SineWeaver* weaverY;
@property (nonatomic,assign) int initHealth;
@property (nonatomic,assign) float timeout;
@property (nonatomic,assign) unsigned int groundedBucket;
@property (nonatomic,assign) unsigned int dynamicsBucket;
@property (nonatomic,assign) float layerDistance;
@property (nonatomic,assign) CGPoint groundedPos;

@property (nonatomic,assign) float introTimer;
@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,assign) unsigned int shotCount;
@property (nonatomic,assign) float roundTimer;
@property (nonatomic,assign) float hoverTimer;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) float  rotateParamTarget;
@property (nonatomic,assign) float  rotateParam;
@property (nonatomic,assign) float  rotateSpeed;
@property (nonatomic,assign) float  nextHoverParam;
@property (nonatomic,assign) float  cruisingTimer;

- (void) setupRotationParamsForSrc:(float)srcAngle target:(float)tgtAngle;
- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface HoverFighter : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemySpawnedDelegate>


@end
