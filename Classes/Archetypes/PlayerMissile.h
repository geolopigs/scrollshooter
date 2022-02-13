//
//  PlayerMissile.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

enum MissileSubtypes
{
    MISSILE_SUBTYPE_HOMING = 0,
    MISSILE_SUBTYPE_STRAIGHT,
    
    MISSILE_SUBTYPE_NUM
};

@class BossWeapon;
@class Enemy;
@interface PlayerMissileContext : NSObject
{
    // config
    unsigned int _subType;
    
}
// config params
@property (nonatomic,assign) float initDir;
@property (nonatomic,assign) float initSpeed;
@property (nonatomic,assign) float initDelay;
@property (nonatomic,assign) float targettingSpeed;
@property (nonatomic,assign) float launchSpeed;
@property (nonatomic,assign) float launchDelay;
@property (nonatomic,assign) float angularSpeed;
@property (nonatomic,assign) unsigned int shotIndex;
@property (nonatomic,retain) Enemy* target;
@property (nonatomic,assign) unsigned int subType;

// runtime params
@property (nonatomic,assign) unsigned int state;
@property (nonatomic,assign) float dir;
@property (nonatomic,assign) float timeTillTarget;
@property (nonatomic,assign) float timeTillLaunch;
@property (nonatomic,assign) CGPoint targetPos;
@property (nonatomic,assign) float rotationVel;
@property (nonatomic,assign) float curSpeed;

- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface PlayerMissile : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemySpawnedDelegate>
{
    NSString* _animName;
    NSString* _trailName;
    NSString* _typeName;
}
@property (nonatomic,retain) NSString* animName;
@property (nonatomic,retain) NSString* trailName;
@property (nonatomic,retain) NSString* typeName;
- (id) initWithAnimNamed:(NSString *)name trailName:(NSString*)trail typeName:(NSString*)givenTypename;
+ (void) incapacitateEnemy:(Enemy *)givenEnemy;

@end
