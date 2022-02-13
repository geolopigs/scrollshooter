//
//  Boomerang.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "Boomerang.h"
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
#import "Shot.h"
#include "MathUtils.h"

enum BOOMERANG_STATE
{
    BOOMERANG_STATE_INIT = 0,
    BOOMERANG_STATE_FORWARD,
    BOOMERANG_STATE_BACK,
    
    BOOMERANG_STATE_NUM
};

static NSString* const TYPENAME = @"Boomerang";
static const float MISSILETRAIL_OFFSET = 2.0f;
static const float MISSILETRAIL_PARTICLE_LIFESPAN = 0.25f;

static const float MISSILETRAIL_LAUNCHSCALE = 1.0f;     // this is how much to scale the y of the trail-particle by
                                                        // when the missile is at launching speed
static const float TRAIL_SCALEOFFSET = 2.0f;
static const float PLAYER_BOOMERANGRETURN_RADIUS = 5.0f;    // collision radius for collection of BOOMERANG_STATE_BACK boomerangs

@implementation BoomerangContext
@synthesize initDir = _initDir;
@synthesize initSpeed = _initSpeed;
@synthesize initDelay = _initDelay;
@synthesize targettingSpeed = _targettingSpeed;
@synthesize angularSpeed = _angularSpeed;
@synthesize forwardSpeed = _forwardSpeed;
@synthesize backSpeed = _backSpeed;
@synthesize radius = _radius;
@synthesize turnbackDur = _turnbackDur;

@synthesize state = _state;
@synthesize dir = _dir;         // 0.0f is up
@synthesize timeTillFire = _timeTillFire;
@synthesize rotationVel = _rotationVel;
@synthesize curSpeed = _curSpeed;
@synthesize turnbackTimer = _turnbackTimer;

