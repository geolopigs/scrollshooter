//
//  TurretLaser.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TurretLaser.h"
#import "Sprite.h"
#import "Enemy.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "EffectFactory.h"
#import "FiringPath.h"
#import "LevelManager.h"
#import "SoundManager.h"
#import "Level.h"
#import "TopCam.h"
#import "TurretSpawner.h"
#import "GameObjectSizes.h"
#import "GameManager.h"
#import "Loot.h"
#import "LootFactory.h"
#import "BossWeapon.h"
#include "MathUtils.h"

enum BehaviorStates 
{
    BEHAVIORSTATE_INIT = 0,
    BEHAVIORSTATE_WARMUP,
    BEHAVIORSTATE_ACTIVE,
    BEHAVIORSTATE_IDLE,
    BEHAVIORSTATE_DESTROYED,
    
    BEHAVIORSTATE_NUM
};


static const float SHOT_OFFSETY = 9.0f;
static const float FIREANIM_LENGTH = 0.17f;

static const unsigned int NUM_HITS_PER_RESPONSE = 2;    // number of hits this guy takes before reacting with an anim

const NSString* TLANIMKEY_IDLE = @"idle";
const NSString* TLANIMKEY_FIRE = @"fire";
const NSString* TLANIMKEY_DESTROYED = @"dta";

@implementation TurretLaserContext
@synthesize idleTimer;
@synthesize timeTillFire;
@synthesize shotsFired;
@synthesize hitCounts;
@synthesize fireSlot;
@synthesize layerDistance;
@synthesize rotateParamTarget;
@synthesize rotateParam;
@synthesize rotateSpeed;
@synthesize behaviorState;
@synthesize bossWeapon;
@synthesize laserDir;

@synthesize idleDelay;
@synthesize roundDelay;
@synthesize shotDelay;
@synthesize shotSpeed;
@synthesize shotsPerRound;
@synthesize initHealth;
@synthesize angularSpeed;
@synthesize angleA;
@synthesize angleB;
@synthesize scatterBombContext;

- (id) init
{
    self = [super init];
    if(self)
    {
        // runtime
        hitCounts = 0;
        rotateParamTarget = 0.0f;
        rotateParam = 0.0f;
        rotateSpeed = 0.0f;
        behaviorState = BEHAVIORSTATE_INIT;
        idleTimer = 0.0f;
        timeTillFire = 0.0f;
        shotsFired = 0;
        fireSlot = 0;
        self.bossWeapon = nil;
        laserDir = 0.0f;
        
        // default configs
        idleDelay = 0.75f;
        roundDelay = 0.75f;
        shotDelay = 0.05f;
        shotsPerRound = 1;
        initHealth = 15;
        angularSpeed = 0.45f * M_PI;
        shotSpeed = 50.0f;
        angleA = normalizeAngle(-0.35f * M_PI);
        angleB = normalizeAngle(0.35f * M_PI);
        self.scatterBombContext = nil;
        _flags = 0;
    }
    return self;
}

- (void) dealloc
{
    self.scatterBombContext = nil;
    self.bossWeapon = nil;
    [super dealloc];
}

- (void) setupRotationParamsForSrc:(float)srcAngle target:(float)tgtAngle
{
    rotateParam = 0.0f;
    float diffPositive = 0.0f;
    float diffNegative = 0.0f;
    if(srcAngle < tgtAngle)
    {
        diffPositive = tgtAngle - srcAngle;
        diffNegative = (2.0f * M_PI) - tgtAngle + srcAngle;
    }
    else
    {
        diffPositive = (2.0f * M_PI) - srcAngle + tgtAngle;
        diffNegative = srcAngle - tgtAngle;
    }
    
    if(diffPositive < diffNegative)
    {
        // rotate in the positive direction
        rotateSpeed = angularSpeed;
        rotateParamTarget = diffPositive / angularSpeed;
    }
    else
    {
        // rotate in the negative direction
        rotateSpeed = -angularSpeed;
        rotateParamTarget = diffNegative / angularSpeed;
    }
}

