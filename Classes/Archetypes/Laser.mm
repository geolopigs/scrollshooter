//
//  Laser.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "Laser.h"
#import "DynamicsSpawner.h"
#import "GameObjectSizes.h"
#import "Sprite.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "AnimClip.h"
#import "FiringPath.h"
#import "GameManager.h"
#import "Player.h"
#import "Effect.h"
#import "EffectFactory.h"
#import "Loot.h"
#import "LootFactory.h"
#import "SoundManager.h"
#import "TopCam.h"
#import "BossWeapon.h"
#import "NSDictionary+Curry.h"
#include "MathUtils.h"

enum LASER_STATE
{
    LASER_STATE_INIT = 0,
    LASER_STATE_ON,
    LASER_STATE_OFF,
    LASER_STATE_RETIRING,
    
    LASER_STATE_NUM
};

static const NSString* ANIMKEY_INIT = @"init";
static const NSString* ANIMKEY_ON = @"on";
static const NSString* ANIMKEY_OFF = @"off";

@implementation LaserContext
@synthesize objectSizeScale = _objectSizeScale;
@synthesize initDir = _initDir;
@synthesize initDur = _initDur;
@synthesize onDur = _onDur;
@synthesize offDur = _offDur;
@synthesize animName = _animName;
@synthesize initAnimName = _initAnimName;
@synthesize offAnimName = _offAnimName;

@synthesize state = _state;
@synthesize timer = _timer;

- (id) init
{
    self = [super init];
    if(self)
    {
        // default configs
        _objectSizeScale = CGPointMake(1.0f, 1.0f);
        _initDir = M_PI;
        _initDur = 1.0f;
        _onDur = 5.0f;
        _offDur = 1.0f;
        self.animName = @"YellowLaser";
        self.initAnimName = @"YellowLaserInit";
        self.offAnimName = @"YellowLaserGone";
        
        // init runtime
        _state = LASER_STATE_INIT;
        _timer = _initDur;
    }
    return self;
}

- (void) dealloc
{
    self.offAnimName = nil;
    self.initAnimName = nil;
    self.animName = nil;
    [super dealloc];
}


- (void) setupFromTriggerContext:(NSDictionary*)triggerContext
{
    if(triggerContext)
    {
        _initDir = [triggerContext getFloatForKey:@"initDir" withDefault:_initDir] * M_PI;
        _initDur = [triggerContext getFloatForKey:@"initDur" withDefault:_initDur];
        _onDur = [triggerContext getFloatForKey:@"onDur" withDefault:_onDur];
        _offDur = [triggerContext getFloatForKey:@"offDur" withDefault:_offDur];
        float objScaleX = [triggerContext getFloatForKey:@"objScaleX" withDefault:1.0f];
        float objScaleY = [triggerContext getFloatForKey:@"objScaleY" withDefault:1.0f];
        _objectSizeScale = CGPointMake(objScaleX, objScaleY);
        self.animName = [triggerContext objectForKey:@"animName"];
        self.initAnimName = [triggerContext objectForKey:@"initAnimName"];
        self.offAnimName = [triggerContext objectForKey:@"offAnimName"];
    }
}

@end

@implementation Laser
@synthesize animName = _animName;
@synthesize typeName = _typeName;

- (id) initWithAnimNamed:(NSString *)name typeName:(NSString *)nameOfType
{
    self = [super init];
    if(self)
    {
        self.animName = name;
        self.typeName = nameOfType;
        _isPlayerWeapon = NO;
    }
    return self;
}

- (id) initAsPlayerWeaponWithAnimNamed:(NSString *)name typeName:(NSString *)nameOfType
{
    self = [super init];
    if(self)
    {
        self.animName = name;
        self.typeName = nameOfType;
        _isPlayerWeapon = YES;
    }
    return self;
}

- (void) dealloc
{
    self.typeName = nil;
    self.animName = nil;
    [super dealloc];
}