- (id) init
{
    self = [super init];
    if(self)
    {
        // default configs
        _initDir = 0.0f;
        _initSpeed = 40.0f;
        _targettingSpeed = 60.0f;
        _angularSpeed = 1.6f;
        _initDelay = 0.2f;
        _forwardSpeed = 120.0f;
        _backSpeed = 120.0f;
        _radius = 50.0f;
        _turnbackDur = 1.5f;
        
        // init runtime
        _state = BOOMERANG_STATE_FORWARD;
        _dir = _initDir;
        _timeTillFire = _initDelay;
        _rotationVel = _angularSpeed;
        _curSpeed = _targettingSpeed;
        _turnbackTimer = _turnbackDur;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}


- (float) getFloatFromContext:(NSDictionary*)triggerContext forVar:(NSString*)varKey withDefault:(float)defaultValue
{
    float result = defaultValue;
    NSNumber* varNumber = [triggerContext objectForKey:varKey];
    if(varNumber)
    {
        result = [varNumber floatValue];
    }
    return result;
}

- (void) setupFromTriggerContext:(NSDictionary*)triggerContext
{
    if(triggerContext)
    {
        _initDir = [self getFloatFromContext:triggerContext forVar:@"initDir" withDefault:_initDir] * M_PI;
        _initSpeed = [self getFloatFromContext:triggerContext forVar:@"initSpeed" withDefault:_initSpeed];
        _targettingSpeed = [self getFloatFromContext:triggerContext forVar:@"targettingSpeed" withDefault:_targettingSpeed];
        _angularSpeed = [self getFloatFromContext:triggerContext forVar:@"angularSpeed" withDefault:_angularSpeed] * M_PI;
        _initDelay = [self getFloatFromContext:triggerContext forVar:@"initDelay" withDefault:_initDelay];
        _forwardSpeed = [self getFloatFromContext:triggerContext forVar:@"forwardSpeed" withDefault:_forwardSpeed];
        _backSpeed = [self getFloatFromContext:triggerContext forVar:@"backSpeed" withDefault:_backSpeed];
        _radius = [self getFloatFromContext:triggerContext forVar:@"radius" withDefault:_radius];
        _turnbackDur = [self getFloatFromContext:triggerContext forVar:@"turnbackDur" withDefault:_turnbackDur];
    }
}

@end

@implementation Boomerang
@synthesize animName;

- (id) initWithAnimNamed:(NSString *)name
{
    self = [super init];
    if(self)
    {
        self.animName = name;
    }
    return self;
}

- (void) dealloc
{
    self.animName = nil;
    [super dealloc];
}



#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    NSString* typeName = TYPENAME;
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:typeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    AnimClipData* clipData = [animData getClipForName:animName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenEnemy.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:typeName];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // game status
    givenEnemy.health = 1;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"BoomerangTrail" dir:0.0f speed:0.0f lifeSpan:MISSILETRAIL_PARTICLE_LIFESPAN hasDestructionEffect:NO isTrailAnim:YES];
    newFiring.isFriendly = YES;             // set the friendly flag so that it does not hurt the player
    givenEnemy.firingPath = newFiring;
    [newFiring release];

    // do not remove bullets when incapacitated because firingPath emits the trail
    givenEnemy.removeBulletsWhenIncapacitated = NO;
    
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
    if(![givenEnemy incapacitated])
    {
        BoomerangContext* myContext = [givenEnemy behaviorContext];
        
        float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
        float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
        if([myContext state] == BOOMERANG_STATE_INIT)
        {
            myContext.timeTillFire -= elapsed;
            if([myContext timeTillFire] <= 0.0f)
            {
                myContext.state = BOOMERANG_STATE_FORWARD;
                givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext dir], [myContext forwardSpeed]); 
                myContext.curSpeed = [myContext forwardSpeed];                
                givenEnemy.readyToFire = YES;
                myContext.timeTillFire = [myContext initDelay];
            }
        }
        else if([myContext state] == BOOMERANG_STATE_FORWARD)
        {
            CGPoint playerPos = [[[GameManager getInstance] playerShip] pos];
            float distFromPlayer = Distance([givenEnemy pos], playerPos);
            
            if(distFromPlayer >= [myContext radius])
            {
                myContext.state = BOOMERANG_STATE_BACK;
                givenEnemy.vel = CGPointMake(0.0f, 0.0f);
            }
        }
        else if([myContext state] == BOOMERANG_STATE_BACK)
        {
            CGPoint playerPos = [[[GameManager getInstance] playerShip] pos];
            CGPoint newPos = CGPointMake(newPosX, newPosY);
            CGPoint vecToPlayer = CGPointSubtract(playerPos, newPos);
            CGPoint targetVec = CGPointNormalize(vecToPlayer);
            
            float targetRot = vectorToRadians(targetVec, M_PI_2); 
            float diffCur = SmallerAngleDiff([myContext dir], targetRot);
            if(diffCur < 0.0f)
            {
                myContext.rotationVel = -[myContext angularSpeed];
            }
            else
            {
                myContext.rotationVel = [myContext angularSpeed];
            }
            float newDir = [myContext dir] + (elapsed * [myContext rotationVel]);
            float diffNext = SmallerAngleDiff(newDir, targetRot);
            myContext.turnbackTimer -= elapsed;
            if((fabsf(diffNext) > fabsf(diffCur)) || ([myContext turnbackTimer] <= 0.0f))
            {
                // target acquired, or targetting timer expired, launch it
                myContext.dir = targetRot;
                givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext dir], [myContext backSpeed]); 
                myContext.curSpeed = [myContext backSpeed];
            }
            else
            {
                myContext.dir = normalizeAngle(newDir);
                givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext dir], [myContext targettingSpeed]);
                myContext.curSpeed = [myContext targettingSpeed];
            }
            givenEnemy.rotate = [myContext dir];
        }
        
        CGPoint trailPos = radiansToVector(CGPointMake(0.0f, -1.0f), [givenEnemy rotate], MISSILETRAIL_OFFSET);
        trailPos.x += [givenEnemy pos].x;
        trailPos.y += [givenEnemy pos].y;
        Shot* trailParticle = [givenEnemy fireFromPos:trailPos dir:[givenEnemy rotate] speed:0.0f];
        
        // scale length of trail-particle based on missile speed
        float scaleY = ([myContext curSpeed] - [myContext targettingSpeed]) * (MISSILETRAIL_LAUNCHSCALE) / ([myContext backSpeed] - [myContext targettingSpeed]);
        scaleY += TRAIL_SCALEOFFSET;
        trailParticle.scale = CGPointMake(1.0f, scaleY);
        givenEnemy.pos = CGPointMake(newPosX, newPosY);
        
        // incap and kill myself when I'm back to the player
        if([myContext state] == BOOMERANG_STATE_BACK)
        {
            CGPoint playerPos = [[[GameManager getInstance] playerShip] pos];
            float distFromPlayer = Distance([givenEnemy pos], playerPos);
            if(distFromPlayer <= PLAYER_BOOMERANGRETURN_RADIUS)
            {
                // incap if I hit something on my way back and I'm close to the player
                // being close to the player is good enough, there's no way to find out who we hit here
                // also, incap without points here
                givenEnemy.health = 0;
                [givenEnemy incapThenKillWithPoints:NO];
            }
        }
    }
    else
    {
        // incapacitated, retire when all trail particles have disappeared
        if([givenEnemy.firingPath.shots count] == 0)
        {
            givenEnemy.willRetire = YES;
        }
    }
}

- (NSString*) getEnemyTypeName
{
    return TYPENAME;
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
    return YES;
}

- (BOOL) isPlayerCollidable
{
    return NO;
}

- (BOOL) isCollidable
{
    return NO;
}

- (BOOL) isCollisionOnFor:(Enemy *)enemy
{
    return YES;
}


#pragma mark - called by BossWeapon to incapacitate missile
+ (void) incapacitateEnemy:(Enemy *)givenEnemy
{
    // play Explosion and hide but don't kill yet because the trail needs to finish
    [EffectFactory effectNamed:@"MissileHit" atPos:givenEnemy.pos];
    
    // play sound
    [[SoundManager getInstance] playClip:@"MissileExplodes"];
    
    givenEnemy.hidden = YES;
}

#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    BoomerangContext* myContext = [givenEnemy behaviorContext];
    
    // init my state
    myContext.state = BOOMERANG_STATE_INIT;
    
    // initDir is set by BossWeapon prior to spawning this boomerang
    myContext.dir = [myContext initDir];
    myContext.timeTillFire = [myContext initDelay];
    myContext.rotationVel = [myContext angularSpeed];
    myContext.curSpeed = [myContext targettingSpeed];
    myContext.turnbackTimer = [myContext turnbackDur];

    // setup my velocity
    givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext initDir], [myContext initSpeed]);
    givenEnemy.rotate = [myContext dir];
    
}



@end