- (void) setupFromTriggerContext:(NSDictionary *)triggerContext
{
    if(triggerContext)
    {
        self.idleDelay = [[triggerContext objectForKey:@"idleDelay"] floatValue];
        self.roundDelay = [[triggerContext objectForKey:@"roundDelay"] floatValue];
        self.shotDelay = [[triggerContext objectForKey:@"shotDelay"] floatValue];
        self.shotSpeed = [[triggerContext objectForKey:@"shotSpeed"] floatValue];
        self.shotsPerRound = [[triggerContext objectForKey:@"shotsPerRound"] unsignedIntValue];
        self.initHealth = [[triggerContext objectForKey:@"health"] intValue];
        self.angularSpeed = [[triggerContext objectForKey:@"angularSpeed"] floatValue] * M_PI;
        self.angleA = normalizeAngle([[triggerContext objectForKey:@"angleA"] floatValue] * M_PI);
        self.angleB = normalizeAngle([[triggerContext objectForKey:@"angleB"] floatValue] * M_PI);
        // setup scatter bomb if config has it
        NSDictionary* scatterBomb = [triggerContext objectForKey:@"scatterBomb"];
        if(scatterBomb)
        {
            self.scatterBombContext = scatterBomb;
        }
        
        NSDictionary* bossWeaponConfig = [triggerContext objectForKey:@"bossWeapon"];
        if(bossWeaponConfig)
        {
            BossWeapon* newWeapon = [[BossWeapon alloc] initFromConfig:bossWeaponConfig];
            self.bossWeapon = newWeapon;
            [newWeapon release];
        }
    }
}


#pragma mark - EnemyBehaviorContext

- (void) setupFromConfig:(NSDictionary *)config
{
    [self setupFromTriggerContext:config];
}

- (int) getInitHealth
{
    return [self initHealth];
}

- (unsigned int) getFlags
{
    return _flags;
}

- (void) setFlags:(unsigned int)newFlags
{
    _flags = newFlags;
}

@end

@interface TurretLaser (PrivateMethods)
- (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy;
@end

@implementation TurretLaser
@synthesize typeName = _typeName;
@synthesize sizeName = _sizeName;
@synthesize animStates = _animStates;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.typeName = @"TurretLaser";
        self.sizeName = @"TurretLaser";
        self.animStates = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                               @"TurretLaserIdle",
                                                               @"TurretLaserActive",
                                                               @"TurretLaserDestroyed",
                                                               nil]
                                                      forKeys:[NSArray arrayWithObjects:
                                                               TLANIMKEY_IDLE,
                                                               TLANIMKEY_FIRE,
                                                               TLANIMKEY_DESTROYED,
                                                               nil]];
    }
    return self;
}

- (id) initWithTypeName:(NSString*)typeName sizeName:(NSString*)sizeName animStates:(NSDictionary*)animStates
{
    self = [super init];
    if(self)
    {
        self.typeName = typeName;
        self.sizeName = sizeName;
        self.animStates = animStates;
    }
    return self;
}

- (void) dealloc
{
    self.animStates = nil;
    self.sizeName = nil;
    self.typeName = nil;
    [super dealloc];
}

