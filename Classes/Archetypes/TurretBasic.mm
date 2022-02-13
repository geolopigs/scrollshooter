//
//  TurretBasic.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TurretBasic.h"
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
    BEHAVIORSTATE_INITIDLE,
    BEHAVIORSTATE_IDLE,
    BEHAVIORSTATE_TARGETING,
    BEHAVIORSTATE_FIRING,
    BEHAVIORSTATE_DESTROYED,
    
    BEHAVIORSTATE_NUM
};


static const float SHOT_OFFSETY = 9.0f;
static const float FIREANIM_LENGTH = 0.17f;

static const unsigned int NUM_HITS_PER_RESPONSE = 1;    // number of hits this guy takes before reacting with an anim

const NSString* TBANIMKEY_IDLE = @"idle";
const NSString* TBANIMKEY_FIRE = @"fire";
const NSString* TBANIMKEY_DESTROYED_TURRET_A = @"dta";
const NSString* TBANIMKEY_DESTROYED_TURRET_B = @"dtb";

@implementation TurretBasicContext
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
        hitCounts = 0;
        rotateParamTarget = 0.0f;
        rotateParam = 0.0f;
        rotateSpeed = 0.0f;
        behaviorState = BEHAVIORSTATE_INIT;
        idleTimer = 0.0f;
        timeTillFire = 0.0f;
        shotsFired = 0;
        fireSlot = 0;
        
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
        self.initHealth = [[triggerContext objectForKey:@"initHealth"] intValue];
        self.angularSpeed = [[triggerContext objectForKey:@"angularSpeed"] floatValue] * M_PI;
        self.angleA = normalizeAngle([[triggerContext objectForKey:@"angleA"] floatValue] * M_PI);
        self.angleB = normalizeAngle([[triggerContext objectForKey:@"angleB"] floatValue] * M_PI);
        // setup scatter bomb if config has it
        NSDictionary* scatterBomb = [triggerContext objectForKey:@"scatterBomb"];
        if(scatterBomb)
        {
            self.scatterBombContext = scatterBomb;
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

@interface TurretBasic (PrivateMethods)
- (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy;
@end

@implementation TurretBasic
@synthesize typeName = _typeName;
@synthesize sizeName = _sizeName;
@synthesize animStates = _animStates;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.typeName = @"TurretBasic";
        self.sizeName = @"TurretBasic";
        self.animStates = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                               @"TurretSingleIdle",
                                                               @"TurretSingleFire",
                                                               @"TurretSingleDestroyedA",
                                                               @"TurretSingleDestroyedB",
                                                               nil]
                                                      forKeys:[NSArray arrayWithObjects:
                                                               TBANIMKEY_IDLE,
                                                               TBANIMKEY_FIRE,
                                                               TBANIMKEY_DESTROYED_TURRET_A,
                                                               TBANIMKEY_DESTROYED_TURRET_B,
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
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TBANIMKEY_IDLE];
    
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
    TurretBasicContext* newContext = [[TurretBasicContext alloc] init];
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
    TurretBasicContext* myContext = [givenEnemy behaviorContext];
    
    // special case for one-time init
    if(BEHAVIORSTATE_INIT == myContext.behaviorState)
    {
        givenEnemy.health = [myContext initHealth];
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TBANIMKEY_IDLE];
        [givenEnemy.curAnimClip playClipForward:YES];
        myContext.behaviorState = BEHAVIORSTATE_INITIDLE;
    }
    
    // regular state processing
    if((BEHAVIORSTATE_IDLE == myContext.behaviorState) ||
       (BEHAVIORSTATE_INITIDLE == myContext.behaviorState))
    {
        myContext.idleTimer -= elapsed;
        if(myContext.idleTimer <= 0.0f)
        {
            myContext.idleTimer = 0.0f;
            myContext.timeTillFire = 0.0f;
            
            float targetAngle = 0;
            if(BEHAVIORSTATE_INITIDLE == myContext.behaviorState)
            {
                myContext.behaviorState = BEHAVIORSTATE_TARGETING;
                targetAngle = myContext.angleA;
                myContext.fireSlot = 0;
                if(randomFrac() < 0.5f)
                {
                    targetAngle = myContext.angleB;
                    myContext.fireSlot = 1;
                }
            }
            else
            {
                myContext.behaviorState = BEHAVIORSTATE_FIRING;
                myContext.timeTillFire = FIREANIM_LENGTH;
                if([givenEnemy readyToFire])
                {
                    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TBANIMKEY_FIRE];
                    [givenEnemy.curAnimClip playClipForward:YES];  
                }
                if(myContext.fireSlot)
                {
                    targetAngle = myContext.angleA;
                    myContext.fireSlot = 0;
                }
                else
                {
                    targetAngle = myContext.angleB;
                    myContext.fireSlot = 1;
                }
            }
            [myContext setupRotationParamsForSrc:givenEnemy.rotate target:targetAngle];
        }
    }
    else if(BEHAVIORSTATE_TARGETING == myContext.behaviorState)
    {
        myContext.rotateParam = myContext.rotateParam + elapsed;
        
        // update rotation
        float newRotate = givenEnemy.rotate + (elapsed * myContext.rotateSpeed);
        if(0.0f > newRotate)
        {
            // normalize it to 0 to 2pi
            newRotate = (2.0f * M_PI) + newRotate;
        }
        givenEnemy.rotate = newRotate;
        
        if(myContext.rotateParamTarget <= myContext.rotateParam)
        {
            myContext.idleTimer = [myContext idleDelay];
            myContext.behaviorState = BEHAVIORSTATE_IDLE;
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TBANIMKEY_IDLE];
            [givenEnemy.curAnimClip playClipForward:YES];
        }
        
        myContext.timeTillFire -= elapsed;
        if(myContext.timeTillFire <= 0.0f)
        {
            myContext.timeTillFire = FIREANIM_LENGTH;
            myContext.behaviorState = BEHAVIORSTATE_FIRING;
            if([givenEnemy readyToFire])
            {
                givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TBANIMKEY_FIRE];
                [givenEnemy.curAnimClip playClipForward:YES];  
            }
        }
    }
    else if(BEHAVIORSTATE_FIRING == myContext.behaviorState)
    {       
        // fire
        myContext.timeTillFire -= elapsed;
        if(myContext.timeTillFire <= 0.0f)
        {
            CGPoint firingDir = CGPointMake(0.0f, -1.0f);   // -1 for y because enemy sprite assets face downwards
            CGAffineTransform t = CGAffineTransformMakeRotation(givenEnemy.rotate);
            CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
            float shotSpeed = [myContext shotSpeed];
            CGPoint vel = CGPointMake(dir.x * shotSpeed, dir.y * shotSpeed);
            CGPoint firingPosOffset = CGPointMake(SHOT_OFFSETY * dir.x, SHOT_OFFSETY * dir.y);
            
            CGPoint firingPos;
            if([givenEnemy isGrounded])
            {
                // on the ground, so, it's position needs to be transformed to cam space
                TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
                CGPoint myPos = [self derivePosFromParentForEnemy:givenEnemy];
                firingPos = [gameCam camPointFromWorldPoint:myPos atDistance:[myContext layerDistance]];
            }
            else
            {
                // otherwise, we're already in cam space;
                firingPos = [self derivePosFromParentForEnemy:givenEnemy];
            }
            
            firingPos.x += firingPosOffset.x;
            firingPos.y += firingPosOffset.y;
            
            if([myContext scatterBombContext])
            {
                [BossWeapon enemyFireScatterBomb:givenEnemy fromPos:firingPos withVel:vel triggerContext:[myContext scatterBombContext]];
            }
            else
            {
                [givenEnemy fireFromPos:firingPos withVel:vel];
            }
            myContext.shotsFired++;
            if(myContext.shotsFired < myContext.shotsPerRound)
            {
                myContext.timeTillFire = myContext.shotDelay;
            }
            else
            {
                myContext.shotsFired = 0;
                myContext.timeTillFire = [myContext roundDelay];
                myContext.behaviorState = BEHAVIORSTATE_TARGETING;
            }
            
            // retire out of screen turrets
            // only check against the bottom boundary of the playArea because Turrets scroll down
            CGRect playArea = [[GameManager getInstance] getPlayArea];
            float buffer = 0.1f;
            CGPoint retireBl = CGPointMake((-buffer * playArea.size.width) + playArea.origin.x,
                                           (-buffer * playArea.size.height) + playArea.origin.y);
            if(firingPos.y < retireBl.x)
            {
                givenEnemy.willRetire = YES;
            }            
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
    enemy.health--;
    TurretBasicContext* myContext = [enemy behaviorContext];
    myContext.hitCounts++;
    if(NUM_HITS_PER_RESPONSE <= myContext.hitCounts)
    {
        myContext.hitCounts = 0;
        CGRect myAABB = [enemy getAABB];
        CGPoint hitPos = CGPointMake(givenAABB.origin.x + (0.5f * givenAABB.size.width),
                                     myAABB.origin.y);
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
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    TurretBasicContext* myContext = [givenEnemy behaviorContext];

    // put gun in destroyed anim state
    if(randomFrac() > 0.6f)
    {
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TBANIMKEY_DESTROYED_TURRET_A];
    }
    else
    {
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:TBANIMKEY_DESTROYED_TURRET_B];
    }
    [givenEnemy.curAnimClip playClipForward:YES];    
    
    // scale it up for 4 because the texture for the destroyed state is 4-times zoomed out to accomodate for the smoke
    givenEnemy.scale = CGPointMake(4.0f, 4.0f);
    givenEnemy.rotate = 0.0f;
    
    // play sound
    [[SoundManager getInstance] playClip:@"TurretHit"];
    
    // interrupt any state and put the gun into the DESTROYED state
    myContext.behaviorState = BEHAVIORSTATE_DESTROYED;

    // drop loots
    if([[GameManager getInstance] shouldReleasePickups])
    {   
        // dequeue game manager pickup
        NSString* pickupType = [[GameManager getInstance] dequeueNextUpgradePack];
        if(nil == pickupType)
        {
            pickupType = @"LootCash";
        }
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
