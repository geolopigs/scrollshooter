//
//  TurretSingle.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TurretSingle.h"
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
#include "MathUtils.h"

enum BehaviorStates 
{
    BEHAVIORSTATE_INIT = 0,
    BEHAVIORSTATE_IDLE,
    BEHAVIORSTATE_TARGETING,
    BEHAVIORSTATE_FIRING,
    BEHAVIORSTATE_DESTROYED,
    
    BEHAVIORSTATE_NUM
};


static const int INIT_HEALTH = 15;

static const float SHOT_OFFSETY = 9.0f;

static const float HOVERVEL_X = -1.0f;
static const float EXITVEL_X = 40.0f;
static const float EXITVEL_Y = -40.0f;
static const float HOVERING_POS = 120.0f;
static const float HOVERING_DURATION = 10.0f;
static const float TIME_TILL_FIRE = 0.25f;
static const float TIME_TILL_NEXTTARGET = 0.75f;
static const float TIME_TILL_NEXTTARGET_CONSEC = 0.2f;
static const unsigned NUM_CONSEC_SHOTS = 3;

static const unsigned int NUM_HITS_PER_RESPONSE = 1;    // number of hits this guy takes before reacting with an anim

static const NSString* ANIMKEY_IDLE = @"idle";
static const NSString* ANIMKEY_FIRE = @"fire";
static const NSString* ANIMKEY_DESTROYED_TURRET_A = @"dta";
static const NSString* ANIMKEY_DESTROYED_TURRET_B = @"dtb";

// firing configs
static const float SHOTSPEED = 50.0f;
static const float FIRING_ANGLES[5] = 
{
    (2.0f * M_PI) - M_PI_4,
    0.0f,
    M_PI_4,
    (M_PI_4 * 0.3f),
    (2.0f * M_PI) - (M_PI_4 * 0.4f)
};
static const float ANGULARSPEED = M_PI * 0.75f;

@implementation TurretSingleContext
@synthesize timeTillFire;
@synthesize shotsFired;
@synthesize hitCounts;
@synthesize fireSlot;
@synthesize layerDistance;
@synthesize rotateParamTarget;
@synthesize rotateParam;
@synthesize rotateSpeed;
@synthesize behaviorState;
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
        timeTillFire = TIME_TILL_NEXTTARGET;
        shotsFired = 0;
    }
    return self;
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
        rotateSpeed = ANGULARSPEED;
        rotateParamTarget = diffPositive / ANGULARSPEED;
    }
    else
    {
        // rotate in the negative direction
        rotateSpeed = -ANGULARSPEED;
        rotateParamTarget = diffNegative / ANGULARSPEED;
    }
}

@end

@interface TurretSingle (PrivateMethods)
- (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy;
@end

@implementation TurretSingle

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
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:@"TurretSingle"];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
        
    // init the anim registry
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    AnimClipData* clipData = [animData getClipForName:@"TurretSingleIdle"];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_IDLE];
    [newClip release];
    
    clipData = [animData getClipForName:@"TurretSingleFire"];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_FIRE];
    [newClip release];
    
    clipData = [animData getClipForName:@"TurretSingleDestroyedA"];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_DESTROYED_TURRET_A];
    [newClip release];

    clipData = [animData getClipForName:@"TurretSingleDestroyedB"];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_DESTROYED_TURRET_B];
    [newClip release];

    // init animclip to idle
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:@"TurretSingle"];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    givenEnemy.collisionAABBDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = INIT_HEALTH;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(TurretSpawnerContext*)spawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    
    // init its context given the spawner's context
    TurretSingleContext* newContext = [[TurretSingleContext alloc] init];
    newContext.fireSlot = [spawnerContext firingSlot];
    newContext.timeTillFire = 1.0f;
    newContext.layerDistance = [spawnerContext layerDistance];
    givenEnemy.behaviorContext = newContext;
    [newContext release];

}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    TurretSingleContext* myContext = [givenEnemy behaviorContext];
    
    // special case for one-time init
    if(BEHAVIORSTATE_INIT == myContext.behaviorState)
    {
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
        [givenEnemy.curAnimClip playClipForward:YES];
        myContext.behaviorState = BEHAVIORSTATE_IDLE;
    }
    
    // regular state processing
    if(BEHAVIORSTATE_IDLE == myContext.behaviorState)
    {
        myContext.timeTillFire -= elapsed;
        if(myContext.timeTillFire <= 0.0f)
        {
            myContext.timeTillFire = TIME_TILL_FIRE;
            myContext.behaviorState = BEHAVIORSTATE_TARGETING;
            [myContext setupRotationParamsForSrc:givenEnemy.rotate target:FIRING_ANGLES[myContext.fireSlot]];
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
            // done targeting, fire
            if([givenEnemy readyToFire])
            {
                myContext.behaviorState = BEHAVIORSTATE_FIRING;
                givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_FIRE];
                [givenEnemy.curAnimClip playClipForward:YES];
            }
            else
            {
                // not ready to fire, go back to IDLE
                myContext.behaviorState = BEHAVIORSTATE_IDLE;
                myContext.timeTillFire = TIME_TILL_NEXTTARGET * randomFrac();
            }
        }
    }
    else if(BEHAVIORSTATE_FIRING == myContext.behaviorState)
    {       
        myContext.timeTillFire -= elapsed;
        if(myContext.timeTillFire <= 0.0f)
        {
            // fire
            CGPoint firingDir = CGPointMake(0.0f, -1.0f);   // -1 for y because enemy sprite assets face downwards
            CGAffineTransform t = CGAffineTransformMakeRotation(givenEnemy.rotate);
            CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
            CGPoint vel = CGPointMake(dir.x * SHOTSPEED, dir.y * SHOTSPEED);
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
            [givenEnemy fireFromPos:firingPos withVel:vel];
            
            myContext.shotsFired++;
            myContext.fireSlot = (myContext.fireSlot + 1) % 5;
            
            if(myContext.shotsFired < NUM_CONSEC_SHOTS)
            {
                myContext.timeTillFire = TIME_TILL_NEXTTARGET_CONSEC;
            }
            else
            {
                myContext.shotsFired = 0;
                myContext.timeTillFire = TIME_TILL_NEXTTARGET * randomFrac();
            }
            myContext.behaviorState = BEHAVIORSTATE_IDLE;
            
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
            [givenEnemy.curAnimClip playClipForward:YES];
        }
    }
}

- (NSString*) getEnemyTypeName
{
    return @"TurretSingle";
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
    TurretSingleContext* myContext = [enemy behaviorContext];
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
    TurretSingleContext* myContext = [givenEnemy behaviorContext];

    // put gun in destroyed anim state
    if(randomFrac() > 0.6f)
    {
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_DESTROYED_TURRET_A];
    }
    else
    {
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_DESTROYED_TURRET_B];
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