#pragma mark - Private Methods
- (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy
{
    CGPoint myPos = [givenEnemy pos];
    if([givenEnemy parentEnemy])
    {
        Enemy* parentEnemy = [givenEnemy parentEnemy];
        CGPoint parentPos = [parentEnemy pos];
        CGAffineTransform t = CGAffineTransformMakeRotation([parentEnemy rotate]);
        CGPoint offset = CGPointApplyAffineTransform(myPos, t);
        
        myPos.x = offset.x + parentPos.x;
        myPos.y = offset.y + parentPos.y;
    }
    return myPos;
}

- (CGPoint) deriveCamPosFromParentForEnemy:(Enemy*)givenEnemy
{
    TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
    CGPoint myWorldPos = [self derivePosFromParentForEnemy:givenEnemy];
    CGPoint myPos = [gameCam camPointFromWorldPoint:myWorldPos atDistance:[[givenEnemy behaviorContext] layerDistance]];
    return myPos;
}

#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:_sizeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    // anim
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    for(NSString* curAnimState in _animStates)
    {
        NSString* curAnimName = [_animStates objectForKey:curAnimState];
        AnimClipData* clipData = [animData getClipForName:curAnimName];
        AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
        [givenEnemy.animClipRegistry setObject:newClip forKey:curAnimState];
        [newClip release];
    }
    
    // init animclip to idle
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TLANIMKEY_IDLE];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:_sizeName];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    givenEnemy.collisionAABBDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = 10;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(NSObject<EnemySpawnerContextDelegate>*)spawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    
    // init its context given the spawner's context
    TurretLaserContext* newContext = [[TurretLaserContext alloc] init];
    if(spawnerContext)
    {
        NSDictionary* triggerContext = [spawnerContext spawnerTriggerContext];
        if(triggerContext)
        {
            [newContext setupFromTriggerContext:triggerContext];
        }    
        newContext.layerDistance = [spawnerContext spawnerLayerDistance];
    }
    givenEnemy.behaviorContext = newContext;
    givenEnemy.health = [newContext initHealth];
    [newContext release];

}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    TurretLaserContext* myContext = [givenEnemy behaviorContext];
    
    // special case for one-time init
    if(BEHAVIORSTATE_INIT == myContext.behaviorState)
    {
        givenEnemy.health = [myContext initHealth];
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TLANIMKEY_IDLE];
        [givenEnemy.curAnimClip playClipForward:YES];
        myContext.behaviorState = BEHAVIORSTATE_WARMUP;
        myContext.idleTimer = [myContext idleDelay];
    }
    
    // regular state processing
    if(BEHAVIORSTATE_WARMUP == [myContext behaviorState])
    {
        myContext.idleTimer -= elapsed;
        if([myContext idleTimer] <= 0.0f)
        {
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TLANIMKEY_FIRE];
            [givenEnemy.curAnimClip playClipForward:YES];
            myContext.behaviorState = BEHAVIORSTATE_ACTIVE;
        }
    }
    else if(BEHAVIORSTATE_ACTIVE == [myContext behaviorState])
    {
        BossWeapon* laserWeapon = [myContext bossWeapon];
        [laserWeapon enemyFire:givenEnemy fromPos:[givenEnemy pos] elapsed:elapsed];
        if([[laserWeapon activeComponents] count] == 0)
        {
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TLANIMKEY_IDLE];
            [givenEnemy.curAnimClip playClipForward:YES];
            myContext.behaviorState = BEHAVIORSTATE_IDLE;
        }
    }
    else if(BEHAVIORSTATE_IDLE == [myContext behaviorState])
    {
        BossWeapon* laserWeapon = [myContext bossWeapon];
        [laserWeapon enemyFire:givenEnemy fromPos:[givenEnemy pos] elapsed:elapsed];
        if([[laserWeapon activeComponents] count] > 0)
        {
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TLANIMKEY_FIRE];
            [givenEnemy.curAnimClip playClipForward:YES];
            myContext.behaviorState = BEHAVIORSTATE_ACTIVE;
        }
    }
    else
    {
        // do nothing
    }
}

- (NSString*) getEnemyTypeName
{
    return _typeName;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    TurretLaserContext* myContext = [givenEnemy behaviorContext];
    if(BEHAVIORSTATE_ACTIVE == [myContext behaviorState])
    {
        [myContext.bossWeapon killAllComponents];
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TLANIMKEY_IDLE];
        [givenEnemy.curAnimClip playClipForward:YES];
        myContext.behaviorState = BEHAVIORSTATE_IDLE;
    }
}


