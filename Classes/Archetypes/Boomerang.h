//
//  Boomerang.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface BoomerangContext : NSObject
{
    // config
    unsigned int _subType;
    float _forwardSpeed;
    float _backSpeed;
    float _radius;
    float _turnbackDur;
    
    // runtime
    float _timeTillFire;
    float _turnbackTimer;
}
// config params
@property (nonatomic,assign) float initDir;
@property (nonatomic,assign) float initSpeed;
@property (nonatomic,assign) float initDelay;
@property (nonatomic,assign) float targettingSpeed;
@property (nonatomic,assign) float angularSpeed;
@property (nonatomic,assign) float forwardSpeed;
@property (nonatomic,assign) float backSpeed;
@property (nonatomic,assign) float radius;
@property (nonatomic,assign) float turnbackDur;

// runtime params
@property (nonatomic,assign) unsigned int state;
@property (nonatomic,assign) float dir;
@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,assign) float rotationVel;
@property (nonatomic,assign) float curSpeed;
@property (nonatomic,assign) float turnbackTimer;

- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface Boomerang : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemySpawnedDelegate>
{
    NSString* animName;
}
@property (nonatomic,retain) NSString* animName;
- (id) initWithAnimNamed:(NSString*)name;
+ (void) incapacitateEnemy:(Enemy *)givenEnemy;

@end