#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // game status
    givenEnemy.health = 1;
    
    // firing params
    givenEnemy.firingPath = nil;

    // install spawned delegate
    givenEnemy.spawnedDelegate = self;  
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(NSObject<EnemySpawnerContextDelegate>*)givenSpawnerContext
{
    // do nothing
}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    LaserContext* myContext = [givenEnemy behaviorContext];
    
    if([myContext state] == LASER_STATE_INIT)
    {
        myContext.timer -= elapsed;
        if([myContext timer] <= 0.0f)
        {
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_ON];
            [givenEnemy.curAnimClip playClipForward:YES];
            myContext.state = LASER_STATE_ON;
            myContext.timer = [myContext onDur];
        }
    }
    else if([myContext state] == LASER_STATE_ON)
    {
        myContext.timer -= elapsed;
        if([myContext timer] <= 0.0f)
        {
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_OFF];
            [givenEnemy.curAnimClip playClipForward:YES];
            myContext.state = LASER_STATE_OFF;
            myContext.timer = [myContext offDur];
        }
    }
    else if([myContext state] == LASER_STATE_OFF)
    {
        myContext.timer -= elapsed;
        if([myContext timer] <= 0.0f)
        {
            // retire
            myContext.state = LASER_STATE_RETIRING;
            givenEnemy.willRetire = YES;
        }
    }
}

- (NSString*) getEnemyTypeName
{
    return _typeName;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    // do nothing
}


#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    // do nothing
}

- (BOOL) isPlayerWeapon
{
    return _isPlayerWeapon;
}

- (BOOL) isPlayerCollidable
{
    return (!_isPlayerWeapon);
}

- (BOOL) isCollidable
{
    return YES;
}

- (BOOL) isCollisionOnFor:(Enemy *)enemy
{
    LaserContext* myContext = [enemy behaviorContext];
    return ([myContext state] == LASER_STATE_ON);
}

#pragma mark - EnemyAABBDelegate
- (CGRect) getAABB:(Enemy *)givenEnemy
{
    const float epsilon = 0.001f;
    float width = givenEnemy.colAABB.size.width;
    float height = givenEnemy.colAABB.size.height;
    float halfWidth = width * 0.5f;
    CGPoint myWorldPos = [Enemy derivePosFromParentForEnemy:givenEnemy];
    
    CGRect result; 
    if(fabsf([givenEnemy rotate] - M_PI_2) < epsilon)
    {
        // shooting right
        result = CGRectMake(myWorldPos.x, myWorldPos.y - halfWidth, height, width);
    }
    else if(fabsf([givenEnemy rotate] - M_PI) < epsilon)
    {
        // shooting up
        result = CGRectMake(myWorldPos.x - halfWidth, myWorldPos.y, width, height);
    }
    else if(fabsf([givenEnemy rotate] - (3.0f * M_PI_2)) < epsilon)
    {
        // shooting left
        result = CGRectMake(myWorldPos.x - height, myWorldPos.y - halfWidth, height, width);
    }
    else
    {
        // default is shooting down
        result = CGRectMake(myWorldPos.x - halfWidth, myWorldPos.y - height, width, height);
    }
    return result;  
}



#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    LaserContext* myContext = [givenEnemy behaviorContext];
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:[myContext animName]];
    mySize.width *= [myContext objectSizeScale].x;
    mySize.height *= [myContext objectSizeScale].y;
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];

    // init the anim registry
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    AnimClipData* clipData = [animData getClipForName:[myContext animName]];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_ON];
    [newClip release];
    
    clipData = [animData getClipForName:[myContext initAnimName]];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_INIT];
    [newClip release];

    clipData = [animData getClipForName:[myContext offAnimName]];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_OFF];
    [newClip release];

    // init animclip to idle
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_INIT];
    [givenEnemy.curAnimClip playClipForward:YES];

    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:[myContext animName]];
    colSize.width *= [myContext objectSizeScale].x;
    colSize.height *= [myContext objectSizeScale].y;
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    givenEnemy.collisionAABBDelegate = self;

    // init my state
    myContext.state = LASER_STATE_INIT;
    myContext.timer = [myContext initDur];
    
    givenEnemy.rotate = [myContext initDir];
    
    // model transform (offset position so that the beginning of the laserbeam line up with its position)
    givenEnemy.modelTranslate = CGPointMake(0.0f, -0.5f * mySize.height);
}



@end