#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    enemy.health--;
    TurretLaserContext* myContext = [enemy behaviorContext];
    myContext.hitCounts++;
    if(NUM_HITS_PER_RESPONSE <= myContext.hitCounts)
    {
        myContext.hitCounts = 0;
        CGPoint hitPos = CGPointMake(givenAABB.origin.x + (0.5f * givenAABB.size.width),
                                     givenAABB.origin.y + (0.5f * givenAABB.size.height));
        [EffectFactory effectNamed:@"BulletHit" atPos:hitPos];
    }
}

- (BOOL) isPlayerCollidable
{
    return NO;
}

- (BOOL) isPlayerWeapon
{
    return NO;
}

- (BOOL) isCollidable
{
    return YES;
}

- (BOOL) isCollisionOnFor:(Enemy *)enemy
{
    BOOL result = YES;
    if(![enemy readyToFire])
    {
        // not ready for collision if not ready to fire
        result = NO;
    }
    else if([enemy incapacitated])
    {
        result = NO;
    }
    return result;
}


#pragma mark -
#pragma mark EnemyAABBDelegate
- (CGRect) getAABB:(Enemy *)givenEnemy
{
    float halfWidth = givenEnemy.colAABB.size.width * 0.5f;
    float halfHeight = givenEnemy.colAABB.size.height * 0.5f;
    TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
    CGPoint myPos = [self derivePosFromParentForEnemy:givenEnemy];
    CGPoint firingPos = myPos;
    if([givenEnemy isGrounded])
    {
        // on the ground, so, it's position needs to be transformed to cam space
        firingPos = [gameCam camPointFromWorldPoint:myPos atDistance:[[givenEnemy behaviorContext] layerDistance]];
    }
    CGRect result = CGRectMake(firingPos.x - halfWidth, firingPos.y - halfHeight, givenEnemy.colAABB.size.width, givenEnemy.colAABB.size.height);
    return result;  
}

#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    if(![givenEnemy incapacitated])
    {
        TurretLaserContext* myContext = [givenEnemy behaviorContext];

        // kill boss weapon
        if([myContext bossWeapon])
        {
            [myContext.bossWeapon killAllComponents];
            myContext.bossWeapon = nil;
        }
    }
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    TurretLaserContext* myContext = [givenEnemy behaviorContext];

    // kill boss weapon
    if([myContext bossWeapon])
    {
        [myContext.bossWeapon killAllComponents];
        myContext.bossWeapon = nil;
    }
    
    // put gun in destroyed anim state
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TLANIMKEY_DESTROYED];
    [givenEnemy.curAnimClip playClipForward:YES];    
    
    // play sound
    [[SoundManager getInstance] playClip:@"TurretHit"];
    
    // interrupt any state and put the gun into the DESTROYED state
    myContext.behaviorState = BEHAVIORSTATE_DESTROYED;

    // drop loots
    if([[GameManager getInstance] shouldReleasePickups])
    {   
        // dequeue game manager pickup
        NSString* pickupType = [[GameManager getInstance] dequeueNextUpgradePack];
        if(pickupType)
        {
            CGPoint myPos = [self derivePosFromParentForEnemy:givenEnemy];
            CGPoint firingPos = myPos;
            if([givenEnemy isGrounded])
            {
                // on the ground, so, it's position needs to be transformed to cam space
                TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
                firingPos = [gameCam camPointFromWorldPoint:myPos atDistance:[[givenEnemy behaviorContext] layerDistance]];
            }

            Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:pickupType atPos:firingPos 
                                                                             isDynamics:YES 
                                                                    groundedBucketIndex:0 
                                                                          layerDistance:0.0f];
            [newLoot spawn];
            [newLoot release];
        }
    }
        
    // show points gained
    if(showPoints)
    {
        CGPoint effectPos = [self derivePosFromParentForEnemy:givenEnemy];
        if([givenEnemy isGrounded])
        {
            // on the ground, so, it's position needs to be transformed to cam space
            TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
            effectPos = [gameCam camPointFromWorldPoint:effectPos atDistance:[[givenEnemy behaviorContext] layerDistance]];
        }
        [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                               atPos:effectPos];
    }
    
    // returns false to leave the destroyed enemy object around until it's off screen
    return NO;
}

@end
