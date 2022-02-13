//
//  Laser.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class BossWeapon;
@class Enemy;
@interface LaserContext : NSObject
{
    CGPoint _objectSizeScale;   // use this to create Laser instances of different sizes from the default GameObjSize
}
// config params
@property (nonatomic,assign) CGPoint objectSizeScale;
@property (nonatomic,assign) float initDir;
@property (nonatomic,assign) float initDur;
@property (nonatomic,assign) float onDur;
@property (nonatomic,assign) float offDur;
@property (nonatomic,retain) NSString* animName;
@property (nonatomic,retain) NSString* initAnimName;
@property (nonatomic,retain) NSString* offAnimName;

// runtime params
@property (nonatomic,assign) unsigned int state;
@property (nonatomic,assign) float timer;

- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface Laser : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemySpawnedDelegate,EnemyAABBDelegate>
{
    NSString* _animName;
    NSString* _typeName;
    BOOL _isPlayerWeapon;
}
@property (nonatomic,retain) NSString* animName;
@property (nonatomic,retain) NSString* typeName;

- (id) initWithAnimNamed:(NSString*)name typeName:(NSString*)nameOfType;
- (id) initAsPlayerWeaponWithAnimNamed:(NSString*)name typeName:(NSString*)nameOfType;

@end
