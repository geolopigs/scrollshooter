//
//  PlayerMissile.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "PlayerMissile.h"
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
#import "Effect.h"
#import "EffectFactory.h"
#import "Loot.h"
#import "LootFactory.h"
#import "SoundManager.h"
#import "TopCam.h"
#import "BossWeapon.h"
#import "Shot.h"
#include "MathUtils.h"

enum PLAYERMISSILE_STATE
{
    PLAYERMISSILE_STATE_INIT = 0,
    PLAYERMISSILE_STATE_TARGET,
    PLAYERMISSILE_STATE_LAUNCH,
    
    PLAYERMISSILE_STATE_NUM
};

static const float MISSILETRAIL_OFFSET = 2.0f;
static const float MISSILETRAIL_PARTICLE_LIFESPAN = 0.35f;

static const float MISSILETRAIL_LAUNCHSCALE = 3.0f;     // this is how much to scale the y of the trail-particle by
                                                        // when the missile is at launching speed
static const float STRAIGHTMISSILE_TARGET_OFFSET_X_SCALE = 20.0f;

@implementation PlayerMissileContext
@synthesize initDir = _initDir;
@synthesize initSpeed = _initSpeed;
@synthesize initDelay = _initDelay;
@synthesize targettingSpeed = _targettingSpeed;
@synthesize launchSpeed = _launchSpeed;
@synthesize launchDelay = _launchDelay;
@synthesize angularSpeed = _angularSpeed;
@synthesize shotIndex = _shotIndex;
@synthesize target = _target;
@synthesize subType = _subType;

@synthesize targetPos = _targetPos;
@synthesize state = _state;
@synthesize dir = _dir;         // 0.0f is up
@synthesize timeTillTarget = _timeTillTarget;
@synthesize timeTillLaunch = _timeTillLaunch;
@synthesize rotationVel = _rotationVel;
@synthesize curSpeed = _curSpeed;

- (id) init
{
    self = [super init];
    if(self)
    {
        // default configs
        _initDir = M_PI_2;
        _initSpeed = 20.0f;
        _targettingSpeed = 60.0f;
        _launchSpeed = 120.0f;
        _launchDelay = 1.5f;
        _angularSpeed = 0.8f * M_PI;
        _initDelay = 0.5f;
        _shotIndex = 0;
        self.target = nil;
        _subType = MISSILE_SUBTYPE_HOMING;
        
        // init runtime
        _targetPos = CGPointMake(50.0f, 120.0f);
        _state = PLAYERMISSILE_STATE_INIT;
        _dir = _initDir;
        _timeTillLaunch = _launchDelay;
        _timeTillTarget = _initDelay;
        _rotationVel = _angularSpeed;
        _curSpeed = _targettingSpeed;
    }
    return self;
}

- (void) dealloc
{
    self.target = nil;
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
        _initDir = [self getFloatFromContext:triggerContext forVar:@"initDir" withDefault:_initDir];
        _initSpeed = [self getFloatFromContext:triggerContext forVar:@"initSpeed" withDefault:_initSpeed];
        _initDelay = [self getFloatFromContext:triggerContext forVar:@"initDelay" withDefault:_initDelay];
        _targettingSpeed = [self getFloatFromContext:triggerContext forVar:@"targettingSpeed" withDefault:_targettingSpeed];
        _launchSpeed = [self getFloatFromContext:triggerContext forVar:@"launchSpeed" withDefault:_launchSpeed];
        _launchDelay = [self getFloatFromContext:triggerContext forVar:@"launchDelay" withDefault:_launchDelay];
        _angularSpeed = [self getFloatFromContext:triggerContext forVar:@"angularSpeed" withDefault:_angularSpeed];
        _curSpeed = _targettingSpeed;
        
        NSString* subTypeString = [triggerContext objectForKey:@"subType"];
        if(subTypeString)
        {
            if([subTypeString isEqualToString:@"straight"])
            {
                _subType = MISSILE_SUBTYPE_STRAIGHT;
            }
        }
    }
}

@end

@implementation PlayerMissile
@synthesize animName = _animName;
@synthesize trailName = _trailName;
@synthesize typeName = _typeName;

- (id) initWithAnimNamed:(NSString *)name trailName:(NSString*)trail typeName:(NSString*)givenTypename
{
    self = [super init];
    if(self)
    {
        self.animName = name;
        self.trailName = trail;
        self.typeName = givenTypename;
    }
    return self;
}

- (void) dealloc
{
    self.typeName = nil;
    self.trailName = nil;
    self.animName = nil;
    [super dealloc];
}



#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:_typeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    if(_animName)
    {
        AnimClipData* clipData = [animData getClipForName:_animName];
        AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
        givenEnemy.animClip = newClip;
        [newClip release];
    }
    else
    {
        // if no anim specified, it's a ghost missile; so hide it
        givenEnemy.animClip = nil;
        givenEnemy.hidden = YES;
    }
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:_typeName];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // game status
    givenEnemy.health = 1;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:_trailName dir:0.0f speed:0.0f lifeSpan:MISSILETRAIL_PARTICLE_LIFESPAN hasDestructionEffect:NO isTrailAnim:YES];
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
        PlayerMissileContext* myContext = [givenEnemy behaviorContext];
        
        if([myContext state] == PLAYERMISSILE_STATE_INIT)
        {
            myContext.timeTillTarget -= elapsed;
            if([myContext timeTillTarget] <= 0.0f)
            {
                myContext.state = PLAYERMISSILE_STATE_TARGET;
                
                // go to TARGETing, change my velocity to match my facing dir
                givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext dir], [myContext targettingSpeed]); 
                myContext.curSpeed = [myContext targettingSpeed];
                CGPoint targetPos;
                Enemy* targetEnemy = [myContext target];
                if([myContext subType] == MISSILE_SUBTYPE_STRAIGHT)
                {
                    // for STRAIGHT missiles, target a point sufficiently far away in front of me
                    CGRect playArea = [[GameManager getInstance] getPlayArea];
                    targetPos.x = (STRAIGHTMISSILE_TARGET_OFFSET_X_SCALE * ([givenEnemy vel].x / [myContext targettingSpeed])) + [givenEnemy pos].x;
                    targetPos.y = playArea.origin.y + (playArea.size.height * 2.0f);
                }
                else if((targetEnemy) && (![targetEnemy incapacitated]))
                {
                    CGRect enemyAABB = [targetEnemy getAABB];
                    targetPos.x = enemyAABB.origin.x + (0.5f * enemyAABB.size.width);
                    targetPos.y = enemyAABB.origin.y + (0.5f * enemyAABB.size.height);
                }
                else
                {
                    CGRect playArea = [[GameManager getInstance] getPlayArea];
                    targetPos.x = givenEnemy.pos.x;
                    targetPos.y = playArea.origin.y + (playArea.size.height * 2.0f);
                }
                myContext.targetPos = targetPos;
                
                givenEnemy.readyToFire = YES;
            }
        }
        else if([myContext state] == PLAYERMISSILE_STATE_TARGET)
        {
            myContext.timeTillLaunch -= elapsed;
            
            CGPoint targetPos = [myContext targetPos];
            
            if(MISSILE_SUBTYPE_STRAIGHT == [myContext subType])
            {
                // if STRAIGHT missile, do not retarget, just keep going
            }
            else
            {
                // update target pos based on target enemy
                Enemy* targetEnemy = [myContext target];
                if(targetEnemy)
                {
                    if([targetEnemy incapacitated])
                    {
                        // if target has become incapacitated, launch right away
                        myContext.timeTillLaunch = 0.0f;
                        
                    }
                    
                    // regardless of whether target still alive, use it as targetPos
                    CGRect enemyAABB = [targetEnemy getAABB];
                    targetPos.x = enemyAABB.origin.x + (0.5f * enemyAABB.size.width);
                    targetPos.y = enemyAABB.origin.y + (0.5f * enemyAABB.size.height);
                }                
            }
            
            CGPoint myPos = [givenEnemy pos];
            CGPoint targetVec = CGPointMake(targetPos.x - myPos.x, targetPos.y - myPos.y);
            
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
            if((fabsf(diffNext) > fabsf(diffCur)) || ([myContext timeTillLaunch] <= 0.0f))
            {
                // target acquired, or targetting timer expired, launch it
                myContext.dir = targetRot;
                givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext dir], [myContext launchSpeed]); 
                myContext.curSpeed = [myContext launchSpeed];
                myContext.state = PLAYERMISSILE_STATE_LAUNCH;
            }
            else
            {
                myContext.dir = normalizeAngle(newDir);
                givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext dir], [myContext targettingSpeed]);
                myContext.curSpeed = [myContext targettingSpeed];
            }
            givenEnemy.rotate = [myContext dir];
        }
        
        float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
        float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
        
        // retire when I am out of screen
        {
            // self retire if  outside of playArea
            CGRect playArea = [[GameManager getInstance] getPlayArea];
            float buffer = 0.25f;
            CGPoint retireBl = CGPointMake((-buffer * playArea.size.width) + playArea.origin.x,
                                           (-buffer * playArea.size.height) + playArea.origin.y);
            CGPoint retireTr = CGPointMake(((1.0f + buffer) * playArea.size.width) + playArea.origin.x,
                                           ((1.0f + buffer) * playArea.size.height) + playArea.origin.y);
            if((newPosX < retireBl.x) || (newPosX > retireTr.x) ||
               (newPosY < retireBl.y) || (newPosY > retireTr.y))
            {
                givenEnemy.willRetire = YES;
            }
        }
        
        CGPoint trailPos = radiansToVector(CGPointMake(0.0f, -1.0f), [givenEnemy rotate], MISSILETRAIL_OFFSET);
        trailPos.x += [givenEnemy pos].x;
        trailPos.y += [givenEnemy pos].y;
        Shot* trailParticle = [givenEnemy fireFromPos:trailPos dir:[givenEnemy rotate] speed:0.0f];
        
        // scale length of trail-particle based on missile speed
        float scaleY = ([myContext curSpeed] - [myContext targettingSpeed]) * (MISSILETRAIL_LAUNCHSCALE) / ([myContext launchSpeed] - [myContext targettingSpeed]);
        scaleY += 2.5f;
        trailParticle.scale = CGPointMake(1.0f, scaleY);
        givenEnemy.pos = CGPointMake(newPosX, newPosY);
    }
    else
    {
        // incapacitated, retire when all trail particles have disappered
        if([givenEnemy.firingPath.shots count] == 0)
        {
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
    enemy.health = 0;
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
    PlayerMissileContext* myContext = [givenEnemy behaviorContext];
    
    // init my state
    myContext.state = PLAYERMISSILE_STATE_INIT;
    myContext.dir = [myContext initDir];
    myContext.timeTillLaunch = [myContext launchDelay];
    myContext.timeTillTarget = [myContext initDelay];
    myContext.rotationVel = [myContext angularSpeed];
    myContext.curSpeed = [myContext targettingSpeed];

    // setup my velocity
    givenEnemy.vel = radiansToVector(CGPointMake(0.0f, 1.0f), [myContext initDir], [myContext initSpeed]);
    givenEnemy.rotate = [myContext dir];
    
    // for STRAIGHT subtype, replace missile trail with blue trail
    /*
    if(MISSILE_SUBTYPE_STRAIGHT == [myContext subType])
    {
        // replace with blue trail
        FiringPath* newFiring = [FiringPath firingPathWithName:@"BlueTrail" dir:0.0f speed:0.0f lifeSpan:MISSILETRAIL_PARTICLE_LIFESPAN hasDestructionEffect:NO isTrailAnim:YES];
        newFiring.isFriendly = YES;             // set the friendly flag so that it does not hurt the player
        givenEnemy.firingPath = newFiring;
        [newFiring release];      
        
        // hide the missile itself
        givenEnemy.hidden = YES;
    }
     */
}



@end
